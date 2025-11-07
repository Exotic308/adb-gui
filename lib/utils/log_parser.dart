import '../models/log_entry.dart';
import '../models/priority.dart';

class LogParser {
  // Regex pattern for logcat threadtime format:
  // MM-DD HH:mm:ss.mmm PID TID PRIORITY TAG: MESSAGE
  static final RegExp _logPattern = RegExp(
    r'^(\d{2}-\d{2})\s+(\d{2}:\d{2}:\d{2}\.\d{3})\s+(\d+)\s+(\d+)\s+([VDIWEF])\s+(.+?):\s+(.*)$',
  );

  static LogEntry? parseLine(String line, {int? currentYear, LogEntry? lastEntry}) {
    if (line.trim().isEmpty) return null;

    final match = _logPattern.firstMatch(line);
    if (match == null) {
      // This might be a continuation of a multiline message
      if (lastEntry != null) {
        return LogEntry(
          dateTime: lastEntry.dateTime,
          processId: lastEntry.processId,
          threadId: lastEntry.threadId,
          priority: lastEntry.priority,
          tag: lastEntry.tag,
          message: '${lastEntry.message}\n$line',
        );
      }
      return null;
    }

    try {
      // Parse date and time
      final dateStr = match.group(1)!; // MM-DD
      final timeStr = match.group(2)!; // HH:mm:ss.mmm
      final year = currentYear ?? DateTime.now().year;

      final dateParts = dateStr.split('-');
      final month = int.parse(dateParts[0]);
      final day = int.parse(dateParts[1]);

      final timeParts = timeStr.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final secondParts = timeParts[2].split('.');
      final second = int.parse(secondParts[0]);
      final millisecond = int.parse(secondParts[1]);

      final dateTime = DateTime(year, month, day, hour, minute, second, millisecond);

      // Parse process and thread IDs
      final processId = int.parse(match.group(3)!);
      final threadId = int.parse(match.group(4)!);

      // Parse priority
      final priorityLetter = match.group(5)!;
      final priority = Priority.fromLetter(priorityLetter);

      // Parse tag and message
      final tag = match.group(6)!.trim();
      final message = match.group(7)!;

      return LogEntry(
        dateTime: dateTime,
        processId: processId,
        threadId: threadId,
        priority: priority,
        tag: tag,
        message: message,
      );
    } catch (e) {
      // If parsing fails, return null
      return null;
    }
  }
}

