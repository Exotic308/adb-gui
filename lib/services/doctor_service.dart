import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/doctor_check.dart';
import '../services/adb_service.dart';
import '../utils/constants.dart';

class DoctorService extends ChangeNotifier {
  final AdbService _adbService;
  Timer? _pollTimer;

  List<DoctorCheck> _checks = [
    const DoctorCheck(title: 'System Permissions', description: 'Checking if we have permission to run commands'),
    const DoctorCheck(title: 'ADB Installation', description: 'Checking if Android Debug Bridge is installed'),
    const DoctorCheck(title: 'ADB Version', description: 'Verifying ADB version'),
    const DoctorCheck(title: 'ADB Server', description: 'Checking ADB server status'),
    const DoctorCheck(title: 'Device Communication', description: 'Testing device communication'),
  ];

  DoctorService(this._adbService);

  List<DoctorCheck> get checks => _checks;
  bool get hasAllPassed => _checks.every((c) => c.status == DoctorCheckStatus.success);
  bool get hasErrors => _checks.any((c) => c.status == DoctorCheckStatus.error);

  Future<void> runChecks() async {
    final checks = <DoctorCheck>[];

    checks.add(await _checkSystemPermissions());
    _checks = List.from(checks);
    notifyListeners();

    if (checks.last.status == DoctorCheckStatus.error) {
      return;
    }

    checks.add(await _checkAdbInstallation());
    _checks = List.from(checks);
    notifyListeners();

    if (checks.last.status == DoctorCheckStatus.error) {
      return;
    }

    checks.add(await _checkAdbVersion());
    _checks = List.from(checks);
    notifyListeners();

    checks.add(await _checkAdbServer());
    _checks = List.from(checks);
    notifyListeners();

    checks.add(await _checkDeviceCommunication());
    _checks = List.from(checks);
    notifyListeners();
  }

  Future<DoctorCheck> _checkSystemPermissions() async {
    try {
      final result = await Process.run('echo', ['test']);
      if (result.exitCode == 0) {
        return const DoctorCheck(
          title: 'System Permissions',
          description: 'Checking if we have permission to run commands',
          status: DoctorCheckStatus.success,
          resultMessage: 'System has permission to execute commands',
        );
      }
      return const DoctorCheck(
        title: 'System Permissions',
        description: 'Checking if we have permission to run commands',
        status: DoctorCheckStatus.error,
        resultMessage: 'Unable to execute system commands',
      );
    } catch (err) {
      if (err.toString().contains('Operation not permitted')) {
        return const DoctorCheck(
          title: 'System Permissions',
          description: 'Checking if we have permission to run commands',
          status: DoctorCheckStatus.error,
          resultMessage: '''macOS Security Restriction:

Your system is blocking command execution. This is required to run ADB.

To fix this:
1. Open System Settings > Privacy & Security
2. Grant permission to your IDE/Terminal
3. Or run: flutter run -d macos from Terminal

After granting permission, click "Recheck" below.''',
        );
      }
      return DoctorCheck(
        title: 'System Permissions',
        description: 'Checking if we have permission to run commands',
        status: DoctorCheckStatus.error,
        resultMessage: 'Permission denied: $err',
      );
    }
  }

  Future<DoctorCheck> _checkAdbInstallation() async {
    if (_adbService.isAdbAvailable) {
      return DoctorCheck(
        title: 'ADB Installation',
        description: 'Checking if Android Debug Bridge is installed',
        status: DoctorCheckStatus.success,
        resultMessage: 'ADB found at: ${_adbService.adbPath}',
      );
    }
    return DoctorCheck(
      title: 'ADB Installation',
      description: 'Checking if Android Debug Bridge is installed',
      status: DoctorCheckStatus.error,
      resultMessage: AdbService.getInstallationInstructions(),
    );
  }

  Future<DoctorCheck> _checkAdbVersion() async {
    try {
      final versionResult = await _adbService.executeCommand(['version']);

      if (versionResult.exitCode == 0) {
        final versionOutput = versionResult.stdout.toString();
        final versionLine = versionOutput.split('\n').first.trim();
        return DoctorCheck(
          title: 'ADB Version',
          description: 'Verifying ADB version',
          status: DoctorCheckStatus.success,
          resultMessage: versionLine,
        );
      }
      return DoctorCheck(
        title: 'ADB Version',
        description: 'Verifying ADB version',
        status: DoctorCheckStatus.error,
        resultMessage: 'Failed to get ADB version: ${versionResult.stderr}',
      );
    } catch (err) {
      return DoctorCheck(
        title: 'ADB Version',
        description: 'Verifying ADB version',
        status: DoctorCheckStatus.error,
        resultMessage: 'Failed to check ADB version: $err',
      );
    }
  }

  Future<DoctorCheck> _checkAdbServer() async {
    try {
      final startServerResult = await _adbService.executeCommand(['start-server']);

      if (startServerResult.exitCode == 0) {
        return const DoctorCheck(
          title: 'ADB Server',
          description: 'Checking ADB server status',
          status: DoctorCheckStatus.success,
          resultMessage: 'ADB server is running',
        );
      }
      return DoctorCheck(
        title: 'ADB Server',
        description: 'Checking ADB server status',
        status: DoctorCheckStatus.error,
        resultMessage: 'Failed to start ADB server: ${startServerResult.stderr}',
      );
    } catch (err) {
      return DoctorCheck(
        title: 'ADB Server',
        description: 'Checking ADB server status',
        status: DoctorCheckStatus.error,
        resultMessage: 'Failed to check ADB server: $err',
      );
    }
  }

  Future<DoctorCheck> _checkDeviceCommunication() async {
    try {
      final devicesResult = await _adbService.executeCommand(['devices']);

      if (devicesResult.exitCode == 0) {
        return const DoctorCheck(
          title: 'Device Communication',
          description: 'Testing device communication',
          status: DoctorCheckStatus.success,
          resultMessage: 'Ready to communicate with devices',
        );
      }
      return DoctorCheck(
        title: 'Device Communication',
        description: 'Testing device communication',
        status: DoctorCheckStatus.warning,
        resultMessage: 'Device communication has issues: ${devicesResult.stderr}',
      );
    } catch (err) {
      return DoctorCheck(
        title: 'Device Communication',
        description: 'Testing device communication',
        status: DoctorCheckStatus.error,
        resultMessage: 'Failed to test device communication: $err',
      );
    }
  }

  void startPolling() {
    stopPolling();

    runChecks();

    _pollTimer = Timer.periodic(AppConstants.devicePollInterval, (_) {
      if (hasErrors) {
        runChecks();
      }
    });
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}

