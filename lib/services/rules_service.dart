import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/log_rule.dart';
import '../models/priority.dart';
import 'tag_service.dart';

class RulesService extends ChangeNotifier {
  final SharedPreferences _prefs;
  final TagService _tagService;
  static const String _rulesKey = 'log_rules';
  List<LogRule> _rules = [];

  List<LogRule> get rules => _rules;

  RulesService(this._prefs, this._tagService) {
    _initializeDefaultRule();
  }

  void _initializeDefaultRule() {
    _rules = [LogRule(id: 'default', tagPattern: '*', minPriority: Priority.warn)];
  }

  Future<void> loadRules() async {
    final rulesJson = _prefs.getString(_rulesKey);

    if (rulesJson != null) {
      try {
        final List<dynamic> rulesList = json.decode(rulesJson);
        _rules = rulesList.map((json) => LogRule.fromJson(json)).toList();
      } catch (e) {
        // If loading fails, use default
        _initializeDefaultRule();
      }
    } else {
      _initializeDefaultRule();
    }
  }

  Future<void> saveRules() async {
    final rulesJson = json.encode(_rules.map((r) => r.toJson()).toList());
    await _prefs.setString(_rulesKey, rulesJson);
  }

  Future<void> addRule({required String tagPattern, required Priority minPriority}) async {
    final rule = LogRule(id: generateId(), tagPattern: tagPattern, minPriority: minPriority);
    _rules.insert(0, rule); // Add to top
    await saveRules();
    notifyListeners();
  }

  Future<void> updateRule(String id, {String? tagPattern, Priority? minPriority}) async {
    final index = _rules.indexWhere((r) => r.id == id);
    if (index != -1) {
      final currentRule = _rules[index];
      _rules[index] = LogRule(
        id: id,
        tagPattern: tagPattern ?? currentRule.tagPattern,
        minPriority: minPriority ?? currentRule.minPriority,
      );
      await saveRules();
      notifyListeners();
    }
  }

  Future<void> deleteRule(String id) async {
    _rules.removeWhere((r) => r.id == id);
    // Always keep at least one rule - if all removed, add default back
    if (_rules.isEmpty) {
      _initializeDefaultRule();
    }
    await saveRules();
    notifyListeners();
  }

  bool shouldRecord(String tag, Priority priority) {
    return _tagService.shouldRecord(tag, priority, _rules);
  }

  String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
