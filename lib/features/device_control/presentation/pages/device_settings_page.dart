import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
import '../../../records/application/providers.dart';
import '../../../records/domain/entities/operation_report.dart';
import '../../application/device_command_controller.dart';
import '../../application/about_device_controller.dart';
import '../../../settings/application/device_settings_controller.dart';
import '../../../settings/application/device_capabilities_controller.dart';
import '../../../settings/application/door_settings_controller.dart';
import '../../../settings/domain/entities/device_capability.dart';
import '../../../settings/domain/entities/device_setting.dart';
import '../../../settings/domain/entities/door_setting_snapshot.dart';
import '../widgets/device_setting_options_sheet.dart';
import 'transmitter_learning_page.dart';
import 'transmitter_list_page.dart';

class DeviceSettingsAssetPaths {
  const DeviceSettingsAssetPaths._();

  static const transmitterManagement =
      'assets/icons/device_settings/device_settings_transmitter_management_icon.png';
  static const ledOffDelay =
      'assets/icons/device_settings/device_settings_led_off_delay_icon.png';
  static const partialOpen =
      'assets/icons/device_settings/device_settings_partial_open_icon.png';
  static const autoClose =
      'assets/icons/device_settings/device_settings_auto_close_icon.png';
  static const openingSpeed =
      'assets/icons/device_settings/device_settings_opening_speed_icon.png';
  static const aboutDevice =
      'assets/icons/device_settings/device_settings_about_device_icon.png';
  static const doorOpenReminder =
      'assets/icons/device_settings/device_settings_door_open_reminder_icon.png';
  static const forceMargin =
      'assets/icons/device_settings/device_settings_force_margin_icon.png';
  static const management =
      'assets/icons/device_settings/device_settings_management_icon.png';
  static const openingSpeedIndicatorPlaceholder =
      'assets/icons/device_settings/opening_speed_indicator_placeholder.png';
  static const forceMarginWarningPlaceholder =
      'assets/icons/device_settings/force_margin_warning_placeholder.png';
  static const forceMarginIndicatorPlaceholder =
      'assets/icons/device_settings/force_margin_indicator_placeholder.png';
  static const transmitterRenamePlaceholder =
      'assets/icons/device_settings/transmitter_rename_placeholder.png';
  static const transmitterAddPlaceholder =
      'assets/icons/device_settings/transmitter_add_placeholder.png';
  static const aboutDeviceBluetoothName =
      'assets/icons/device_settings/about_device_bluetooth_name.png';
  static const aboutDeviceFirmwareVersion =
      'assets/icons/device_settings/about_device_firmware_version.png';
  static const aboutDeviceHardwareVersion =
      'assets/icons/device_settings/about_device_hardware_version.png';
  static const aboutDeviceCheckVersion =
      'assets/icons/device_settings/about_device_check_version.png';
}

class OpeningSpeedConfig {
  factory OpeningSpeedConfig({
    required List<int> allowedValues,
    required int current,
  }) {
    assert(allowedValues.isNotEmpty);
    assert(allowedValues.toSet().length == allowedValues.length);
    assert(allowedValues.every((value) => value >= 0 && value <= 100));
    assert(allowedValues.contains(current));
    return OpeningSpeedConfig._(
      allowedValues: List.unmodifiable(allowedValues),
      current: current,
    );
  }

  const OpeningSpeedConfig._({
    required this.allowedValues,
    required this.current,
  });

  final List<int> allowedValues;
  final int current;
}

String _normalizeCapabilityCode(String code) => code.trim().toUpperCase();

class DeviceSettingsCapabilityScope {
  DeviceSettingsCapabilityScope({
    required Iterable<String> allowedCapabilityCodes,
  }) : allowedCapabilityCodes = Set.unmodifiable(
         allowedCapabilityCodes
             .map(_normalizeCapabilityCode)
             .where((code) => code.isNotEmpty),
       );

  final Set<String> allowedCapabilityCodes;

  bool allows(String code) =>
      allowedCapabilityCodes.contains(_normalizeCapabilityCode(code));
}

class DeviceSettingsPage extends ConsumerStatefulWidget {
  const DeviceSettingsPage({
    required this.doorId,
    required this.deviceId,
    this.bleName = '',
    this.bleDeviceId = '',
    this.capabilityScope,
    this.forceMarginDialogState = 1,
    this.openingSpeedConfig = const OpeningSpeedConfig._(
      allowedValues: [100, 80, 60],
      current: 80,
    ),
    super.key,
  }) : assert(forceMarginDialogState >= 0 && forceMarginDialogState <= 2);

  static const routeName = 'device-settings';
  static const routePath = '/device-settings';

  final String deviceId;
  final String doorId;
  final String bleName;
  final String bleDeviceId;
  final DeviceSettingsCapabilityScope? capabilityScope;
  final int forceMarginDialogState;
  final OpeningSpeedConfig openingSpeedConfig;

  @override
  ConsumerState<DeviceSettingsPage> createState() => _DeviceSettingsPageState();
}

class _DeviceSettingsPageState extends ConsumerState<DeviceSettingsPage> {
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final settingsState = ref.watch(
      deviceSettingsControllerProvider(widget.bleDeviceId),
    );
    final capabilitiesState = ref.watch(
      deviceCapabilitiesControllerProvider(widget.deviceId),
    );
    final doorSettingsState = ref.watch(
      doorSettingsControllerProvider(widget.doorId),
    );
    final showsForceMargin = _supportsCapability(
      capabilitiesState,
      DeviceCapabilityCode.forceMargin,
    );

