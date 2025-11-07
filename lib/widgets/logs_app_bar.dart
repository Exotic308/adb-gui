import 'package:flutter/material.dart';
import '../models/device.dart';
import '../services/logs_service.dart';
import '../utils/constants.dart';

/// App bar for the logs screen showing device info and clear button
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

