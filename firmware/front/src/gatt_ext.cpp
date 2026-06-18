#include "gatt_ext.h"
#include "config.h"
#include "bt_classic.h"
#include <NimBLEDevice.h>
#include <ArduinoJson.h>
#include <esp_ota_ops.h>
#include <esp_partition.h>
#include <esp_system.h>
#include <string.h>

static NimBLECharacteristic* pVoltageChar = nullptr;

// ── little-endian helpers ─────────────────────────────────────────────────────
static uint16_t rd_u16(const uint8_t* p) { return p[0] | (p[1] << 8); }
static uint32_t rd_u32(const uint8_t* p) {
    return (uint32_t)p[0] | ((uint32_t)p[1] << 8) | ((uint32_t)p[2] << 16) |
           ((uint32_t)p[3] << 24);
}

// Chainable CRC-32 (IEEE). Maintain the running state un-inverted across calls;
// init with 0xFFFFFFFF and XOR with 0xFFFFFFFF once at the end to get the final
// value (matching the app-side ByteCodec.crc32 / OtaCodec).
static uint32_t crc32_chain(uint32_t crc, const uint8_t* data, size_t len) {
    for (size_t i = 0; i < len; i++) {
        crc ^= data[i];
        for (int b = 0; b < 8; b++) {
            uint32_t mask = -(crc & 1);
            crc = (crc >> 1) ^ (0xEDB88320u & mask);
        }
    }
    return crc;
}

// ── LED config characteristic ─────────────────────────────────────────────────
class LedCfgCallbacks : public NimBLECharacteristicCallbacks {
    void onRead(NimBLECharacteristic* c) override {
        uint8_t buf[8];
        if (xSemaphoreTake(configMutex, pdMS_TO_TICKS(20)) == pdTRUE) {
            buf[0] = g_ledConfig.led_count & 0xFF;
            buf[1] = (g_ledConfig.led_count >> 8) & 0xFF;
            buf[2] = g_ledConfig.brightness;
            buf[3] = g_ledConfig.effect;
            for (int i = 0; i < 4; i++) buf[4 + i] = g_ledConfig.params[i];
            xSemaphoreGive(configMutex);
        }
        c->setValue(buf, sizeof(buf));
    }
    void onWrite(NimBLECharacteristic* c) override {
        std::string v = c->getValue();
        if (v.size() < 8) return;
        const uint8_t* d = (const uint8_t*)v.data();
        if (xSemaphoreTake(configMutex, pdMS_TO_TICKS(20)) == pdTRUE) {
            uint16_t count = rd_u16(d);
            if (count == 0) count = 1;
            if (count > FRONT_LED_COUNT) count = FRONT_LED_COUNT;
            g_ledConfig.led_count  = count;
            g_ledConfig.brightness = d[2];
            g_ledConfig.effect     = d[3];
            for (int i = 0; i < 4; i++) g_ledConfig.params[i] = d[4 + i];
            xSemaphoreGive(configMutex);
        }
        Serial.println("[GATT] LED config updated");
    }
};

