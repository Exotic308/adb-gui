import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/device.dart';
import '../models/named_query.dart';
import '../services/logs_service.dart';
import '../services/rules_service.dart';
import '../utils/constants.dart';

/// App bar for the logs screen showing device info, query filter, and clear button
class LogsAppBar extends StatelessWidget {
  final Device device;
  final bool isDeviceConnected;
  final LogsService service;

  const LogsAppBar({
    super.key,
    required this.device,
    required this.isDeviceConnected,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppConstants.appTitle, style: Theme.of(context).textTheme.titleLarge),
                Text(device.toString(), style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Consumer<RulesService>(
            builder: (context, rulesService, _) {
              // Validate selectedQueryId exists in queries list
              final selectedId = rulesService.selectedQueryId;
              final validSelectedId = selectedId != null &&
                      rulesService.queries.any((q) => q.id == selectedId)
                  ? selectedId
                  : null;
              
              // Ensure no duplicate IDs
              final uniqueQueries = <String, NamedQuery>{};
              for (final query in rulesService.queries) {
                if (!uniqueQueries.containsKey(query.id)) {
                  uniqueQueries[query.id] = query;
                }
              }
              
              // If selectedId was invalid, clear it
              if (selectedId != null && validSelectedId == null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  rulesService.setSelectedQuery(null);
                });
              }
              
              return DropdownButton<String?>(
                value: validSelectedId,
                hint: const Text('Filter: <all>'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('<all>'),
                  ),
                  ...uniqueQueries.values.map((query) => DropdownMenuItem<String?>(
                        value: query.id,
                        child: Text(query.name),
                      )),
                ],
                onChanged: (queryId) {
                  rulesService.setSelectedQuery(queryId);
                },
              );
            },
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: isDeviceConnected ? () => service.clearLogs() : null,
            tooltip: isDeviceConnected ? 'Clear Logs' : 'Device disconnected',
          ),
        ],
      ),
    );
  }
}

