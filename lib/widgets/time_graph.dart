/// Time graph widget showing voltage, current, and power over time.

import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// Data point for time series.
class TimeDataPoint {
  final DateTime timestamp;
  final double voltage;
  final double current;
  final double power;
  final bool outputEnabled;

  TimeDataPoint({
    required this.timestamp,
    required this.voltage,
    required this.current,
    required this.power,
    required this.outputEnabled,
  });
}

/// Time graph widget for displaying voltage, current, and power over time.
class TimeGraph extends StatefulWidget {
  final double voltage;
  final double current;
  final double power;
  final bool outputEnabled;
  final Duration maxHistoryDuration;

  const TimeGraph({
    super.key,
    required this.voltage,
    required this.current,
    required this.power,
    required this.outputEnabled,
    this.maxHistoryDuration = const Duration(minutes: 5),
  });

  @override
  State<TimeGraph> createState() => _TimeGraphState();
}

class _TimeGraphState extends State<TimeGraph> {
  final Queue<TimeDataPoint> _dataPoints = Queue<TimeDataPoint>();
  DateTime? _startTime;
  DateTime? _frozenTime; // Freeze time when power is off
  Timer? _updateTimer;
  Duration _timeframe = const Duration(minutes: 5);
  
  // Max value across all three (V, A, W) for unified scale
  double _maxValue = 10.0;

  @override
  void initState() {
    super.initState();
    _timeframe = widget.maxHistoryDuration;
    // Only start timer if output is enabled initially
    if (widget.outputEnabled) {
      _startUpdateTimer();
    } else {
      // Freeze time if output is disabled initially
      _frozenTime = DateTime.now();
    }
  }

  @override
  void didUpdateWidget(TimeGraph oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update timeframe if it changed
    if (widget.maxHistoryDuration != oldWidget.maxHistoryDuration) {
      _timeframe = widget.maxHistoryDuration;
    }
    
    // Restart timer if output state changed
    if (widget.outputEnabled != oldWidget.outputEnabled) {
      if (widget.outputEnabled) {
        // Unfreeze time when power is turned on
        _frozenTime = null;
        _startUpdateTimer();
        // Add a data point when output is enabled
        _addDataPoint();
      } else {
        _stopUpdateTimer();
        // Freeze time when power is turned off
        _frozenTime = DateTime.now();
        // Add a final data point when output is disabled
        _addDataPoint();
      }
      if (mounted) {
        setState(() {});
      }
    }
    
    // Only add data points when output is enabled and values change
    if (widget.outputEnabled) {
      final valuesChanged = widget.voltage != oldWidget.voltage ||
          widget.current != oldWidget.current ||
          widget.power != oldWidget.power;
      
      if (valuesChanged) {
        // Capture all values at the exact same timestamp
        _addDataPoint();
        _updateMaxValues();
        // Force update to show new data immediately
        if (mounted) {
          setState(() {});
        }
      }
    }
  }

