import 'dart:async';

import 'package:flutter/material.dart';

import '../models/device.dart';
import '../services/service_locator.dart';
import 'logs_screen.dart';
import 'settings_screen.dart';
import 'splash_screen.dart';

class MainShell extends StatefulWidget {
  final Device device;

  const MainShell({super.key, required this.device});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  bool _isConnected = true;
  Timer? _connectionCheckTimer;

  @override
  void initState() {
    super.initState();
    _startConnectionMonitoring();
  }

  @override
  void dispose() {
    _connectionCheckTimer?.cancel();
    super.dispose();
  }

  void _startConnectionMonitoring() {
    _connectionCheckTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (!mounted) return;

      try {
        final devices = await Services.deviceService.getConnectedDevices();
        final stillConnected = devices.any((d) => d.id == widget.device.id);

        if (mounted && _isConnected != stillConnected) {
          setState(() {
            _isConnected = stillConnected;
          });
        }
      } catch (e) {
        // Error checking devices
        if (mounted && _isConnected) {
          setState(() {
            _isConnected = false;
          });
        }
      }
    });
  }

  void _handleRestart() {
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const SplashScreen()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              FocusScope.of(context).unfocus();
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            leading: Column(
              children: [
                const SizedBox(height: 16),
                InkWell(
                  onTap: _isConnected ? null : _handleRestart,
                  borderRadius: BorderRadius.circular(8),
                  child: Tooltip(
                    message: _isConnected ? '' : 'Device disconnected - Click to reconnect',
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.phone_android, color: Theme.of(context).colorScheme.onPrimaryContainer),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _isConnected ? Colors.green : Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                            ),
                          ),
                        ),
                        if (!_isConnected)
                          Positioned(
                            right: -2,
                            bottom: -2,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.error,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.refresh, size: 16, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 80,
                  child: Column(
                    children: [
                      Text(
                        widget.device.toString(),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (!_isConnected) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Disconnected',
                          textAlign: TextAlign.center,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.error, fontSize: 10),
                        ),
                      ],
                    ],
                  ),
                ),
                const Divider(height: 32),
              ],
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.article_outlined),
                selectedIcon: Icon(Icons.article),
                label: Text('Logs'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.memory_outlined),
                selectedIcon: Icon(Icons.memory),
                label: Text('Memory'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.keyboard_outlined),
                selectedIcon: Icon(Icons.keyboard),
                label: Text('Input'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.screenshot_outlined),
                selectedIcon: Icon(Icons.screenshot),
                label: Text('Screen'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('Settings'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                LogsScreen(device: widget.device, isDeviceConnected: _isConnected),
                const _PlaceholderScreen(title: 'Memory Profiler'),
                const _PlaceholderScreen(title: 'Input Simulator'),
                const _PlaceholderScreen(title: 'Screen Capture'),
                const SettingsScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;

  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction, size: 64, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Coming Soon',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
