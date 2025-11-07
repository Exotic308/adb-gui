import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/device.dart';
import '../services/doctor_service.dart';
import '../services/service_locator.dart';
import '../utils/constants.dart';
import '../widgets/app_brand_name.dart';
import '../widgets/app_tagline.dart';
import '../widgets/checklist_item.dart';
import '../widgets/device_selection_dialog.dart';
import '../widgets/github_link.dart';
import '../widgets/splash_logo.dart';
import 'doctor_screen.dart';
import 'main_shell.dart';

enum ChecklistStep { init, runningTests, waitingForConnection }

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  ChecklistStep _currentStep = ChecklistStep.init;
  final Set<ChecklistStep> _completedSteps = {};
  Timer? _devicePollTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeIn));

    _animationController.forward();
    _initialize();
  }

  @override
  void dispose() {
    _devicePollTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    await Future.delayed(const Duration(milliseconds: 1000));

    if (!mounted) return;

    // Step 1: Init
    setState(() {
      _currentStep = ChecklistStep.init;
    });
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    setState(() {
      _completedSteps.add(ChecklistStep.init);
    });

    await Future.delayed(const Duration(milliseconds: 200));

    if (!mounted) return;

    // Step 2: Running tests
    setState(() {
      _currentStep = ChecklistStep.runningTests;
    });

    // Run doctor checks
    final doctorService = context.read<DoctorService>();
    await doctorService.runChecks();

    if (!mounted) return;

    if (doctorService.hasAllPassed) {
      // Mark tests as completed
      setState(() {
        _completedSteps.add(ChecklistStep.runningTests);
      });

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        setState(() {
          _currentStep = ChecklistStep.waitingForConnection;
        });
        _startDevicePolling();
      }
    } else {
      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const DoctorScreen()));
      }
    }
  }

  void _startDevicePolling() {
    // Start periodic checking
    _devicePollTimer = Timer.periodic(AppConstants.devicePollInterval, (_) => _checkForDevices());
    // Check immediately
    _checkForDevices();
  }

  Future<void> _checkForDevices() async {
    if (!mounted) return;

    try {
      final devices = await Services.deviceService.getConnectedDevices();

      if (devices.isEmpty || !mounted) return;

      _devicePollTimer?.cancel();

      if (devices.length == 1) {
        // Single device - connect automatically
        _navigateToDevice(devices.first);
      } else {
        // Multiple devices - show selection dialog
        _showDeviceSelectionDialog(devices);
      }
    } catch (e) {
      // Ignore errors and keep polling
    }
  }

  void _navigateToDevice(Device device) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => MainShell(device: device)));
  }

  Future<void> _showDeviceSelectionDialog(List<Device> devices) async {
    if (!mounted) return;

    final selected = await showDialog<Device>(
      context: context,
      barrierDismissible: false,
      builder: (context) => DeviceSelectionDialog(devices: devices),
    );

    if (selected != null && mounted) {
      _navigateToDevice(selected);
    } else {
      // User cancelled - restart polling
      _startDevicePolling();
    }
  }

  String _getStepTitle(ChecklistStep step) {
    switch (step) {
      case ChecklistStep.init:
        return 'Initializing';
      case ChecklistStep.runningTests:
        return 'Running tests';
      case ChecklistStep.waitingForConnection:
        return 'Waiting for Connection';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Header
            const Expanded(
              flex: 3,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SplashLogo(),
                    const SizedBox(height: 24),
                    const AppBrandName(),
                    const SizedBox(height: 8),
                    const AppTagline(text: 'Complete ADB Management Solution'),
                  ],
                ),
              ),
            ),
            // Body - Checklist
            Expanded(
              flex: 2,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: ChecklistStep.values.map((step) {
                    final isCompleted = _completedSteps.contains(step);
                    final isCurrent = _currentStep == step;
                    return ChecklistItem(title: _getStepTitle(step), isCompleted: isCompleted, isCurrent: isCurrent);
                  }).toList(),
                ),
              ),
            ),
            // Footer
            const Padding(
              padding: EdgeInsets.all(24),
              child: GitHubLink(url: 'https://github.com/Exotic308/adb-gui'),
            ),
          ],
        ),
      ),
    );
  }
}
