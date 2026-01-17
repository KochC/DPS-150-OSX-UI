/// Settings screen for preset groups.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dps150_control/providers/device_provider.dart';
import 'package:dps150_control/models/device_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final Map<int, TextEditingController> _voltageControllers = {};
  final Map<int, TextEditingController> _currentControllers = {};
  final Set<int> _editingGroups = {};

  @override
  void dispose() {
    for (final controller in _voltageControllers.values) {
      controller.dispose();
    }
    for (final controller in _currentControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeControllers(DeviceState state) {
    for (int i = 1; i <= 6; i++) {
      if (!_voltageControllers.containsKey(i)) {
        double voltage;
        double current;
        switch (i) {
          case 1:
            voltage = state.group1SetVoltage;
            current = state.group1SetCurrent;
            break;
          case 2:
            voltage = state.group2SetVoltage;
            current = state.group2SetCurrent;
            break;
          case 3:
            voltage = state.group3SetVoltage;
            current = state.group3SetCurrent;
            break;
          case 4:
            voltage = state.group4SetVoltage;
            current = state.group4SetCurrent;
            break;
          case 5:
            voltage = state.group5SetVoltage;
            current = state.group5SetCurrent;
            break;
          case 6:
            voltage = state.group6SetVoltage;
            current = state.group6SetCurrent;
            break;
          default:
            voltage = 0.0;
            current = 0.0;
        }
        _voltageControllers[i] = TextEditingController(text: voltage.toStringAsFixed(2));
        _currentControllers[i] = TextEditingController(text: current.toStringAsFixed(2));
      }
    }
  }

  void _updateControllers(DeviceState state) {
    for (int i = 1; i <= 6; i++) {
      if (!_editingGroups.contains(i)) {
        double voltage;
        double current;
        switch (i) {
          case 1:
            voltage = state.group1SetVoltage;
            current = state.group1SetCurrent;
            break;
          case 2:
            voltage = state.group2SetVoltage;
            current = state.group2SetCurrent;
            break;
          case 3:
            voltage = state.group3SetVoltage;
            current = state.group3SetCurrent;
            break;
          case 4:
            voltage = state.group4SetVoltage;
            current = state.group4SetCurrent;
            break;
          case 5:
            voltage = state.group5SetVoltage;
            current = state.group5SetCurrent;
            break;
          case 6:
            voltage = state.group6SetVoltage;
            current = state.group6SetCurrent;
            break;
          default:
            voltage = 0.0;
            current = 0.0;
        }
        final vController = _voltageControllers[i];
        final cController = _currentControllers[i];
        if (vController != null) {
          final currentValue = double.tryParse(vController.text);
          if (currentValue == null || (currentValue - voltage).abs() > 0.01) {
            vController.text = voltage.toStringAsFixed(2);
          }
        }
        if (cController != null) {
          final currentValue = double.tryParse(cController.text);
          if (currentValue == null || (currentValue - current).abs() > 0.01) {
            cController.text = current.toStringAsFixed(2);
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Presets'),
      ),
      body: SafeArea(
        child: Consumer<DeviceProvider>(
          builder: (context, provider, child) {
            if (!provider.isConnected) {
              return const Center(
                child: Text('Please connect to a device'),
              );
            }

            final state = provider.state;
            _initializeControllers(state);
            _updateControllers(state);

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Preset groups
                _buildPresetGroups(provider, state),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPresetGroups(DeviceProvider provider, DeviceState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Preset Groups',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            for (int i = 1; i <= 6; i++)
              _buildPresetGroup(provider, state, i),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetGroup(DeviceProvider provider, DeviceState state, int group) {
    final voltageController = _voltageControllers[group]!;
    final currentController = _currentControllers[group]!;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Group $group',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Voltage (V)',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: voltageController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          contentPadding: const EdgeInsets.all(8),
                          isDense: true,
                        ),
                        onTap: () {
                          setState(() {
                            _editingGroups.add(group);
                          });
                        },
                        onSubmitted: (value) {
                          setState(() {
                            _editingGroups.remove(group);
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current (A)',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: currentController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          contentPadding: const EdgeInsets.all(8),
                          isDense: true,
                        ),
                        onTap: () {
                          setState(() {
                            _editingGroups.add(group);
                          });
                        },
                        onSubmitted: (value) {
                          setState(() {
                            _editingGroups.remove(group);
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  children: [
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        final voltage = double.tryParse(voltageController.text);
                        final current = double.tryParse(currentController.text);
                        if (voltage != null && current != null && voltage >= 0 && current >= 0) {
                          provider.setGroup(group, voltage, current);
                        }
                      },
                      child: const Text('Save'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => provider.loadGroup(group),
                      child: const Text('Load'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
