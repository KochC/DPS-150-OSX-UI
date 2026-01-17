/// Main DPS150 device class with high-level API.
///
/// This module provides the high-level API for controlling the DPS-150
/// power supply. It handles:
/// - Device connection and initialization
/// - Command encoding and sending
/// - Response parsing and state management
/// - Callback-based state monitoring
/// - All device operations (voltage, current, protection, etc.)

import 'dart:async';
import 'dart:typed_data';
import 'package:dps150_control/models/device_info.dart';
import 'package:dps150_control/models/device_state.dart';
import 'package:dps150_control/services/protocol_service.dart';
import 'package:dps150_control/services/serial_service.dart';
import 'package:dps150_control/utils/constants.dart';

/// Exception for device errors.
class DeviceError implements Exception {
  final String message;
  DeviceError(this.message);
  @override
  String toString() => 'DeviceError: $message';
}

/// Main class for controlling FNIRSI DPS-150 power supply.
class DeviceService {
  String? _port;
  SerialTransport? _transport;
  final DeviceState _state = DeviceState();
  final DeviceInfo _info = DeviceInfo();
  final List<void Function(DeviceState)> _callbacks = [];
  Timer? _pollingTimer;
  final Duration _pollingInterval = const Duration(seconds: 1);
  bool _isConnected = false;

  DeviceService({String? port}) : _port = port;

  /// Get current device state.
  DeviceState get state => _state;

  /// Get device information.
  DeviceInfo get info => _info;

  /// Check if device is connected.
  bool get isConnected => _isConnected;

  /// Register callback for state updates.
  void onStateUpdate(void Function(DeviceState) callback) {
    _callbacks.add(callback);
  }

  /// Remove callback.
  void removeStateUpdateCallback(void Function(DeviceState) callback) {
    _callbacks.remove(callback);
  }

  /// Scan ports and auto-connect to DPS-150.
  Future<bool> scanAndConnect() async {
    final port = await SerialTransport.findDps150Port();
    if (port != null) {
      return await connect(port);
    }
    return false;
  }

  /// Connect to the device.
  Future<bool> connect([String? port]) async {
    if (_isConnected) return true;

    if (port != null) {
      _port = port;
    } else if (_port == null) {
      final foundPort = await SerialTransport.findDps150Port();
      if (foundPort == null) {
        throw DeviceError('No DPS-150 port found');
      }
      _port = foundPort;
    }

    try {
      _transport = SerialTransport(_port!, onPacketReceived: _onPacketReceived);
      await _transport!.connect();
      _isConnected = true;

      // Initialize device
      await _initDevice();

      // Start polling
      _startPolling();

      return true;
    } catch (e) {
      _isConnected = false;
      throw DeviceError('Failed to connect: $e');
    }
  }

  /// Disconnect from the device.
  Future<void> disconnect() async {
    _stopPolling();
    _isConnected = false;

    if (_transport != null) {
      try {
        // Send disconnect command
        await _sendCommand(cmdC1, 0, Uint8List.fromList([0]));
      } catch (e) {
        // Ignore errors during disconnect
      }

      await _transport!.disconnect();
      _transport = null;
    }
  }

  /// Initialize device after connection.
  Future<void> _initDevice() async {
    // Step 1: Send connection/initialization command
    await _sendCommand(cmdC1, 0, Uint8List.fromList([1]));
    await Future.delayed(const Duration(milliseconds: 200));

    // Step 2: Set baud rate to 115200
    final baudIndex = baudRateOptions.indexOf(115200) + 1;
    await _sendCommand(cmdB0, 0, Uint8List.fromList([baudIndex]));
    await Future.delayed(const Duration(milliseconds: 200));

    // Step 3: Request device information
    await _sendCommand(cmdGet, modelName, Uint8List(0));
    await Future.delayed(const Duration(milliseconds: 300));

    await _sendCommand(cmdGet, hardwareVersion, Uint8List(0));
    await Future.delayed(const Duration(milliseconds: 300));

    await _sendCommand(cmdGet, firmwareVersion, Uint8List(0));
    await Future.delayed(const Duration(milliseconds: 300));

    // Step 4: Get complete device state
    await getAll();
    await Future.delayed(const Duration(milliseconds: 200));
  }

