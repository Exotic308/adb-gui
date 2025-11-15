import 'priority.dart';

class LogEntry {
  final DateTime dateTime;
  final String timeString;
  final int processId;
  final int threadId;
  final Priority priority;
  final String tag;
  final String message;

  int get pid => processId;
  int get tid => threadId;

  LogEntry({
    required this.dateTime,
    required this.processId,
    required this.threadId,
    required this.priority,
    required this.tag,
    required this.message,
  }) : timeString = toStringTime(dateTime);

  static String toStringTime(DateTime dateTime) {
    final h = dateTime.hour.toString().padLeft(2, '0');
    final m = dateTime.minute.toString().padLeft(2, '0');
    final s = dateTime.second.toString().padLeft(2, '0');
    final ms = dateTime.millisecond.toString().padLeft(3, '0');
    return '$h:$m:$s.$ms';
  }
}
