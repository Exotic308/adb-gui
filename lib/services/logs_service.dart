import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/log_entry.dart';
import '../services/logcat_service.dart';
import '../services/settings_service.dart';
import '../utils/constants.dart';

class LogsService extends ChangeNotifier {
  final LogcatService _logcatService;
  final SettingsService _settingsService;

  final List<LogEntry> _entries = [];
  final List<LogEntry> _pendingEntries = [];
  StreamSubscription<LogEntry>? _logSubscription;
  Timer? _batchTimer;
  String? _currentDeviceId;
  int _maxLogEntries = AppConstants.maxLogEntries;

  bool _isLoading = false;
  bool _isStreaming = false;
  String? _error;
  bool _isDisposed = false;
  bool _hasTransitionedToStreaming = false;

  LogsService(this._logcatService, this._settingsService);

  List<LogEntry> get entries => _entries;
  bool get isLoading => _isLoading;
  bool get isStreaming => _isStreaming;
  String? get error => _error;
  int get totalCount => _entries.length;

  Future<void> startStreaming(String deviceId) async {
    _currentDeviceId = deviceId;
    _hasTransitionedToStreaming = false;

    try {
      // Get max log entries from settings service
      _maxLogEntries = _settingsService.maxLogEntries;

      _isLoading = true;
      _error = null;
      notifyListeners();

      final stream = await _logcatService.startLogcat(deviceId);

      _logSubscription = stream.listen(
        _addLogEntryBatched,
        onError: (err) {
          _flushPendingEntries();
          if (!_isDisposed) {
            _error = err.toString();
            _isLoading = false;
            _isStreaming = false;
            notifyListeners();
          }
        },
        onDone: () {
          _flushPendingEntries();
          if (!_isDisposed) {
            _isStreaming = false;
            notifyListeners();
          }
        },
      );

      _startBatchTimer();
    } catch (err) {
      if (!_isDisposed) {
        _error = err.toString();
        _isLoading = false;
        _isStreaming = false;
        notifyListeners();
      }
    }
  }

  void stopStreaming() {
    _batchTimer?.cancel();
    _batchTimer = null;
    _flushPendingEntries();

    _logSubscription?.cancel();
    _logSubscription = null;

    _logcatService.stopLogcat();

    if (!_isDisposed) {
      _isStreaming = false;
      notifyListeners();
    }
  }

  Future<void> clearLogs() async {
    if (_currentDeviceId == null || _isDisposed) return;

    try {
      await _logcatService.clearLogcat(_currentDeviceId!);
      _entries.clear();
      _pendingEntries.clear();
      notifyListeners();
    } catch (err) {
      if (!_isDisposed) {
        _error = err.toString();
        notifyListeners();
      }
    }
  }

  void _startBatchTimer() {
    _batchTimer?.cancel();
    _batchTimer = Timer.periodic(AppConstants.logBatchInterval, (_) {
      _flushPendingEntries();
    });
  }

  void _addLogEntryBatched(LogEntry entry) {
    if (_isDisposed) return;

    _pendingEntries.add(entry);

    if (_pendingEntries.length > AppConstants.logBatchSize) {
      _flushPendingEntries();
    }
  }

  void _flushPendingEntries() {
    if (_pendingEntries.isEmpty || _isDisposed) return;

    _entries.addAll(_pendingEntries);

    if (_entries.length > _maxLogEntries) {
      final excess = _entries.length - _maxLogEntries;
      _entries.removeRange(0, excess);
    }

    _pendingEntries.clear();

    if (!_isDisposed) {
      if (!_hasTransitionedToStreaming) {
        _hasTransitionedToStreaming = true;
        _isLoading = false;
        _isStreaming = true;
      }
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _batchTimer?.cancel();
    _logSubscription?.cancel();
    _logcatService.stopLogcat();
    super.dispose();
  }
}

