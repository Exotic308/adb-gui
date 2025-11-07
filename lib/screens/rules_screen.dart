import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/log_rule.dart';
import '../models/priority.dart';
import '../services/rules_service.dart';

class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log Filtering Rules')),
      body: Consumer<RulesService>(
        builder: (context, service, _) {
          return Column(
            children: [
              _buildHeader(context),
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => service.addRule(tagPattern: '*', minPriority: Priority.warn),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Rule'),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: service.rules.isEmpty
                    ? const Center(child: Text('No rules defined'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: service.rules.length,
                        itemBuilder: (context, index) {
                          final rule = service.rules[index];
                          return _buildRuleCard(context, service, rule);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Log Filtering Rules', style: Theme.of(context).textTheme.titleLarge)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.filter_alt, size: 16, color: Theme.of(context).colorScheme.onPrimaryContainer),
                    const SizedBox(width: 6),
                    Text(
                      'Active',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Logs are filtered in real-time based on tag and priority level',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            'Use * as wildcard to match any tag',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleCard(BuildContext context, RulesService service, LogRule rule) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tag Pattern', style: Theme.of(context).textTheme.labelSmall),
                  const SizedBox(height: 4),
                  TextField(
                    controller: TextEditingController(text: rule.tagPattern),
                    decoration: const InputDecoration(
                      hintText: 'e.g., com.example.* or *',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onSubmitted: (value) {
                      service.updateRule(rule.id, tagPattern: value);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Minimum Priority', style: Theme.of(context).textTheme.labelSmall),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<Priority>(
                    initialValue: rule.minPriority,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: Priority.values.map((priority) {
                      return DropdownMenuItem(value: priority, child: Text(priority.name.toUpperCase()));
                    }).toList(),
                    onChanged: (priority) {
                      if (priority != null) {
                        service.updateRule(rule.id, minPriority: priority);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => service.deleteRule(rule.id),
              tooltip: 'Delete Rule',
            ),
          ],
        ),
      ),
    );
  }
}
