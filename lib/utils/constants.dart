import 'package:flutter/material.dart';
import '../models/priority.dart';

class AppConstants {
  AppConstants._();

  static const String appTitle = 'Android Debug Bridge GUI';
  static const int maxLogEntries = 10000;
  static const int logBatchSize = 100;
  static const Duration logBatchInterval = Duration(milliseconds: 100);
  static const Duration devicePollInterval = Duration(seconds: 2);

  static Color getPriorityColor(Priority priority, bool isDark) {
    return isDark
        ? _getPriorityColorDark(priority)
        : _getPriorityColorLight(priority);
  }

  static Color _getPriorityColorDark(Priority priority) {
    switch (priority) {
      case Priority.verbose:
        return Colors.grey;
      case Priority.debug:
        return Colors.lightBlue;
      case Priority.info:
        return Colors.lightGreen;
      case Priority.warn:
        return Colors.orange;
      case Priority.error:
        return Colors.redAccent;
      case Priority.fatal:
        return Colors.red.shade900;
    }
  }

  static Color _getPriorityColorLight(Priority priority) {
    switch (priority) {
      case Priority.verbose:
        return Colors.grey.shade700;
      case Priority.debug:
        return Colors.blue.shade700;
      case Priority.info:
        return Colors.green.shade700;
      case Priority.warn:
        return Colors.orange.shade700;
      case Priority.error:
        return Colors.red.shade700;
      case Priority.fatal:
        return Colors.red.shade900;
    }
  }

  static FontWeight getPriorityFontWeight(Priority priority) {
    return priority == Priority.fatal ? FontWeight.bold : FontWeight.normal;
  }
}
