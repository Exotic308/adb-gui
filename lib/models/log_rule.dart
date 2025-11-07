import 'priority.dart';

class LogRule {
  final String id;
  final String tagPattern;
  final Priority minPriority;

  LogRule({required this.id, required this.tagPattern, required this.minPriority});

  Map<String, dynamic> toJson() {
    return {'id': id, 'tagPattern': tagPattern, 'minPriority': minPriority.name};
  }

  factory LogRule.fromJson(Map<String, dynamic> json) {
    return LogRule(
      id: json['id'] as String,
      tagPattern: json['tagPattern'] as String,
      minPriority: Priority.values.firstWhere((p) => p.name == json['minPriority'], orElse: () => Priority.warn),
    );
  }
}
