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
          useMaterial3: true,
          brightness: Brightness.dark,
          colorScheme: ColorScheme.dark(
            primary: const Color(0xFF00D4FF), // Bright cyan/teal - matches app icon
            secondary: const Color(0xFF00B8D4), // Slightly darker cyan
            tertiary: const Color(0xFF00ACC1), // Darker teal accent
            surface: const Color(0xFF1E1E1E), // Dark gray background
            surfaceContainerHighest: const Color(0xFF2D2D2D), // Elevated surfaces
            onSurface: const Color(0xFFE0E0E0), // Light text on dark
            onPrimary: const Color(0xFF000000), // Black text on cyan buttons
            background: const Color(0xFF121212), // Very dark background
            error: const Color(0xFFCF6679), // Softer red for errors
            onError: const Color(0xFF000000),
            outline: const Color(0xFF424242), // Borders
          ),
          scaffoldBackgroundColor: const Color(0xFF121212),
          cardTheme: CardThemeData(
            elevation: 2,
            color: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1E1E1E),
            elevation: 0,
            foregroundColor: Color(0xFF00D4FF),
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Color(0xFF1E1E1E),
            selectedItemColor: Color(0xFF00D4FF),
            unselectedItemColor: Color(0xFF757575),
            type: BottomNavigationBarType.fixed,
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Color(0xFF424242)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Color(0xFF424242)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Color(0xFF00D4FF), width: 2),
            ),
            fillColor: const Color(0xFF1E1E1E),
            filled: true,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D4FF),
              foregroundColor: const Color(0xFF000000),
              elevation: 2,
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
