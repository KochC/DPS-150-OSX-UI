/// Complete device state model.

import 'enums.dart';

class DeviceState {
  // Input/Output measurements
  double inputVoltage;
  double outputVoltage;
  double outputCurrent;
  double outputPower;
  double temperature;

  // Set values
  double setVoltage;
  double setCurrent;

  // Group presets (1-6)
  double group1SetVoltage;
  double group1SetCurrent;
  double group2SetVoltage;
  double group2SetCurrent;
  double group3SetVoltage;
  double group3SetCurrent;
  double group4SetVoltage;
  double group4SetCurrent;
  double group5SetVoltage;
  double group5SetCurrent;
  double group6SetVoltage;
  double group6SetCurrent;

  // Protection settings
  double overVoltageProtection;
  double overCurrentProtection;
  double overPowerProtection;
  double overTemperatureProtection;
  double lowVoltageProtection;

  // Display and audio
  int brightness;
  int volume;

  // Metering
  bool meteringClosed;
  double outputCapacity; // Ah
  double outputEnergy; // Wh

  // Status
  bool outputClosed; // Output enabled/disabled
  ProtectionState protectionState;
  Mode mode;

  // Limits
  double upperLimitVoltage;
  double upperLimitCurrent;

  DeviceState({
    this.inputVoltage = 0.0,
    this.outputVoltage = 0.0,
    this.outputCurrent = 0.0,
    this.outputPower = 0.0,
    this.temperature = 0.0,
    this.setVoltage = 0.0,
    this.setCurrent = 0.0,
    this.group1SetVoltage = 0.0,
    this.group1SetCurrent = 0.0,
    this.group2SetVoltage = 0.0,
    this.group2SetCurrent = 0.0,
    this.group3SetVoltage = 0.0,
    this.group3SetCurrent = 0.0,
    this.group4SetVoltage = 0.0,
    this.group4SetCurrent = 0.0,
    this.group5SetVoltage = 0.0,
    this.group5SetCurrent = 0.0,
    this.group6SetVoltage = 0.0,
    this.group6SetCurrent = 0.0,
    this.overVoltageProtection = 0.0,
    this.overCurrentProtection = 0.0,
    this.overPowerProtection = 0.0,
    this.overTemperatureProtection = 0.0,
    this.lowVoltageProtection = 0.0,
    this.brightness = 0,
    this.volume = 0,
    this.meteringClosed = false,
    this.outputCapacity = 0.0,
    this.outputEnergy = 0.0,
    this.outputClosed = false,
    ProtectionState? protectionState,
    Mode? mode,
    this.upperLimitVoltage = 0.0,
    this.upperLimitCurrent = 0.0,
  })  : protectionState = protectionState ?? ProtectionState.normal,
        mode = mode ?? Mode.cv;

  /// Update state from dictionary (from parsed packet data).
  ///
  /// Keys in the dictionary use camelCase (matching the JavaScript implementation)
  /// and are mapped to Dart properties.
  void updateFromMap(Map<String, dynamic> data) {
    if (data.containsKey('inputVoltage')) {
      inputVoltage = (data['inputVoltage'] as num).toDouble();
    }
    if (data.containsKey('outputVoltage')) {
      outputVoltage = (data['outputVoltage'] as num).toDouble();
    }
    if (data.containsKey('outputCurrent')) {
      outputCurrent = (data['outputCurrent'] as num).toDouble();
    }
    if (data.containsKey('outputPower')) {
      outputPower = (data['outputPower'] as num).toDouble();
    }
    if (data.containsKey('temperature')) {
      temperature = (data['temperature'] as num).toDouble();
    }
    if (data.containsKey('setVoltage')) {
      setVoltage = (data['setVoltage'] as num).toDouble();
    }
    if (data.containsKey('setCurrent')) {
      setCurrent = (data['setCurrent'] as num).toDouble();
    }
    if (data.containsKey('group1setVoltage')) {
      group1SetVoltage = (data['group1setVoltage'] as num).toDouble();
    }
    if (data.containsKey('group1setCurrent')) {
      group1SetCurrent = (data['group1setCurrent'] as num).toDouble();
    }
    if (data.containsKey('group2setVoltage')) {
      group2SetVoltage = (data['group2setVoltage'] as num).toDouble();
    }
    if (data.containsKey('group2setCurrent')) {
      group2SetCurrent = (data['group2setCurrent'] as num).toDouble();
    }
    if (data.containsKey('group3setVoltage')) {
      group3SetVoltage = (data['group3setVoltage'] as num).toDouble();
    }
    if (data.containsKey('group3setCurrent')) {
      group3SetCurrent = (data['group3setCurrent'] as num).toDouble();
    }
    if (data.containsKey('group4setVoltage')) {
      group4SetVoltage = (data['group4setVoltage'] as num).toDouble();
    }
    if (data.containsKey('group4setCurrent')) {
      group4SetCurrent = (data['group4setCurrent'] as num).toDouble();
    }
    if (data.containsKey('group5setVoltage')) {
      group5SetVoltage = (data['group5setVoltage'] as num).toDouble();
    }
    if (data.containsKey('group5setCurrent')) {
      group5SetCurrent = (data['group5setCurrent'] as num).toDouble();
    }
    if (data.containsKey('group6setVoltage')) {
      group6SetVoltage = (data['group6setVoltage'] as num).toDouble();
    }
    if (data.containsKey('group6setCurrent')) {
      group6SetCurrent = (data['group6setCurrent'] as num).toDouble();
    }
    if (data.containsKey('overVoltageProtection')) {
      overVoltageProtection = (data['overVoltageProtection'] as num).toDouble();
    }
    if (data.containsKey('overCurrentProtection')) {
      overCurrentProtection = (data['overCurrentProtection'] as num).toDouble();
    }
    if (data.containsKey('overPowerProtection')) {
      overPowerProtection = (data['overPowerProtection'] as num).toDouble();
    }
    if (data.containsKey('overTemperatureProtection')) {
      overTemperatureProtection = (data['overTemperatureProtection'] as num).toDouble();
    }
    if (data.containsKey('lowVoltageProtection')) {
      lowVoltageProtection = (data['lowVoltageProtection'] as num).toDouble();
    }
    if (data.containsKey('brightness')) {
      brightness = data['brightness'] as int;
    }
    if (data.containsKey('volume')) {
      volume = data['volume'] as int;
    }
    if (data.containsKey('meteringClosed')) {
      meteringClosed = data['meteringClosed'] as bool;
    }
    if (data.containsKey('outputCapacity')) {
      outputCapacity = (data['outputCapacity'] as num).toDouble();
    }
    if (data.containsKey('outputEnergy')) {
      outputEnergy = (data['outputEnergy'] as num).toDouble();
    }
    if (data.containsKey('outputClosed')) {
      outputClosed = data['outputClosed'] as bool;
    }
    if (data.containsKey('protectionState')) {
      protectionState = ProtectionState.fromString(data['protectionState'] as String);
    }
    if (data.containsKey('mode')) {
      mode = data['mode'] == 'CC' ? Mode.cc : Mode.cv;
    }
    if (data.containsKey('upperLimitVoltage')) {
      upperLimitVoltage = (data['upperLimitVoltage'] as num).toDouble();
    }
    if (data.containsKey('upperLimitCurrent')) {
      upperLimitCurrent = (data['upperLimitCurrent'] as num).toDouble();
    }
  }

