import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../core/diagnostics/diagnostic_logging.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
import '../../../../shared/widgets/flinx_switch.dart';

class HardwareDiagnosticsPage extends ConsumerWidget {
  const HardwareDiagnosticsPage({super.key});

  static const routeName = 'hardware-diagnostics';
  static const routePath = '/account/hardware-diagnostics';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final setting = ref.watch(diagnosticLoggingControllerProvider);
    final enabled = setting.value ?? false;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: FlinxNavigationBar(title: l10n.hardwareDiagnosticsTitle),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.hardwareDiagnosticsDetailedLogging,
                    style: textTheme.titleMedium,
                  ),
                ),
                FlinxSwitch(
                  value: enabled,
                  enabled: !setting.isLoading,
                  onChanged: (value) => ref
                      .read(diagnosticLoggingControllerProvider.notifier)
                      .setEnabled(value),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(l10n.hardwareDiagnosticsWarning, style: textTheme.bodyMedium),
            if (setting.hasError) ...[
              const SizedBox(height: 16),
              Text(
                l10n.hardwareDiagnosticsUpdateFailed,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.deviceSettingsForceMarginWarningText,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