    return Scaffold(
      appBar: const FlinxNavigationBar(title: '', showBottomDivider: false),
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 25, 20, 24),
              children: [
                Text(
                  l10n.deviceSettingsTitle,
                  style: AppTextTokens.deviceSettingsTitle(textTheme),
                ),
                if (settingsState.loading ||
                    capabilitiesState.loading ||
                    doorSettingsState.loading)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(l10n.deviceSettingsLoading),
                  ),
                if (settingsState.errorMessage != null ||
                    capabilitiesState.errorMessage != null ||
                    doorSettingsState.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Expanded(child: Text(l10n.deviceSettingsLoadFailed)),
                        TextButton(
                          onPressed:
                              settingsState.loading ||
                                  capabilitiesState.loading ||
                                  doorSettingsState.loading
                              ? null
                              : () {
                                  ref
                                      .read(
                                        deviceSettingsControllerProvider(
                                          widget.bleDeviceId,
                                        ).notifier,
                                      )
                                      .load();
                                  ref
                                      .read(
                                        doorSettingsControllerProvider(
                                          widget.doorId,
                                        ).notifier,
                                      )
                                      .load();
                                  ref
                                      .read(
                                        deviceCapabilitiesControllerProvider(
                                          widget.deviceId,
                                        ).notifier,
                                      )
                                      .load();
                                },
                          child: Text(l10n.deviceSettingsRetry),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  l10n.deviceSettingsForUsers,
                  style: AppTextTokens.deviceSettingsMainSectionLabel(
                    textTheme,
                  ),
                ),
                const SizedBox(height: 10),
                _SettingsRows(
                  rows: [
                    if (_supportsCapability(
                      capabilitiesState,
                      DeviceCapabilityCode.transmitterPairing,
                    ))
                      _SettingsRowData(
                        assetPath:
                            DeviceSettingsAssetPaths.transmitterManagement,
                        fallbackIcon: Icons.settings_remote_outlined,
                        title: l10n.deviceSettingsTransmitterManagement,
                        onTap: () => context.push(
                          '${TransmitterManagementPage.routePath}'
                          '?deviceId=${Uri.encodeComponent(widget.deviceId)}',
                        ),
                      ),
                    if (_supportsCapability(
                      capabilitiesState,
                      DeviceCapabilityCode.ledOffDelay,
                    ))
                      _capabilitySettingsRow(
                        assetPath: DeviceSettingsAssetPaths.ledOffDelay,
                        fallbackIcon: Icons.light_mode_outlined,
                        localizedTitle: l10n.deviceSettingsLedOffDelay,
                        key: DeviceSettingKey.ledOffDelay,
                        capability: capabilitiesState.capabilityFor(
                          DeviceCapabilityCode.ledOffDelay,
                        ),
                        setting: doorSettingsState.settingFor(
                          DeviceCapabilityCode.ledOffDelay,
                        ),
                      ),
                    if (_supportsCapability(
                      capabilitiesState,
                      DeviceCapabilityCode.partialOpenLevel,
                    ))
                      _capabilitySettingsRow(
                        assetPath: DeviceSettingsAssetPaths.partialOpen,
                        fallbackIcon: Icons.sensor_door_outlined,
                        localizedTitle: l10n.deviceSettingsPartialOpen,
                        key: DeviceSettingKey.partialOpen,
                        capability: capabilitiesState.capabilityFor(
                          DeviceCapabilityCode.partialOpenLevel,
                        ),
                        setting: doorSettingsState.settingFor(
                          DeviceCapabilityCode.partialOpen,
                        ),
                      ),
                    if (_supportsCapability(
                      capabilitiesState,
                      DeviceCapabilityCode.autoClose,
                    ))
                      _capabilitySettingsRow(
                        assetPath: DeviceSettingsAssetPaths.autoClose,
                        fallbackIcon: Icons.door_back_door_outlined,
                        localizedTitle: l10n.deviceSettingsAutoClose,
                        key: DeviceSettingKey.autoCloseTime,
                        capability: capabilitiesState.capabilityFor(
                          DeviceCapabilityCode.autoClose,
                        ),
                        setting: doorSettingsState.settingFor(
                          DeviceCapabilityCode.autoClose,
                        ),
                      ),
                    if (_supportsCapability(
                      capabilitiesState,
                      DeviceCapabilityCode.openingSpeed,
                    ))
                      _capabilitySettingsRow(
                        assetPath: DeviceSettingsAssetPaths.openingSpeed,
                        fallbackIcon: Icons.speed_outlined,
                        localizedTitle: l10n.deviceSettingsOpeningSpeed,
                        key: DeviceSettingKey.openingSpeed,
                        capability: capabilitiesState.capabilityFor(
                          DeviceCapabilityCode.openingSpeed,
                        ),
                        setting: doorSettingsState.settingFor(
                          DeviceCapabilityCode.openingSpeed,
                        ),
                      ),
                    _SettingsRowData(
                      assetPath: DeviceSettingsAssetPaths.aboutDevice,
                      fallbackIcon: Icons.info_outline,
                      title: l10n.deviceSettingsAboutDevice,
                      onTap: () => context.push(
                        AboutDevicePage.location(
                          doorId: widget.doorId,
                          deviceId: widget.deviceId,
                        ),
                      ),
                    ),
                    if (_supportsCapability(
                      capabilitiesState,
                      DeviceCapabilityCode.doorOpenReminder,
                    ))
                      _capabilitySettingsRow(
                        assetPath: DeviceSettingsAssetPaths.doorOpenReminder,
                        fallbackIcon: Icons.notifications_active_outlined,
                        localizedTitle: l10n.deviceSettingsDoorOpenReminder,
                        key: DeviceSettingKey.doorOpenReminder,
                        capability: capabilitiesState.capabilityFor(
                          DeviceCapabilityCode.doorOpenReminder,
                        ),
                        setting: doorSettingsState.settingFor(
                          DeviceCapabilityCode.doorOpenReminder,
                        ),
                      ),
                  ],
                ),
                if (showsForceMargin) ...[
                  const SizedBox(height: 22),
                  Text(
                    l10n.deviceSettingsForInstallers,
                    style: AppTextTokens.deviceSettingsMainSectionLabel(
                      textTheme,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _SettingsRows(
                    rows: [
                      _SettingsRowData(
                        assetPath: DeviceSettingsAssetPaths.forceMargin,
                        fallbackIcon: Icons.tune_rounded,
                        title: l10n.deviceSettingsForceMargin,
                        value: _settingValue(
                          settingsState,
                          DeviceSettingKey.openingForce,
                          l10n,
                          null,
                          doorSettingsState.settingFor(
                            DeviceCapabilityCode.forceMargin,
                          ),
                        ),
                        onTap: () => _showRawValueEditor(
                          DeviceSettingKey.openingForce,
                          l10n.deviceSettingsForceMargin,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _supportsCapability(
    DeviceCapabilitiesState capabilitiesState,
    String code,
  ) {
    return capabilitiesState.supports(code) &&
        (widget.capabilityScope?.allows(code) ?? true);
  }

  String _settingValue(
    DeviceSettingsState state,
    DeviceSettingKey key,
    AppLocalizations l10n,
    DeviceCapability? capability,
    DoorSettingSnapshot? setting,
  ) {
    if (state.pendingKey == key) {
      return l10n.deviceSettingsWriting;
    }
    if (setting != null) {
      final currentValue = setting.currentValue;
      if (currentValue == null) {
        return l10n.deviceSettingsRawUnavailable;
      }
      final option = capability?.options.where(
        (option) => option.value == currentValue,
      );
      if (option != null && option.isNotEmpty) {
        return _optionLabel(option.first, setting.unit ?? capability?.unit);
      }
      return _valueWithUnit(currentValue, setting.unit);
    }
    final rawValue = state.values[key]?.rawValue;
    final option = capability?.options.where(
      (option) => option.value == rawValue,
    );
    if (option != null && option.isNotEmpty) {
      return _optionLabel(option.first, capability?.unit);
    }
    final rawSettingValue = state.values[key];
    if (rawSettingValue == null) {
      return l10n.deviceSettingsRawUnavailable;
    }
    return l10n.deviceSettingsRawValueDisplay(
      rawSettingValue.hexValue,
      rawSettingValue.rawValue,
    );
  }

  _SettingsRowData _capabilitySettingsRow({
    required String assetPath,
    required IconData fallbackIcon,
    required String localizedTitle,
    required DeviceSettingKey key,
    required DeviceCapability? capability,
    required DoorSettingSnapshot? setting,
  }) {
    final l10n = AppLocalizations.of(context);
    final settingsState = ref.read(
      deviceSettingsControllerProvider(widget.bleDeviceId),
    );
    final title = localizedTitle;
    return _SettingsRowData(
      assetPath: assetPath,
      fallbackIcon: fallbackIcon,
      title: title,
      value: _settingValue(settingsState, key, l10n, capability, setting),
      onTap: () => _showCapabilityValueEditor(
        key: key,
        title: title,
        capability: capability,
      ),
    );
  }

  Future<void> _showCapabilityValueEditor({
    required DeviceSettingKey key,
    required String title,
    required DeviceCapability? capability,
  }) async {
    if (!_isCurrentBleDeviceConnected()) {
      _showBluetoothConnectionRequired();
      return;
    }
    final state = ref.read(
      deviceSettingsControllerProvider(widget.bleDeviceId),
    );
    if (state.loading || state.pendingKey != null) {
      return;
    }
    if (capability == null || capability.options.isEmpty) {
      await _showRawValueEditor(key, title);
      return;
    }

    final rawValue = state.values[key]?.rawValue;
    final initialValue =
        capability.options.any((option) => option.value == rawValue)
        ? rawValue!
        : capability.options.first.value;
    final value = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DeviceCapabilityOptionsSheet(
        title: title,
        options: capability.options,
        unit: capability.unit,
        initialValue: initialValue,
      ),
    );
    if (value == null || !mounted || value == rawValue) {
      return;
    }
    await _saveSetting(key, value);
  }

  Future<void> _showRawValueEditor(DeviceSettingKey key, String title) async {
    if (!_isCurrentBleDeviceConnected()) {
      _showBluetoothConnectionRequired();
      return;
    }
    final l10n = AppLocalizations.of(context);
    final state = ref.read(
      deviceSettingsControllerProvider(widget.bleDeviceId),
    );
    if (state.loading || state.pendingKey != null) {
      return;
    }
    final controller = TextEditingController(
      text: state.values[key]?.rawValue.toString() ?? '',
    );
    final value = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        String? validationMessage;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.deviceSettingsRawValueHelp),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: l10n.deviceSettingsRawValueLabel,
                      errorText: validationMessage,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(l10n.deviceSettingsRawCancel),
                ),
                FilledButton(
                  onPressed: () {
                    final text = controller.text.trim();
                    final parsed = text.toLowerCase().startsWith('0x')
                        ? int.tryParse(text.substring(2), radix: 16)
                        : int.tryParse(text);
                    final maximum = (1 << (key.byteWidth * 8)) - 1;
                    if (parsed == null || parsed < 0 || parsed > maximum) {
                      setDialogState(() {
                        validationMessage = l10n.deviceSettingsRawValueInvalid(
                          maximum,
                        );
                      });
                      return;
                    }
                    if (!key.supportsValue(parsed)) {
                      setDialogState(() {
                        validationMessage =
                            l10n.deviceSettingsRawValueProtocolInvalid;
                      });
                      return;
                    }
                    Navigator.of(dialogContext).pop(parsed);
                  },
                  child: Text(l10n.deviceSettingsRawSave),
                ),
              ],
            );
          },
        );
      },
    );
    if (value == null || !mounted) {
      return;
    }
    await _saveSetting(key, value);
  }

  Future<void> _saveSetting(DeviceSettingKey key, int value) async {
    final saved = await ref
        .read(deviceSettingsControllerProvider(widget.bleDeviceId).notifier)
        .setRawValue(key, value);
    if (!saved || !mounted) {
      return;
    }
    ref
        .read(doorSettingsControllerProvider(widget.doorId).notifier)
        .updateCurrentValue(key.capabilityCode, value);
    final reportAction = switch (key) {
      DeviceSettingKey.ledOffDelay => OperationReportAction.ledOffDelayChanged,
      DeviceSettingKey.partialOpen => OperationReportAction.partialOpenChanged,
      DeviceSettingKey.autoCloseTime =>
        OperationReportAction.autoCloseDelayChanged,
      DeviceSettingKey.doorOpenReminder =>
        OperationReportAction.doorOpenReminderDelayChanged,
      _ => null,
    };
    if (reportAction != null) {
      unawaited(
        ref
            .read(operationReportControllerProvider)
            .report(
              doorId: widget.doorId,
              action: reportAction,
              operationSource: OperationReportSource.bluetooth,
            ),
      );
    }
  }

  bool _isCurrentBleDeviceConnected() {
    final bleName = widget.bleName.trim();
    final bleDeviceId = widget.bleDeviceId.trim();
    if (bleName.isEmpty || bleDeviceId.isEmpty) {
      return false;
    }
    final commandState = ref.read(deviceCommandControllerProvider);
    return commandState.bleConnectionStatus ==
            DeviceBleConnectionStatus.connected &&
        commandState.bleTargetName?.trim() == bleName;
  }

  void _showBluetoothConnectionRequired() {
    AppToast.info(
      context,
      AppLocalizations.of(context).deviceSettingsBluetoothConnectionRequired,
    );
  }
}

