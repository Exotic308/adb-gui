import 'dart:async';
import 'dart:convert';

import 'adb_service.dart';

class PackageService {
  final AdbService _adbService;
  final Map<int, String> _pidToPackage = {}; // pid → packageName
  Timer? _refreshTimer;
  String? _currentDeviceId;

  PackageService(this._adbService);

  /// Get package name for a given PID (synchronous, from cache only)
  /// Returns empty string if not in cache
  String getPackageName(int pid) {
    return _pidToPackage[pid] ?? '';
  }

  /// Start periodic refresh of PID → package mapping every 5 seconds
  void startRefresh(String deviceId) {
    _currentDeviceId = deviceId;
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) => _refreshMapping());
    _refreshMapping(); // Initial load
  }

  /// Stop periodic refresh
  void stopRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _currentDeviceId = null;
    _pidToPackage.clear();
  }

  /// Query current PID → package mapping from device
  Future<void> _refreshMapping() async {
    if (_currentDeviceId == null) return;

    try {
      // Run: adb shell ps -A -o PID,NAME
      final result = await _adbService.executeCommand([
        '-s',
        _currentDeviceId!,
        'shell',
        'ps',
        '-A',
        '-o',
        'PID,NAME',
      ]);

      if (result.exitCode == 0) {
        _parsePsOutput(result.stdout.toString());
      }
    } catch (e) {
      // Silently fail - old mapping will remain
    }
  }

  /// Parse output of `ps -A -o PID,NAME`
  void _parsePsOutput(String output) {
    final lines = LineSplitter.split(output);
    
    for (final line in lines.skip(1)) {
      // Skip header line
      final parts = line.trim().split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        final pid = int.tryParse(parts[0]);
        final packageName = parts[1];
        
        if (pid != null && packageName.contains('.')) {
          // Only store if it looks like a package name (has dots)
          _pidToPackage[pid] = packageName;
        }
      }
    }
  }

  void dispose() {
    stopRefresh();
  }
}