// ── Sensor config characteristic (forwarded to rear over SPP) ─────────────────
class SensorCfgCallbacks : public NimBLECharacteristicCallbacks {
    void onRead(NimBLECharacteristic* c) override {
        uint8_t buf[5];
        if (xSemaphoreTake(configMutex, pdMS_TO_TICKS(20)) == pdTRUE) {
            buf[0] = g_sensorConfig.active_sensor;
            buf[1] = g_sensorConfig.calib_offset_cm & 0xFF;
            buf[2] = (g_sensorConfig.calib_offset_cm >> 8) & 0xFF;
            buf[3] = g_sensorConfig.max_range_cm & 0xFF;
            buf[4] = (g_sensorConfig.max_range_cm >> 8) & 0xFF;
            xSemaphoreGive(configMutex);
        }
        c->setValue(buf, sizeof(buf));
    }
    void onWrite(NimBLECharacteristic* c) override {
        std::string v = c->getValue();
        if (v.size() < 5) return;
        const uint8_t* d = (const uint8_t*)v.data();
        int16_t offset = (int16_t)rd_u16(d + 1);
        uint16_t range = rd_u16(d + 3);
        if (xSemaphoreTake(configMutex, pdMS_TO_TICKS(20)) == pdTRUE) {
            g_sensorConfig.active_sensor   = d[0];
            g_sensorConfig.calib_offset_cm = offset;
            g_sensorConfig.max_range_cm    = range;
            xSemaphoreGive(configMutex);
        }
        // Forward to the rear controller, which owns the sensors.
        StaticJsonDocument<128> doc;
        doc["cmd"]          = "sensorcfg";
        doc["sensor"]       = d[0];
        doc["calib_cm"]     = offset;
        doc["max_range_cm"] = range;
        char out[128];
        serializeJson(doc, out, sizeof(out));
        sppSend(out);
        Serial.println("[GATT] sensor config forwarded to rear");
    }
};

// ── OTA characteristics ───────────────────────────────────────────────────────
class OtaState {
public:
    esp_ota_handle_t handle = 0;
    const esp_partition_t* partition = nullptr;
    bool active = false;
    uint32_t expectedLen = 0;
    uint32_t expectedCrc = 0;
    uint32_t written = 0;
    uint32_t runningCrc = 0;
};
static OtaState ota;
static NimBLECharacteristic* pOtaCtrl = nullptr;

static void otaNotify(const char* status) {
    if (!pOtaCtrl) return;
    pOtaCtrl->setValue((uint8_t*)status, strlen(status));
    pOtaCtrl->notify();
}

class OtaCtrlCallbacks : public NimBLECharacteristicCallbacks {
    void onWrite(NimBLECharacteristic* c) override {
        std::string v = c->getValue();
        if (v.empty()) return;
        const uint8_t* d = (const uint8_t*)v.data();
        uint8_t op = d[0];
        if (op == 0x00 && v.size() >= 9) {          // begin
            ota.partition = esp_ota_get_next_update_partition(nullptr);
            if (!ota.partition) { otaNotify("err:partition"); return; }
            ota.expectedLen = rd_u32(d + 1);
            ota.expectedCrc = rd_u32(d + 5);
            ota.written = 0;
            ota.runningCrc = 0xFFFFFFFF;
            if (esp_ota_begin(ota.partition, ota.expectedLen, &ota.handle) != ESP_OK) {
                otaNotify("err:begin");
                return;
            }
            ota.active = true;
            otaNotify("ack:begin");
            Serial.printf("[OTA] begin, %u bytes\n", ota.expectedLen);
        } else if (op == 0x01) {                    // abort
            if (ota.active) { esp_ota_abort(ota.handle); ota.active = false; }
            otaNotify("ack:abort");
        } else if (op == 0x02) {                    // commit
            if (!ota.active) { otaNotify("err:inactive"); return; }
            ota.active = false;
            uint32_t finalCrc = ota.runningCrc ^ 0xFFFFFFFFu;
            if (finalCrc != ota.expectedCrc) {
                esp_ota_abort(ota.handle);
                otaNotify("err:crc");
                Serial.println("[OTA] CRC mismatch — aborted");
                return;
            }
            if (esp_ota_end(ota.handle) != ESP_OK) { otaNotify("err:end"); return; }
            if (esp_ota_set_boot_partition(ota.partition) != ESP_OK) {
                otaNotify("err:setboot");
                return;
            }
            otaNotify("ack:commit");
            Serial.println("[OTA] commit OK — rebooting");
            delay(200);
            esp_restart();
        }
    }
};

