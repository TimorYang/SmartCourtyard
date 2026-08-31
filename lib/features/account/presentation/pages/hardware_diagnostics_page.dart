import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../core/diagnostics/diagnostic_logging.dart';
import '../../../../core/network/network_proxy_controller.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
import '../../../../shared/widgets/flinx_switch.dart';
import '../../../hardware_debug/presentation/pages/http_proxy_settings_page.dart';

class HardwareDiagnosticsPage extends ConsumerWidget {
  const HardwareDiagnosticsPage({super.key});

  static const routeName = 'hardware-diagnostics';
  static const routePath = '/account/hardware-diagnostics';

  static const httpProxyRowKey = ValueKey<String>(
    'hardware-diagnostics-http-proxy-row',
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final setting = ref.watch(diagnosticLoggingControllerProvider);
    final values = setting.value ?? const DiagnosticLoggingSettings.defaults();
    final proxySettings = ref.watch(networkProxySettingsProvider);
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
            const SizedBox(height: AppSpacingTokens.httpProxySettingsRowGap),
            _HttpProxyDiagnosticsRow(
              enabled: proxySettings.isActive,
              onTap: () => context.pushNamed(HttpProxySettingsPage.routeName),
            ),
          ],
        ),
      ),
    );
  }
}

class _HttpProxyDiagnosticsRow extends StatelessWidget {
  const _HttpProxyDiagnosticsRow({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: l10n.hardwareDiagnosticsHttpProxy,
      child: InkWell(
        key: HardwareDiagnosticsPage.httpProxyRowKey,
        borderRadius: BorderRadius.circular(
          AppShapeTokens.httpProxySettingsRowRadius,
        ),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacingTokens.httpProxySettingsRowHorizontal,
            vertical: AppSpacingTokens.httpProxySettingsRowVertical,
          ),
          decoration: BoxDecoration(
            color: AppColors.httpProxySettingsRowSurface,
            borderRadius: BorderRadius.circular(
              AppShapeTokens.httpProxySettingsRowRadius,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.hardwareDiagnosticsHttpProxy,
                      style: AppTextTokens.httpProxySettingsRowTitle(textTheme),
                    ),
                    const SizedBox(
                      height: AppSpacingTokens.httpProxySettingsRowTextGap,
                    ),
                    Text(
                      enabled
                          ? l10n.httpProxySettingsStatusEnabled
                          : l10n.httpProxySettingsStatusDisabled,
                      style: AppTextTokens.httpProxySettingsRowStatus(
                        textTheme,
                        enabled: enabled,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.iconAccountChevron,
                size: AppLayoutTokens.httpProxySettingsChevronSize,
              ),
            ],
          ),
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
