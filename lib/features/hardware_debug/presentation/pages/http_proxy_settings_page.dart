import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../core/network/network_proxy_controller.dart';
import '../../../../core/network/network_proxy_settings.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
import '../../../../shared/widgets/flinx_switch.dart';

class HttpProxySettingsPage extends ConsumerStatefulWidget {
  const HttpProxySettingsPage({super.key});

  static const routeName = 'http-proxy-settings';
  static const routePath = '/account/hardware-diagnostics/http-proxy';

  @override
  ConsumerState<HttpProxySettingsPage> createState() =>
      _HttpProxySettingsPageState();
}

class HttpProxySettingsPageKeys {
  const HttpProxySettingsPageKeys._();

  static const enabledSwitch = ValueKey<String>(
    'http-proxy-settings-enabled-switch',
  );
  static const hostField = ValueKey<String>('http-proxy-settings-host-field');
  static const portField = ValueKey<String>('http-proxy-settings-port-field');
  static const saveButton = ValueKey<String>('http-proxy-settings-save-button');
}

class _HttpProxySettingsPageState extends ConsumerState<HttpProxySettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _hostController;
  late final TextEditingController _portController;

  bool _enabled = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(networkProxySettingsProvider);
    _enabled = settings.enabled;
    _hostController = TextEditingController(text: settings.host);
    _portController = TextEditingController(
      text: settings.port?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: FlinxNavigationBar(title: l10n.httpProxySettingsTitle),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppLayoutTokens.httpProxySettingsContentMaxWidth,
            ),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacingTokens.httpProxySettingsPageHorizontal,
                  vertical: AppSpacingTokens.httpProxySettingsPageVertical,
                ),
                children: [
                  Text(
                    l10n.httpProxySettingsDescription,
                    style: AppTextTokens.httpProxySettingsDescription(
                      textTheme,
                    ),
                  ),
                  const SizedBox(
                    height: AppSpacingTokens.httpProxySettingsDescriptionGap,
                  ),
                  _ProxySwitchRow(
                    enabled: _enabled,
                    isSaving: _isSaving,
                    onChanged: (value) => setState(() => _enabled = value),
                  ),
                  const SizedBox(
                    height: AppSpacingTokens.httpProxySettingsSectionGap,
                  ),
                  TextFormField(
                    key: HttpProxySettingsPageKeys.hostField,
                    controller: _hostController,
                    enabled: !_isSaving,
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    enableSuggestions: false,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    style: AppTextTokens.httpProxySettingsFieldValue(textTheme),
                    decoration: _inputDecoration(
                      context,
                      label: l10n.httpProxySettingsHostLabel,
                      hint: l10n.httpProxySettingsHostHint,
                      helper: l10n.httpProxySettingsHostHelper,
                    ),
                    validator: (value) => _validateHost(value, l10n),
                  ),
                  const SizedBox(
                    height: AppSpacingTokens.httpProxySettingsFieldGap,
                  ),
                  TextFormField(
                    key: HttpProxySettingsPageKeys.portField,
                    controller: _portController,
                    enabled: !_isSaving,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    autocorrect: false,
                    enableSuggestions: false,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    style: AppTextTokens.httpProxySettingsFieldValue(textTheme),
                    decoration: _inputDecoration(
                      context,
                      label: l10n.httpProxySettingsPortLabel,
                      hint: l10n.httpProxySettingsPortHint,
                    ),
                    validator: (value) => _validatePort(value, l10n),
                    onFieldSubmitted: (_) => _save(),
                  ),
                  const SizedBox(
                    height: AppSpacingTokens.httpProxySettingsWarningGap,
                  ),
                  _ProxyWarningCard(
                    message: l10n.httpProxySettingsWarning,
                    certificateMessage: l10n.httpProxySettingsCertificateHint,
                  ),
                  const SizedBox(
                    height: AppSpacingTokens.httpProxySettingsActionGap,
                  ),
                  SizedBox(
                    height: AppSpacingTokens.httpProxySettingsActionHeight,
                    child: FilledButton(
                      key: HttpProxySettingsPageKeys.saveButton,
                      onPressed: _isSaving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.httpProxySettingsAction,
                        foregroundColor:
                            AppColors.httpProxySettingsActionForeground,
                        disabledBackgroundColor:
                            AppColors.httpProxySettingsActionDisabled,
                        disabledForegroundColor:
                            AppColors.httpProxySettingsActionDisabledForeground,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppShapeTokens.httpProxySettingsActionRadius,
                          ),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width:
                                  AppLayoutTokens.httpProxySettingsProgressSize,
                              height:
                                  AppLayoutTokens.httpProxySettingsProgressSize,
                              child: CircularProgressIndicator(
                                strokeWidth: AppLayoutTokens
                                    .httpProxySettingsProgressStrokeWidth,
                                color:
                                    AppColors.httpProxySettingsActionForeground,
                              ),
                            )
                          : Text(
                              l10n.httpProxySettingsSaveAction,
                              style: AppTextTokens.httpProxySettingsAction(
                                textTheme,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String label,
    required String hint,
    String? helper,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(
        AppShapeTokens.httpProxySettingsFieldRadius,
      ),
      borderSide: const BorderSide(
        color: AppColors.httpProxySettingsFieldBorder,
      ),
    );
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      labelStyle: AppTextTokens.httpProxySettingsFieldLabel(textTheme),
      hintStyle: AppTextTokens.httpProxySettingsFieldHint(textTheme),
      helperStyle: AppTextTokens.httpProxySettingsFieldHelper(textTheme),
      errorStyle: AppTextTokens.httpProxySettingsFieldError(textTheme),
      filled: true,
      fillColor: AppColors.httpProxySettingsFieldSurface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacingTokens.httpProxySettingsFieldHorizontal,
        vertical: AppSpacingTokens.httpProxySettingsFieldVertical,
      ),
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(
          color: AppColors.httpProxySettingsFieldFocusedBorder,
          width: AppLayoutTokens.httpProxySettingsFieldFocusedBorderWidth,
        ),
      ),
      errorBorder: border.copyWith(
        borderSide: const BorderSide(
          color: AppColors.httpProxySettingsFieldError,
        ),
      ),
      focusedErrorBorder: border.copyWith(
        borderSide: const BorderSide(
          color: AppColors.httpProxySettingsFieldError,
          width: AppLayoutTokens.httpProxySettingsFieldFocusedBorderWidth,
        ),
      ),
      disabledBorder: border.copyWith(
        borderSide: const BorderSide(
          color: AppColors.httpProxySettingsFieldDisabledBorder,
        ),
      ),
    );
  }

  String? _validateHost(String? value, AppLocalizations l10n) {
    if (!_enabled) {
      return null;
    }
    final host = value?.trim() ?? '';
    if (host.isEmpty) {
      return l10n.httpProxySettingsHostRequired;
    }
    if (!NetworkProxySettings.isValidHost(host)) {
      return l10n.httpProxySettingsHostInvalid;
    }
    return null;
  }

  String? _validatePort(String? value, AppLocalizations l10n) {
    if (!_enabled) {
      return null;
    }
    final portText = value?.trim() ?? '';
    if (portText.isEmpty) {
      return l10n.httpProxySettingsPortRequired;
    }
    final port = int.tryParse(portText);
    if (!NetworkProxySettings.isValidPort(port)) {
      return l10n.httpProxySettingsPortInvalid;
    }
    return null;
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (_enabled && !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isSaving = true);
    final settings = NetworkProxySettings(
      enabled: _enabled,
      host: _hostController.text.trim(),
      port: int.tryParse(_portController.text.trim()),
    );

    try {
      await ref.read(networkProxySettingsProvider.notifier).save(settings);
      if (!mounted) {
        return;
      }
      AppToast.success(context, l10n.httpProxySettingsSaved);
      context.pop(true);
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() => _isSaving = false);
      AppToast.error(context, l10n.httpProxySettingsSaveFailed);
    }
  }
}

