/// Device information model.

class DeviceInfo {
  String modelName;
  String hardwareVersion;
  String firmwareVersion;

  DeviceInfo({
    this.modelName = '',
    this.hardwareVersion = '',
    this.firmwareVersion = '',
  });

  bool get isEmpty => modelName.isEmpty && hardwareVersion.isEmpty && firmwareVersion.isEmpty;

  DeviceInfo copyWith({
    String? modelName,
    String? hardwareVersion,
    String? firmwareVersion,
  }) {
    return DeviceInfo(
      modelName: modelName ?? this.modelName,
      hardwareVersion: hardwareVersion ?? this.hardwareVersion,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
    );
  }
}
