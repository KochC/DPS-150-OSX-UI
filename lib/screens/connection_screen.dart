/// Connection screen for device connection management.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dps150_control/providers/device_provider.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-scan and connect on startup
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<DeviceProvider>(context, listen: false);
      // Scan ports first
      await provider.scanPorts();
      // Always try to auto-connect if a matching device is found (force=true)
      await provider.scanAndConnect(force: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connection'),
      ),
      body: SafeArea(
        child: Consumer<DeviceProvider>(
          builder: (context, provider, child) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Connection status
                _buildStatusCard(provider),
                const SizedBox(height: 16),
                // Auto-connect toggle
                _buildAutoConnectToggle(provider),
                const SizedBox(height: 16),
                // Port selection
                _buildPortSelection(provider),
                const SizedBox(height: 16),
                // Device info
                if (provider.isConnected) _buildDeviceInfo(provider),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusCard(DeviceProvider provider) {
    String statusText;
    Color statusColor;
    Widget statusIcon;

    switch (provider.status) {
      case ConnectionStatus.disconnected:
        statusText = 'Disconnected';
        statusColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.5);
        statusIcon = const Icon(Icons.circle, size: 12);
        break;
      case ConnectionStatus.scanning:
        statusText = 'Scanning for device...';
        statusColor = Theme.of(context).colorScheme.primary;
        statusIcon = SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Theme.of(context).colorScheme.primary,
          ),
        );
        break;
      case ConnectionStatus.connecting:
        statusText = 'Connecting...';
        statusColor = Theme.of(context).colorScheme.primary;
        statusIcon = SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Theme.of(context).colorScheme.primary,
          ),
        );
        break;
      case ConnectionStatus.connected:
        statusText = 'Connected';
        statusColor = Colors.green;
        statusIcon = const Icon(Icons.check_circle, size: 12);
        break;
      case ConnectionStatus.error:
        statusText = 'Error: ${provider.errorMessage ?? "Unknown error"}';
        statusColor = Theme.of(context).colorScheme.error;
        statusIcon = const Icon(Icons.error, size: 12);
        break;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            statusIcon,
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (provider.isConnected)
              TextButton(
                onPressed: () => provider.disconnect(),
                child: const Text('Disconnect'),
              )
            else
              TextButton(
                onPressed: () {
                  if (provider.autoConnect) {
                    provider.scanAndConnect();
                  } else {
                    provider.scanPorts();
                  }
                },
                child: const Text('Connect'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoConnectToggle(DeviceProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Auto-connect on startup'),
            Switch(
              value: provider.autoConnect,
              onChanged: (value) {
                provider.autoConnect = value;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortSelection(DeviceProvider provider) {
    // Filter ports to show only USB modem devices and other relevant devices
    final filteredPorts = provider.availablePorts.where((port) {
      final device = port.device;
      final description = port.description?.toLowerCase() ?? '';
      
      // Show USB modem devices
      if (device.startsWith('/dev/tty.usbmodem') || device.startsWith('/dev/cu.usbmodem')) {
        return true;
      }
      
      // Show devices matching known patterns
      const patterns = ['at32', 'virtual com port', 'dps-150'];
      for (final pattern in patterns) {
        if (description.contains(pattern)) {
          return true;
        }
      }
      
      // Hide common system ports
      if (device.contains('debug-console') || 
          device.contains('Bluetooth') ||
          device.contains('PigmentPete')) {
        return false;
      }
      
      // Show other USB devices
      if (device.contains('usb') || device.contains('USB')) {
        return true;
      }
      
      return false;
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Available Devices',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () => provider.scanPorts(),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Refresh'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (filteredPorts.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      Icons.usb_off, 
                      size: 48, 
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No compatible devices found',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${provider.availablePorts.length} total port(s) detected',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...filteredPorts.map((port) {
                final isUsbModem = port.device.startsWith('/dev/tty.usbmodem') || 
                                   port.device.startsWith('/dev/cu.usbmodem');
                final isConnected = provider.isConnected && 
                                   provider.availablePorts.any((p) => p.device == port.device);
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: isUsbModem 
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.05) 
                      : null,
                  child: ListTile(
                    leading: Icon(
                      isUsbModem ? Icons.usb : Icons.settings_input_component,
                      color: isUsbModem 
                          ? Theme.of(context).colorScheme.primary 
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                    title: Text(
                      port.device,
                      style: TextStyle(
                        fontWeight: isUsbModem ? FontWeight.bold : FontWeight.normal,
                        color: isUsbModem 
                            ? Theme.of(context).colorScheme.primary 
                            : null,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (port.description != null)
                          Text(port.description!),
                        if (isUsbModem)
                          Text(
                            'USB Modem Device (Auto-connect)',
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.primary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                    trailing: isConnected
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                    enabled: !provider.isConnected,
                    onTap: provider.isConnected
                        ? null
                        : () => provider.connect(port.device),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceInfo(DeviceProvider provider) {
    final info = provider.info;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Device Information',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (info.modelName.isNotEmpty)
              _buildInfoRow('Model', info.modelName),
            if (info.hardwareVersion.isNotEmpty)
              _buildInfoRow('Hardware', info.hardwareVersion),
            if (info.firmwareVersion.isNotEmpty)
              _buildInfoRow('Firmware', info.firmwareVersion),
            if (info.isEmpty)
              Text(
                'No device information available',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          Text(value),
        ],
      ),
    );
  }
}
