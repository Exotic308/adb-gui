import 'package:flutter_querybuilder/flutter_querybuilder.dart';

import '../models/log_entry.dart';

class QueryEvaluatorService {
  final QueryEvaluator _evaluator = QueryEvaluator();

  /// Converts LogEntry to a Map for query evaluation
  Map<String, dynamic> _logEntryToMap(LogEntry entry) {
    return {
      'tag': entry.tag,
      'message': entry.message,
      'priority': entry.priority.name,
      'processId': entry.processId,
      'pid': entry.processId, // Alias
      'threadId': entry.threadId,
      'tid': entry.threadId, // Alias
      'dateTime': entry.dateTime.millisecondsSinceEpoch,
      'timeString': entry.timeString,
    };
  }

  /// Evaluates a query against a log entry
  bool evaluate(QueryGroup query, LogEntry entry) {
    final data = _logEntryToMap(entry);
    return _evaluator.evaluate(query, data);
  }

  /// Clears the evaluator cache
  void clearCache() {
    _evaluator.clearCache();
  }
}

