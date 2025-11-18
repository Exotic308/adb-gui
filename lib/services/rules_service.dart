import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_querybuilder/flutter_querybuilder.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/import_result.dart';
import '../models/log_entry.dart';
import '../models/named_query.dart';
import 'query_evaluator_service.dart';

class RulesService extends ChangeNotifier {
  final SharedPreferences _prefs;
  final QueryEvaluatorService _evaluator;
  static const String _queriesKey = 'named_queries';
  static const String _selectedQueryKey = 'selected_query_id';
  
  List<NamedQuery> _queries = [];
  String? _selectedQueryId;

  List<NamedQuery> get queries => _queries;
  String? get selectedQueryId => _selectedQueryId;
  NamedQuery? get selectedQuery {
    if (_selectedQueryId == null) return null;
    try {
      return _queries.firstWhere((q) => q.id == _selectedQueryId);
    } catch (e) {
      return null;
    }
  }

  RulesService(this._prefs, this._evaluator);

  Future<void> loadQueries() async {
    final queriesJson = _prefs.getString(_queriesKey);
    if (queriesJson != null) {
      try {
        final List<dynamic> queriesList = json.decode(queriesJson);
        final loadedQueries = queriesList.map((json) => NamedQuery.fromJson(json as Map<String, dynamic>)).toList();
        
        // Remove duplicates by ID (keep first occurrence)
        final seenIds = <String>{};
        _queries = loadedQueries.where((query) {
          if (seenIds.contains(query.id)) {
            return false;
          }
          seenIds.add(query.id);
          return true;
        }).toList();
      } catch (e) {
        _queries = [];
      }
    }
  }

  Future<void> loadSelectedQuery() async {
    _selectedQueryId = _prefs.getString(_selectedQueryKey);
  }

  Future<void> _saveQueries() async {
    final queriesJson = json.encode(_queries.map((q) => q.toJson()).toList());
    await _prefs.setString(_queriesKey, queriesJson);
  }

  Future<void> _saveSelectedQuery() async {
    if (_selectedQueryId != null) {
      await _prefs.setString(_selectedQueryKey, _selectedQueryId!);
    } else {
      await _prefs.remove(_selectedQueryKey);
    }
  }

  Future<void> addQuery({required String name, required QueryGroup query}) async {
    final namedQuery = NamedQuery(
      id: generateId(),
      name: name,
      query: query,
    );
    _queries.insert(0, namedQuery);
    await _saveQueries();
    notifyListeners();
  }

  Future<void> updateQuery(String id, {String? name, QueryGroup? query}) async {
    final index = _queries.indexWhere((q) => q.id == id);
    if (index != -1) {
      final current = _queries[index];
      _queries[index] = current.copyWith(
        name: name ?? current.name,
        query: query ?? current.query,
      );
      await _saveQueries();
      notifyListeners();
    }
  }

  Future<void> deleteQuery(String id) async {
    _queries.removeWhere((q) => q.id == id);
    if (_selectedQueryId == id) {
      _selectedQueryId = null;
      await _saveSelectedQuery();
    }
    await _saveQueries();
    notifyListeners();
  }

  Future<void> setSelectedQuery(String? queryId) async {
    _selectedQueryId = queryId;
    await _saveSelectedQuery();
    notifyListeners();
  }

  /// Evaluates if a log entry matches the selected query
  bool evaluateQuery(LogEntry entry, String? queryId) {
    if (queryId == null) {
      return true; // No filter = show all
    }
    
    final query = _queries.firstWhere(
      (q) => q.id == queryId,
      orElse: () => _queries.isNotEmpty ? _queries.first : NamedQuery(
        id: '',
        name: '',
        query: QueryGroup(combinator: Combinator.and, rules: [], groups: []),
      ),
    );
    
    return _evaluator.evaluate(query.query, entry);
  }

  /// Exports all queries as JSON string
  String exportQueries() {
    final exportData = {
      'queries': _queries.map((q) => q.toJson()).toList(),
      'version': '1.0',
    };
    return const JsonEncoder.withIndent('  ').convert(exportData);
  }

  /// Imports queries from JSON string with conflict resolution
  Future<ImportResult> importQueries(String jsonString) async {
    final Map<String, dynamic> data;
    try {
      data = json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      throw FormatException('Invalid JSON format');
    }

    final List<dynamic> queriesList = data['queries'] as List<dynamic>? ?? [];
    final List<NamedQuery> importedQueries = queriesList
        .map((q) => NamedQuery.fromJson(q as Map<String, dynamic>))
        .toList();

    final List<NamedQuery> added = [];
    final List<String> skipped = [];
    final Map<String, String> renamed = {};

    for (final imported in importedQueries) {
      final existingIndex = _queries.indexWhere((q) => q.name == imported.name);
      
      if (existingIndex == -1) {
        // No conflict - add as is
        added.add(imported);
        _queries.add(imported);
      } else {
        final existing = _queries[existingIndex];
        // Check if queries are identical (same query structure)
        if (_queriesEqual(existing, imported)) {
          // Same query - skip
          skipped.add(imported.name);
        } else {
          // Different query with same name - rename imported
          final newName = _generateUniqueName(imported.name);
          renamed[imported.name] = newName;
          final renamedQuery = imported.copyWith(name: newName);
          added.add(renamedQuery);
          _queries.add(renamedQuery);
        }
      }
    }

    if (added.isNotEmpty || renamed.isNotEmpty) {
      await _saveQueries();
      notifyListeners();
    }

    return ImportResult(
      added: added,
      skipped: skipped,
      renamed: renamed,
    );
  }

  /// Reverts the last import operation
  Future<void> revertImport(List<NamedQuery> originalQueries) async {
    _queries = originalQueries;
    await _saveQueries();
    notifyListeners();
  }

  bool _queriesEqual(NamedQuery a, NamedQuery b) {
    // Compare query JSON representations
    final aJson = QuerySerializer.toJson(a.query);
    final bJson = QuerySerializer.toJson(b.query);
    return const JsonEncoder().convert(aJson) == const JsonEncoder().convert(bJson);
  }

  String _generateUniqueName(String baseName) {
    // Check if base name is available
    if (!_queries.any((q) => q.name == baseName)) {
      return baseName;
    }
    
    // Otherwise, find next available number
    int counter = 1;
    String candidate = '$baseName ($counter)';
    
    while (_queries.any((q) => q.name == candidate)) {
      counter++;
      candidate = '$baseName ($counter)';
    }
    
    return candidate;
  }

  String generateUniqueQueryName() {
    return _generateUniqueName('New query');
  }

  String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}

