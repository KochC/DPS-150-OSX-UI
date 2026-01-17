/// Main app entry point.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dps150_control/providers/device_provider.dart';
import 'package:dps150_control/screens/connection_screen.dart';
import 'package:dps150_control/screens/main_screen.dart';
import 'package:dps150_control/screens/settings_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DeviceProvider(),
      child: MaterialApp(
        title: 'DPS-150 Control',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        home: const MainTabBar(),
      ),
    );
  }
}

class MainTabBar extends StatefulWidget {
  const MainTabBar({super.key});

  @override
  State<MainTabBar> createState() => _MainTabBarState();
}

class _MainTabBarState extends State<MainTabBar> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Auto-connect on app startup
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
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          MainScreen(),
          SettingsScreen(),
          ConnectionScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Control',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.link),
            label: 'Connection',
          ),
        ],
      ),
    );
  }
}
