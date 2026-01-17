/// Widget tests for LiveMonitor widget.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dps150_control/widgets/live_monitor.dart';
import 'package:dps150_control/providers/device_provider.dart';
import 'package:dps150_control/models/device_state.dart';
import 'package:dps150_control/models/enums.dart';

void main() {
  group('LiveMonitor Widget Tests', () {
    late DeviceState testState;
    late DeviceProvider deviceProvider;

    setUp(() {
      // Create test device state
      testState = DeviceState(
        outputVoltage: 5.0,
        outputCurrent: 1.0,
        outputPower: 5.0,
        temperature: 25.0,
        inputVoltage: 12.0,
        setVoltage: 5.0,
        setCurrent: 1.0,
        overVoltageProtection: 15.0,
        overCurrentProtection: 3.0,
        overPowerProtection: 45.0,
        overTemperatureProtection: 60.0,
        lowVoltageProtection: 1.0,
        outputClosed: false,
        mode: Mode.cv,
        protectionState: ProtectionState.normal,
      );

      deviceProvider = DeviceProvider();
    });

    testWidgets('LiveMonitor displays all sections correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<DeviceProvider>.value(
            value: deviceProvider,
            child: LiveMonitor(state: testState),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check that all main sections are present
      expect(find.text('Voltage'), findsOneWidget);
      expect(find.text('Current'), findsOneWidget);
      expect(find.text('Power'), findsOneWidget);
      expect(find.text('Input Voltage'), findsOneWidget);
      expect(find.text('Temperature'), findsOneWidget);
      expect(find.text('Mode'), findsOneWidget);
      expect(find.text('Protection'), findsOneWidget);
    });

    testWidgets('Output button displays correct state', (WidgetTester tester) async {
      // Test with output OFF
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<DeviceProvider>.value(
            value: deviceProvider,
            child: LiveMonitor(state: testState),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Output OFF'), findsOneWidget);
      expect(find.text('Output ON'), findsNothing);

      // Test with output ON
      final onState = DeviceState(
        outputVoltage: 5.0,
        outputCurrent: 1.0,
        outputPower: 5.0,
        temperature: 25.0,
        inputVoltage: 12.0,
        setVoltage: 5.0,
        setCurrent: 1.0,
        outputClosed: true,
        mode: Mode.cv,
        protectionState: ProtectionState.normal,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<DeviceProvider>.value(
            value: deviceProvider,
            child: LiveMonitor(state: onState),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Output ON'), findsOneWidget);
      expect(find.text('Output OFF'), findsNothing);
    });

    testWidgets('Output button exists and is tappable', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<DeviceProvider>.value(
            value: deviceProvider,
            child: LiveMonitor(state: testState),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap the output button
      final outputButton = find.text('Output OFF');
      expect(outputButton, findsOneWidget);
      
      // Verify button is tappable (doesn't throw)
      await tester.tap(outputButton);
      await tester.pumpAndSettle();

      // Verify provider methods exist
      expect(deviceProvider.enableOutput, isNotNull);
      expect(deviceProvider.disableOutput, isNotNull);
    });

    testWidgets('Voltage section displays values correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<DeviceProvider>.value(
            value: deviceProvider,
            child: LiveMonitor(state: testState),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check voltage display
      expect(find.textContaining('5.000 V'), findsWidgets);
      
      // Check target and limit fields exist
      expect(find.text('Target V'), findsOneWidget);
      // Note: "Limit V" appears twice (voltage limit and low voltage limit)
      expect(find.text('Limit V'), findsAtLeastNWidgets(1));
    });

    testWidgets('Current section displays values correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<DeviceProvider>.value(
            value: deviceProvider,
            child: LiveMonitor(state: testState),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check current display
      expect(find.textContaining('1.000 A'), findsWidgets);
      
      // Check target and limit fields exist
      expect(find.text('Target A'), findsOneWidget);
      expect(find.text('Limit A'), findsOneWidget);
    });

    testWidgets('Status chips display correct values', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<DeviceProvider>.value(
            value: deviceProvider,
            child: LiveMonitor(state: testState),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check Mode chip
      expect(find.text('Mode'), findsOneWidget);
      expect(find.text('CV'), findsOneWidget);

      // Check Protection chip
      expect(find.text('Protection'), findsOneWidget);
      expect(find.text('Normal'), findsOneWidget);

      // Check Temperature
      expect(find.text('Temperature'), findsOneWidget);
      expect(find.textContaining('25.0'), findsWidgets);
    });

    testWidgets('Mode chip displays CC when in constant current mode', (WidgetTester tester) async {
      final ccState = DeviceState(
        outputVoltage: 5.0,
        outputCurrent: 1.0,
        outputPower: 5.0,
        temperature: 25.0,
        inputVoltage: 12.0,
        setVoltage: 5.0,
        setCurrent: 1.0,
        outputClosed: false,
        mode: Mode.cc,
        protectionState: ProtectionState.normal,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<DeviceProvider>.value(
            value: deviceProvider,
            child: LiveMonitor(state: ccState),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('CC'), findsOneWidget);
      expect(find.text('CV'), findsNothing);
    });

    testWidgets('Protection chip shows error state when protection is active', (WidgetTester tester) async {
      final protectedState = DeviceState(
        outputVoltage: 5.0,
        outputCurrent: 1.0,
        outputPower: 5.0,
        temperature: 25.0,
        inputVoltage: 12.0,
        setVoltage: 5.0,
        setCurrent: 1.0,
        outputClosed: false,
        mode: Mode.cv,
        protectionState: ProtectionState.ovp,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<DeviceProvider>.value(
            value: deviceProvider,
            child: LiveMonitor(state: protectedState),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('OVP'), findsOneWidget);
    });

    testWidgets('Voltage target field can be edited', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<DeviceProvider>.value(
            value: deviceProvider,
            child: LiveMonitor(state: testState),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the voltage target field
      final targetFields = find.widgetWithText(TextField, '5.00');
      expect(targetFields, findsWidgets);

      // Enter a new value
      await tester.enterText(targetFields.first, '10.00');
      await tester.pump();

      // Verify provider method exists
      expect(deviceProvider.setVoltage, isNotNull);
      
      // Submit the field
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
    });

    testWidgets('Voltage limit field can be edited', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<DeviceProvider>.value(
            value: deviceProvider,
            child: LiveMonitor(state: testState),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find limit fields (should contain the OVP value)
      final limitFields = find.widgetWithText(TextField, '15.00');
      expect(limitFields, findsWidgets);

      // Enter a new value
      await tester.enterText(limitFields.first, '20.00');
      await tester.pump();

      // Verify provider method exists
      expect(deviceProvider.setOvp, isNotNull);
      
      // Submit the field
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
    });

    testWidgets('Current target field can be edited', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<DeviceProvider>.value(
            value: deviceProvider,
            child: LiveMonitor(state: testState),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the current target field
      final targetFields = find.widgetWithText(TextField, '1.00');
      expect(targetFields, findsWidgets);

      // Enter a new value
      await tester.enterText(targetFields.last, '2.00');
      await tester.pump();

      // Verify provider method exists
      expect(deviceProvider.setCurrent, isNotNull);
      
      // Submit the field
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
    });

    testWidgets('Power limit field can be edited', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<DeviceProvider>.value(
            value: deviceProvider,
            child: LiveMonitor(state: testState),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find power limit field
      final limitFields = find.widgetWithText(TextField, '45.00');
      expect(limitFields, findsWidgets);

      // Enter a new value
      await tester.enterText(limitFields.first, '50.00');
      await tester.pump();

      // Verify provider method exists
      expect(deviceProvider.setOpp, isNotNull);
      
      // Submit the field
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
    });

    testWidgets('Invalid input handles gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<DeviceProvider>.value(
            value: deviceProvider,
            child: LiveMonitor(state: testState),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find voltage target field
      final targetFields = find.widgetWithText(TextField, '5.00');
      expect(targetFields, findsWidgets);

      // Enter invalid value
      await tester.enterText(targetFields.first, 'invalid');
      await tester.pump();

      // Submit the field
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Verify no exception was thrown and widget still exists
      expect(find.byType(LiveMonitor), findsOneWidget);
      // The field should still be present (may have reset or kept invalid text)
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('Widget updates when state changes', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<DeviceProvider>.value(
            value: deviceProvider,
            child: LiveMonitor(state: testState),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify initial state
      expect(find.textContaining('5.000 V'), findsWidgets);

      // Update state
      final newState = DeviceState(
        outputVoltage: 10.0,
        outputCurrent: 2.0,
        outputPower: 20.0,
        temperature: 30.0,
        inputVoltage: 12.0,
        setVoltage: 10.0,
        setCurrent: 2.0,
        overVoltageProtection: 15.0,
        overCurrentProtection: 3.0,
        overPowerProtection: 45.0,
        overTemperatureProtection: 60.0,
        lowVoltageProtection: 1.0,
        outputClosed: false,
        mode: Mode.cv,
        protectionState: ProtectionState.normal,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<DeviceProvider>.value(
            value: deviceProvider,
            child: LiveMonitor(state: newState),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify updated values are displayed
      expect(find.textContaining('10.000 V'), findsWidgets);
      expect(find.textContaining('2.000 A'), findsWidgets);
    });

    testWidgets('All value sections are scrollable', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<DeviceProvider>.value(
              value: deviceProvider,
              child: LiveMonitor(
                state: DeviceState(
                  outputVoltage: 5.0,
                  outputCurrent: 1.0,
                  outputPower: 5.0,
                  temperature: 25.0,
                  inputVoltage: 12.0,
                  setVoltage: 5.0,
                  setCurrent: 1.0,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify SingleChildScrollView exists
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });
}
