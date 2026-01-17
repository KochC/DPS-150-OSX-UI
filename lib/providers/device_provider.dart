/// Provider for device state management.
///
/// This provider wraps the DeviceService and provides reactive state updates
/// to the UI using the Provider pattern.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dps150_control/models/device_info.dart';
import 'package:dps150_control/models/device_state.dart';
import 'package:dps150_control/services/device_service.dart';
import 'package:dps150_control/services/serial_service.dart';

/// Connection status enum.
enum ConnectionStatus {
  disconnected,
  scanning,
  connecting,
  connected,
  error,
}

/// Device provider for state management.
class DeviceProvider extends ChangeNotifier {
  final DeviceService _deviceService = DeviceService();
  ConnectionStatus _status = ConnectionStatus.disconnected;
  String? _errorMessage;
  bool _autoConnect = true;
  List<SerialPortInfo> _availablePorts = [];

  DeviceProvider() {
    // Register callback for state updates
    _deviceService.onStateUpdate((state) {
      notifyListeners();
    });
  }

  /// Get current connection status.
  ConnectionStatus get status => _status;

  /// Get error message if any.
  String? get errorMessage => _errorMessage;

  /// Get auto-connect setting.
  bool get autoConnect => _autoConnect;

  /// Set auto-connect setting.
  set autoConnect(bool value) {
    _autoConnect = value;
    notifyListeners();
  }

  /// Get available serial ports.
  List<SerialPortInfo> get availablePorts => _availablePorts;

  /// Get current device state.
  DeviceState get state => _deviceService.state;

  /// Get device information.
  DeviceInfo get info => _deviceService.info;

  /// Check if device is connected.
  bool get isConnected => _deviceService.isConnected;

  /// Scan for available ports.
  Future<void> scanPorts() async {
    try {
      _availablePorts = await SerialTransport.listPorts();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to scan ports: $e';
      _status = ConnectionStatus.error;
      notifyListeners();
    }
  }

  /// Scan and auto-connect to DPS-150.
  Future<void> scanAndConnect({bool force = false}) async {
    if (!_autoConnect && !force) return;

    _status = ConnectionStatus.scanning;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _deviceService.scanAndConnect();
      if (success) {
        _status = ConnectionStatus.connected;
        _errorMessage = null;
        // Refresh available ports after connection
        await scanPorts();
      } else {
        _status = ConnectionStatus.disconnected;
        _errorMessage = 'No DPS-150 device found';
      }
    } catch (e) {
      _status = ConnectionStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  /// Connect to device on specified port.
  Future<void> connect(String port) async {
    _status = ConnectionStatus.connecting;
    _errorMessage = null;
    notifyListeners();

    try {
      await _deviceService.connect(port);
      _status = ConnectionStatus.connected;
      _errorMessage = null;
      // Refresh available ports after connection
      await scanPorts();
    } catch (e) {
      _status = ConnectionStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  /// Disconnect from device.
  Future<void> disconnect() async {
    try {
      await _deviceService.disconnect();
      _status = ConnectionStatus.disconnected;
      _errorMessage = null;
    } catch (e) {
      _status = ConnectionStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  /// Set voltage.
  Future<void> setVoltage(double value) async {
    try {
      await _deviceService.setVoltage(value);
    } catch (e) {
      _errorMessage = 'Failed to set voltage: $e';
      notifyListeners();
    }
  }

  /// Set current.
  Future<void> setCurrent(double value) async {
    try {
      await _deviceService.setCurrent(value);
    } catch (e) {
      _errorMessage = 'Failed to set current: $e';
      notifyListeners();
    }
  }

  /// Enable output.
  Future<void> enableOutput() async {
    try {
      await _deviceService.enableOutput();
    } catch (e) {
      _errorMessage = 'Failed to enable output: $e';
      notifyListeners();
    }
  }

  /// Disable output.
  Future<void> disableOutput() async {
    try {
      await _deviceService.disableOutput();
    } catch (e) {
      _errorMessage = 'Failed to disable output: $e';
      notifyListeners();
    }
  }

  /// Set over-voltage protection.
  Future<void> setOvp(double value) async {
    try {
      await _deviceService.setOvp(value);
    } catch (e) {
      _errorMessage = 'Failed to set OVP: $e';
      notifyListeners();
    }
  }

  /// Set over-current protection.
  Future<void> setOcp(double value) async {
    try {
      await _deviceService.setOcp(value);
    } catch (e) {
      _errorMessage = 'Failed to set OCP: $e';
      notifyListeners();
    }
  }

  /// Set over-power protection.
  Future<void> setOpp(double value) async {
    try {
      await _deviceService.setOpp(value);
    } catch (e) {
      _errorMessage = 'Failed to set OPP: $e';
      notifyListeners();
    }
  }

  /// Set over-temperature protection.
  Future<void> setOtp(double value) async {
    try {
      await _deviceService.setOtp(value);
    } catch (e) {
      _errorMessage = 'Failed to set OTP: $e';
      notifyListeners();
    }
  }

  /// Set low-voltage protection.
  Future<void> setLvp(double value) async {
    try {
      await _deviceService.setLvp(value);
    } catch (e) {
      _errorMessage = 'Failed to set LVP: $e';
      notifyListeners();
    }
  }

  /// Set brightness.
  Future<void> setBrightness(int value) async {
    try {
      await _deviceService.setBrightness(value);
    } catch (e) {
      _errorMessage = 'Failed to set brightness: $e';
      notifyListeners();
    }
  }

  /// Set volume.
  Future<void> setVolume(int value) async {
    try {
      await _deviceService.setVolume(value);
    } catch (e) {
      _errorMessage = 'Failed to set volume: $e';
      notifyListeners();
    }
  }

  /// Set preset group.
  Future<void> setGroup(int group, double voltage, double current) async {
    try {
      await _deviceService.setGroup(group, voltage, current);
    } catch (e) {
      _errorMessage = 'Failed to set group: $e';
      notifyListeners();
    }
  }

  /// Load preset group.
  Future<void> loadGroup(int group) async {
    try {
      await _deviceService.loadGroup(group);
    } catch (e) {
      _errorMessage = 'Failed to load group: $e';
      notifyListeners();
    }
  }

  /// Start energy metering.
  Future<void> startMetering() async {
    try {
      await _deviceService.startMetering();
    } catch (e) {
      _errorMessage = 'Failed to start metering: $e';
      notifyListeners();
    }
  }

  /// Stop energy metering.
  Future<void> stopMetering() async {
    try {
      await _deviceService.stopMetering();
    } catch (e) {
      _errorMessage = 'Failed to stop metering: $e';
      notifyListeners();
    }
  }

  /// Get device info.
  Future<void> refreshInfo() async {
    try {
      await _deviceService.getInfo();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to get info: $e';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _deviceService.disconnect();
    super.dispose();
  }
}