  DeviceState copyWith({
    double? inputVoltage,
    double? outputVoltage,
    double? outputCurrent,
    double? outputPower,
    double? temperature,
    double? setVoltage,
    double? setCurrent,
    double? group1SetVoltage,
    double? group1SetCurrent,
    double? group2SetVoltage,
    double? group2SetCurrent,
    double? group3SetVoltage,
    double? group3SetCurrent,
    double? group4SetVoltage,
    double? group4SetCurrent,
    double? group5SetVoltage,
    double? group5SetCurrent,
    double? group6SetVoltage,
    double? group6SetCurrent,
    double? overVoltageProtection,
    double? overCurrentProtection,
    double? overPowerProtection,
    double? overTemperatureProtection,
    double? lowVoltageProtection,
    int? brightness,
    int? volume,
    bool? meteringClosed,
    double? outputCapacity,
    double? outputEnergy,
    bool? outputClosed,
    ProtectionState? protectionState,
    Mode? mode,
    double? upperLimitVoltage,
    double? upperLimitCurrent,
  }) {
    return DeviceState(
      inputVoltage: inputVoltage ?? this.inputVoltage,
      outputVoltage: outputVoltage ?? this.outputVoltage,
      outputCurrent: outputCurrent ?? this.outputCurrent,
      outputPower: outputPower ?? this.outputPower,
      temperature: temperature ?? this.temperature,
      setVoltage: setVoltage ?? this.setVoltage,
      setCurrent: setCurrent ?? this.setCurrent,
      group1SetVoltage: group1SetVoltage ?? this.group1SetVoltage,
      group1SetCurrent: group1SetCurrent ?? this.group1SetCurrent,
      group2SetVoltage: group2SetVoltage ?? this.group2SetVoltage,
      group2SetCurrent: group2SetCurrent ?? this.group2SetCurrent,
      group3SetVoltage: group3SetVoltage ?? this.group3SetVoltage,
      group3SetCurrent: group3SetCurrent ?? this.group3SetCurrent,
      group4SetVoltage: group4SetVoltage ?? this.group4SetVoltage,
      group4SetCurrent: group4SetCurrent ?? this.group4SetCurrent,
      group5SetVoltage: group5SetVoltage ?? this.group5SetVoltage,
      group5SetCurrent: group5SetCurrent ?? this.group5SetCurrent,
      group6SetVoltage: group6SetVoltage ?? this.group6SetVoltage,
      group6SetCurrent: group6SetCurrent ?? this.group6SetCurrent,
      overVoltageProtection: overVoltageProtection ?? this.overVoltageProtection,
      overCurrentProtection: overCurrentProtection ?? this.overCurrentProtection,
      overPowerProtection: overPowerProtection ?? this.overPowerProtection,
      overTemperatureProtection: overTemperatureProtection ?? this.overTemperatureProtection,
      lowVoltageProtection: lowVoltageProtection ?? this.lowVoltageProtection,
      brightness: brightness ?? this.brightness,
      volume: volume ?? this.volume,
      meteringClosed: meteringClosed ?? this.meteringClosed,
      outputCapacity: outputCapacity ?? this.outputCapacity,
      outputEnergy: outputEnergy ?? this.outputEnergy,
      outputClosed: outputClosed ?? this.outputClosed,
      protectionState: protectionState ?? this.protectionState,
      mode: mode ?? this.mode,
      upperLimitVoltage: upperLimitVoltage ?? this.upperLimitVoltage,
      upperLimitCurrent: upperLimitCurrent ?? this.upperLimitCurrent,
    );
  }
}
