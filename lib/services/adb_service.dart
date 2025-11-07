import 'dart:io';

class AdbService {
  String? _adbPath;
  bool _isInitialized = false;

  bool get isAdbAvailable => _adbPath != null;
  String? get adbPath => _adbPath;

  /// Initialize ADB service by detecting ADB installation
  Future<bool> initialize() async {
    if (_isInitialized) return isAdbAvailable;

    _adbPath = await _detectAdbPath();
    _isInitialized = true;
    return isAdbAvailable;
  }

  /// Detect ADB path by checking PATH and common locations
  Future<String?> _detectAdbPath() async {
    // First, try just "adb" command without full path (works better on macOS)
    try {
      final result = await Process.run('adb', ['version']);
      if (result.exitCode == 0) {
        // ADB is in PATH and executable, just use "adb"
        return 'adb';
      }
    } catch (e) {
      // Continue to other methods
    }

    // Try to find adb in PATH using which/where
    try {
      final whichCommand = Platform.isWindows ? 'where' : 'which';
      final result = await Process.run(whichCommand, ['adb']);
      if (result.exitCode == 0) {
        final path = result.stdout.toString().trim().split('\n').first;
        if (path.isNotEmpty) {
          // Test if we can actually execute it
          try {
            final testResult = await Process.run(path, ['version']);
            if (testResult.exitCode == 0) {
              return path;
            }
          } catch (e) {
            // If full path doesn't work, try just "adb"
            return 'adb';
          }
        }
      }
    } catch (e) {
      // Continue to check other locations
    }

    // Try common Android SDK locations
    final commonPaths = _getCommonAdbPaths();
    for (final path in commonPaths) {
      if (await File(path).exists()) {
        try {
          final testResult = await Process.run(path, ['version']);
          if (testResult.exitCode == 0) {
            return path;
          }
        } catch (e) {
          // Skip paths that can't be executed
          continue;
        }
      }
    }

    return null;
  }

  /// Get common ADB installation paths based on platform
  List<String> _getCommonAdbPaths() {
    final homeDir = Platform.environment['HOME'] ?? '';

    if (Platform.isMacOS) {
      return [
        '$homeDir/Library/Android/sdk/platform-tools/adb',
        '/usr/local/bin/adb',
        '/opt/homebrew/bin/adb',
        '$homeDir/Android/Sdk/platform-tools/adb',
      ];
    } else if (Platform.isLinux) {
      return [
        '$homeDir/Android/Sdk/platform-tools/adb',
        '/usr/bin/adb',
        '/usr/local/bin/adb',
        '$homeDir/.android/sdk/platform-tools/adb',
      ];
    } else if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'] ?? '';
      return [
        '$userProfile\\AppData\\Local\\Android\\Sdk\\platform-tools\\adb.exe',
        'C:\\Program Files (x86)\\Android\\android-sdk\\platform-tools\\adb.exe',
        'C:\\Android\\sdk\\platform-tools\\adb.exe',
      ];
    }

