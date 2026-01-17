//
//  SerialPortChannel.swift
//  Runner
//
//  Created for DPS-150 Control
//

import Cocoa
import FlutterMacOS
import IOKit
import IOKit.serial
import Darwin

class SerialPortChannel: NSObject, FlutterPlugin {
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "dps150_control/serial",
                                          binaryMessenger: registrar.messenger)
        let instance = SerialPortChannel()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    private var openPorts: [String: Int32] = [:] // Store file descriptors instead of FileHandle
    
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "listPorts":
            listPorts(result: result)
        case "connect":
            connect(call: call, result: result)
        case "disconnect":
            disconnect(call: call, result: result)
        case "write":
            write(call: call, result: result)
        case "read":
            read(call: call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func listPorts(result: @escaping FlutterResult) {
        var ports: [[String: Any?]] = []
        
        // Get all serial ports using IOKit
        let matching = IOServiceMatching(kIOSerialBSDServiceValue)
        var iterator: io_iterator_t = 0
        
        if IOServiceGetMatchingServices(kIOMasterPortDefault, matching, &iterator) == KERN_SUCCESS {
            var service = IOIteratorNext(iterator)
            while service != 0 {
                if let portName = getPortName(service: service) {
                    let portInfo: [String: Any?] = [
                        "device": portName,
                        "description": getPortDescription(service: service),
                        "vid": getVendorID(service: service),
                        "pid": getProductID(service: service),
                        "serialNumber": getSerialNumber(service: service)
                    ]
                    ports.append(portInfo)
                }
                IOObjectRelease(service)
                service = IOIteratorNext(iterator)
            }
            IOObjectRelease(iterator)
        }
        
        result(ports)
    }
    
    private func getPortName(service: io_service_t) -> String? {
        if let portName = IORegistryEntryCreateCFProperty(service, kIOCalloutDeviceKey as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? String {
            return portName
        }
        return nil
    }
    
    private func getPortDescription(service: io_service_t) -> String? {
        if let description = IORegistryEntryCreateCFProperty(service, "IOTTYDevice" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? String {
            return description
        }
        if let description = IORegistryEntryCreateCFProperty(service, "USB Product Name" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? String {
            return description
        }
        return nil
    }
    
    private func getVendorID(service: io_service_t) -> Int? {
        if let vid = IORegistryEntryCreateCFProperty(service, "idVendor" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? Int {
            return vid
        }
        return nil
    }
    
    private func getProductID(service: io_service_t) -> Int? {
        if let pid = IORegistryEntryCreateCFProperty(service, "idProduct" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? Int {
            return pid
        }
        return nil
    }
    
    private func getSerialNumber(service: io_service_t) -> String? {
        if let serial = IORegistryEntryCreateCFProperty(service, "USB Serial Number" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? String {
            return serial
        }
        return nil
    }
    
    private func connect(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let port = args["port"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "Port name required", details: nil))
            return
        }
        
        // Try to open for read/write using POSIX
        let fd = open(port, O_RDWR | O_NOCTTY | O_NONBLOCK)
        if fd < 0 {
            result(FlutterError(code: "CONNECTION_FAILED", message: "Failed to open port: \(port)", details: nil))
            return
        }
        
        // Configure serial port settings
        var settings = termios()
        tcgetattr(fd, &settings)
        
        // Set baud rate
        let baudRate = args["baudRate"] as? Int ?? 115200
        cfsetispeed(&settings, speed_t(baudRate))
        cfsetospeed(&settings, speed_t(baudRate))
        
        // 8 data bits, no parity, 1 stop bit
        settings.c_cflag &= ~UInt(CSIZE)
        settings.c_cflag |= UInt(CS8)
        settings.c_cflag &= ~UInt(PARENB)
        settings.c_cflag &= ~UInt(CSTOPB)
        
        // Enable receiver, ignore modem control lines
        settings.c_cflag |= UInt(CLOCAL | CREAD)
        
        // Raw input
        settings.c_lflag &= ~UInt(ICANON | ECHO | ECHOE | ISIG)
        settings.c_iflag &= ~UInt(IXON | IXOFF | IXANY | INLCR | IGNCR | ICRNL)
        settings.c_oflag &= ~UInt(OPOST)
        
        // Apply settings
        tcsetattr(fd, TCSANOW, &settings)
        
        // Set non-blocking mode for reading
        let flags = fcntl(fd, F_GETFL, 0)
        _ = fcntl(fd, F_SETFL, flags | O_NONBLOCK)
        
        // Store file descriptor
        openPorts[port] = fd
        result(true)
    }
    
    private func disconnect(call: FlutterMethodCall, result: @escaping FlutterResult) {
        // Disconnect all ports
        for (_, fd) in openPorts {
            close(fd)
        }
        openPorts.removeAll()
        result(true)
    }
    
    private func write(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let port = args["port"] as? String,
              let data = args["data"] as? FlutterStandardTypedData else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "Port and data required", details: nil))
            return
        }
        
        if let fd = openPorts[port] {
            let bytesWritten = data.data.withUnsafeBytes { bytes in
                Darwin.write(fd, bytes.baseAddress, data.data.count)
            }
            if bytesWritten >= 0 {
                result(true)
            } else {
                result(FlutterError(code: "WRITE_FAILED", message: "Failed to write data", details: nil))
            }
        } else {
            result(FlutterError(code: "NOT_CONNECTED", message: "Port not open: \(port)", details: nil))
        }
    }
    
    private func read(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let port = args["port"] as? String else {
            result(nil)
            return
        }
        
        guard let fd = openPorts[port] else {
            result(nil)
            return
        }
        
        // Read from file descriptor directly (non-blocking)
        var buffer = [UInt8](repeating: 0, count: 1024)
        let bytesRead = Darwin.read(fd, &buffer, 1024)
        
        if bytesRead > 0 {
            let data = Data(buffer.prefix(bytesRead))
            result(FlutterStandardTypedData(bytes: data))
        } else {
            result(nil)
        }
    }
}
