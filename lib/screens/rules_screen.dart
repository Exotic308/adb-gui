import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_querybuilder/flutter_querybuilder.dart';
import 'package:provider/provider.dart';

import '../models/named_query.dart';
import '../services/query_fields.dart';
import '../services/rules_service.dart';
import '../widgets/import_result_dialog.dart';

class RulesScreen extends StatefulWidget {
  const RulesScreen({super.key});

  @override
  State<RulesScreen> createState() => _RulesScreenState();
}

class _RulesScreenState extends State<RulesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Query Rules')),
      body: Consumer<RulesService>(
        builder: (context, service, _) {
          return Column(
            children: [
              _buildActions(context, service),
              Expanded(
                child: service.queries.isEmpty
                    ? const Center(child: Text('No queries defined. Create one to get started.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: service.queries.length,
                        itemBuilder: (context, index) {
                          final query = service.queries[index];
                          return _buildQueryCard(context, service, query);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActions(BuildContext context, RulesService service) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          ElevatedButton.icon(
            onPressed: () {
              final uniqueName = service.generateUniqueQueryName();
              service.addQuery(
                name: uniqueName,
                query: QueryGroup(combinator: Combinator.and, rules: [], groups: []),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('New Query'),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () => _exportQueries(context, service),
            icon: const Icon(Icons.upload_file),
            label: const Text('Export'),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () => _importQueries(context, service),
            icon: const Icon(Icons.download),
            label: const Text('Import'),
          ),
        ],
      ),
    );
  }

  Widget _buildQueryCard(BuildContext context, RulesService service, NamedQuery query) {
    final isEditing = _editingQueryId == query.id;
    final queryBuilderKey = GlobalKey<_QueryBuilderWidgetState>();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: isEditing
            ? TextField(
                controller: _nameController,
                decoration: const InputDecoration(hintText: 'Query name', border: OutlineInputBorder(), isDense: true),
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    service.updateQuery(query.id, name: value.trim());
                    setState(() => _editingQueryId = null);
                  }
                },
              )
            : Text(query.name, style: Theme.of(context).textTheme.titleMedium),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(isEditing ? Icons.check : Icons.edit),
              onPressed: () {
                if (isEditing) {
                  final name = _nameController.text.trim();
                  if (name.isNotEmpty) {
                    service.updateQuery(query.id, name: name);
                  }
                  setState(() => _editingQueryId = null);
                } else {
                  _nameController.text = query.name;
                  setState(() => _editingQueryId = query.id);
                }
              },
              tooltip: isEditing ? 'Save' : 'Edit Name',
            ),
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () => _exportSingleQuery(context, query, queryBuilderKey),
              tooltip: 'Export Query',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteQuery(context, service, query),
              tooltip: 'Delete Query',
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: _QueryBuilderWidget(
              key: queryBuilderKey,
              query: query,
              onQueryChanged: (newQuery) {
                service.updateQuery(query.id, query: newQuery);
              },
            ),
          ),
        ],
      ),
    );
  }

  String? _editingQueryId;
  final TextEditingController _nameController = TextEditingController();

  Future<void> _exportQueries(BuildContext context, RulesService service) async {
    try {
      final jsonString = service.exportQueries();
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Queries',
        fileName: 'queries.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        final file = File(result);
        await file.writeAsString(jsonString);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Queries exported successfully')));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  Future<void> _exportSingleQuery(
    BuildContext context,
    NamedQuery query,
    GlobalKey<_QueryBuilderWidgetState>? queryBuilderKey,
  ) async {
    try {
      final exportData = {
        'queries': [query.toJson()],
        'version': '1.0',
      };
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Query',
        fileName: '${query.name.replaceAll(RegExp(r'[^\w\s-]'), '_')}.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        final file = File(result);
        await file.writeAsString(jsonString);
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Query "${query.name}" exported successfully')));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  Future<void> _importQueries(BuildContext context, RulesService service) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final jsonString = await file.readAsString();

        // Store original state for revert
        final originalQueries = List<NamedQuery>.from(service.queries);

        final importResult = await service.importQueries(jsonString);

        if (context.mounted) {
          showDialog(
            context: context,
            builder: (dialogContext) => ImportResultDialog(
              result: importResult,
              onRevert: () {
                service.revertImport(originalQueries);
                Navigator.of(dialogContext).pop();
              },
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import failed: $e')));
      }
    }
  }

  Future<void> _deleteQuery(BuildContext context, RulesService service, NamedQuery query) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Query'),
        content: Text('Are you sure you want to delete "${query.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      service.deleteQuery(query.id);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}

class _QueryBuilderWidget extends StatefulWidget {
  final NamedQuery query;
  final ValueChanged<QueryGroup> onQueryChanged;

  const _QueryBuilderWidget({super.key, required this.query, required this.onQueryChanged});

  @override
  State<_QueryBuilderWidget> createState() => _QueryBuilderWidgetState();
}

class _QueryBuilderWidgetState extends State<_QueryBuilderWidget> {
  late QueryBuilderController _controller;

  @override
  void initState() {
    super.initState();
    _controller = QueryBuilderController(fields: getLogEntryFields(), initialQuery: widget.query.query);
    _controller.addListener(_onQueryChanged);
  }

  @override
  void didUpdateWidget(_QueryBuilderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query.id != widget.query.id) {
      _controller.updateQuery(widget.query.query);
    }
  }

  void _onQueryChanged() {
    widget.onQueryChanged(_controller.query);
  }

  @override
  void dispose() {
    _controller.removeListener(_onQueryChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return QueryBuilder(controller: _controller);
  }
}
