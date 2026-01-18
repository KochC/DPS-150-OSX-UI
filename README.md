# DPS-150 Control - Flutter macOS App

A native macOS application for controlling the FNIRSI DPS-150 programmable power supply via serial communication.

> **Note**: This is a standalone Flutter application. For the Python library, see the [DPS-150 Python Library](https://github.com/KochC/DPS-150-python-library) repository.

## Features

- **Automatic Device Detection**: Automatically scans USB ports and connects to DPS-150 devices
- **Live Monitoring**: Real-time display of voltage, current, power, and temperature
- **Voltage/Current Control**: Adjustable sliders and text inputs for precise control
- **Protection Settings**: Configure over-voltage, over-current, over-power, over-temperature, and low-voltage protection
- **Preset Groups**: Save and load up to 6 preset configurations
- **Native macOS UI**: Beautiful Cupertino design matching macOS aesthetics

## Requirements

- macOS 10.14 or later
- DPS-150 device connected via USB

## Installation

### Download Pre-built Release (Recommended)

1. Go to the [Releases](https://github.com/KochC/DPS-150-OSX-UI/releases) page
2. Download the latest `dps150_control-macos.zip` file
3. Extract the ZIP file
4. Move `dps150_control.app` to your Applications folder
5. Launch the app from Applications

> **Note**: On first launch, macOS may show a security warning. Go to System Preferences > Security & Privacy and click "Open Anyway" if needed.

### Build from Source

If you want to build the app yourself:

1. **Install Flutter** (if not already installed):
   ```bash
   # Follow instructions at https://flutter.dev/docs/get-started/install/macos
   ```

2. **Navigate to the project directory**:
   ```bash
   cd DPS-150-Control
   ```

3. **Install dependencies**:
   ```bash
   flutter pub get
   ```

4. **Run the app**:
   ```bash
   flutter run -d macos
   ```

## Building for Release

### Automated Builds (CI/CD)

This project uses GitHub Actions to automatically build and release the app when tags are pushed:

1. **Create a release tag**:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

2. **GitHub Actions will automatically**:
   - Build the macOS app using Flutter
   - Create a ZIP archive
   - Create a GitHub release with the built app attached

The workflow is defined in `.github/workflows/build-and-release.yml` and triggers on tags matching `v*`.

### Local Build

To build the app locally:

1. **Build the app**:
   ```bash
   flutter build macos --release
   ```

2. **The built app will be in**:
   ```
   build/macos/Build/Products/Release/dps150_control.app
   ```

3. **Create a distributable archive** (optional):
   ```bash
   cd build/macos/Build/Products/Release
   zip -r dps150_control-macos.zip dps150_control.app
   ```

## Usage

### First Launch

1. Launch the app
2. The app will automatically scan for DPS-150 devices
3. If a device is found, it will automatically connect
4. If no device is found, you can manually select a port from the Connection tab

### Main Control Tab

- **Live Monitoring**: View real-time voltage, current, power, and temperature
- **Voltage Control**: Adjust target voltage using the slider or text input
- **Current Control**: Adjust target current (current limit) using the slider or text input
- **Output Toggle**: Enable or disable the power supply output
- **Apply Settings**: Apply the configured voltage and current settings

### Settings Tab

- **Protection Settings**: Configure all protection limits (OVP, OCP, OPP, OTP, LVP)
- **Preset Groups**: View and load preset groups (1-6)
- **Device Information**: View device model, hardware version, and firmware version

### Connection Tab

- **Connection Status**: View current connection status
- **Auto-connect Toggle**: Enable/disable automatic connection on startup
- **Port Selection**: Manually select a serial port if auto-detection fails
- **Device Information**: View connected device information

## Troubleshooting

### Device Not Found

1. Check that the DPS-150 is connected via USB
2. Verify the device appears in System Information > USB
3. Try manually selecting the port from the Connection tab
4. Check that the device description contains "AT32" or "Virtual Com Port"

### Connection Errors

1. Ensure no other application is using the serial port
2. Try disconnecting and reconnecting the USB cable
3. Restart the app
4. Check macOS System Preferences > Security & Privacy for serial port permissions

### Permission Issues

If you see permission errors:
1. Go to System Preferences > Security & Privacy > Privacy
2. Add the app to the list of applications allowed to access serial ports
3. Restart the app

## Releases

Releases are automatically created via GitHub Actions when version tags are pushed. Each release includes:

- Pre-built macOS application (`dps150_control-macos.zip`)
- Release notes (auto-generated from commits)
- Source code for the tagged version

To create a new release:
1. Update the version in `pubspec.yaml`
2. Commit and push your changes
3. Create and push a version tag: `git tag v1.0.0 && git push origin v1.0.0`
4. The GitHub Actions workflow will automatically build and publish the release

## Development

### Project Structure

```
DPS-150-Control/
├── lib/
│   ├── main.dart              # App entry point
│   ├── models/                # Data models
│   ├── services/              # Protocol, serial, device services
│   ├── providers/             # State management
│   ├── screens/               # UI screens
│   ├── widgets/               # Reusable widgets
│   └── utils/                 # Constants and utilities
├── macos/                     # macOS-specific configuration
├── test/                      # Test files
└── pubspec.yaml               # Dependencies
```

### Dependencies

- `provider`: State management
- `liquid_flutter`: UI components
- `fl_chart`: Charting library for time-series graphs
- Platform channels: Native serial communication (macOS)

## License

MIT License

## Acknowledgments

- Based on the [DPS-150 Python Library](https://github.com/KochC/DPS-150-python-library) implementation
- Protocol reference from the JavaScript implementation by [cho45](https://github.com/cho45/fnirsi-dps-150)
