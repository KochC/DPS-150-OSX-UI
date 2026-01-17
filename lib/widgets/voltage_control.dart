/// Voltage control widget with slider and text input.

import 'package:flutter/material.dart';

class VoltageControl extends StatefulWidget {
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const VoltageControl({
    super.key,
    required this.value,
    this.min = 0.0,
    this.max = 30.0,
    required this.onChanged,
  });

  @override
  State<VoltageControl> createState() => _VoltageControlState();
}

class _VoltageControlState extends State<VoltageControl> {
  late TextEditingController _controller;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toStringAsFixed(2));
  }

  @override
  void didUpdateWidget(VoltageControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing && widget.value != oldWidget.value) {
      _controller.text = widget.value.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  'Voltage',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _controller,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      suffixText: 'V',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      contentPadding: const EdgeInsets.all(8),
                    ),
                    onTap: () => _isEditing = true,
                    onSubmitted: (value) {
                      _isEditing = false;
                      final numValue = double.tryParse(value);
                      if (numValue != null) {
                        final clamped = numValue.clamp(widget.min, widget.max);
                        widget.onChanged(clamped);
                        _controller.text = clamped.toStringAsFixed(2);
                      } else {
                        _controller.text = widget.value.toStringAsFixed(2);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Slider(
              value: widget.value.clamp(widget.min, widget.max),
              min: widget.min,
              max: widget.max,
              onChangeStart: (value) {
                _isEditing = true;
              },
              onChangeEnd: (value) {
                _isEditing = false;
                // Send final value to device when user releases slider
                widget.onChanged(value);
                _controller.text = value.toStringAsFixed(2);
              },
              onChanged: (value) {
                // Update display while dragging, but don't send to device yet
                if (!_isEditing) {
                  _controller.text = value.toStringAsFixed(2);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
