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
    final values = setting.value ?? const DiagnosticLoggingSettings.defaults();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: FlinxNavigationBar(title: l10n.hardwareDiagnosticsTitle),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          children: [
            _LoggingSwitchRow(
              label: l10n.hardwareDiagnosticsFlutterLogging,
              value: values.flutterConsoleEnabled,
              enabled: !setting.isLoading,
              onChanged: (value) => ref
                  .read(diagnosticLoggingControllerProvider.notifier)
                  .setFlutterConsoleEnabled(value),
            ),
            const SizedBox(height: 16),
            _LoggingSwitchRow(
              label: l10n.hardwareDiagnosticsNativeLogging,
              value: values.nativeConsoleEnabled,
              enabled: !setting.isLoading,
              onChanged: (value) => ref
                  .read(diagnosticLoggingControllerProvider.notifier)
                  .setNativeConsoleEnabled(value),
            ),
            const SizedBox(height: 20),
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

class _LoggingSwitchRow extends StatelessWidget {
  const _LoggingSwitchRow({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.titleMedium),
        ),
        FlinxSwitch(value: value, enabled: enabled, onChanged: onChanged),
      ],
    );
  }
}
