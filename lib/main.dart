import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import 'screens/splash_screen.dart';
import 'services/doctor_service.dart';
import 'services/logs_service.dart';
import 'services/service_locator.dart';
import 'services/settings_service.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await setupServices();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();

    windowManager.waitUntilReadyToShow(
      const WindowOptions(
        size: Size(1400, 900),
        minimumSize: Size(800, 600),
        center: true,
        backgroundColor: Colors.transparent,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.normal,
        title: AppConstants.appTitle,
      ),
      () async {
        await windowManager.show();
        await windowManager.focus();
      },
    );
  }

  runApp(const AndroidLogcatApp());
}

class AndroidLogcatApp extends StatelessWidget {
  const AndroidLogcatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: Services.settingsService),
        ChangeNotifierProvider(create: (_) => DoctorService(Services.adbService)),
        ChangeNotifierProvider(create: (_) => LogsService(Services.logcatService, Services.settingsService)),
        ChangeNotifierProvider.value(value: Services.rulesService),
      ],
      child: Consumer<SettingsService>(
        builder: (context, settingsService, _) {
          return MaterialApp(
            title: AppConstants.appTitle,
            debugShowCheckedModeBanner: false,
            themeMode: settingsService.themeMode,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.light),
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
              useMaterial3: true,
            ),
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