class OtaDataCallbacks : public NimBLECharacteristicCallbacks {
    void onWrite(NimBLECharacteristic* c) override {
        if (!ota.active) return;
        std::string v = c->getValue();
        if (v.size() < 2) return;                    // [seq u16][chunk]
        const uint8_t* d = (const uint8_t*)v.data();
        const uint8_t* chunk = d + 2;
        size_t len = v.size() - 2;
        if (esp_ota_write(ota.handle, chunk, len) != ESP_OK) {
            esp_ota_abort(ota.handle);
            ota.active = false;
            otaNotify("err:write");
            return;
        }
        ota.runningCrc = crc32_chain(ota.runningCrc, chunk, len);
        ota.written += len;
    }
};

// ── Public init ───────────────────────────────────────────────────────────────
void gattExtInit(NimBLEServer* server) {
    const uint32_t RW_ENC =
        NIMBLE_PROPERTY::READ | NIMBLE_PROPERTY::READ_ENC |
        NIMBLE_PROPERTY::READ_AUTHEN | NIMBLE_PROPERTY::WRITE |
        NIMBLE_PROPERTY::WRITE_ENC | NIMBLE_PROPERTY::WRITE_AUTHEN;

    // Telemetry: open-read voltage (notify) + device info.
    NimBLEService* tel = server->createService(BLE_SVC_TELEMETRY);
    pVoltageChar = tel->createCharacteristic(
        BLE_CHR_VOLTAGE, NIMBLE_PROPERTY::READ | NIMBLE_PROPERTY::NOTIFY);
    NimBLECharacteristic* info = tel->createCharacteristic(
        BLE_CHR_DEVINFO, NIMBLE_PROPERTY::READ);
    {
        uint8_t buf[1 + sizeof(FIRMWARE_VERSION)];
        buf[0] = DEVICE_ROLE;
        memcpy(buf + 1, FIRMWARE_VERSION, sizeof(FIRMWARE_VERSION) - 1);
        info->setValue(buf, sizeof(FIRMWARE_VERSION));  // role + version chars
    }
    tel->start();

    // LED config (secured).
    NimBLEService* led = server->createService(BLE_SVC_LEDCFG);
    NimBLECharacteristic* ledCfg = led->createCharacteristic(BLE_CHR_LEDCFG, RW_ENC);
    ledCfg->setCallbacks(new LedCfgCallbacks());
    led->start();

    // Sensor config (secured).
    NimBLEService* sen = server->createService(BLE_SVC_SENSORCFG);
    NimBLECharacteristic* senCfg =
        sen->createCharacteristic(BLE_CHR_SENSORCFG, RW_ENC);
    senCfg->setCallbacks(new SensorCfgCallbacks());
    sen->start();

    // OTA (secured): control (write/notify) + data (write without response).
    NimBLEService* otaSvc = server->createService(BLE_SVC_OTA);
    pOtaCtrl = otaSvc->createCharacteristic(
        BLE_CHR_OTA_CTRL,
        NIMBLE_PROPERTY::WRITE | NIMBLE_PROPERTY::WRITE_ENC |
            NIMBLE_PROPERTY::WRITE_AUTHEN | NIMBLE_PROPERTY::NOTIFY);
    pOtaCtrl->setCallbacks(new OtaCtrlCallbacks());
    NimBLECharacteristic* otaData = otaSvc->createCharacteristic(
        BLE_CHR_OTA_DATA, NIMBLE_PROPERTY::WRITE_NR |
                              NIMBLE_PROPERTY::WRITE_ENC |
                              NIMBLE_PROPERTY::WRITE_AUTHEN);
    otaData->setCallbacks(new OtaDataCallbacks());
    otaSvc->start();
}

void gattExtNotifyVoltage(uint16_t millivolts) {
    if (!pVoltageChar) return;
    uint8_t buf[2] = {(uint8_t)(millivolts & 0xFF), (uint8_t)(millivolts >> 8)};
    pVoltageChar->setValue(buf, sizeof(buf));
    pVoltageChar->notify();
}
