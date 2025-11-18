import 'package:shared_preferences/shared_preferences.dart';

import 'adb_service.dart';
import 'device_service.dart';
import 'logcat_service.dart';
import 'package_service.dart';
import 'query_evaluator_service.dart';
import 'rules_service.dart';
import 'settings_service.dart';

class Services {
  static late SharedPreferences sharedPreferences;
  static late AdbService adbService;
  static late DeviceService deviceService;
  static late PackageService packageService;
  static late QueryEvaluatorService queryEvaluatorService;
  static late RulesService rulesService;
  static late LogcatService logcatService;
  static late SettingsService settingsService;
}

Future<void> setupServices() async {
  Services.sharedPreferences = await SharedPreferences.getInstance();

  Services.adbService = AdbService();
  await Services.adbService.initialize();

  Services.deviceService = DeviceService(Services.adbService);

  // Initialize PackageService for PID → package name mapping
  Services.packageService = PackageService(Services.adbService);

  // Initialize QueryEvaluatorService before RulesService
  Services.queryEvaluatorService = QueryEvaluatorService();
  Services.rulesService = RulesService(Services.sharedPreferences, Services.queryEvaluatorService);
  await Services.rulesService.loadQueries();
  await Services.rulesService.loadSelectedQuery();

  Services.logcatService = LogcatService(
    Services.adbService,
    Services.packageService,
  );

  Services.settingsService = SettingsService(Services.sharedPreferences);
  await Services.settingsService.loadSettings();
}