class _ProxySwitchRow extends StatelessWidget {
  const _ProxySwitchRow({
    required this.enabled,
    required this.isSaving,
    required this.onChanged,
  });

  final bool enabled;
  final bool isSaving;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      container: true,
      label: l10n.httpProxySettingsEnableLabel,
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.httpProxySettingsEnableLabel,
              style: AppTextTokens.httpProxySettingsRowTitle(textTheme),
            ),
          ),
          SizedBox(
            width: AppLayoutTokens.httpProxySettingsSwitchHitWidth,
            height: AppLayoutTokens.httpProxySettingsSwitchHitHeight,
            child: Center(
              child: FlinxSwitch(
                key: HttpProxySettingsPageKeys.enabledSwitch,
                value: enabled,
                enabled: !isSaving,
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProxyWarningCard extends StatelessWidget {
  const _ProxyWarningCard({
    required this.message,
    required this.certificateMessage,
  });

  final String message;
  final String certificateMessage;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(
        AppSpacingTokens.httpProxySettingsWarningPadding,
      ),
      decoration: BoxDecoration(
        color: AppColors.httpProxySettingsWarningSurface,
        borderRadius: BorderRadius.circular(
          AppShapeTokens.httpProxySettingsWarningRadius,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              top: AppSpacingTokens.httpProxySettingsWarningIconTop,
            ),
            child: ExcludeSemantics(
              child: Icon(
                Icons.warning_amber_rounded,
                color: AppColors.httpProxySettingsWarningIcon,
                size: AppLayoutTokens.httpProxySettingsWarningIconSize,
              ),
            ),
          ),
          const SizedBox(
            width: AppSpacingTokens.httpProxySettingsWarningIconGap,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: AppTextTokens.httpProxySettingsWarning(textTheme),
                ),
                const SizedBox(
                  height: AppSpacingTokens.httpProxySettingsWarningTextGap,
                ),
                Text(
                  certificateMessage,
                  style: AppTextTokens.httpProxySettingsCertificateHint(
                    textTheme,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
