/// Enums for DPS-150 device state.

/// Protection state enumeration.
enum ProtectionState {
  normal(''),
  ovp('OVP'), // Over Voltage Protection
  ocp('OCP'), // Over Current Protection
  opp('OPP'), // Over Power Protection
  otp('OTP'), // Over Temperature Protection
  lvp('LVP'), // Low Voltage Protection
  rep('REP'); // Reverse Connection Protection

  const ProtectionState(this.value);
  final String value;

  static ProtectionState fromString(String value) {
    for (var state in ProtectionState.values) {
      if (state.value == value) {
        return state;
      }
    }
    return ProtectionState.normal;
  }
}

/// Output mode enumeration.
enum Mode {
  cc('CC'), // Constant Current
  cv('CV'); // Constant Voltage

  const Mode(this.value);
  final String value;
}
