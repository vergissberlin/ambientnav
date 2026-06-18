import 'dart:typed_data';

/// Little-endian read/write helpers shared by the BLE characteristic codecs.
///
/// The extended AmbientNav GATT protocol uses little-endian for all
/// multi-byte values, so these are the single source of truth for packing.
class ByteCodec {
  const ByteCodec._();

  static int u16(List<int> bytes, int offset) =>
      bytes[offset] | (bytes[offset + 1] << 8);

  static int u32(List<int> bytes, int offset) =>
      bytes[offset] |
      (bytes[offset + 1] << 8) |
      (bytes[offset + 2] << 16) |
      (bytes[offset + 3] << 24);

  /// Read a signed 16-bit little-endian value.
  static int i16(List<int> bytes, int offset) {
    final raw = u16(bytes, offset);
    return raw >= 0x8000 ? raw - 0x10000 : raw;
  }

  static void writeU16(List<int> out, int value) {
    out.add(value & 0xFF);
    out.add((value >> 8) & 0xFF);
  }

  static void writeU32(List<int> out, int value) {
    out.add(value & 0xFF);
    out.add((value >> 8) & 0xFF);
    out.add((value >> 16) & 0xFF);
    out.add((value >> 24) & 0xFF);
  }

  static void writeI16(List<int> out, int value) {
    final v = value & 0xFFFF;
    out.add(v & 0xFF);
    out.add((v >> 8) & 0xFF);
  }

  /// CRC-32 (IEEE 802.3) — used to verify OTA images before commit.
  static int crc32(List<int> data) {
    var crc = 0xFFFFFFFF;
    for (final byte in data) {
      crc ^= byte;
      for (var i = 0; i < 8; i++) {
        final mask = -(crc & 1);
        crc = (crc >> 1) ^ (0xEDB88320 & mask);
      }
    }
    return (crc ^ 0xFFFFFFFF) & 0xFFFFFFFF;
  }

  static Uint8List toBytes(List<int> values) => Uint8List.fromList(values);
}
