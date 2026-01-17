/// Constants for DPS-150 protocol.
///
/// This module contains all protocol constants including:
/// - Packet headers (input/output)
/// - Command codes (GET, SET, etc.)
/// - Type codes for different parameters
/// - Protection state mappings
/// - Serial port configuration

// Packet headers
const int headerInput = 0xF0; // 240 - incoming packets from device
const int headerOutput = 0xF1; // 241 - outgoing packets to device

// Command codes
const int cmdGet = 0xA1; // 161 - get value
const int cmdB0 = 0xB0; // 176 - unknown (used for baud rate setting)
const int cmdSet = 0xB1; // 177 - set value
const int cmdC0 = 0xC0; // 192 - unknown
const int cmdC1 = 0xC1; // 193 - connection/initialization

// Type codes for float values
const int voltageSet = 193;
const int currentSet = 194;

// Group preset type codes (float)
const int group1VoltageSet = 197;
const int group1CurrentSet = 198;
const int group2VoltageSet = 199;
const int group2CurrentSet = 200;
const int group3VoltageSet = 201;
const int group3CurrentSet = 202;
const int group4VoltageSet = 203;
const int group4CurrentSet = 204;
const int group5VoltageSet = 205;
const int group5CurrentSet = 206;
const int group6VoltageSet = 207;
const int group6CurrentSet = 208;

// Protection type codes (float)
const int ovp = 209; // Over Voltage Protection
const int ocp = 210; // Over Current Protection
const int opp = 211; // Over Power Protection
const int otp = 212; // Over Temperature Protection
const int lvp = 213; // Low Voltage Protection

// Type codes for byte values
const int brightness = 214;
const int volume = 215;

// Type codes for control
const int meteringEnable = 216;
const int outputEnable = 219;

// Type codes for reading
const int inputVoltage = 192;
const int outputVoltageCurrentPower = 195;
const int temperature = 196;
const int outputCapacity = 217;
const int outputEnergy = 218;
const int protectionState = 220;
const int mode = 221; // CC=0 or CV=1
const int modelName = 222;
const int hardwareVersion = 223;
const int firmwareVersion = 224;
const int upperLimitVoltage = 226;
const int upperLimitCurrent = 227;

// Special type code
const int all = 255; // Get all device state

// Protection states
const List<String> protectionStates = [
  '', // 0 - Normal
  'OVP', // 1 - Over Voltage Protection
  'OCP', // 2 - Over Current Protection
  'OPP', // 3 - Over Power Protection
  'OTP', // 4 - Over Temperature Protection
  'LVP', // 5 - Low Voltage Protection
  'REP', // 6 - Reverse Connection Protection
];

// Serial port settings
const int baudRate = 115200;
const int dataBits = 8;
const int stopBits = 1;
const String parity = 'N'; // No parity
const String flowControl = 'hardware';

// Baud rate options (for initialization)
const List<int> baudRateOptions = [9600, 19200, 38400, 57600, 115200];

// USB Vendor/Product IDs (if available for auto-detection)
// Note: These may need to be determined from actual device
int? usbVid; // To be determined
int? usbPid; // To be determined

// Device identification patterns for auto-detection
const List<String> deviceDescriptionPatterns = [
  'AT32',
  'Virtual Com Port',
  'DPS-150',
];
