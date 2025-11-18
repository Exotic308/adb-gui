import 'package:flutter/material.dart';

import '../models/import_result.dart';

class ImportResultDialog extends StatelessWidget {
  final ImportResult result;
  final VoidCallback onRevert;

  const ImportResultDialog({
    super.key,
    required this.result,
    required this.onRevert,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Import Results'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (result.added.isNotEmpty) ...[
              _buildSection(
                context,
                'Added',
                result.added.length,
                result.added.map((q) => q.name).toList(),
                Colors.green,
              ),
              const SizedBox(height: 16),
            ],
            if (result.skipped.isNotEmpty) ...[
              _buildSection(
                context,
                'Skipped (duplicates)',
                result.skipped.length,
                result.skipped,
                Colors.orange,
              ),
              const SizedBox(height: 16),
            ],
            if (result.renamed.isNotEmpty) ...[
              _buildSection(
                context,
                'Renamed (conflicts)',
                result.renamed.length,
                result.renamed.entries.map((e) => '${e.key} → ${e.value}').toList(),
                Colors.blue,
              ),
            ],
            if (result.added.isEmpty && result.skipped.isEmpty && result.renamed.isEmpty)
              const Text('No queries were imported.'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: onRevert,
          child: const Text('Revert Changes'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    int count,
    List<String> items,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$title: $count',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        if (items.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...items.take(10).map((item) => Padding(
                padding: const EdgeInsets.only(left: 20, top: 4),
                child: Text(
                  '• $item',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              )),
          if (items.length > 10)
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 4),
              child: Text(
                '... and ${items.length - 10} more',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ),
        ],
      ],
    );
  }
}

