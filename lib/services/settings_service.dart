import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings.dart';

class SettingsService extends ChangeNotifier {
  static const String _settingsKey = 'settings';
  final SharedPreferences _prefs;
  Settings _settings = const Settings();

  Settings get settings => _settings;
  ThemeMode get themeMode => _settings.themeMode;
  int get maxLogEntries => _settings.maxLogEntries;

  SettingsService(this._prefs);

  Future<void> loadSettings() async {
    final jsonString = _prefs.getString(_settingsKey);
    if (jsonString == null) {
      _settings = const Settings();
      return;
    }

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      _settings = Settings.fromJson(json);
    } catch (e) {
      _settings = const Settings();
    }
    notifyListeners();
  }

  Future<void> _saveSettings() async {
    final jsonString = jsonEncode(_settings.toJson());
    await _prefs.setString(_settingsKey, jsonString);
  }

  Future<void> updateThemeMode(ThemeMode themeMode) async {
    _settings = _settings.copyWith(themeMode: themeMode);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> updateMaxLogEntries(int maxLogEntries) async {
    _settings = _settings.copyWith(maxLogEntries: maxLogEntries);
    await _saveSettings();
    notifyListeners();
  }
}

