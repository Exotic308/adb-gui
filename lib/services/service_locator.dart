import 'package:shared_preferences/shared_preferences.dart';

import 'adb_service.dart';
import 'device_service.dart';
import 'logcat_service.dart';
import 'rules_service.dart';
import 'settings_service.dart';
import 'tag_service.dart';

class Services {
  static late SharedPreferences sharedPreferences;
  static late AdbService adbService;
  static late DeviceService deviceService;
  static late TagService tagService;
  static late RulesService rulesService;
  static late LogcatService logcatService;
  static late SettingsService settingsService;
}

Future<void> setupServices() async {
  Services.sharedPreferences = await SharedPreferences.getInstance();

  Services.adbService = AdbService();
  await Services.adbService.initialize();

  Services.deviceService = DeviceService(Services.adbService);

  // Initialize TagService before RulesService
  Services.tagService = TagService();
  Services.rulesService = RulesService(Services.sharedPreferences, Services.tagService);
  await Services.rulesService.loadRules();

  Services.logcatService = LogcatService(Services.adbService, Services.rulesService);

  Services.settingsService = SettingsService(Services.sharedPreferences);
  await Services.settingsService.loadSettings();
}