final _autoCloseTimeOptions = [
  '0s',
  '30s',
  for (var minute = 1; minute <= 60; minute++) '${minute}min',
];

const _doorOpenReminderTimeOptions = ['5min', '10min', '15min'];

String _formatDuration(AppLocalizations l10n, String value) {
  if (value.endsWith('min')) {
    return l10n.deviceSettingsMinutes(
      int.parse(value.substring(0, value.length - 3)),
    );
  }
  if (value.endsWith('s')) {
    return l10n.deviceSettingsSeconds(
      int.parse(value.substring(0, value.length - 1)),
    );
  }
  return value;
}

class AboutDevicePage extends ConsumerStatefulWidget {
  const AboutDevicePage({
    required this.doorId,
    required this.deviceId,
    super.key,
  });

  static const routeName = 'about-device';
  static const routePath = '/device-settings/about';

  static String location({required String doorId, required String deviceId}) {
    return Uri(
      path: routePath,
      queryParameters: <String, String>{'doorId': doorId, 'deviceId': deviceId},
    ).toString();
  }

  final String doorId;
  final String deviceId;

  @override
  ConsumerState<AboutDevicePage> createState() => _AboutDevicePageState();
}

class _AboutDevicePageState extends ConsumerState<AboutDevicePage> {
  AboutDeviceRequest get _request =>
      (doorId: widget.doorId, deviceId: widget.deviceId);

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  void _load() {
    ref
        .read(aboutDeviceControllerProvider(_request).notifier)
        .load(doorId: widget.doorId, deviceId: widget.deviceId);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(aboutDeviceControllerProvider(_request));

    return Scaffold(
      appBar: const FlinxNavigationBar(title: '', showBottomDivider: false),
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              children: [
                Padding(
                  padding: EdgeInsetsGeometry.only(left: 20),
                  child: Text(
                    l10n.deviceSettingsAboutDevice,
                    style: AppTextTokens.deviceSettingsTitle(textTheme),
                  ),
                ),
                const SizedBox(height: 28),
                state.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.only(top: 36),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, _) => Padding(
                    padding: const EdgeInsets.only(top: 36),
                    child: Center(
                      child: TextButton(
                        onPressed: _load,
                        child: Text(l10n.deviceSettingsLoadFailed),
                      ),
                    ),
                  ),
                  data: (info) => _SettingsRows(
                    rows: [
                      _SettingsRowData(
                        assetPath:
                            DeviceSettingsAssetPaths.aboutDeviceBluetoothName,
                        fallbackIcon: Icons.bluetooth,
                        title: l10n.deviceSettingsBluetoothName,
                        value: info.bluetoothName,
                        showChevron: false,
                      ),
                      _SettingsRowData(
                        assetPath:
                            DeviceSettingsAssetPaths.aboutDeviceFirmwareVersion,
                        fallbackIcon: Icons.developer_board_outlined,
                        title: l10n.deviceSettingsFirmwareVersion,
                        value: info.firmwareVersion,
                        showChevron: false,
                      ),
                      _SettingsRowData(
                        assetPath:
                            DeviceSettingsAssetPaths.aboutDeviceHardwareVersion,
                        fallbackIcon: Icons.memory_outlined,
                        title: l10n.deviceSettingsHardwareVersion,
                        value: info.hardwareVersion,
                        showChevron: false,
                      ),
                      // _SettingsRowData(
                      //   assetPath:
                      //       DeviceSettingsAssetPaths.aboutDeviceCheckVersion,
                      //   fallbackIcon: Icons.manage_search_outlined,
                      //   title: l10n.deviceSettingsCheckVersion,
                      // ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TransmitterManagementPage extends StatelessWidget {
  const TransmitterManagementPage({required this.deviceId, super.key});

  static const routeName = 'transmitter-management';
  static const routePath = '/device-settings/transmitters';

  final String deviceId;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: const FlinxNavigationBar(title: '', showBottomDivider: false),
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              children: [
                Text(
                  l10n.deviceSettingsTitle,
                  style: AppTextTokens.deviceSettingsTitle(textTheme),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.deviceSettingsForUsers,
                  style: AppTextTokens.deviceSettingsSectionLabel(textTheme),
                ),
                const SizedBox(height: 8),
                _SettingsRows(
                  rows: [
                    _SettingsRowData(
                      assetPath: DeviceSettingsAssetPaths.transmitterManagement,
                      fallbackIcon: Icons.settings_remote_outlined,
                      title: l10n.deviceSettingsTransmitterLearning,
                      onTap: () => context.push(
                        '${TransmitterLearningPage.routePath}?deviceId=${Uri.encodeComponent(deviceId)}',
                      ),
                    ),
                    _SettingsRowData(
                      assetPath: DeviceSettingsAssetPaths.management,
                      fallbackIcon: Icons.settings_outlined,
                      title: l10n.deviceSettingsManagement,
                      onTap: () => context.push(
                        '${TransmitterListPage.routePath}?deviceId=${Uri.encodeComponent(deviceId)}',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsRows extends StatelessWidget {
  const _SettingsRows({required this.rows});

  final List<_SettingsRowData> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < rows.length; index++)
          _SettingsRow(data: rows[index], showTopDivider: index == 0),
      ],
    );
  }
}

class _SettingsRowData {
  const _SettingsRowData({
    required this.assetPath,
    required this.fallbackIcon,
    required this.title,
    this.value,
    this.showChevron = true,
    this.onTap,
  });

  final String assetPath;
  final IconData fallbackIcon;
  final String title;
  final String? value;
  final bool showChevron;
  final VoidCallback? onTap;
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.data, required this.showTopDivider});

  final _SettingsRowData data;
  final bool showTopDivider;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: data.onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              top: showTopDivider
                  ? const BorderSide(color: AppColors.deviceSettingsDivider)
                  : BorderSide.none,
              bottom: const BorderSide(color: AppColors.deviceSettingsDivider),
            ),
          ),
          child: SizedBox(
            height: 77,
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      _DeviceSettingsAssetIcon(
                        assetPath: data.assetPath,
                        fallbackIcon: data.fallbackIcon,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          data.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextTokens.deviceSettingsRowTitle(
                            textTheme,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (data.value != null)
                  SizedBox(
                    width: 112,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12, right: 12),
                      child: Text(
                        data.value!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: AppTextTokens.deviceSettingsRowValue(textTheme),
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 12),
                if (data.showChevron)
                  const SizedBox(
                    width: 28,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Icon(
                        Icons.chevron_right,
                        size: 28,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DeviceSettingsAssetIcon extends StatelessWidget {
  const _DeviceSettingsAssetIcon({
    required this.assetPath,
    required this.fallbackIcon,
  });

  final String assetPath;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: 34,
      height: 34,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => SizedBox(
        width: 34,
        height: 34,
        child: Icon(fallbackIcon, size: 24, color: AppColors.textIcon),
      ),
    );
  }
}

String _optionLabel(DeviceCapabilityOption option, String? unit) {
  return formatDeviceCapabilityOption(option, unit);
}

String _valueWithUnit(int value, String? unit) {
  final normalizedUnit = unit?.trim();
  return normalizedUnit == null || normalizedUnit.isEmpty
      ? '$value'
      : '$value $normalizedUnit';
}

class _DoorOpenReminderSheet extends StatefulWidget {
  const _DoorOpenReminderSheet({required this.initialValue});

  final String initialValue;

  @override
  State<_DoorOpenReminderSheet> createState() => _DoorOpenReminderSheetState();
}

class _DoorOpenReminderSheetState extends State<_DoorOpenReminderSheet> {
  late String _selectedValue = widget.initialValue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return DeviceSettingsSheetFrame(
      heightFactor: 0.50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.deviceSettingsDoorOpenReminder,
            textAlign: TextAlign.center,
            style: AppTextTokens.deviceSettingsSheetTitle(textTheme),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.deviceSettingsDoorOpenReminderTime,
            style: AppTextTokens.deviceSettingsSheetCaption(textTheme),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: DeviceSettingsFixedSelectionList<String>(
              values: _doorOpenReminderTimeOptions,
              initialValue: _selectedValue,
              labelBuilder: (value) => _formatDuration(l10n, value),
              onSelected: (value) => setState(() => _selectedValue = value),
            ),
          ),
          const SizedBox(height: 20),
          DeviceSettingsSheetActionRow(
            onConfirm: () => Navigator.pop(context, _selectedValue),
          ),
        ],
      ),
    );
  }
}

class _AutoCloseSheet extends StatefulWidget {
  const _AutoCloseSheet({
    required this.initialPosition,
    required this.initialTime,
    required this.heightFactor,
  });

  final _AutoClosePosition initialPosition;
  final String initialTime;
  final double heightFactor;

  @override
  State<_AutoCloseSheet> createState() => _AutoCloseSheetState();
}

class _AutoCloseSheetState extends State<_AutoCloseSheet> {
  static const _positions = [
    _AutoClosePosition.upLimit,
    _AutoClosePosition.anyPosition,
  ];

  late _AutoClosePosition _position = widget.initialPosition;
  late String _time = widget.initialTime;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    return DeviceSettingsSheetFrame(
      heightFactor: widget.heightFactor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.deviceSettingsAutoClosingSetting,
            textAlign: TextAlign.center,
            style: AppTextTokens.deviceSettingsSheetTitle(textTheme),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              l10n.deviceSettingsAutoCloseCaption,
              style: AppTextTokens.deviceSettingsSheetCaption(textTheme),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              for (final position in _positions) ...[
                Expanded(
                  child: _SegmentButton(
                    label: _positionLabel(l10n, position),
                    selected: _position == position,
                    onTap: () => setState(() => _position = position),
                  ),
                ),
                if (position != _positions.last) const SizedBox(width: 36),
              ],
            ],
          ),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              l10n.deviceSettingsAutoCloseTime,
              style: AppTextTokens.deviceSettingsSheetCaption(textTheme),
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: DeviceSettingsFixedSelectionList<String>(
              values: _autoCloseTimeOptions,
              initialValue: _time,
              labelBuilder: (time) => _formatDuration(l10n, time),
              onSelected: (time) => setState(() => _time = time),
            ),
          ),
          const SizedBox(height: 20),
          DeviceSettingsSheetActionRow(
            onConfirm: () => Navigator.pop(
              context,
              _AutoCloseSelection(position: _position, time: _time),
            ),
          ),
        ],
      ),
    );
  }
}

