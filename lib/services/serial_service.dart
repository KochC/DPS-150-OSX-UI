/// Async serial transport layer for DPS-150.
///
/// This module provides the low-level serial communication layer.
/// It handles:
/// - Async serial port connection/disconnection
/// - Background reading and packet extraction
/// - Thread-safe writing with proper locking
/// - Packet buffer management for stream parsing
/// - Port scanning and device detection

import 'dart:async';
import 'dart:typed_data';
// TODO: Implement serial port communication via platform channels
// The serial_port packages don't exist, so we need to create platform channel implementations
import 'package:dps150_control/services/protocol_service.dart';
import 'package:dps150_control/utils/constants.dart';
import 'package:flutter/services.dart';

/// Exception for connection errors.
class SerialConnectionError implements Exception {
  final String message;
  SerialConnectionError(this.message);
  @override
  String toString() => 'SerialConnectionError: $message';
}

/// Serial port information.
class SerialPortInfo {
  final String device;
  final String? description;
  final int? vid;
  final int? pid;
  final String? serialNumber;

  SerialPortInfo({
    required this.device,
    this.description,
    this.vid,
    this.pid,
    this.serialNumber,
  });
}

/// Async serial transport for DPS-150 device.
/// 
/// Serial port communication is implemented via platform channels.
class SerialTransport {
  final String port;
  final Function(int command, int typeCode, Uint8List data)? onPacketReceived;
  
  static const MethodChannel _channel = MethodChannel('dps150_control/serial');
  final PacketBuffer _buffer = PacketBuffer();
  bool _connected = false;
  Timer? _readTimer;
  String? _currentPort;

  SerialTransport(this.port, {this.onPacketReceived});

  /// Check if transport is connected.
  bool get isConnected => _connected;

  /// Connect to the serial port.
  /// TODO: Implement via platform channels
  Future<void> connect() async {
    if (_connected) return;

    try {
      final result = await _channel.invokeMethod('connect', {
        'port': port,
        'baudRate': baudRate,
        'dataBits': dataBits,
        'stopBits': stopBits,
        'parity': parity,
      });

      if (result == true) {
        _connected = true;
        _currentPort = port;
        _buffer.clear();
        // Start reading loop
        _startReadLoop();
      } else {
        throw SerialConnectionError('Failed to connect to $port');
      }
    } catch (e) {
      _connected = false;
      throw SerialConnectionError('Failed to connect to $port: $e');
    }
  }

  /// Disconnect from the serial port.
  Future<void> disconnect() async {
    _connected = false;
    _readTimer?.cancel();
    _readTimer = null;

    try {
      await _channel.invokeMethod('disconnect', {'port': _currentPort});
    } catch (e) {
      // Ignore errors during close
    }

    _currentPort = null;
    _buffer.clear();
  }

  /// Write data to the serial port.
  Future<void> write(Uint8List data) async {
    if (!_connected) {
      throw SerialConnectionError('Not connected');
    }

    try {
      await _channel.invokeMethod('write', {
        'port': _currentPort,
        'data': data,
      });
      // Small delay after write (matches Python implementation timing)
      await Future.delayed(const Duration(milliseconds: 50));
    } catch (e) {
      throw SerialConnectionError('Write failed: $e');
    }
  }

  /// Start background reading loop.
  void _startReadLoop() {
    // Use a timer to periodically read available data
    _readTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      if (!_connected) {
        timer.cancel();
        return;
      }

      try {
        final result = await _channel.invokeMethod('read', {'port': _currentPort});
        if (result != null) {
          Uint8List data;
          if (result is Uint8List) {
            data = result;
          } else if (result is List) {
            data = Uint8List.fromList(result.cast<int>());
          } else {
            return;
          }
          
          if (data.isNotEmpty) {
            _buffer.append(data);

            // Extract and process complete packets
            final packets = _buffer.extractPackets();
            for (final packet in packets) {
              try {
                final decoded = decodePacket(packet);
                if (onPacketReceived != null) {
                  onPacketReceived!(decoded.command, decoded.typeCode, decoded.data);
                }
              } on ProtocolError {
                // Log but continue processing
              }
            }
          }
        }
      } catch (e) {
        // Unexpected error, but continue
        if (!_connected) {
          timer.cancel();
        }
      }
    });
  }

  /// List all available serial ports.
  /// TODO: Implement via platform channels
  static Future<List<SerialPortInfo>> listPorts() async {
    try {
      final result = await _channel.invokeMethod('listPorts');
      if (result != null && result is List) {
        return result.map((port) {
          return SerialPortInfo(
            device: port['device'] ?? '',
            description: port['description'],
            vid: port['vid'],
            pid: port['pid'],
            serialNumber: port['serialNumber'],
          );
        }).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Find DPS-150 port by description patterns or USB modem pattern.
  static Future<String?> findDps150Port() async {
    final ports = await listPorts();
    
    for (final port in ports) {
      final device = port.device;
      final description = port.description?.toLowerCase() ?? '';
      
      // First, check for USB modem devices matching /dev/tty.usbmodem* or /dev/cu.usbmodem* pattern
      // macOS can return either tty (terminal) or cu (callout) devices
      // This matches devices like /dev/tty.usbmodem1475E18C40251 or /dev/cu.usbmodem1475E18C40251
      if (device.startsWith('/dev/tty.usbmodem') || device.startsWith('/dev/cu.usbmodem')) {
        return device;
      }
      
      // Check if description matches any pattern
      for (final pattern in deviceDescriptionPatterns) {
        if (description.contains(pattern.toLowerCase())) {
          return device;
        }
      }
      
      // Check VID/PID if available
      if (usbVid != null && usbPid != null) {
        if (port.vid == usbVid && port.pid == usbPid) {
          return device;
        }
      }
    }
    
    return null;
  }
}
