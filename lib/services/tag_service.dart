import '../models/log_rule.dart';
import '../models/log_tag.dart';
import '../models/priority.dart';

class TagService {
  final Map<String, Tag> _tags = {};

  Tag getTag(String tagName) {
    return _tags.putIfAbsent(tagName, () => Tag(tagName));
  }

  bool shouldRecord(String tagName, Priority priority, List<LogRule> rules) {
    final tag = getTag(tagName);

    for (final rule in rules) {
      if (priority >= rule.minPriority && tag.matchesPattern(rule.tagPattern)) {
        return true;
      }
    }

    return false;
  }
}
