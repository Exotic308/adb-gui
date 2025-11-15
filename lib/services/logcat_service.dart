import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/log_entry.dart';
import '../utils/log_parser.dart';
import 'adb_service.dart';
import 'rules_service.dart';
import 'package_service.dart';

class LogcatService {
  final AdbService _adbService;
  final RulesService _rulesService;
  final PackageService _packageService;
  Process? _logcatProcess;
  StreamController<LogEntry>? _logStreamController;
  LogEntry? _lastEntry;
  
  bool get isRunning => _logcatProcess != null;

  LogcatService(this._adbService, this._rulesService, this._packageService);

  /// Start streaming logcat from a device
  Future<Stream<LogEntry>> startLogcat(String deviceId, {int? processId}) async {
    if (_logcatProcess != null) {
      await stopLogcat();
    }

    _logStreamController = StreamController<LogEntry>.broadcast();
    
    // Start periodic package name refresh
    _packageService.startRefresh(deviceId);
    
    // Build ADB command arguments
    final args = <String>['-s', deviceId, 'logcat', '-v', 'threadtime'];
    
    // Capture all priorities (rules will filter)
    args.add('*:V');
    
    // Add process ID filter if specified (requires Android 7.0+)
    if (processId != null) {
      args.addAll(['--pid=$processId']);
    }

    try {
      _logcatProcess = await _adbService.startProcess(args);
      
      // Listen to stdout
      _logcatProcess!.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            (line) => _processLogLine(line),
            onError: (error) => _logStreamController?.addError(error),
            onDone: () => _logStreamController?.close(),
          );
      
      // Listen to stderr
      _logcatProcess!.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            (line) => _processLogLine(line),
            onError: (error) => _logStreamController?.addError(error),
          );
      
      return _logStreamController!.stream;
    } catch (e) {
      _logStreamController?.addError(e);
      _logStreamController?.close();
      rethrow;
    }
  }

  void _processLogLine(String line) {
    if (line.trim().isEmpty) return;
    
    // Don't process if stream is closed
    if (_logStreamController == null || _logStreamController!.isClosed) return;

    final entry = LogParser.parseLine(
      line,
      currentYear: DateTime.now().year,
      lastEntry: _lastEntry,
    );
    
    if (entry != null) {
      _lastEntry = entry;
      
      // Apply rules filtering - only add entry if it matches at least one rule
      if (_rulesService.shouldRecord(entry.tag, entry.priority)) {
        // Only add if stream is still open
        if (!_logStreamController!.isClosed) {
          _logStreamController!.add(entry);
        }
      }
    }
  }

  /// Stop the logcat stream
  Future<void> stopLogcat() async {
    // Stop package service refresh
    _packageService.stopRefresh();
    
    // Close stream first to prevent new events
    if (_logStreamController != null && !_logStreamController!.isClosed) {
      await _logStreamController!.close();
    }
    _logStreamController = null;
    
    // Then kill the process
    if (_logcatProcess != null) {
      _logcatProcess!.kill();
      _logcatProcess = null;
    }
    
    _lastEntry = null;
  }

  /// Clear logcat buffer on device
  Future<void> clearLogcat(String deviceId) async {
    await _adbService.clearLogcat(deviceId);
  }

  void dispose() {
    stopLogcat();
  }
}

