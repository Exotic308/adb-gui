import 'package:flutter/material.dart';
import '../models/device.dart';

/// Dialog for selecting a device when multiple devices are connected
class DeviceSelectionDialog extends StatelessWidget {
  final List<Device> devices;

  const DeviceSelectionDialog({super.key, required this.devices});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Device'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: devices.length,
          itemBuilder: (context, index) {
            final device = devices[index];
            return ListTile(
              leading: const Icon(Icons.phone_android),
              title: Text(device.name),
              subtitle: Text(device.id),
              onTap: () => Navigator.of(context).pop(device),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

