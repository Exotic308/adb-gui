import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/device.dart';
import '../models/log_entry.dart';
import '../models/named_query.dart';
import '../services/logs_service.dart';
import '../services/rules_service.dart';
import '../services/service_locator.dart';
import '../utils/constants.dart';
import '../widgets/error_display.dart';
import '../widgets/loading_indicator.dart';
import 'rules_screen.dart';

class LogsScreen extends StatefulWidget {
  final Device device;
  final bool isDeviceConnected;

  const LogsScreen({super.key, required this.device, required this.isDeviceConnected});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();

  LogEntry? _selectedLogEntry;
  bool _autoScroll = true;
  double _splitRatio = 0.7;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<LogsService>().startStreaming(widget.device.id);
      }
    });
    _scrollController.addListener(_handleScrollChange);
  }

  @override
  void deactivate() {
    _searchFocusNode.unfocus();
    super.deactivate();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _handleScrollChange() {
    if (_scrollController.hasClients) {
      final isAtBottom = _scrollController.offset >= _scrollController.position.maxScrollExtent - 50;
      if (_autoScroll != isAtBottom) {
        setState(() {
          _autoScroll = isAtBottom;
        });
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  List<LogEntry> _filterLogs(List<LogEntry> entries) {
    final searchQuery = _searchController.text.toLowerCase();
    if (searchQuery.isEmpty) return entries;

    return entries.where((entry) {
      return entry.tag.toLowerCase().contains(searchQuery) || entry.message.toLowerCase().contains(searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<LogsService>(
      builder: (context, service, _) {
        return _buildContent(context, service, isDark);
      },
    );
  }

  Widget _buildContent(BuildContext context, LogsService service, bool isDark) {
    if (service.isLoading) {
      return const LoadingIndicator(message: 'Connecting to logcat...');
    }

    if (service.error != null) {
      return ErrorDisplay(error: service.error!, onRetry: () => service.startStreaming(widget.device.id));
    }

    final filteredEntries = _filterLogs(service.getFilteredEntries());

    if (service.isStreaming && _autoScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }

    return Column(
      children: [
        _buildToolbar(context, filteredEntries.length, service.totalCount),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                children: [
                  Expanded(flex: (_splitRatio * 100).toInt(), child: _buildLogList(context, filteredEntries, isDark)),
                  if (_selectedLogEntry != null)
                    GestureDetector(
                      onVerticalDragUpdate: (details) {
                        setState(() {
                          _splitRatio += details.primaryDelta! / constraints.maxHeight;
                          _splitRatio = _splitRatio.clamp(0.2, 0.8);
                        });
                      },
                      child: Container(
                        height: 8,
                        color: Theme.of(context).dividerColor,
                        alignment: Alignment.center,
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  if (_selectedLogEntry != null)
                    Expanded(
                      flex: ((1 - _splitRatio) * 100).toInt(),
                      child: _buildLogDetailsPanel(context, _selectedLogEntry!, isDark),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar(BuildContext context, int displayedCount, int totalCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RulesScreen()));
            },
            tooltip: 'Filtering Rules',
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Search logs...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 8),
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
                hint: const Text('<all>'),
                isDense: true,
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
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: widget.isDeviceConnected ? () => context.read<LogsService>().clearLogs() : null,
            tooltip: widget.isDeviceConnected ? 'Clear Logs' : 'Device disconnected',
          ),
          const SizedBox(width: 16),
          Text('$displayedCount / $totalCount'),
          if (!_autoScroll) ...[
            const SizedBox(width: 8),
            IconButton(icon: const Icon(Icons.arrow_downward), onPressed: _scrollToBottom, tooltip: 'Scroll to Bottom'),
          ],
        ],
      ),
    );
  }

  Widget _buildLogList(BuildContext context, List<LogEntry> entries, bool isDark) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final isSelected = _selectedLogEntry == entry;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedLogEntry = isSelected ? null : entry;
            });
          },
          child: Container(
            color: isSelected ? Theme.of(context).colorScheme.primaryContainer : Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 100, child: Text(entry.timeString, style: Theme.of(context).textTheme.bodySmall)),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final packageName = Services.packageService.getPackageName(entry.pid);
                      final displayText = packageName.isNotEmpty
                          ? '$packageName/${entry.tag}: ${entry.message}'
                          : '${entry.tag}: ${entry.message}';
                      return Text(
                        displayText,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: AppConstants.getPriorityColor(entry.priority, isDark)),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogDetailsPanel(BuildContext context, LogEntry entry, bool isDark) {
    final packageName = Services.packageService.getPackageName(entry.pid);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Log Details', style: Theme.of(context).textTheme.titleMedium),
          const Divider(),
          _buildDetailRow(context, 'Time', entry.timeString),
          _buildDetailRow(
            context,
            'Priority',
            entry.priority.name.toUpperCase(),
            valueColor: AppConstants.getPriorityColor(entry.priority, isDark),
          ),
          _buildDetailRow(context, 'PID', entry.pid.toString()),
          _buildDetailRow(context, 'TID', entry.tid.toString()),
          _buildDetailRow(context, 'Package', packageName),
          _buildDetailRow(context, 'Tag', entry.tag),
          const SizedBox(height: 8),
          Expanded(child: SingleChildScrollView(child: Text(entry.message))),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text('$label:', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: valueColor)),
          ),
        ],
      ),
    );
  }
}
