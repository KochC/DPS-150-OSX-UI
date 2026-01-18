/// Main screen with live monitoring and controls.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dps150_control/providers/device_provider.dart';
import 'package:dps150_control/widgets/live_monitor.dart';
import 'package:dps150_control/widgets/time_graph.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<DeviceProvider>(
          builder: (context, provider, child) {
            final isConnected = provider.isConnected || provider.status == ConnectionStatus.connected;
            
            if (!isConnected) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.usb_off, 
                      size: 64, 
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Please connect to a device',
                      style: TextStyle(
                        fontSize: 18, 
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Go to the Connection tab to connect',
                      style: TextStyle(
                        fontSize: 12, 
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              );
            }

            final state = provider.state;
            return LayoutBuilder(
              builder: (context, constraints) {
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Left side: Time graph (expands to fill remaining space)
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16, right: 8, top: 16, bottom: 16),
                          child: TimeGraph(
                            voltage: state.outputVoltage,
                            current: state.outputCurrent,
                            power: state.outputPower,
                            outputEnabled: state.outputClosed,
                          ),
                        ),
                      ),
                      // Right side: Value controls (fixed width)
                      SizedBox(
                        width: 400,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8, right: 16, top: 16, bottom: 16),
                          child: LiveMonitor(state: state),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

}
