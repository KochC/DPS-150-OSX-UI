/// Live monitoring widget for real-time device state display.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dps150_control/models/device_state.dart';
import 'package:dps150_control/models/enums.dart';
import 'package:dps150_control/providers/device_provider.dart';

class LiveMonitor extends StatefulWidget {
  final DeviceState state;

  const LiveMonitor({super.key, required this.state});

  @override
  State<LiveMonitor> createState() => _LiveMonitorState();
}

class _LiveMonitorState extends State<LiveMonitor> {
  late TextEditingController _voltageSetpointController;
  late TextEditingController _currentSetpointController;
  late TextEditingController _ovpController;
  late TextEditingController _ocpController;
  late TextEditingController _oppController;
  late TextEditingController _otpController;
  late TextEditingController _lvpController;
  final Set<String> _editingFields = {};

  @override
  void initState() {
    super.initState();
    _voltageSetpointController = TextEditingController(
      text: widget.state.setVoltage.toStringAsFixed(2),
    );
    _currentSetpointController = TextEditingController(
      text: widget.state.setCurrent.toStringAsFixed(2),
    );
    _ovpController = TextEditingController(
      text: widget.state.overVoltageProtection.toStringAsFixed(2),
    );
    _ocpController = TextEditingController(
      text: widget.state.overCurrentProtection.toStringAsFixed(2),
    );
    _oppController = TextEditingController(
      text: widget.state.overPowerProtection.toStringAsFixed(2),
    );
    _otpController = TextEditingController(
      text: widget.state.overTemperatureProtection.toStringAsFixed(1),
    );
    _lvpController = TextEditingController(
      text: widget.state.lowVoltageProtection.toStringAsFixed(2),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update controllers from device state when dependencies change
    _updateControllersFromState();
  }

  @override
  void didUpdateWidget(LiveMonitor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update controllers when state changes (but not if user is editing)
    _updateControllersFromState();
  }

  void _updateControllersFromState() {
    // Update voltage setpoint
    if (!_editingFields.contains('voltage_setpoint')) {
      final currentValue = double.tryParse(_voltageSetpointController.text);
      if (currentValue == null ||
          (currentValue - widget.state.setVoltage).abs() > 0.01) {
        _voltageSetpointController.text = widget.state.setVoltage.toStringAsFixed(2);
      }
    }
    
    // Update current setpoint
    if (!_editingFields.contains('current_setpoint')) {
      final currentValue = double.tryParse(_currentSetpointController.text);
      if (currentValue == null ||
          (currentValue - widget.state.setCurrent).abs() > 0.01) {
        _currentSetpointController.text = widget.state.setCurrent.toStringAsFixed(2);
      }
    }
    
    // Update OVP
    if (!_editingFields.contains('voltage_limit')) {
      final currentValue = double.tryParse(_ovpController.text);
      if (currentValue == null ||
          (currentValue - widget.state.overVoltageProtection).abs() > 0.01) {
        _ovpController.text = widget.state.overVoltageProtection.toStringAsFixed(2);
      }
    }
    
    // Update OCP
    if (!_editingFields.contains('current_limit')) {
      final currentValue = double.tryParse(_ocpController.text);
      if (currentValue == null ||
          (currentValue - widget.state.overCurrentProtection).abs() > 0.01) {
        _ocpController.text = widget.state.overCurrentProtection.toStringAsFixed(2);
      }
    }
    
    // Update OPP
    if (!_editingFields.contains('power_limit')) {
      final currentValue = double.tryParse(_oppController.text);
      if (currentValue == null ||
          (currentValue - widget.state.overPowerProtection).abs() > 0.01) {
        _oppController.text = widget.state.overPowerProtection.toStringAsFixed(2);
      }
    }
    
    // Update OTP
    if (!_editingFields.contains('temperature_limit')) {
      final currentValue = double.tryParse(_otpController.text);
      if (currentValue == null ||
          (currentValue - widget.state.overTemperatureProtection).abs() > 0.1) {
        _otpController.text = widget.state.overTemperatureProtection.toStringAsFixed(1);
      }
    }
    
    // Update LVP
    if (!_editingFields.contains('low voltage_limit')) {
      final currentValue = double.tryParse(_lvpController.text);
      if (currentValue == null ||
          (currentValue - widget.state.lowVoltageProtection).abs() > 0.01) {
        _lvpController.text = widget.state.lowVoltageProtection.toStringAsFixed(2);
      }
    }
  }

  @override
  void dispose() {
    _voltageSetpointController.dispose();
    _currentSetpointController.dispose();
    _ovpController.dispose();
    _ocpController.dispose();
    _oppController.dispose();
    _otpController.dispose();
    _lvpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ensure controllers are synchronized with state
    _updateControllersFromState();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
              // Enable button at the top
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final provider = Provider.of<DeviceProvider>(context, listen: false);
                    if (widget.state.outputClosed) {
                      provider.disableOutput();
                    } else {
                      provider.enableOutput();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.state.outputClosed 
                        ? Colors.green 
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    foregroundColor: widget.state.outputClosed 
                        ? Colors.white 
                        : Theme.of(context).colorScheme.onSurface,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    widget.state.outputClosed ? 'Output ON' : 'Output OFF',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Temperature, Mode, and Protection in one row
              Row(
                children: [
                  Expanded(
                    child: _buildCompactValueSection(
                      'Temperature',
                      widget.state.temperature,
                      '°C',
                      Colors.red,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatusChip(
                      'Mode',
                      widget.state.mode == Mode.cc ? 'CC' : 'CV',
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatusChip(
                      'Protection',
                      widget.state.protectionState.value.isEmpty
                          ? 'Normal'
                          : widget.state.protectionState.value,
                      widget.state.protectionState == ProtectionState.normal
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Preset shortcuts (M1, M2, M3, etc.)
              _buildPresetButtons(context),
              const SizedBox(height: 12),
              // Voltage section
              _buildValueSection(
                context,
                'Voltage',
                widget.state.outputVoltage,
                'V',
                Colors.yellow,
                _voltageSetpointController,
                _ovpController,
                (value) => Provider.of<DeviceProvider>(context, listen: false).setVoltage(value),
                (value) => Provider.of<DeviceProvider>(context, listen: false).setOvp(value),
              ),
              const SizedBox(height: 12),
              // Current section
              _buildValueSection(
                context,
                'Current',
                widget.state.outputCurrent,
                'A',
                Colors.green,
                _currentSetpointController,
                _ocpController,
                (value) => Provider.of<DeviceProvider>(context, listen: false).setCurrent(value),
                (value) => Provider.of<DeviceProvider>(context, listen: false).setOcp(value),
              ),
              const SizedBox(height: 12),
              // Power and Input Voltage side by side
              Row(
                children: [
                  Expanded(
                    child: _buildValueSectionWithLimitOnly(
                      context,
                      'Power',
                      widget.state.outputPower,
                      'W',
                      Colors.blue,
                      _oppController,
                      (value) => Provider.of<DeviceProvider>(context, listen: false).setOpp(value),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildValueSectionWithLimitOnly(
                      context,
                      'Input Voltage',
                      widget.state.inputVoltage,
                      'V',
                      Colors.purple,
                      _lvpController,
                      (value) => Provider.of<DeviceProvider>(context, listen: false).setLvp(value),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
    );
  }

  Widget _buildValueSection(
    BuildContext context,
    String label,
    double actualValue,
    String unit,
    Color color,
    TextEditingController setpointController,
    TextEditingController limitController,
    ValueChanged<double> onSetpointChanged,
    ValueChanged<double> onLimitChanged,
  ) {
    final fieldId = label.toLowerCase();
    
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          // Actual value
          Text(
            '${actualValue.toStringAsFixed(3)} $unit',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          // Target and Limit in a row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Target $unit',
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: setpointController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(
                        fontSize: 12,
                        color: color,
                      ),
                      decoration: InputDecoration(
                        suffixText: unit,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(color: color.withOpacity(0.5)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        isDense: true,
                      ),
                      onTap: () {
                        _editingFields.add('${fieldId}_setpoint');
                      },
                      onSubmitted: (value) {
                        _editingFields.remove('${fieldId}_setpoint');
                        final numValue = double.tryParse(value);
                        if (numValue != null && numValue >= 0) {
                          onSetpointChanged(numValue);
                        } else {
                          final currentValue = double.tryParse(setpointController.text) ?? 0.0;
                          setpointController.text = currentValue.toStringAsFixed(2);
                        }
                      },
                      onEditingComplete: () {
                        _editingFields.remove('${fieldId}_setpoint');
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Limit $unit',
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: limitController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      decoration: InputDecoration(
                        suffixText: unit,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.error.withOpacity(0.5)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        isDense: true,
                      ),
                      onTap: () {
                        _editingFields.add('${fieldId}_limit');
                      },
                      onSubmitted: (value) {
                        _editingFields.remove('${fieldId}_limit');
                        final numValue = double.tryParse(value);
                        if (numValue != null && numValue >= 0) {
                          onLimitChanged(numValue);
                        } else {
                          final currentValue = double.tryParse(limitController.text) ?? 0.0;
                          limitController.text = currentValue.toStringAsFixed(2);
                        }
                      },
                      onEditingComplete: () {
                        _editingFields.remove('${fieldId}_limit');
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildValueSectionWithLimitOnly(
    BuildContext context,
    String label,
    double actualValue,
    String unit,
    Color color,
    TextEditingController limitController,
    ValueChanged<double> onLimitChanged,
  ) {
    final fieldId = label.toLowerCase();
    final isTemperature = unit == '°C';
    final decimalPlaces = isTemperature ? 1 : 3;
    
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          // Actual value
          Text(
            '${actualValue.toStringAsFixed(decimalPlaces)} $unit',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          // Limit only
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Limit $unit',
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: limitController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red,
                ),
                decoration: InputDecoration(
                  suffixText: unit,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(color: Colors.red.withOpacity(0.5)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  isDense: true,
                ),
                onTap: () {
                  _editingFields.add('${fieldId}_limit');
                },
                onSubmitted: (value) {
                  _editingFields.remove('${fieldId}_limit');
                  final numValue = double.tryParse(value);
                  if (numValue != null && numValue >= 0) {
                    onLimitChanged(numValue);
                  } else {
                    final currentValue = double.tryParse(limitController.text) ?? 0.0;
                    limitController.text = isTemperature 
                        ? currentValue.toStringAsFixed(1)
                        : currentValue.toStringAsFixed(2);
                  }
                },
                onEditingComplete: () {
                  _editingFields.remove('${fieldId}_limit');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactValueSection(
    String label,
    double value,
    String unit,
    Color color,
  ) {
    final isTemperature = unit == '°C';
    final decimalPlaces = isTemperature ? 1 : 3;
    
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${value.toStringAsFixed(decimalPlaces)} $unit',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 1; i <= 6; i++)
          Padding(
            padding: EdgeInsets.only(right: i < 6 ? 6 : 0),
            child: _buildPresetButton(context, i),
          ),
      ],
    );
  }

  Widget _buildPresetButton(BuildContext context, int group) {
    // Determine if this preset is currently active
    double groupVoltage;
    double groupCurrent;
    
    switch (group) {
      case 1:
        groupVoltage = widget.state.group1SetVoltage;
        groupCurrent = widget.state.group1SetCurrent;
        break;
      case 2:
        groupVoltage = widget.state.group2SetVoltage;
        groupCurrent = widget.state.group2SetCurrent;
        break;
      case 3:
        groupVoltage = widget.state.group3SetVoltage;
        groupCurrent = widget.state.group3SetCurrent;
        break;
      case 4:
        groupVoltage = widget.state.group4SetVoltage;
        groupCurrent = widget.state.group4SetCurrent;
        break;
      case 5:
        groupVoltage = widget.state.group5SetVoltage;
        groupCurrent = widget.state.group5SetCurrent;
        break;
      case 6:
        groupVoltage = widget.state.group6SetVoltage;
        groupCurrent = widget.state.group6SetCurrent;
        break;
      default:
        groupVoltage = 0.0;
        groupCurrent = 0.0;
    }
    
    // Check if this preset matches current set values (within 0.01 tolerance)
    final isActive = (widget.state.setVoltage - groupVoltage).abs() < 0.01 &&
                     (widget.state.setCurrent - groupCurrent).abs() < 0.01;
    
    return SizedBox(
      width: 50,
      height: 32,
      child: OutlinedButton(
        onPressed: () {
          Provider.of<DeviceProvider>(context, listen: false).loadGroup(group);
        },
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          side: BorderSide(
            color: isActive 
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.primary.withOpacity(0.5),
            width: isActive ? 2 : 1,
          ),
          backgroundColor: isActive 
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1) 
              : Colors.transparent,
        ),
        child: Text(
          'M$group',
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive 
                ? Theme.of(context).colorScheme.primary 
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