String _positionLabel(AppLocalizations l10n, _AutoClosePosition position) =>
    switch (position) {
      _AutoClosePosition.upLimit => l10n.deviceSettingsUpLimit,
      _AutoClosePosition.anyPosition => l10n.deviceSettingsAnyPosition,
    };

enum _AutoClosePosition { upLimit, anyPosition }

class _AutoCloseSelection {
  const _AutoCloseSelection({required this.position, required this.time});

  final _AutoClosePosition position;
  final String time;
}

class _SpeedAdjustmentSheet extends StatefulWidget {
  const _SpeedAdjustmentSheet({
    required this.title,
    required this.speedConfig,
    required this.placeholderAssetPath,
  });

  final String title;
  final OpeningSpeedConfig speedConfig;
  final String placeholderAssetPath;

  @override
  State<_SpeedAdjustmentSheet> createState() => _SpeedAdjustmentSheetState();
}

class _SpeedAdjustmentSheetState extends State<_SpeedAdjustmentSheet> {
  late int _value = widget.speedConfig.current;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    return DeviceSettingsSheetFrame(
      heightFactor: 0.61,
      child: Column(
        children: [
          Text(
            widget.title,
            style: AppTextTokens.deviceSettingsSheetTitle(textTheme),
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              l10n.deviceSettingsOpeningSpeedCurrent(_value),
              style: AppTextTokens.deviceSettingsSheetCaption(textTheme),
            ),
          ),
          const SizedBox(height: 35),
          Expanded(
            child: Row(
              children: [
                _SpeedIndicatorCluster(assetPath: widget.placeholderAssetPath),
                const SizedBox(width: 20),
                _DiscreteVerticalSpeedSlider(
                  value: _value,
                  allowedValues: widget.speedConfig.allowedValues,
                  onChanged: (value) => setState(() => _value = value),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SliderScaleGuides(
                    labels: [
                      for (
                        var index = 0;
                        index < widget.speedConfig.allowedValues.length;
                        index++
                      )
                        index == widget.speedConfig.allowedValues.length - 1
                            ? AppLocalizations.of(
                                context,
                              ).deviceSettingsOpeningSpeedStandardGuide(
                                widget.speedConfig.allowedValues[index],
                              )
                            : AppLocalizations.of(
                                context,
                              ).deviceSettingsPercent(
                                widget.speedConfig.allowedValues[index],
                              ),
                    ],
                    guideKeyPrefix: 'openingSpeedSliderGuide',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          DeviceSettingsSheetActionRow(onConfirm: () => Navigator.pop(context)),
        ],
      ),
    );
  }
}

class _SpeedIndicatorCluster extends StatelessWidget {
  const _SpeedIndicatorCluster({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    const placements = [
      Offset(22, 0),
      Offset(62, 0),
      Offset(102, 0),
      Offset(22, 122),
      Offset(62, 122),
      Offset(22, 244),
    ];

    return SizedBox(
      width: 152,
      height: _VerticalSpeedSlider._height,
      child: Stack(
        children: [
          for (final placement in placements)
            Positioned(
              left: placement.dx,
              top: placement.dy,
              child: _CutAssetPlaceholder(assetPath: assetPath, height: 28),
            ),
        ],
      ),
    );
  }
}

class _SliderScaleGuides extends StatelessWidget {
  const _SliderScaleGuides({
    required this.labels,
    required this.guideKeyPrefix,
  });

  static const _rightScreenInset = 19.0;
  static const _labelWidth = 40.0;
  static const _guideToLabelGap = 10.0;

  final List<String> labels;
  final String guideKeyPrefix;

  @override
  Widget build(BuildContext context) {
    final textStyle = AppTextTokens.deviceSettingsSheetCaption(
      Theme.of(context).textTheme,
    );
    return Padding(
      padding: const EdgeInsets.only(right: _rightScreenInset),
      child: SizedBox(
        height: _VerticalSpeedSlider._height,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var index = 0; index < labels.length; index++)
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 1,
                      child: CustomPaint(
                        key: Key('$guideKeyPrefix-$index'),
                        painter: const _DashedHorizontalLinePainter(),
                      ),
                    ),
                  ),
                  const SizedBox(width: _guideToLabelGap),
                  SizedBox(
                    width: _labelWidth,
                    child: Text(
                      labels[index],
                      textAlign: TextAlign.right,
                      style: textStyle,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _DashedHorizontalLinePainter extends CustomPainter {
  const _DashedHorizontalLinePainter();

  static const _dashWidth = 3.0;
  static const _dashGap = 3.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.deviceSettingsSliderGuide
      ..strokeWidth = 1;
    for (var start = 0.0; start < size.width; start += _dashWidth + _dashGap) {
      canvas.drawLine(
        Offset(start, size.height / 2),
        Offset((start + _dashWidth).clamp(0.0, size.width), size.height / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedHorizontalLinePainter oldDelegate) =>
      false;
}

class _VerticalSpeedSlider extends StatelessWidget {
  const _VerticalSpeedSlider({
    required this.value,
    required this.minimum,
    required this.maximum,
    required this.onChanged,
  });

  final double value;
  final int minimum;
  final int maximum;
  final ValueChanged<double> onChanged;

  static const _height = 300.0;
  static const _thumbHeight = 60.0;
  static const _thumbInset = 10.0;

  void _updateValue(Offset localPosition) {
    final progress = (1 - localPosition.dy / (_height - _thumbHeight)).clamp(
      0.0,
      1.0,
    );
    final steppedValue = (minimum + (progress * (maximum - minimum)).round())
        .toDouble();
    onChanged(steppedValue);
  }

  @override
  Widget build(BuildContext context) {
    final progress = (value - minimum) / (maximum - minimum);
    final thumbBottom =
        _thumbInset + progress * (_height - _thumbHeight - 2 * _thumbInset);
    return GestureDetector(
      key: const Key('forceMarginContinuousSlider'),
      behavior: HitTestBehavior.opaque,
      onVerticalDragStart: (details) => _updateValue(details.localPosition),
      onVerticalDragUpdate: (details) => _updateValue(details.localPosition),
      onTapDown: (details) => _updateValue(details.localPosition),
      child: SizedBox(
        width: 40,
        height: _height,
        child: LayoutBuilder(
          builder: (context, constraints) => Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 56,
                height: _height,
                decoration: BoxDecoration(
                  color: AppColors.deviceSettingsSheetCancel,
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              Positioned(
                bottom: thumbBottom,
                child: Container(
                  width: 28,
                  height: _thumbHeight,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary,
                    borderRadius: BorderRadius.circular(23),
                  ),
                  child: const Icon(
                    Icons.drag_handle,
                    color: AppColors.backgroundPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiscreteVerticalSpeedSlider extends StatelessWidget {
  const _DiscreteVerticalSpeedSlider({
    required this.value,
    required this.allowedValues,
    required this.onChanged,
  });

  final int value;
  final List<int> allowedValues;
  final ValueChanged<int> onChanged;

  static const _height = _VerticalSpeedSlider._height;
  static const _thumbHeight = _VerticalSpeedSlider._thumbHeight;
  static const _thumbInset = 10.0;

  void _updateValue(Offset localPosition) {
    final progress = (localPosition.dy / (_height - _thumbHeight)).clamp(
      0.0,
      1.0,
    );
    final index = (progress * (allowedValues.length - 1)).round();
    onChanged(allowedValues[index]);
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = allowedValues.indexOf(value);
    final progress = allowedValues.length == 1
        ? 0.0
        : selectedIndex / (allowedValues.length - 1);
    final thumbTop =
        _thumbInset + progress * (_height - _thumbHeight - 2 * _thumbInset);
    return GestureDetector(
      key: const Key('openingSpeedDiscreteSlider'),
      behavior: HitTestBehavior.opaque,
      onVerticalDragStart: (details) => _updateValue(details.localPosition),
      onVerticalDragUpdate: (details) => _updateValue(details.localPosition),
      onTapDown: (details) => _updateValue(details.localPosition),
      child: SizedBox(
        width: 40,
        height: _height,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 56,
              height: _height,
              decoration: BoxDecoration(
                color: AppColors.deviceSettingsSheetCancel,
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            Positioned(
              top: thumbTop,
              child: Container(
                width: 28,
                height: _thumbHeight,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary,
                  borderRadius: BorderRadius.circular(23),
                ),
                child: const Icon(
                  Icons.drag_handle,
                  color: AppColors.backgroundPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ForceMarginAdjustmentSheet extends StatefulWidget {
  const _ForceMarginAdjustmentSheet({
    required this.description,
    required this.placeholderAssetPath,
  });

  final String description;
  final String placeholderAssetPath;

  @override
  State<_ForceMarginAdjustmentSheet> createState() =>
      _ForceMarginAdjustmentSheetState();
}

class _ForceMarginAdjustmentSheetState
    extends State<_ForceMarginAdjustmentSheet> {
  var _value = 0.0;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return DeviceSettingsSheetFrame(
      heightFactor: 0.72,
      child: Column(
        children: [
          Text(
            AppLocalizations.of(context).deviceSettingsForceMargin,
            style: AppTextTokens.deviceSettingsSheetTitle(textTheme),
          ),
          const SizedBox(height: 24),
          Text(
            widget.description,
            style: AppTextTokens.deviceSettingsSheetCaption(
              textTheme,
            ).copyWith(color: AppColors.deviceSettingsForceMarginWarningText),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Row(
              children: [
                _ForceMarginIndicatorCluster(
                  assetPath: widget.placeholderAssetPath,
                ),
                const SizedBox(width: 50),
                _VerticalSpeedSlider(
                  value: _value,
                  minimum: 0,
                  maximum: 15,
                  onChanged: (value) => setState(() => _value = value),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SliderScaleGuides(
                    labels: [
                      AppLocalizations.of(
                        context,
                      ).deviceSettingsForceMarginMaximumGuide,
                      AppLocalizations.of(
                        context,
                      ).deviceSettingsStandardAbbreviation,
                    ],
                    guideKeyPrefix: 'forceMarginSliderGuide',
                  ),
                ),
              ],
            ),
          ),
          DeviceSettingsSheetActionRow(onConfirm: () => Navigator.pop(context)),
        ],
      ),
    );
  }
}

class _ForceMarginIndicatorCluster extends StatelessWidget {
  const _ForceMarginIndicatorCluster({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 112,
    height: _VerticalSpeedSlider._height,
    child: Stack(
      children: [
        Positioned(
          left: 8,
          top: 0,
          child: _CutAssetPlaceholder(assetPath: assetPath, height: 28),
        ),
        Positioned(
          left: 58,
          top: 0,
          child: _CutAssetPlaceholder(assetPath: assetPath, height: 28),
        ),
        Positioned(
          left: 8,
          bottom: 0,
          child: _CutAssetPlaceholder(assetPath: assetPath, height: 28),
        ),
      ],
    ),
  );
}

class _ForceMarginLevelSheet extends StatefulWidget {
  @override
  State<_ForceMarginLevelSheet> createState() => _ForceMarginLevelSheetState();
}

class _ForceMarginLevelSheetState extends State<_ForceMarginLevelSheet> {
  var _level = 5;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final options = [
      for (var level = 3; level <= 7; level++)
        l10n.deviceSettingsForceMarginLevel(level),
    ];
    return DeviceSettingsSheetFrame(
      heightFactor: 0.5,
      child: Column(
        children: [
          Text(
            l10n.deviceSettingsForceMargin,
            style: AppTextTokens.deviceSettingsSheetTitle(
              Theme.of(context).textTheme,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.deviceSettingsForceMarginLevelCurrent(_level),
            style: AppTextTokens.deviceSettingsSheetCaption(
              Theme.of(context).textTheme,
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: DeviceSettingsFixedSelectionList<String>(
              values: options,
              initialValue: l10n.deviceSettingsForceMarginLevel(_level),
              labelBuilder: (value) => value,
              onSelected: (value) =>
                  setState(() => _level = options.indexOf(value) + 3),
            ),
          ),
          DeviceSettingsSheetActionRow(onConfirm: () => Navigator.pop(context)),
        ],
      ),
    );
  }
}

class _CutAssetPlaceholder extends StatelessWidget {
  const _CutAssetPlaceholder({required this.assetPath, this.height});

  final String assetPath;
  final double? height;

  @override
  Widget build(BuildContext context) => Image.asset(
    assetPath,
    width: height,
    height: height,
    fit: BoxFit.contain,
    errorBuilder: (context, error, stackTrace) => SizedBox(height: height),
  );
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      height: 45,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          backgroundColor: selected
              ? AppColors.brandPrimary
              : AppColors.deviceSettingsSheetCancel,
          foregroundColor: selected
              ? AppColors.backgroundPrimary
              : AppColors.textMuted,
          shape: const StadiumBorder(),
        ),
        child: Text(
          label,
          style: AppTextTokens.deviceSettingsSheetButton(textTheme).copyWith(
            color: selected ? AppColors.backgroundPrimary : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
