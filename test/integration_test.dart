/// Integration tests for DPS-150 device with real hardware.
///
/// These tests require a physical DPS-150 device to be connected.
/// They will:
/// - Connect to the device
/// - Set voltage and current values
/// - Read back the values to verify they were set correctly
///
/// To run these tests:
///   flutter test test/integration_test.dart
///
/// Note: These tests will skip if no device is found.

import 'package:flutter_test/flutter_test.dart';
import 'package:dps150_control/services/device_service.dart';

void main() {
  // Initialize Flutter bindings for platform channels
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('DPS-150 Integration Tests', () {
    late DeviceService deviceService;
    const double tolerance = 0.1; // Allow 0.1V/0.1A tolerance for floating point precision
    
    // Set this to your device port if auto-detection doesn't work
    // Example: '/dev/tty.usbmodem1475E18C40251'
    // Set to null to use auto-detection
    const String? manualPort = '/dev/tty.usbmodem1475E18C40251';

    setUp(() async {
      deviceService = DeviceService();
    });

    tearDown(() async {
      // Always disable output and disconnect
      if (deviceService.isConnected) {
        try {
          await deviceService.disableOutput();
          await Future.delayed(const Duration(milliseconds: 500));
          await deviceService.disconnect();
        } catch (e) {
          // Ignore errors during cleanup
        }
      }
    });

    test('Connect to real device', () async {
      // Try to connect to device
      bool success = false;
      
      if (manualPort != null) {
        // Connect to manually specified port
        print('Connecting to manual port: $manualPort');
        try {
          success = await deviceService.connect(manualPort);
        } catch (e) {
          print('Failed to connect to $manualPort: $e');
          success = false;
        }
      } else {
        // Try auto-detection
        print('Attempting auto-detection...');
        success = await deviceService.scanAndConnect();
      }
      
      if (!success) {
        // Skip test if no device found
        print('⚠️  No DPS-150 device found. Skipping integration tests.');
        print('💡 Tip: Set manualPort in the test file to connect to a specific port.');
        print('   Example: const String? manualPort = "/dev/tty.usbmodem1475E18C40251";');
        return;
      }

      expect(deviceService.isConnected, isTrue);
      print('✓ Connected to device');
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('Set and read back voltage', () async {
      // Connect to device
      bool connected = false;
      if (manualPort != null) {
        connected = await deviceService.connect(manualPort);
      } else {
        connected = await deviceService.scanAndConnect();
      }
      if (!connected) {
        print('⚠️  No DPS-150 device found. Skipping test.');
        return;
      }

      // Wait for initial state to be loaded
      await Future.delayed(const Duration(milliseconds: 1000));
      await deviceService.getAll();
      await Future.delayed(const Duration(milliseconds: 500));

      // Test multiple voltage values
      final testVoltages = [5.0, 10.0, 12.0, 3.3, 0.0];
      
      for (final targetVoltage in testVoltages) {
        print('Testing voltage: ${targetVoltage}V');
        
        // Set voltage
        await deviceService.setVoltage(targetVoltage);
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Read back from device
        await deviceService.getAll();
        await Future.delayed(const Duration(milliseconds: 500));
        
        final readVoltage = deviceService.state.setVoltage;
        
        print('  Set: ${targetVoltage}V, Read: ${readVoltage}V');
        
        // Verify the value was set correctly (within tolerance)
        expect(
          (readVoltage - targetVoltage).abs(),
          lessThanOrEqualTo(tolerance),
          reason: 'Voltage mismatch: set ${targetVoltage}V but read ${readVoltage}V',
        );
      }
      
      print('✓ All voltage tests passed');
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('Set and read back current', () async {
      // Connect to device
      bool connected = false;
      if (manualPort != null) {
        connected = await deviceService.connect(manualPort);
      } else {
        connected = await deviceService.scanAndConnect();
      }
      if (!connected) {
        print('⚠️  No DPS-150 device found. Skipping test.');
        return;
      }

      // Wait for initial state to be loaded
      await Future.delayed(const Duration(milliseconds: 1000));
      await deviceService.getAll();
      await Future.delayed(const Duration(milliseconds: 500));

      // Test multiple current values
      final testCurrents = [0.5, 1.0, 2.0, 0.1, 0.0];
      
      for (final targetCurrent in testCurrents) {
        print('Testing current: ${targetCurrent}A');
        
        // Set current
        await deviceService.setCurrent(targetCurrent);
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Read back from device
        await deviceService.getAll();
        await Future.delayed(const Duration(milliseconds: 500));
        
        final readCurrent = deviceService.state.setCurrent;
        
        print('  Set: ${targetCurrent}A, Read: ${readCurrent}A');
        
        // Verify the value was set correctly (within tolerance)
        expect(
          (readCurrent - targetCurrent).abs(),
          lessThanOrEqualTo(tolerance),
          reason: 'Current mismatch: set ${targetCurrent}A but read ${readCurrent}A',
        );
      }
      
      print('✓ All current tests passed');
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('Set and read back voltage and current together', () async {
      // Connect to device
      bool connected = false;
      if (manualPort != null) {
        connected = await deviceService.connect(manualPort);
      } else {
        connected = await deviceService.scanAndConnect();
      }
      if (!connected) {
        print('⚠️  No DPS-150 device found. Skipping test.');
        return;
      }

      // Wait for initial state to be loaded
      await Future.delayed(const Duration(milliseconds: 1000));
      await deviceService.getAll();
      await Future.delayed(const Duration(milliseconds: 500));

      // Test combinations
      final testCombinations = [
        {'voltage': 5.0, 'current': 1.0},
        {'voltage': 12.0, 'current': 0.5},
        {'voltage': 3.3, 'current': 2.0},
        {'voltage': 0.0, 'current': 0.0},
      ];
      
      for (final combo in testCombinations) {
        final targetVoltage = combo['voltage'] as double;
        final targetCurrent = combo['current'] as double;
        
        print('Testing combination: ${targetVoltage}V / ${targetCurrent}A');
        
        // Set both values
        await deviceService.setVoltage(targetVoltage);
        await Future.delayed(const Duration(milliseconds: 300));
        await deviceService.setCurrent(targetCurrent);
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Read back from device
        await deviceService.getAll();
        await Future.delayed(const Duration(milliseconds: 500));
        
        final readVoltage = deviceService.state.setVoltage;
        final readCurrent = deviceService.state.setCurrent;
        
        print('  Set: ${targetVoltage}V / ${targetCurrent}A');
        print('  Read: ${readVoltage}V / ${readCurrent}A');
        
        // Verify both values were set correctly
        expect(
          (readVoltage - targetVoltage).abs(),
          lessThanOrEqualTo(tolerance),
          reason: 'Voltage mismatch: set ${targetVoltage}V but read ${readVoltage}V',
        );
        
        expect(
          (readCurrent - targetCurrent).abs(),
          lessThanOrEqualTo(tolerance),
          reason: 'Current mismatch: set ${targetCurrent}A but read ${readCurrent}A',
        );
      }
      
      print('✓ All combination tests passed');
    }, timeout: const Timeout(Duration(minutes: 3)));

    test('Set and read back protection settings', () async {
      // Connect to device
      bool connected = false;
      if (manualPort != null) {
        connected = await deviceService.connect(manualPort);
      } else {
        connected = await deviceService.scanAndConnect();
      }
      if (!connected) {
        print('⚠️  No DPS-150 device found. Skipping test.');
        return;
      }

      // Wait for initial state to be loaded
      await Future.delayed(const Duration(milliseconds: 1000));
      await deviceService.getAll();
      await Future.delayed(const Duration(milliseconds: 500));

      // Store original values to restore later
      final originalOvp = deviceService.state.overVoltageProtection;
      final originalOcp = deviceService.state.overCurrentProtection;
      final originalOpp = deviceService.state.overPowerProtection;

      try {
        // Test OVP
        print('Testing Over-Voltage Protection');
        await deviceService.setOvp(15.0);
        await Future.delayed(const Duration(milliseconds: 500));
        await deviceService.getAll();
        await Future.delayed(const Duration(milliseconds: 500));
        expect(
          (deviceService.state.overVoltageProtection - 15.0).abs(),
          lessThanOrEqualTo(tolerance),
          reason: 'OVP mismatch',
        );
        print('  OVP: Set 15.0V, Read ${deviceService.state.overVoltageProtection}V');

        // Test OCP
        print('Testing Over-Current Protection');
        await deviceService.setOcp(3.0);
        await Future.delayed(const Duration(milliseconds: 500));
        await deviceService.getAll();
        await Future.delayed(const Duration(milliseconds: 500));
        expect(
          (deviceService.state.overCurrentProtection - 3.0).abs(),
          lessThanOrEqualTo(tolerance),
          reason: 'OCP mismatch',
        );
        print('  OCP: Set 3.0A, Read ${deviceService.state.overCurrentProtection}A');

        // Test OPP
        print('Testing Over-Power Protection');
        await deviceService.setOpp(45.0);
        await Future.delayed(const Duration(milliseconds: 500));
        await deviceService.getAll();
        await Future.delayed(const Duration(milliseconds: 500));
        expect(
          (deviceService.state.overPowerProtection - 45.0).abs(),
          lessThanOrEqualTo(tolerance),
          reason: 'OPP mismatch',
        );
        print('  OPP: Set 45.0W, Read ${deviceService.state.overPowerProtection}W');
      } finally {
        // Restore original values
        try {
          await deviceService.setOvp(originalOvp);
          await deviceService.setOcp(originalOcp);
          await deviceService.setOpp(originalOpp);
          await Future.delayed(const Duration(milliseconds: 500));
        } catch (e) {
          // Ignore restore errors
        }
      }
      
      print('✓ All protection settings tests passed');
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('Enable and disable output', () async {
      // Connect to device
      bool connected = false;
      if (manualPort != null) {
        connected = await deviceService.connect(manualPort);
      } else {
        connected = await deviceService.scanAndConnect();
      }
      if (!connected) {
        print('⚠️  No DPS-150 device found. Skipping test.');
        return;
      }

      // Wait for initial state to be loaded
      await Future.delayed(const Duration(milliseconds: 1000));
      await deviceService.getAll();
      await Future.delayed(const Duration(milliseconds: 500));

      // Test enabling output
      print('Testing enable output');
      await deviceService.enableOutput();
      await Future.delayed(const Duration(milliseconds: 500));
      await deviceService.getAll();
      await Future.delayed(const Duration(milliseconds: 500));
      expect(deviceService.state.outputClosed, isTrue);
      print('  Output enabled: ${deviceService.state.outputClosed}');

      // Test disabling output
      print('Testing disable output');
      await deviceService.disableOutput();
      await Future.delayed(const Duration(milliseconds: 500));
      await deviceService.getAll();
      await Future.delayed(const Duration(milliseconds: 500));
      expect(deviceService.state.outputClosed, isFalse);
      print('  Output disabled: ${deviceService.state.outputClosed}');

      print('✓ Output control tests passed');
    }, timeout: const Timeout(Duration(minutes: 1)));

    test('Read live measurements', () async {
      // Connect to device
      bool connected = false;
      if (manualPort != null) {
        connected = await deviceService.connect(manualPort);
      } else {
        connected = await deviceService.scanAndConnect();
      }
      if (!connected) {
        print('⚠️  No DPS-150 device found. Skipping test.');
        return;
      }

      // Wait for initial state to be loaded
      await Future.delayed(const Duration(milliseconds: 1000));
      await deviceService.getAll();
      await Future.delayed(const Duration(milliseconds: 500));

      // Set some values
      await deviceService.setVoltage(5.0);
      await deviceService.setCurrent(1.0);
      await Future.delayed(const Duration(milliseconds: 500));

      // Enable output to get live readings
      await deviceService.enableOutput();
      await Future.delayed(const Duration(milliseconds: 1000));

      // Read measurements multiple times
      for (int i = 0; i < 3; i++) {
        await deviceService.getAll();
        await Future.delayed(const Duration(milliseconds: 500));

        final voltage = deviceService.state.outputVoltage;
        final current = deviceService.state.outputCurrent;
        final power = deviceService.state.outputPower;

        print('Reading ${i + 1}: ${voltage.toStringAsFixed(3)}V, '
            '${current.toStringAsFixed(3)}A, ${power.toStringAsFixed(3)}W');

        // Verify measurements are reasonable (not negative, within device limits)
        expect(voltage, greaterThanOrEqualTo(0.0));
        expect(current, greaterThanOrEqualTo(0.0));
        expect(power, greaterThanOrEqualTo(0.0));
        expect(voltage, lessThanOrEqualTo(150.0)); // Device max voltage
        expect(current, lessThanOrEqualTo(10.0)); // Device max current
      }

      // Disable output
      await deviceService.disableOutput();
      await Future.delayed(const Duration(milliseconds: 500));

      print('✓ Live measurements test passed');
    }, timeout: const Timeout(Duration(minutes: 2)));
  });
}
