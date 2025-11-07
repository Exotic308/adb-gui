import 'package:flutter/material.dart';

class Settings {
  final ThemeMode themeMode;
  final int maxLogEntries;

  const Settings({this.themeMode = ThemeMode.dark, this.maxLogEntries = 10000});

  Settings copyWith({ThemeMode? themeMode, int? maxLogEntries}) {
    return Settings(themeMode: themeMode ?? this.themeMode, maxLogEntries: maxLogEntries ?? this.maxLogEntries);
  }

  Map<String, dynamic> toJson() {
    return {'themeMode': themeMode.index, 'maxLogEntries': maxLogEntries};
  }

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      themeMode: ThemeMode.values[json['themeMode'] as int? ?? 2],
      maxLogEntries: json['maxLogEntries'] as int? ?? 10000,
    );
  }
}