  /// Send a command to the device.
  Future<void> _sendCommand(int command, int typeCode, Uint8List data) async {
    if (!_isConnected || _transport == null) {
      throw DeviceError('Not connected');
    }

    final packet = encodePacket(command, typeCode, data);
    await _transport!.write(packet);
  }

  /// Handle received packet from device.
  void _onPacketReceived(int command, int typeCode, Uint8List data) {
    try {
      final parsedData = _parsePacketData(typeCode, data);
      if (parsedData != null) {
        // Update state
        _state.updateFromMap(parsedData);

        // Update info if applicable
        if (parsedData.containsKey('modelName')) {
          _info.modelName = parsedData['modelName'] as String;
        }
        if (parsedData.containsKey('hardwareVersion')) {
          _info.hardwareVersion = parsedData['hardwareVersion'] as String;
        }
        if (parsedData.containsKey('firmwareVersion')) {
          _info.firmwareVersion = parsedData['firmwareVersion'] as String;
        }

        // Invoke callbacks
        for (final callback in _callbacks) {
          try {
            callback(_state);
          } catch (e) {
            // Don't let callback errors break the system
          }
        }
      }
    } catch (e) {
      // Ignore parsing errors
    }
  }

  /// Parse packet data based on type code.
  Map<String, dynamic>? _parsePacketData(int typeCode, Uint8List data) {
    if (data.isEmpty) return null;

    final result = <String, dynamic>{};

    try {
      if (typeCode == inputVoltage) {
        result['inputVoltage'] = bytesToFloat(data);
      } else if (typeCode == outputVoltageCurrentPower) {
        if (data.length >= 12) {
          result['outputVoltage'] = bytesToFloat(data.sublist(0, 4));
          result['outputCurrent'] = bytesToFloat(data.sublist(4, 8));
          result['outputPower'] = bytesToFloat(data.sublist(8, 12));
        }
      } else if (typeCode == temperature) {
        result['temperature'] = bytesToFloat(data);
      } else if (typeCode == outputCapacity) {
        result['outputCapacity'] = bytesToFloat(data);
      } else if (typeCode == outputEnergy) {
        result['outputEnergy'] = bytesToFloat(data);
      } else if (typeCode == outputEnable) {
        result['outputClosed'] = data.isNotEmpty && data[0] == 1;
      } else if (typeCode == protectionState) {
        final stateIndex = data.isNotEmpty ? data[0] : 0;
        if (stateIndex >= 0 && stateIndex < protectionStates.length) {
          result['protectionState'] = protectionStates[stateIndex];
        }
      } else if (typeCode == mode) {
        result['mode'] = data.isNotEmpty && data[0] == 0 ? 'CC' : 'CV';
      } else if (typeCode == modelName) {
        final str = String.fromCharCodes(data);
        result['modelName'] = str.replaceAll('\x00', '').trim();
      } else if (typeCode == hardwareVersion) {
        final str = String.fromCharCodes(data);
        result['hardwareVersion'] = str.replaceAll('\x00', '').trim();
      } else if (typeCode == firmwareVersion) {
        final str = String.fromCharCodes(data);
        result['firmwareVersion'] = str.replaceAll('\x00', '').trim();
      } else if (typeCode == upperLimitVoltage) {
        result['upperLimitVoltage'] = bytesToFloat(data);
      } else if (typeCode == upperLimitCurrent) {
        result['upperLimitCurrent'] = bytesToFloat(data);
      } else if (typeCode == all) {
        // Parse complete state (type 255)
        if (data.length >= 139) {
          final allData = _parseAllPacket(data);
          result.addAll(allData);
        }
      }
    } catch (e) {
      // Parsing error, return null
      return null;
    }

    return result.isNotEmpty ? result : null;
  }

