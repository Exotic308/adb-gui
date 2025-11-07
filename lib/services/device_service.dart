import 'dart:async';

import '../models/device.dart';
import 'adb_service.dart';

class DeviceService {
  final AdbService _adbService;

  DeviceService(this._adbService);

  Future<List<Device>> getConnectedDevices() async {
    final deviceList = await _adbService.getDevices();
    final devices = <Device>[];

    for (final deviceInfo in deviceList) {
      final deviceId = deviceInfo['id']!;

      try {
        final props = await _adbService.getDeviceProperties(deviceId);
        final manufacturer = props['ro.product.manufacturer'] ?? '';
        final model = props['ro.product.model'] ?? '';
        final name = '$manufacturer $model'.trim();
        devices.add(Device(id: deviceId, name: name.isNotEmpty ? name : deviceId));
      } catch (e) {
        // If properties fail, use device ID as name
        devices.add(Device(id: deviceId, name: deviceId));
      }
    }

    return devices;
  }
}