    return [];
  }

  /// Execute an ADB command
  Future<ProcessResult> executeCommand(List<String> arguments) async {
    if (_adbPath == null) {
      throw Exception('ADB is not available. Please install Android SDK Platform Tools.');
    }

    try {
      final result = await Process.run(_adbPath!, arguments);
      return result;
    } catch (e) {
      if (e.toString().contains('Operation not permitted')) {
        throw Exception(
          'Permission denied to execute ADB.\n\n'
          'On macOS, you may need to:\n'
          '1. Grant Terminal/IDE permission in System Settings > Privacy & Security\n'
          '2. Or try running: chmod +x $_adbPath\n'
          '3. Or use "adb" directly instead of the full path',
        );
      }
      throw Exception('Failed to execute ADB command: $e\nCommand: $_adbPath ${arguments.join(" ")}');
    }
  }

  /// Start an ADB process and return the Process object for streaming
  Future<Process> startProcess(List<String> arguments) async {
    if (_adbPath == null) {
      throw Exception('ADB is not available. Please install Android SDK Platform Tools.');
    }

    try {
      return await Process.start(_adbPath!, arguments);
    } catch (e) {
      throw Exception('Failed to start ADB process: $e');
    }
  }

  /// Get list of connected devices
  Future<List<Map<String, String>>> getDevices() async {
    final result = await executeCommand(['devices', '-l']);

    if (result.exitCode != 0) {
      throw Exception('Failed to get devices: ${result.stderr}');
    }

    final output = result.stdout.toString();
    final lines = output.split('\n');
    final devices = <Map<String, String>>[];

    for (var line in lines.skip(1)) {
      // Skip the "List of devices attached" line
      line = line.trim();
      if (line.isEmpty) continue;

      final parts = line.split(RegExp(r'\s+'));
      if (parts.length >= 2 && parts[1] == 'device') {
        final deviceId = parts[0];
        final deviceInfo = <String, String>{'id': deviceId};

        // Parse additional device information
        for (var i = 2; i < parts.length; i++) {
          if (parts[i].contains(':')) {
            final keyValue = parts[i].split(':');
            if (keyValue.length == 2) {
              deviceInfo[keyValue[0]] = keyValue[1];
            }
          }
        }

        devices.add(deviceInfo);
      }
    }

    return devices;
  }

  /// Get device properties using shell getprop
  Future<Map<String, String>> getDeviceProperties(String deviceId) async {
    final result = await executeCommand(['-s', deviceId, 'shell', 'getprop']);

    if (result.exitCode != 0) {
      throw Exception('Failed to get device properties: ${result.stderr}');
    }

    final output = result.stdout.toString();
    final properties = <String, String>{};
    final propPattern = RegExp(r'\[(.*?)\]:\s*\[(.*?)\]');

    for (final line in output.split('\n')) {
      final match = propPattern.firstMatch(line);
      if (match != null) {
        properties[match.group(1)!] = match.group(2)!;
      }
    }

    return properties;
  }

  /// Clear logcat buffer
  Future<void> clearLogcat(String deviceId) async {
    await executeCommand(['-s', deviceId, 'logcat', '-c']);
  }

  /// Get installation instructions based on platform
  static String getInstallationInstructions() {
    if (Platform.isMacOS) {
      return '''
ADB (Android Debug Bridge) is not installed on your system.

To install ADB on macOS:

1. Using Homebrew (recommended):
   brew install android-platform-tools

2. Or download manually:
   - Visit: https://developer.android.com/tools/releases/platform-tools
   - Download "SDK Platform-Tools for Mac"
   - Extract and add to your PATH

After installation, click "Check Again" to continue.
''';
    } else if (Platform.isLinux) {
      return '''
ADB (Android Debug Bridge) is not installed on your system.

To install ADB on Linux:

1. Using package manager:
   - Ubuntu/Debian: sudo apt-get install android-tools-adb
   - Fedora: sudo dnf install android-tools
   - Arch: sudo pacman -S android-tools

2. Or download manually:
   - Visit: https://developer.android.com/tools/releases/platform-tools
   - Download "SDK Platform-Tools for Linux"
   - Extract and add to your PATH

After installation, click "Check Again" to continue.
''';
    } else if (Platform.isWindows) {
      return '''
ADB (Android Debug Bridge) is not installed on your system.

To install ADB on Windows:

1. Download Android SDK Platform Tools:
   - Visit: https://developer.android.com/tools/releases/platform-tools
   - Download "SDK Platform-Tools for Windows"
   - Extract to a folder (e.g., C:\\platform-tools)

2. Add to PATH:
   - Search for "Environment Variables" in Windows
   - Add the platform-tools folder to your PATH

After installation, click "Check Again" to continue.
''';
    }

    return 'Please install Android SDK Platform Tools to continue.';
  }
}
