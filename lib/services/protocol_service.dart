/// Protocol layer for DPS-150 packet encoding and decoding.
///
/// This module handles the low-level protocol details:
/// - Packet encoding (outgoing commands)
/// - Packet decoding (incoming responses)
/// - Checksum calculation and verification
/// - Float/byte conversion (little-endian)
/// - Packet buffer management for stream parsing

import 'dart:typed_data';
import 'package:dps150_control/utils/constants.dart';

/// Exception for protocol errors.
class ProtocolError implements Exception {
  final String message;
  ProtocolError(this.message);
  @override
  String toString() => 'ProtocolError: $message';
}

/// Convert float to little-endian 32-bit IEEE 754 format.
Uint8List floatToBytes(double value) {
  final bytes = ByteData(4);
  bytes.setFloat32(0, value, Endian.little);
  return bytes.buffer.asUint8List();
}

/// Convert little-endian 32-bit IEEE 754 format to float.
double bytesToFloat(Uint8List data) {
  if (data.length < 4) {
    throw ProtocolError('Insufficient data for float: ${data.length} bytes');
  }
  final bytes = ByteData.sublistView(data, 0, 4);
  return bytes.getFloat32(0, Endian.little);
}

/// Calculate checksum for packet.
///
/// The DPS-150 protocol uses a simple checksum: sum of type code, length,
/// and all data bytes, modulo 256. Note that the header and command bytes
/// are NOT included in the checksum calculation.
///
/// Formula: checksum = (type_code + length + sum(data_bytes)) % 256
int calculateChecksum(int header, int command, int typeCode, Uint8List data) {
  final length = data.length;
  var checksum = typeCode + length;
  for (final byte in data) {
    checksum += byte;
  }
  return checksum % 256;
}

/// Encode a packet for transmission to the device.
///
/// Packet format: [0xF1, command, type, length, data..., checksum]
Uint8List encodePacket(int command, int typeCode, [Uint8List? data]) {
  data ??= Uint8List(0);
  final length = data.length;
  final packet = <int>[];
  
  packet.add(headerOutput);
  packet.add(command);
  packet.add(typeCode);
  packet.add(length);
  packet.addAll(data);
  
  // Calculate checksum
  final checksum = calculateChecksum(headerOutput, command, typeCode, data);
  packet.add(checksum);
  
  return Uint8List.fromList(packet);
}

/// Encode a packet with a float value.
Uint8List encodeFloatPacket(int command, int typeCode, double value) {
  final data = floatToBytes(value);
  return encodePacket(command, typeCode, data);
}

/// Encode a packet with a single byte value.
Uint8List encodeBytePacket(int command, int typeCode, int value) {
  if (value < 0 || value > 255) {
    throw ArgumentError('Byte value must be 0-255, got $value');
  }
  return encodePacket(command, typeCode, Uint8List.fromList([value]));
}

/// Decode a packet received from the device.
///
/// Packet format: [0xF0, command, type, length, data..., checksum]
///
/// Returns: (command, typeCode, length, data)
/// Throws: ProtocolError if packet is malformed or checksum is invalid
({int command, int typeCode, int length, Uint8List data}) decodePacket(
    Uint8List packet) {
  if (packet.length < 5) {
    throw ProtocolError('Packet too short: ${packet.length} bytes (minimum 5)');
  }

  if (packet[0] != headerInput) {
    throw ProtocolError(
        'Invalid header: expected 0x${headerInput.toRadixString(16).padLeft(2, '0')}, got 0x${packet[0].toRadixString(16).padLeft(2, '0')}');
  }

  final command = packet[1];
  final typeCode = packet[2];
  final length = packet[3];

  // Check packet length
  final expectedLength = 5 + length; // header + command + type + length + data + checksum
  if (packet.length < expectedLength) {
    throw ProtocolError(
        'Packet incomplete: expected $expectedLength bytes, got ${packet.length}');
  }

  final data = packet.sublist(4, 4 + length);
  final checksum = packet[4 + length];

  // Verify checksum
  final calculatedChecksum = calculateChecksum(headerInput, command, typeCode, data);
  if (checksum != calculatedChecksum) {
    throw ProtocolError(
        'Checksum mismatch: expected 0x${calculatedChecksum.toRadixString(16).padLeft(2, '0')}, got 0x${checksum.toRadixString(16).padLeft(2, '0')}');
  }

  return (
    command: command,
    typeCode: typeCode,
    length: length,
    data: data,
  );
}

/// Buffer for accumulating partial packets from serial stream.
///
/// The serial port may deliver data in chunks that don't align with packet
/// boundaries. This buffer accumulates incoming data and extracts complete
/// packets when they're available, leaving incomplete packets in the buffer
/// for the next read cycle.
class PacketBuffer {
  final List<int> _buffer = [];

  /// Append new data to buffer.
  void append(Uint8List data) {
    _buffer.addAll(data);
  }

  /// Extract complete packets from buffer.
  ///
  /// Scans the buffer for complete packets starting with HEADER_INPUT (0xF0).
  /// A complete packet has the format:
  /// [header, command, type, length, data..., checksum]
  /// where total length = 5 + length (header + command + type + length + data + checksum)
  ///
  /// Returns: List of complete packet bytes. Incomplete packets remain in buffer.
  List<Uint8List> extractPackets() {
    final packets = <Uint8List>[];
    var i = 0;

    while (i < _buffer.length - 5) {
      // Need at least 5 bytes (header + command + type + length + checksum)
      // Look for start byte
      if (_buffer[i] == headerInput) {
        // Found potential packet start
        if (i + 3 >= _buffer.length) {
          // Don't have length byte yet
          break;
        }

        final length = _buffer[i + 3];
        final packetLength = 5 + length; // header + command + type + length + data + checksum

        if (i + packetLength > _buffer.length) {
          // Don't have complete packet yet
          break;
        }

        // Extract complete packet
        final packet = Uint8List.fromList(_buffer.sublist(i, i + packetLength));
        packets.add(packet);
        i += packetLength;
      } else {
        i++;
      }
    }

    // Remove extracted packets from buffer
    if (packets.isNotEmpty) {
      _buffer.removeRange(0, i);
    }

    return packets;
  }

  /// Clear the buffer.
  void clear() {
    _buffer.clear();
  }
}