  void _startUpdateTimer() {
    _stopUpdateTimer();
    if (widget.outputEnabled) {
      // Update every 500ms for smoother animation
      _updateTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
        if (mounted && widget.outputEnabled) {
          _addDataPoint();
          // Only rebuild if we have data points
          if (_dataPoints.isNotEmpty) {
            setState(() {});
          }
        }
      });
    }
  }

  void _stopUpdateTimer() {
    _updateTimer?.cancel();
    _updateTimer = null;
  }

  @override
  void dispose() {
    _stopUpdateTimer();
    super.dispose();
  }

  void _addDataPoint() {
    final now = DateTime.now();
    if (_startTime == null) {
      _startTime = now;
    }

    // Store zero values when output is off
    _dataPoints.add(TimeDataPoint(
      timestamp: now,
      voltage: widget.outputEnabled ? widget.voltage : 0.0,
      current: widget.outputEnabled ? widget.current : 0.0,
      power: widget.outputEnabled ? widget.power : 0.0,
      outputEnabled: widget.outputEnabled,
    ));

    // Only remove very old data points (older than 1 hour) to preserve history
    // The display will filter based on the current timeframe
    final maxHistory = const Duration(hours: 1);
    final cutoffTime = now.subtract(maxHistory);
    while (_dataPoints.isNotEmpty &&
        _dataPoints.first.timestamp.isBefore(cutoffTime)) {
      _dataPoints.removeFirst();
    }

    _updateMaxValues();

    if (mounted) {
      setState(() {});
    }
  }

  /// Get data point closest to a given time (for tooltips)
  TimeDataPoint? _getDataPointAtTime(double secondsFromStart) {
    if (_dataPoints.isEmpty) return null;
    
    final now = _frozenTime ?? DateTime.now();
    final windowStart = now.subtract(_timeframe);
    final targetTime = windowStart.add(Duration(milliseconds: (secondsFromStart * 1000).toInt()));
    
    TimeDataPoint? closest;
    Duration? minDiff;
    
    for (final point in _dataPoints) {
      final diff = (point.timestamp.difference(targetTime)).abs();
      if (minDiff == null || diff < minDiff) {
        minDiff = diff;
        closest = point;
      }
    }
    
    return closest;
  }

  /// Update max value across all three (V, A, W) for unified scale
  void _updateMaxValues() {
    if (_dataPoints.isEmpty) {
      _maxValue = 10.0;
      return;
    }
    
    double max = 0.0;
    
    for (final point in _dataPoints) {
      max = max > point.voltage ? max : point.voltage;
      max = max > point.current ? max : point.current;
      max = max > point.power ? max : point.power;
    }
    
    _maxValue = (max * 1.1).clamp(1.0, double.infinity);
  }

  /// Get voltage line segments, scaled to 0-10 range
  List<LineChartBarData> _getVoltageLineSegments() {
    return _getLineSegments(
      (point) => (point.voltage / _maxValue) * 10.0,
      Colors.blue,
    );
  }

  /// Get current line segments, scaled to 0-10 range
  List<LineChartBarData> _getCurrentLineSegments() {
    return _getLineSegments(
      (point) => (point.current / _maxValue) * 10.0,
      Colors.green,
    );
  }

  /// Get power line segments, scaled to 0-10 range
  List<LineChartBarData> _getPowerLineSegments() {
    return _getLineSegments(
      (point) => (point.power / _maxValue) * 10.0,
      Colors.orange,
    );
  }

  /// Helper to create line segments split at output state changes
  List<LineChartBarData> _getLineSegments(
      double Function(TimeDataPoint) getValue, Color color) {
    if (_dataPoints.isEmpty) return [];
    
    // Use frozen time if power is off, otherwise use current time
    final now = _frozenTime ?? DateTime.now();
    final windowStart = now.subtract(_timeframe);
    
    final visiblePoints = _dataPoints
        .where((point) => point.timestamp.isAfter(windowStart))
        .toList();
    
    if (visiblePoints.isEmpty) return [];
    
    final List<LineChartBarData> segments = [];
    List<FlSpot> currentSegment = [];
    bool? lastOutputState;
    
    for (final point in visiblePoints) {
      // Use milliseconds for more precise time positioning
      final millisecondsFromWindowStart =
          point.timestamp.difference(windowStart).inMilliseconds.toDouble();
      final secondsFromWindowStart = millisecondsFromWindowStart / 1000.0;
      
      // If output state changed, finalize current segment and start new one
      if (lastOutputState != null && lastOutputState != point.outputEnabled) {
        if (currentSegment.isNotEmpty) {
          segments.add(LineChartBarData(
            spots: currentSegment,
            isCurved: false, // No smoothing - straight lines
            color: color,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ));
        }
        currentSegment = [];
      }
      
      currentSegment.add(FlSpot(secondsFromWindowStart, getValue(point)));
      lastOutputState = point.outputEnabled;
    }
    
    // Add final segment
    if (currentSegment.isNotEmpty) {
      segments.add(LineChartBarData(
        spots: currentSegment,
        isCurved: false, // No smoothing - straight lines
        color: color,
        barWidth: 2,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: false),
      ));
    }
    
    return segments;
  }

  double _getMaxTime() {
    return _timeframe.inMilliseconds.toDouble() / 1000.0;
  }

  void _setTimeframe(Duration duration) {
    setState(() {
      _timeframe = duration;
      // Don't remove data points - just change the display window
      // Data points are filtered in the display logic (_getLineSegments)
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Time Graph',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: _dataPoints.isEmpty
                  ? Center(
                      child: Text(
                        'No data yet. Connect to device and enable output.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    )
                  : LineChart(
                      LineChartData(
                        // Enable touch interactions with tooltip
                        lineTouchData: LineTouchData(
                          enabled: true,
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems: (List<LineBarSpot> touchedSpots) {
                              return touchedSpots.map((LineBarSpot touchedSpot) {
                                final point = _getDataPointAtTime(touchedSpot.x);
                                if (point == null) return null;
                                
                                String label;
                                Color color;
                                if (touchedSpot.barIndex == 0) {
                                  // Voltage
                                  label = 'V: ${point.voltage.toStringAsFixed(2)}';
                                  color = Colors.blue;
                                } else if (touchedSpot.barIndex == 1) {
                                  // Current
                                  label = 'A: ${point.current.toStringAsFixed(3)}';
                                  color = Colors.green;
                                } else {
                                  // Power
                                  label = 'W: ${point.power.toStringAsFixed(2)}';
                                  color = Colors.orange;
                                }
                                
                                return LineTooltipItem(
                                  label,
                                  TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              }).toList();
                            },
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 1.0, // 10 divisions (0-10)
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                              strokeWidth: 1,
                            );
                          },
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                // Use frozen time if power is off, otherwise use current time
                                final now = _frozenTime ?? DateTime.now();
                                final windowStart = now.subtract(_timeframe);
                                final targetTime = windowStart.add(Duration(milliseconds: (value * 1000).toInt()));
                                final secondsFromNow = now.difference(targetTime).inSeconds;
                                
                                // Show labels at intervals based on timeframe
                                if (_timeframe.inHours > 0) {
                                  // For hour+ timeframes, show every 10 minutes
                                  if (secondsFromNow % 600 == 0) {
                                    return Text(
                                      '${-secondsFromNow ~/ 60}m',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                        fontSize: 10,
                                      ),
                                    );
                                  }
                                } else if (_timeframe.inMinutes >= 10) {
                                  // For 10+ minute timeframes, show every minute
                                  if (secondsFromNow % 60 == 0) {
                                    return Text(
                                      '${-secondsFromNow ~/ 60}m',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                        fontSize: 10,
                                      ),
                                    );
                                  }
                                } else {
                                  // For shorter timeframes, show every 10 seconds
                                  if (secondsFromNow % 10 == 0) {
                                    return Text(
                                      '${-secondsFromNow}s',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                        fontSize: 10,
                                      ),
                                    );
                                  }
                                }
                                return const Text('');
                              },
                              reservedSize: 30,
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 50,
                              interval: 1.0, // 10 divisions (0-10)
                              getTitlesWidget: (value, meta) {
                                // Convert 0-10 scale to actual max value
                                final actualValue = (value / 10.0) * _maxValue;
                                return Text(
                                  actualValue.toStringAsFixed(1),
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                    fontSize: 10,
                                  ),
                                );
                              },
                            ),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                          ),
                        ),
                        minX: 0,
                        maxX: _getMaxTime(),
                        minY: 0,
                        maxY: 10.0,
                        clipData: const FlClipData.all(),
                        lineBarsData: [
                          // Voltage line segments (split by output state changes)
                          ..._getVoltageLineSegments(),
                          // Current line segments (scaled for visibility)
                          ..._getCurrentLineSegments(),
                          // Power line segments
                          ..._getPowerLineSegments(),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Voltage (V)', Colors.blue),
                const SizedBox(width: 16),
                _buildLegendItem('Current (A)', Colors.green),
                const SizedBox(width: 16),
                _buildLegendItem('Power (W)', Colors.orange),
              ],
            ),
            const SizedBox(height: 8),
            // Timeframe settings
            _buildTimeframeSettings(),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 2,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12, 
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeframeSettings() {
    final timeframes = [
      const Duration(seconds: 30),
      const Duration(minutes: 1),
      const Duration(minutes: 2),
      const Duration(minutes: 5),
      const Duration(minutes: 10),
      const Duration(minutes: 30),
      const Duration(hours: 1),
    ];

    String _formatDuration(Duration duration) {
      if (duration.inHours > 0) {
        return '${duration.inHours}h';
      } else if (duration.inMinutes > 0) {
        return '${duration.inMinutes}m';
      } else {
        return '${duration.inSeconds}s';
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Timeframe: ',
          style: TextStyle(
            fontSize: 11, 
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        ...timeframes.map((duration) {
          final isSelected = _timeframe.inMilliseconds == duration.inMilliseconds;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () => _setTimeframe(duration),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  _formatDuration(duration),
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected 
                        ? Theme.of(context).colorScheme.primary 
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}
