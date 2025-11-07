import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/doctor_check.dart';
import '../services/doctor_service.dart';
import '../utils/constants.dart';
import 'splash_screen.dart';

class DoctorScreen extends StatefulWidget {
  const DoctorScreen({super.key});

  @override
  State<DoctorScreen> createState() => _DoctorScreenState();
}

class _DoctorScreenState extends State<DoctorScreen> {
  bool _isRestarting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final doctorService = context.read<DoctorService>();
      doctorService.startPolling();
      doctorService.addListener(_onDoctorServiceChanged);
    });
  }

  @override
  void dispose() {
    final doctorService = context.read<DoctorService>();
    doctorService.removeListener(_onDoctorServiceChanged);
    doctorService.stopPolling();
    super.dispose();
  }

  void _onDoctorServiceChanged() {
    if (_isRestarting) return; // Prevent multiple restarts

    final doctorService = context.read<DoctorService>();

    // Only restart if:
    // 1. All checks are present (5 checks expected)
    // 2. No checks are pending or checking
    // 3. All checks have passed

    if (!mounted) return;

    final checks = doctorService.checks;

    // Must have all 5 checks
    if (checks.length < 5) return;

    // No checks should be in pending or checking state
    final hasIncompleteChecks = checks.any(
      (check) => check.status == DoctorCheckStatus.pending || check.status == DoctorCheckStatus.checking,
    );

    if (hasIncompleteChecks) return;

    // Only proceed if all checks passed
    if (!doctorService.hasAllPassed) return;

    // Final verification: every check is in success state
    final allSuccess = checks.every((check) => check.status == DoctorCheckStatus.success);

    if (allSuccess) {
      _isRestarting = true;
      doctorService.removeListener(_onDoctorServiceChanged);
      doctorService.stopPolling();

      // Add small delay to show "Restarting..." message
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const SplashScreen()));
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('${AppConstants.appTitle} - Doctor')),
      body: Consumer<DoctorService>(
        builder: (context, service, _) {
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Text('Prerequisites Check', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 8),
                    Text(
                      'Verifying system requirements before connecting to devices',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 32),
                    ...service.checks.map((check) => _buildCheckCard(context, check)),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        service.hasAllPassed
                            ? 'All checks passed! Restarting...'
                            : 'Please resolve the issues above. Checks will re-run automatically.',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ),
                    if (service.hasErrors) const SizedBox(width: 16),
                    if (service.hasErrors)
                      TextButton.icon(
                        onPressed: () => service.runChecks(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Recheck'),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCheckCard(BuildContext context, DoctorCheck check) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _buildStatusIcon(context, check.status),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    check.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(check.resultMessage ?? check.description, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(BuildContext context, DoctorCheckStatus status) {
    switch (status) {
      case DoctorCheckStatus.pending:
        return const Icon(Icons.circle_outlined, size: 32, color: Colors.grey);
      case DoctorCheckStatus.checking:
        return const SizedBox(width: 32, height: 32, child: CircularProgressIndicator(strokeWidth: 2));
      case DoctorCheckStatus.success:
        return Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary, size: 32);
      case DoctorCheckStatus.warning:
        return const Icon(Icons.warning_amber, color: Colors.orange, size: 32);
      case DoctorCheckStatus.error:
        return Icon(Icons.error, color: Theme.of(context).colorScheme.error, size: 32);
    }
  }
}
