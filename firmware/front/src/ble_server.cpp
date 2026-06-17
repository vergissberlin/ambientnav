#include "ble_server.h"
#include "config.h"
#include <NimBLEDevice.h>

static NimBLEServer*         pServer         = nullptr;
static NimBLECharacteristic* pNavChar        = nullptr;
static bool                  deviceConnected = false;

// ── Server callbacks ──────────────────────────────────────────────────────────
class ServerCallbacks : public NimBLEServerCallbacks {
    void onConnect(NimBLEServer* pSrv) override {
        deviceConnected = true;
        Serial.println("[BLE] client connected");
    }
    void onDisconnect(NimBLEServer* pSrv) override {
        deviceConnected = false;
        Serial.println("[BLE] client disconnected — restarting advertising");

        // Push a zeroed NavState so the orchestrator detects the drop
        NavState stale = {};
        stale.timestamp_ms = 0;  // forces BLE_FADE_TIMEOUT_MS to expire immediately
        xQueueOverwrite(navQueue, &stale);

        pSrv->startAdvertising();
    }
};

// ── Characteristic write callback ────────────────────────────────────────────
class NavCharCallbacks : public NimBLECharacteristicCallbacks {
    void onWrite(NimBLECharacteristic* pChar) override {
        const uint8_t* data = pChar->getValue().data();
        size_t         len  = pChar->getValue().length();

        if (len < 3) {
            Serial.printf("[BLE] bad payload length %u\n", len);
            return;
        }

        NavState state;
        state.direction    = static_cast<Direction>(data[0]);
        state.distance_m   = data[1];
        state.blinker      = static_cast<BlinkerState>(data[2]);
        state.timestamp_ms = millis();

        xQueueOverwrite(navQueue, &state);
    }
};

// ── Public init ───────────────────────────────────────────────────────────────
void bleServerInit() {
    NimBLEDevice::init(BLE_DEVICE_NAME);
    NimBLEDevice::setPower(ESP_PWR_LVL_P9);

    pServer = NimBLEDevice::createServer();
    pServer->setCallbacks(new ServerCallbacks());

    NimBLEService* pService = pServer->createService(BLE_SERVICE_UUID);

    pNavChar = pService->createCharacteristic(
        BLE_CHAR_UUID,
        NIMBLE_PROPERTY::WRITE_NR  // Write Without Response
    );
    pNavChar->setCallbacks(new NavCharCallbacks());

    pService->start();

    NimBLEAdvertising* pAdv = NimBLEDevice::getAdvertising();
    pAdv->addServiceUUID(BLE_SERVICE_UUID);
    pAdv->setScanResponse(false);
    pAdv->start();

    Serial.printf("[BLE] advertising as \"%s\"\n", BLE_DEVICE_NAME);
}