  /// Parse ALL packet (type 255) containing complete device state.
  Map<String, dynamic> _parseAllPacket(Uint8List data) {
    final result = <String, dynamic>{};

    // Measurements (floats, 4 bytes each)
    result['inputVoltage'] = bytesToFloat(data.sublist(0, 4));
    result['setVoltage'] = bytesToFloat(data.sublist(4, 8));
    result['setCurrent'] = bytesToFloat(data.sublist(8, 12));
    result['outputVoltage'] = bytesToFloat(data.sublist(12, 16));
    result['outputCurrent'] = bytesToFloat(data.sublist(16, 20));
    result['outputPower'] = bytesToFloat(data.sublist(20, 24));
    result['temperature'] = bytesToFloat(data.sublist(24, 28));

    // Group presets (floats, 4 bytes each, groups 1-6)
    result['group1setVoltage'] = bytesToFloat(data.sublist(28, 32));
    result['group1setCurrent'] = bytesToFloat(data.sublist(32, 36));
    result['group2setVoltage'] = bytesToFloat(data.sublist(36, 40));
    result['group2setCurrent'] = bytesToFloat(data.sublist(40, 44));
    result['group3setVoltage'] = bytesToFloat(data.sublist(44, 48));
    result['group3setCurrent'] = bytesToFloat(data.sublist(48, 52));
    result['group4setVoltage'] = bytesToFloat(data.sublist(52, 56));
    result['group4setCurrent'] = bytesToFloat(data.sublist(56, 60));
    result['group5setVoltage'] = bytesToFloat(data.sublist(60, 64));
    result['group5setCurrent'] = bytesToFloat(data.sublist(64, 68));
    result['group6setVoltage'] = bytesToFloat(data.sublist(68, 72));
    result['group6setCurrent'] = bytesToFloat(data.sublist(72, 76));

    // Protection settings (floats, 4 bytes each)
    result['overVoltageProtection'] = bytesToFloat(data.sublist(76, 80));
    result['overCurrentProtection'] = bytesToFloat(data.sublist(80, 84));
    result['overPowerProtection'] = bytesToFloat(data.sublist(84, 88));
    result['overTemperatureProtection'] = bytesToFloat(data.sublist(88, 92));
    result['lowVoltageProtection'] = bytesToFloat(data.sublist(92, 96));

    // Display and audio (single bytes)
    if (data.length > 96) result['brightness'] = data[96];
    if (data.length > 97) result['volume'] = data[97];
    if (data.length > 98) result['meteringClosed'] = data[98] == 0;

    // Energy metering (floats, 4 bytes each)
    if (data.length > 102) {
      result['outputCapacity'] = bytesToFloat(data.sublist(99, 103));
    }
    if (data.length > 106) {
      result['outputEnergy'] = bytesToFloat(data.sublist(103, 107));
    }

    // Status (single bytes)
    if (data.length > 107) result['outputClosed'] = data[107] == 1;
    if (data.length > 108 && data[108] >= 0 && data[108] < protectionStates.length) {
      result['protectionState'] = protectionStates[data[108]];
    }
    if (data.length > 109) {
      result['mode'] = data[109] == 0 ? 'CC' : 'CV';
    }

    // Limits (floats, 4 bytes each)
    if (data.length > 114) {
      result['upperLimitVoltage'] = bytesToFloat(data.sublist(111, 115));
    }
    if (data.length > 118) {
      result['upperLimitCurrent'] = bytesToFloat(data.sublist(115, 119));
    }

    return result;
  }

  /// Start polling for state updates.
  void _startPolling() {
    _stopPolling();
    _pollingTimer = Timer.periodic(_pollingInterval, (timer) async {
      if (_isConnected) {
        try {
          await getAll();
        } catch (e) {
          // Ignore polling errors
        }
      }
    });
  }

  /// Stop polling.
  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  // Reading methods

  /// Get complete device state.
  Future<DeviceState> getAll() async {
    await _sendCommand(cmdGet, all, Uint8List(0));
    await Future.delayed(const Duration(milliseconds: 100));
    return _state;
  }

  /// Get output voltage.
  Future<double> getVoltage() async {
    await getAll();
    return _state.outputVoltage;
  }

  /// Get output current.
  Future<double> getCurrent() async {
    await getAll();
    return _state.outputCurrent;
  }

  /// Get output power.
  Future<double> getPower() async {
    await getAll();
    return _state.outputPower;
  }

  /// Get device temperature.
  Future<double> getTemperature() async {
    await getAll();
    return _state.temperature;
  }

  /// Get device information.
  Future<DeviceInfo> getInfo() async {
    if (_info.modelName.isEmpty) {
      await _sendCommand(cmdGet, modelName, Uint8List(0));
      await Future.delayed(const Duration(milliseconds: 300));
    }
    if (_info.hardwareVersion.isEmpty) {
      await _sendCommand(cmdGet, hardwareVersion, Uint8List(0));
      await Future.delayed(const Duration(milliseconds: 300));
    }
    if (_info.firmwareVersion.isEmpty) {
      await _sendCommand(cmdGet, firmwareVersion, Uint8List(0));
      await Future.delayed(const Duration(milliseconds: 300));
    }
    return _info;
  }

  // Writing methods

  /// Set target voltage.
  Future<void> setVoltage(double value) async {
    await _sendCommand(cmdSet, voltageSet, floatToBytes(value));
  }

  /// Set target current.
  Future<void> setCurrent(double value) async {
    await _sendCommand(cmdSet, currentSet, floatToBytes(value));
  }

  /// Enable output.
  Future<void> enableOutput() async {
    await _sendCommand(cmdSet, outputEnable, Uint8List.fromList([1]));
  }

  /// Disable output.
  Future<void> disableOutput() async {
    await _sendCommand(cmdSet, outputEnable, Uint8List.fromList([0]));
  }

  /// Set over-voltage protection.
  Future<void> setOvp(double value) async {
    await _sendCommand(cmdSet, ovp, floatToBytes(value));
  }

  /// Set over-current protection.
  Future<void> setOcp(double value) async {
    await _sendCommand(cmdSet, ocp, floatToBytes(value));
  }

  /// Set over-power protection.
  Future<void> setOpp(double value) async {
    await _sendCommand(cmdSet, opp, floatToBytes(value));
  }

  /// Set over-temperature protection.
  Future<void> setOtp(double value) async {
    await _sendCommand(cmdSet, otp, floatToBytes(value));
  }

  /// Set low-voltage protection.
  Future<void> setLvp(double value) async {
    await _sendCommand(cmdSet, lvp, floatToBytes(value));
  }

  /// Set display brightness.
  Future<void> setBrightness(int value) async {
    if (value < 0 || value > 10) {
      throw ArgumentError('Brightness must be between 0 and 10');
    }
    await _sendCommand(cmdSet, brightness, Uint8List.fromList([value]));
  }

  /// Set beep volume.
  Future<void> setVolume(int value) async {
    if (value < 0 || value > 10) {
      throw ArgumentError('Volume must be between 0 and 10');
    }
    await _sendCommand(cmdSet, volume, Uint8List.fromList([value]));
  }

  /// Start energy metering.
  Future<void> startMetering() async {
    await _sendCommand(cmdSet, meteringEnable, Uint8List.fromList([1]));
  }

  /// Stop energy metering.
  Future<void> stopMetering() async {
    await _sendCommand(cmdSet, meteringEnable, Uint8List.fromList([0]));
  }

  /// Set preset group values.
  Future<void> setGroup(int group, double voltage, double current) async {
    if (group < 1 || group > 6) {
      throw ArgumentError('Group must be between 1 and 6');
    }

    final voltageType = group1VoltageSet + (group - 1) * 2;
    final currentType = group1CurrentSet + (group - 1) * 2;

    await _sendCommand(cmdSet, voltageType, floatToBytes(voltage));
    await _sendCommand(cmdSet, currentType, floatToBytes(current));
  }

  /// Load preset group values as current settings.
  Future<void> loadGroup(int group) async {
    if (group < 1 || group > 6) {
      throw ArgumentError('Group must be between 1 and 6');
    }

    // Get group values from state
    double voltage;
    double current;

    switch (group) {
      case 1:
        voltage = _state.group1SetVoltage;
        current = _state.group1SetCurrent;
        break;
      case 2:
        voltage = _state.group2SetVoltage;
        current = _state.group2SetCurrent;
        break;
      case 3:
        voltage = _state.group3SetVoltage;
        current = _state.group3SetCurrent;
        break;
      case 4:
        voltage = _state.group4SetVoltage;
        current = _state.group4SetCurrent;
        break;
      case 5:
        voltage = _state.group5SetVoltage;
        current = _state.group5SetCurrent;
        break;
      case 6:
        voltage = _state.group6SetVoltage;
        current = _state.group6SetCurrent;
        break;
      default:
        throw ArgumentError('Group must be between 1 and 6');
    }

    // Set as current values
    await setVoltage(voltage);
    await setCurrent(current);
  }
}
