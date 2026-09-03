import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/logging/providers.dart';
import '../../../../platform_bridge/hardware_models.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/flinx_door_command_button.dart';
import '../../../../shared/widgets/flinx_fbox_control_assets.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
import '../../../../shared/widgets/flinx_switch.dart';
import '../../../add_device/presentation/navigation/f_box_wiring_test_route.dart';
import '../../../records/application/providers.dart';
import '../../../records/domain/entities/operation_report.dart';
import '../../../records/presentation/pages/operation_record_page.dart';
import '../../../security_center/presentation/pages/security_center_page.dart';
import '../../../settings/application/device_settings_controller.dart';
import '../../../settings/application/device_capabilities_controller.dart';
import '../../../settings/application/door_settings_controller.dart';
import '../../../settings/domain/entities/device_capability.dart';
import '../../../settings/domain/entities/device_setting.dart';
import '../../application/device_command_controller.dart';
import '../../domain/entities/door_control_mode.dart';
import '../../domain/entities/door_detail.dart';
import '../../domain/entities/door_device.dart';
import '../../domain/entities/door_realtime_state.dart';
import '../widgets/device_detail_bottom_navigation.dart';
import '../widgets/device_setting_options_sheet.dart';
import 'already_added_devices_page.dart';
import 'device_settings_page.dart';

class DeviceCommandPage extends ConsumerStatefulWidget {
  const DeviceCommandPage({
    required this.doorId,
    this.deviceId = '',
    this.onboardingFlowId,
    super.key,
  });

  static const routeName = 'device-command';
  static const routePath = '/device-command';

  static String location({
    required String doorId,
    required String deviceId,
    String? onboardingFlowId,
  }) {
    final queryParameters = <String, String>{
      'doorId': doorId,
      'deviceId': deviceId,
    };
    final flowId = onboardingFlowId?.trim();
    if (flowId != null && flowId.isNotEmpty) {
      queryParameters['onboardingFlowId'] = flowId;
    }
    return Uri(path: routePath, queryParameters: queryParameters).toString();
  }

  final String doorId;
  final String deviceId;
  final String? onboardingFlowId;

  @override
  ConsumerState<DeviceCommandPage> createState() => _DeviceCommandPageState();
}

class _DeviceCommandPageState extends ConsumerState<DeviceCommandPage> {
  bool? _ledEnabledOverride;
  bool? _autoCloseEnabledOverride;
  bool? _openReminderEnabledOverride;
  bool _isAwaitingDoorDetail = true;
  int _doorDetailLoadSequence = 0;
  DeviceDetailTab _selectedTab = DeviceDetailTab.command;
  late final DeviceCommandController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ref.read(deviceCommandControllerProvider.notifier);
    final flowId = widget.onboardingFlowId?.trim();
    if (flowId != null && flowId.isNotEmpty) {
      ref
          .read(appLoggerProvider)
          .info(
            'device_detail_entered',
            tag: AppLogTag.binding,
            flowId: flowId,
            context: {
              'deviceId': widget.deviceId,
              'doorId': widget.doorId,
              'stage': 'device_detail',
              'result': 'entered',
            },
          );
    }
    Future.microtask(_loadDoorDetail);
  }

  @override
  void didUpdateWidget(covariant DeviceCommandPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.doorId != widget.doorId) {
      _ledEnabledOverride = null;
      _autoCloseEnabledOverride = null;
      _openReminderEnabledOverride = null;
      _isAwaitingDoorDetail = true;
      Future.microtask(_loadDoorDetail);
    }
  }

  @override
  void dispose() {
    unawaited(_controller.disposeBleSession());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final commandState = ref.watch(deviceCommandControllerProvider);
    if (_isAwaitingDoorDetail || commandState.isLoadingDoorDetail) {
      return _DeviceCommandLoadingPage(
        semanticsLabel: AppLocalizations.of(context).deviceCommandLoading,
      );
    }
    if (commandState.doorDetailErrorMessage != null ||
        commandState.doorDetail == null) {
      return _DeviceCommandLoadFailurePage(onRetry: _loadDoorDetail);
    }
    final controller = _controller;
    final isBusy =
        commandState.pendingAction != null ||
        commandState.pendingRemotePairingAction != null ||
        commandState.pendingRemoteManagementAction != null;
    final textTheme = Theme.of(context).textTheme;

    return IndexedStack(
      index: _selectedTab.index,
      children: [
        OperationRecordPage(
          doorId: widget.doorId,
          onTabSelected: _selectTab,
          isActive: _selectedTab == DeviceDetailTab.operationRecords,
        ),
        _buildCommandPage(
          commandState: commandState,
          controller: controller,
          isBusy: isBusy,
          textTheme: textTheme,
        ),
        SecurityCenterPage(
          doorId: widget.doorId,
          deviceId: _hardwareDeviceId(commandState),
          onTabSelected: _selectTab,
          isActive: _selectedTab == DeviceDetailTab.securityCenter,
        ),
      ],
    );
  }

  void _selectTab(DeviceDetailTab tab) {
    if (_selectedTab == tab) {
      return;
    }
    setState(() => _selectedTab = tab);
  }

  Future<void> _loadDoorDetail({String? preferredDeviceId}) async {
    final loadSequence = ++_doorDetailLoadSequence;
    if (!_isAwaitingDoorDetail && mounted) {
      setState(() => _isAwaitingDoorDetail = true);
    }
    await _controller.loadDoorDetail(
      doorId: widget.doorId,
      preferredDeviceId: preferredDeviceId ?? '',
    );
    if (!mounted || loadSequence != _doorDetailLoadSequence) {
      return;
    }
    setState(() => _isAwaitingDoorDetail = false);
  }

  String _hardwareDeviceId(DeviceCommandState commandState) {
    final selectedDeviceId = commandState.selectedDeviceId;
    if (selectedDeviceId != null) {
      final nativeId = commandState.bleDeviceIds[selectedDeviceId]?.trim();
      if (nativeId?.isNotEmpty == true) {
        return nativeId!;
      }
    }
    final detailDeviceId = commandState.doorDetail?.name ?? '';
    if (detailDeviceId.trim().isNotEmpty) {
      return detailDeviceId.trim();
    }
    if (widget.deviceId.trim().isNotEmpty) {
      return widget.deviceId.trim();
    }
    return widget.doorId.trim();
  }

  DoorDevice? _selectedDoorDevice(DeviceCommandState commandState) {
    final selectedDeviceId = commandState.selectedDeviceId;
    if (selectedDeviceId != null) {
      for (final device in commandState.doorDevices) {
        if (device.deviceId == selectedDeviceId) {
          return device;
        }
      }
    }
    final candidates = <String>{
      commandState.bleDeviceId?.trim() ?? '',
      commandState.bleTargetName?.trim() ?? '',
      commandState.doorDetail?.name.trim() ?? '',
      widget.deviceId.trim(),
    }..remove('');

    for (final device in commandState.doorDevices) {
      if (candidates.contains(device.bleName?.trim()) ||
          candidates.contains(device.sn.trim()) ||
          candidates.contains(device.deviceId.trim())) {
        return device;
      }
    }

    return null;
  }

  Set<String> _capabilitiesForCurrentDevice(DeviceCommandState commandState) {
    final device = _selectedDoorDevice(commandState);
    if (device == null) {
      // Capabilities must be tied to a known device type. Do not enable an
      // extension when the response cannot be matched to the active device.
      return const <String>{};
    }

    final deviceCapabilities = _normalizeCapabilityCodes(device.capabilities);
    if (commandState.doorDetail?.relationType == 0) {
      return deviceCapabilities;
    }

    final effectiveCapabilities = _normalizeCapabilityCodes(
      commandState.doorDetail?.effectiveCapabilities ?? const <String>[],
    );
    return deviceCapabilities.intersection(effectiveCapabilities);
  }

  Set<String> _normalizeCapabilityCodes(Iterable<String> capabilities) {
    return capabilities
        .map((capability) => capability.trim().toUpperCase())
        .where((capability) => capability.isNotEmpty)
        .toSet();
  }

  Widget _buildCommandPage({
    required DeviceCommandState commandState,
    required DeviceCommandController controller,
    required bool isBusy,
    required TextTheme textTheme,
  }) {
    final doorDetail = commandState.doorDetail;
    final l10n = AppLocalizations.of(context);
    final isOwner = doorDetail?.relationType == 0;
    final effectiveCapabilities = _normalizeCapabilityCodes(
      doorDetail?.effectiveCapabilities ?? const <String>[],
    );
    void showPermissionDenied() {
      AppToast.info(context, l10n.deviceCommandPermissionDenied);
    }

    VoidCallback? permissionDeniedFor(String capabilityCode) {
      if (isOwner || effectiveCapabilities.contains(capabilityCode)) {
        return null;
      }
      return showPermissionDenied;
    }

    final ledEnabled = _ledEnabledOverride ?? doorDetail?.isLedEnabled ?? false;
    final autoCloseEnabled =
        _autoCloseEnabledOverride ?? doorDetail?.autoCloseEnabled ?? false;
    final openReminderEnabled =
        _openReminderEnabledOverride ??
        doorDetail?.openReminderEnabled ??
        false;
    final hardwareDeviceId = _hardwareDeviceId(commandState);
    final selectedDevice = _selectedDoorDevice(commandState);
    final selectedDeviceId =
        selectedDevice?.deviceId.trim() ?? widget.deviceId.trim();
    final selectedBleName = selectedDevice?.bleName?.trim() ?? '';
    final isFBox = selectedDevice?.deviceType.trim().toLowerCase() == 'fbox';
    final controlMode = DoorControlMode.fromBackend(
      value: doorDetail?.controlMode,
      label: doorDetail?.controlModeLabel,
    );
    final connectedBleDeviceId =
        commandState.bleConnectionStatus == DeviceBleConnectionStatus.connected
        ? commandState.bleDeviceId?.trim() ?? ''
        : '';
    final selectedDeviceUsesBle =
        commandState.selectedDeviceId != null &&
        commandState.bleConnectionStatuses[commandState.selectedDeviceId] ==
            DeviceBleConnectionStatus.connected;
    final deviceSettingsState = ref.watch(
      deviceSettingsControllerProvider(connectedBleDeviceId),
    );
    final deviceCapabilitiesState = ref.watch(
      deviceCapabilitiesControllerProvider(selectedDeviceId),
    );
    final doorSettingsState = ref.watch(
      doorSettingsControllerProvider(widget.doorId),
    );
    final partialOpenCapability = deviceCapabilitiesState.capabilityFor(
      DeviceCapabilityCode.partialOpenLevel,
    );
    final partialOpenSetting = doorSettingsState.settingFor(
      DeviceCapabilityCode.partialOpen,
    );
    final autoCloseCapability = deviceCapabilitiesState.capabilityFor(
      DeviceCapabilityCode.autoClose,
    );
    final autoCloseSetting = doorSettingsState.settingFor(
      DeviceCapabilityCode.autoClose,
    );
    final openReminderMinutes =
        doorSettingsState
            .settingFor(DeviceCapabilityCode.doorOpenReminder)
            ?.currentValue ??
        deviceSettingsState
            .values[DeviceSettingKey.doorOpenReminder]
            ?.rawValue ??
        DeviceSettingKey.doorOpenReminder.defaultEnabledValue;
    final autoCloseAllowedValues =
        autoCloseCapability?.options.map((option) => option.value).toList() ??
        const <int>[];
    final reportedAutoCloseValue =
        deviceSettingsState.values[DeviceSettingKey.autoCloseTime];
    final matchingAutoCloseValue = matchingDeviceSettingCandidate(
      reportedAutoCloseValue,
      autoCloseAllowedValues,
    );
    final configuredAutoCloseValue =
        autoCloseSetting?.currentValue ?? matchingAutoCloseValue;
    final autoCloseEnabledValue =
        autoCloseAllowedValues.contains(configuredAutoCloseValue) &&
            configuredAutoCloseValue != 0
        ? configuredAutoCloseValue
        : autoCloseAllowedValues.cast<int?>().firstWhere(
            (value) => value != 0,
            orElse: () => null,
          );
    final partialOpenLevel =
        partialOpenSetting?.currentValue ??
        deviceSettingsState.values[DeviceSettingKey.partialOpen]?.rawValue;
    final partialOpenOption = _capabilityOptionForValue(
      partialOpenCapability,
      partialOpenLevel,
    );
    final partialOpenValueLabel = partialOpenOption == null
        ? doorDetail?.partialOpenValue == null
              ? null
              : AppLocalizations.of(
                  context,
                ).deviceCommandCentimeters(doorDetail!.partialOpenValue!)
        : formatDeviceCapabilityOption(
            partialOpenOption,
            partialOpenSetting?.unit ?? partialOpenCapability?.unit,
          );
    final capabilities = _capabilitiesForCurrentDevice(commandState);
    final canControlDoor = capabilities.contains('DOOR_CONTROL');
    final canControlLed = capabilities.contains('LED_CONTROL');
    final canPartialOpen = capabilities.contains('PARTIAL_OPEN');
    final canSetPartialOpenLevel =
        capabilities.contains(DeviceCapabilityCode.partialOpenLevel) &&
        partialOpenCapability != null &&
        partialOpenCapability.options.isNotEmpty;
    final canUseAutoClose =
        capabilities.contains('AUTO_CLOSE') &&
        autoCloseAllowedValues.isNotEmpty &&
        autoCloseEnabledValue != null;
    final canUseOpenReminder = capabilities.contains('DOOR_OPEN_REMINDER');
    final settingsCapabilityScope = doorDetail?.relationType == 0
        ? null
        : DeviceSettingsCapabilityScope(allowedCapabilityCodes: capabilities);
    final realtimePositionPercent =
        commandState.doorRealtimeState?.positionPercent;
    final doorPositionPercent =
        realtimePositionPercent ?? doorDetail?.positionPercent;
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: FlinxNavigationBar(
        title: doorDetail?.name ?? l10n.deviceCommandFallbackDoorName,
        showBottomDivider: false,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            tooltip: l10n.deviceCommandMoreTooltip,
            onPressed: isBusy
                ? null
                : () async {
                    final addedDeviceId = await context.push<String>(
                      '${AlreadyAddedDevicesPage.routePath}'
                      '?doorId=${Uri.encodeComponent(widget.doorId)}'
                      '&deviceId=${Uri.encodeComponent(hardwareDeviceId)}',
                    );
                    final normalizedDeviceId = addedDeviceId?.trim();
                    if (!mounted ||
                        normalizedDeviceId == null ||
                        normalizedDeviceId.isEmpty) {
                      return;
                    }
                    _loadDoorDetail(preferredDeviceId: normalizedDeviceId);
                  },
            icon: const Icon(Icons.more_horiz, size: 24),
          ),
          const SizedBox(width: 4),
        ],
      ),
      bottomNavigationBar: DeviceDetailBottomNavigation(
        selectedTab: DeviceDetailTab.command,
        onSelected: _selectTab,
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final contentWidth =
                constraints.maxWidth >
                    AppLayoutTokens.deviceControlLargeScreenMinWidth
                ? math.min(
                    constraints.maxWidth,
                    AppLayoutTokens.deviceControlContentMaxWidth,
                  )
                : constraints.maxWidth;

            return Center(
              child: SizedBox(
                width: contentWidth,
                child: Column(
                  children: [
                    if (isFBox)
                      const _FBoxVideoHeader()
                    else
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                        child: DecoratedBox(
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: AppColors.deviceControlDivider,
                              ),
                            ),
                          ),
                          child: _CycleSummary(
                            operatedCycles: doorDetail?.operatedCycles,
                            remainingCycles: doorDetail?.remainingCycles,
                            textTheme: textTheme,
                          ),
                        ),
                      ),
                    _DeviceConnectionStrip(
                      devices: commandState.doorDevices,
                      connectionStatuses: commandState.bleConnectionStatuses,
                      selectedDeviceId: commandState.selectedDeviceId,
                      onDeviceTap: (device) =>
                          controller.selectDevice(device.deviceId),
                    ),
                    SizedBox(
                      height: isFBox
                          ? AppSpacingTokens
                                .deviceControlFBoxConnectionToContent
                          : 12,
                    ),
                    Expanded(
                      child: isFBox
                          ? _buildFBoxScrollableContent(
                              commandState: commandState,
                              controlMode: controlMode,
                              doorDetail: doorDetail!,
                              doorPositionPercent: doorPositionPercent,
                              hardwareDeviceId: hardwareDeviceId,
                              selectedDeviceId: selectedDeviceId,
                              selectedDeviceUsesBle: selectedDeviceUsesBle,
                              isBusy: isBusy,
                              canControlDoor: canControlDoor,
                              onPermissionDenied: permissionDeniedFor(
                                'DOOR_CONTROL',
                              ),
                              textTheme: textTheme,
                              l10n: l10n,
                            )
                          : ListView(
                              key: const PageStorageKey<String>(
                                'device-command-scroll',
                              ),
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                              children: [
                                _DoorHeroImage(
                                  doorType: DoorType.fromWireValue(
                                    doorDetail?.doorType,
                                  ),
                                  doorTypeWireValue: doorDetail?.doorType,
                                  positionPercent: doorPositionPercent ?? 0,
                                  logger: ref.read(appLoggerProvider),
                                ),
                                const SizedBox(height: 4),
                                Center(
                                  child: Text(
                                    _doorStateLabel(
                                      l10n,
                                      realtimeStatus: commandState
                                          .doorRealtimeState
                                          ?.status,
                                      fallbackState: doorDetail?.doorState,
                                      positionPercent: doorPositionPercent,
                                    ),
                                    style: AppTextTokens.deviceControlDoorState(
                                      textTheme,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                if (commandState.doorDetailErrorMessage !=
                                    null) ...[
                                  _CommandFeedback(
                                    message:
                                        commandState.doorDetailErrorMessage!,
                                    icon: Icons.error_outline,
                                    foregroundColor: AppColors.textPrimary,
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                _DoorCommandRow(
                                  enabled: canControlDoor,
                                  busy: isBusy,
                                  pendingAction: commandState.pendingAction,
                                  onPermissionDenied: permissionDeniedFor(
                                    'DOOR_CONTROL',
                                  ),
                                  onClose: () {
                                    unawaited(
                                      _runCommandAndReport(
                                        deviceId: hardwareDeviceId,
                                        action: DeviceCommandAction.closeDoor,
                                      ),
                                    );
                                  },
                                  onStop: () {
                                    unawaited(
                                      _runCommandAndReport(
                                        deviceId: hardwareDeviceId,
                                        action: DeviceCommandAction.stopDoor,
                                      ),
                                    );
                                  },
                                  onOpen: () {
                                    unawaited(
                                      _runCommandAndReport(
                                        deviceId: hardwareDeviceId,
                                        action: DeviceCommandAction.openDoor,
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 18),
                                if (commandState.commandFeedback != null) ...[
                                  _CommandFeedback(
                                    message: _commandFeedbackMessage(
                                      l10n,
                                      commandState.commandFeedback!,
                                    ),
                                    icon: commandState.commandFeedback!.isError
                                        ? Icons.error_outline
                                        : commandState.commandFeedback!.kind ==
                                              DeviceCommandFeedbackKind.sending
                                        ? Icons.sync
                                        : Icons.check_circle_outline,
                                    foregroundColor:
                                        commandState.commandFeedback!.isError
                                        ? AppColors.textPrimary
                                        : AppColors.textMuted,
                                  ),
                                  const SizedBox(height: 12),
                                ] else if (commandState.errorMessage !=
                                    null) ...[
                                  _CommandFeedback(
                                    message: commandState.errorMessage!,
                                    icon: Icons.error_outline,
                                    foregroundColor: AppColors.textPrimary,
                                  ),
                                  const SizedBox(height: 12),
                                ] else if (commandState.infoMessage !=
                                    null) ...[
                                  _CommandFeedback(
                                    message: commandState.infoMessage!,
                                    icon: Icons.check_circle_outline,
                                    foregroundColor: AppColors.textMuted,
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                _QuickActionGrid(
                                  ledEnabled: ledEnabled,
                                  autoCloseEnabled: autoCloseEnabled,
                                  openReminderEnabled: openReminderEnabled,
                                  openReminderMinutes: openReminderMinutes,
                                  partialOpenValueLabel: partialOpenValueLabel,
                                  ledAvailable: canControlLed,
                                  autoCloseAvailable: canUseAutoClose,
                                  partialOpenAvailable: canPartialOpen,
                                  partialOpenSettingAvailable:
                                      canSetPartialOpenLevel,
                                  openReminderAvailable: canUseOpenReminder,
                                  ledPermissionDenied: permissionDeniedFor(
                                    'LED_CONTROL',
                                  ),
                                  autoClosePermissionDenied:
                                      permissionDeniedFor('AUTO_CLOSE'),
                                  openReminderPermissionDenied:
                                      permissionDeniedFor('DOOR_OPEN_REMINDER'),
                                  partialOpenPermissionDenied:
                                      permissionDeniedFor('PARTIAL_OPEN'),
                                  partialOpenSettingPermissionDenied:
                                      permissionDeniedFor(
                                        DeviceCapabilityCode.partialOpenLevel,
                                      ),
                                  busy: isBusy,
                                  settingsBusy:
                                      deviceSettingsState.pendingKey != null,
                                  partialOpenSettingBusy:
                                      deviceCapabilitiesState.loading ||
                                      doorSettingsState.loading ||
                                      deviceSettingsState.loading,
                                  onLedChanged: (enabled) async {
                                    setState(
                                      () => _ledEnabledOverride = enabled,
                                    );
                                    final action = enabled
                                        ? DeviceCommandAction.turnLightOn
                                        : DeviceCommandAction.turnLightOff;
                                    final result = await controller.runAction(
                                      deviceId: hardwareDeviceId,
                                      action: action,
                                    );
                                    _reportSuccessfulCommand(action, result);
                                    if (mounted && !selectedDeviceUsesBle) {
                                      setState(
                                        () => _ledEnabledOverride = null,
                                      );
                                    }
                                  },
                                  onAutoCloseChanged: (enabled) =>
                                      _setBluetoothToggle(
                                        connected: selectedDeviceUsesBle,
                                        bleDeviceId: connectedBleDeviceId,
                                        key: DeviceSettingKey.autoCloseTime,
                                        enabled: enabled,
                                        enabledValue: autoCloseEnabledValue,
                                        allowedValues: autoCloseAllowedValues,
                                        actionLabel:
                                            l10n.deviceCommandAutoCloseTitle,
                                      ),
                                  onOpenReminderChanged: (enabled) =>
                                      _setBluetoothToggle(
                                        connected: selectedDeviceUsesBle,
                                        bleDeviceId: connectedBleDeviceId,
                                        key: DeviceSettingKey.doorOpenReminder,
                                        enabled: enabled,
                                        actionLabel:
                                            l10n.deviceCommandOpenReminderTitle,
                                      ),
                                  onPartialOpen: () {
                                    if (!_requireBluetoothConnection(
                                      connected: selectedDeviceUsesBle,
                                      actionLabel:
                                          l10n.deviceCommandActionPartialOpen,
                                    )) {
                                      return;
                                    }
                                    final reportAction =
                                        _partialOpenReportAction(
                                          ref.read(
                                            deviceCommandControllerProvider,
                                          ),
                                        );
                                    unawaited(
                                      _runCommandAndReport(
                                        deviceId: hardwareDeviceId,
                                        action:
                                            DeviceCommandAction.partialOpenDoor,
                                        reportActionOverride: reportAction,
                                      ),
                                    );
                                  },
                                  onPartialOpenSetting: () =>
                                      _showPartialOpenLevelEditor(
                                        connected: selectedDeviceUsesBle,
                                        bleDeviceId: connectedBleDeviceId,
                                        capability: partialOpenCapability,
                                        currentLevel: partialOpenLevel,
                                      ),
                                  onMoreSettings: () => context.push(
                                    '${DeviceSettingsPage.routePath}'
                                    '?doorId=${Uri.encodeComponent(widget.doorId)}'
                                    '&deviceId=${Uri.encodeComponent(selectedDeviceId)}'
                                    '&bleName=${Uri.encodeComponent(selectedBleName)}'
                                    '&bleDeviceId=${Uri.encodeComponent(connectedBleDeviceId)}',
                                    extra: settingsCapabilityScope,
                                  ),
                                ),
                                const SizedBox(height: 22),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFBoxScrollableContent({
    required DeviceCommandState commandState,
    required DoorControlMode controlMode,
    required DoorDetail doorDetail,
    required double? doorPositionPercent,
    required String hardwareDeviceId,
    required String selectedDeviceId,
    required bool selectedDeviceUsesBle,
    required bool isBusy,
    required bool canControlDoor,
    required VoidCallback? onPermissionDenied,
    required TextTheme textTheme,
    required AppLocalizations l10n,
  }) {
    final commandFeedback = commandState.commandFeedback;

    return CustomScrollView(
      key: const PageStorageKey<String>('device-command-fbox-scroll'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacingTokens.deviceControlPageHorizontal,
          ),
          sliver: SliverToBoxAdapter(
            child: Column(
              children: [
                _DoorHeroImage(
                  doorType: DoorType.fromWireValue(doorDetail.doorType),
                  doorTypeWireValue: doorDetail.doorType,
                  positionPercent: doorPositionPercent ?? 0,
                  logger: ref.read(appLoggerProvider),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    _doorStateLabel(
                      l10n,
                      realtimeStatus: commandState.doorRealtimeState?.status,
                      fallbackState: doorDetail.doorState,
                      positionPercent: doorPositionPercent,
                    ),
                    style: AppTextTokens.deviceControlDoorState(textTheme),
                  ),
                ),
                const SizedBox(
                  height: AppSpacingTokens.deviceControlFBoxStateToControls,
                ),
                if (commandState.doorDetailErrorMessage != null) ...[
                  _CommandFeedback(
                    message: commandState.doorDetailErrorMessage!,
                    icon: Icons.error_outline,
                    foregroundColor: AppColors.textPrimary,
                  ),
                  const SizedBox(height: 12),
                ],
                if (controlMode == DoorControlMode.pb)
                  _FBoxPbControl(
                    key: const ValueKey<String>('fbox-device-command-pb'),
                    tooltip: l10n.deviceCommandActionPb,
                    pending:
                        commandState.pendingAction == DeviceCommandAction.pb,
                    onPressed: canControlDoor && !isBusy
                        ? () => unawaited(
                            _runCommandAndReport(
                              deviceId: hardwareDeviceId,
                              action: DeviceCommandAction.pb,
                            ),
                          )
                        : null,
                    onDisabled: !canControlDoor && !isBusy
                        ? onPermissionDenied
                        : null,
                  )
                else
                  _DoorCommandRow(
                    key: const ValueKey<String>('fbox-device-command-osc'),
                    enabled: canControlDoor,
                    busy: isBusy,
                    pendingAction: commandState.pendingAction,
                    onPermissionDenied: onPermissionDenied,
                    buttonSize: AppSpacingTokens.fBoxWiringTestControlSize,
                    buttonIconSize:
                        AppSpacingTokens.fBoxWiringTestControlIconSize,
                    buttonRadius: AppShapeTokens.fBoxWiringTestControlRadius,
                    gap: AppSpacingTokens.fBoxWiringTestControlGap,
                    onClose: () {
                      unawaited(
                        _runCommandAndReport(
                          deviceId: hardwareDeviceId,
                          action: DeviceCommandAction.closeDoor,
                        ),
                      );
                    },
                    onStop: () {
                      unawaited(
                        _runCommandAndReport(
                          deviceId: hardwareDeviceId,
                          action: DeviceCommandAction.stopDoor,
                        ),
                      );
                    },
                    onOpen: () {
                      unawaited(
                        _runCommandAndReport(
                          deviceId: hardwareDeviceId,
                          action: DeviceCommandAction.openDoor,
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 18),
                if (commandFeedback != null) ...[
                  _CommandFeedback(
                    message: _commandFeedbackMessage(l10n, commandFeedback),
                    icon: commandFeedback.isError
                        ? Icons.error_outline
                        : commandFeedback.kind ==
                              DeviceCommandFeedbackKind.sending
                        ? Icons.sync
                        : Icons.check_circle_outline,
                    foregroundColor: commandFeedback.isError
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                  ),
                ] else if (commandState.errorMessage != null) ...[
                  _CommandFeedback(
                    message: commandState.errorMessage!,
                    icon: Icons.error_outline,
                    foregroundColor: AppColors.textPrimary,
                  ),
                ] else if (commandState.infoMessage != null) ...[
                  _CommandFeedback(
                    message: commandState.infoMessage!,
                    icon: Icons.check_circle_outline,
                    foregroundColor: AppColors.textMuted,
                  ),
                ],
              ],
            ),
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacingTokens.deviceControlPageHorizontal,
              AppSpacingTokens.deviceControlFBoxControlsToEntries,
              AppSpacingTokens.deviceControlPageHorizontal,
              AppSpacingTokens.deviceControlFBoxContentBottom,
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: _FBoxEntryRow(
                busy: isBusy,
                onControlMethod: () {
                  if (!_requireBluetoothConnection(
                    connected: selectedDeviceUsesBle,
                    actionLabel: l10n.deviceCommandControlMethod,
                  )) {
                    return;
                  }
                  unawaited(_openFBoxControlMethod(deviceId: selectedDeviceId));
                },
                onAboutDevice: () => context.push(
                  AboutDevicePage.location(
                    doorId: widget.doorId,
                    deviceId: selectedDeviceId,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openFBoxControlMethod({required String deviceId}) async {
    await context.push<String>(
      FBoxWiringTestRoute.location(
        doorId: widget.doorId,
        deviceId: deviceId,
        onboardingFlowId: widget.onboardingFlowId,
        entryPoint: FBoxWiringTestEntryPoint.deviceCommand,
      ),
    );
    if (!mounted) {
      return;
    }
    await _loadDoorDetail(preferredDeviceId: deviceId);
  }

  bool _requireBluetoothConnection({
    required bool connected,
    required String actionLabel,
  }) {
    if (connected) {
      return true;
    }
    AppToast.info(
      context,
      AppLocalizations.of(context).deviceCommandBluetoothRequired(actionLabel),
    );
    return false;
  }

  DeviceCapabilityOption? _capabilityOptionForValue(
    DeviceCapability? capability,
    int? value,
  ) {
    if (capability == null || value == null) {
      return null;
    }
    for (final option in capability.options) {
      if (option.value == value) {
        return option;
      }
    }
    return null;
  }

  Future<void> _showPartialOpenLevelEditor({
    required bool connected,
    required String bleDeviceId,
    required DeviceCapability? capability,
    required int? currentLevel,
  }) async {
    final l10n = AppLocalizations.of(context);
    if (!_requireBluetoothConnection(
      connected: connected,
      actionLabel: l10n.deviceSettingsPartialOpenHeight,
    )) {
      return;
    }
    if (capability == null || capability.options.isEmpty) {
      AppToast.info(context, l10n.deviceCommandPartialOpenSettingUnavailable);
      return;
    }

    final initialValue =
        capability.options.any((option) => option.value == currentLevel)
        ? currentLevel!
        : capability.options.first.value;
    final value = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DeviceCapabilityOptionsSheet(
        title: l10n.deviceSettingsPartialOpenHeight,
        options: capability.options,
        unit: capability.unit,
        initialValue: initialValue,
      ),
    );
    if (value == null || !mounted || value == currentLevel) {
      return;
    }

    final saved = await ref
        .read(deviceSettingsControllerProvider(bleDeviceId).notifier)
        .setRawValue(DeviceSettingKey.partialOpen, value);
    if (!mounted) {
      return;
    }
    if (!saved) {
      AppToast.error(context, l10n.deviceCommandPartialOpenSettingFailed);
      return;
    }
    ref
        .read(doorSettingsControllerProvider(widget.doorId).notifier)
        .updateCurrentValue(DeviceCapabilityCode.partialOpen, value);
    _reportSuccessfulOperation(
      action: OperationReportAction.partialOpenChanged,
      operationSource: OperationReportSource.bluetooth,
    );
  }

  Future<void> _setBluetoothToggle({
    required bool connected,
    required String bleDeviceId,
    required DeviceSettingKey key,
    required bool enabled,
    int? enabledValue,
    Iterable<int>? allowedValues,
    required String actionLabel,
  }) async {
    if (!_requireBluetoothConnection(
      connected: connected,
      actionLabel: actionLabel,
    )) {
      return;
    }

    setState(() {
      if (key == DeviceSettingKey.autoCloseTime) {
        _autoCloseEnabledOverride = enabled;
      } else {
        _openReminderEnabledOverride = enabled;
      }
    });
    final saved = await ref
        .read(deviceSettingsControllerProvider(bleDeviceId).notifier)
        .setEnabled(
          key,
          enabled: enabled,
          enabledValue: enabledValue,
          allowedValues: allowedValues,
        );
    if (!mounted) {
      return;
    }
    if (!saved) {
      setState(() {
        if (key == DeviceSettingKey.autoCloseTime) {
          _autoCloseEnabledOverride = null;
        } else {
          _openReminderEnabledOverride = null;
        }
      });
      return;
    }
    final appliedValue = ref
        .read(deviceSettingsControllerProvider(bleDeviceId))
        .values[key]
        ?.rawValue;
    ref
        .read(doorSettingsControllerProvider(widget.doorId).notifier)
        .updateCurrentValue(
          key.capabilityCode,
          appliedValue ??
              (enabled ? enabledValue ?? key.defaultEnabledValue : 0),
        );
    final reportAction = switch (key) {
      DeviceSettingKey.autoCloseTime => OperationReportAction.autoCloseToggle,
      DeviceSettingKey.doorOpenReminder =>
        OperationReportAction.doorOpenReminderToggle,
      _ => null,
    };
    if (reportAction != null) {
      _reportSuccessfulOperation(
        action: reportAction,
        operationSource: OperationReportSource.bluetooth,
      );
    }
  }

  Future<void> _runCommandAndReport({
    required String deviceId,
    required DeviceCommandAction action,
    OperationReportAction? reportActionOverride,
  }) async {
    final result = await _controller.runAction(
      deviceId: deviceId,
      action: action,
    );
    _reportSuccessfulCommand(
      action,
      result,
      reportActionOverride: reportActionOverride,
    );
  }

  void _reportSuccessfulCommand(
    DeviceCommandAction action,
    DeviceCommandExecutionResult? result, {
    OperationReportAction? reportActionOverride,
  }) {
    if (!mounted || result?.succeeded != true) {
      return;
    }
    final reportAction =
        reportActionOverride ??
        switch (action) {
          DeviceCommandAction.openDoor => OperationReportAction.open,
          DeviceCommandAction.closeDoor => OperationReportAction.close,
          DeviceCommandAction.stopDoor => OperationReportAction.stop,
          DeviceCommandAction.partialOpenDoor =>
            OperationReportAction.partialOpen,
          DeviceCommandAction.turnLightOn => OperationReportAction.ledOn,
          DeviceCommandAction.turnLightOff => OperationReportAction.ledOff,
          DeviceCommandAction.pb => null,
        };
    final operationSource = switch (result!.transport) {
      DeviceCommandTransport.bluetooth => OperationReportSource.bluetooth,
      DeviceCommandTransport.app => OperationReportSource.app,
      null => null,
    };
    if (reportAction == null || operationSource == null) {
      return;
    }
    _reportSuccessfulOperation(
      action: reportAction,
      operationSource: operationSource,
    );
  }

  OperationReportAction _partialOpenReportAction(
    DeviceCommandState commandState,
  ) {
    final realtimeStatus = commandState.doorRealtimeState?.status;
    final isClosed = realtimeStatus != null
        ? realtimeStatus == DoorRealtimeStatus.closed
        : commandState.doorDetail?.doorState == DoorState.closed;
    return isClosed
        ? OperationReportAction.partialOpen
        : OperationReportAction.close;
  }

  void _reportSuccessfulOperation({
    required OperationReportAction action,
    required OperationReportSource operationSource,
  }) {
    if (!mounted) {
      return;
    }
    unawaited(
      ref
          .read(operationReportControllerProvider)
          .report(
            doorId: widget.doorId,
            action: action,
            operationSource: operationSource,
          ),
    );
  }

  String _doorStateLabel(
    AppLocalizations l10n, {
    required DoorRealtimeStatus? realtimeStatus,
    required DoorState? fallbackState,
    required double? positionPercent,
  }) {
    final stateLabel = realtimeStatus != null
        ? switch (realtimeStatus) {
            DoorRealtimeStatus.open => l10n.homeDoorStateOpen,
            DoorRealtimeStatus.closed => l10n.homeDoorStateClosed,
            DoorRealtimeStatus.stopped =>
              positionPercent != null && positionPercent > 0
                  ? l10n.homeDoorStateOpen
                  : l10n.homeDoorStateStopped,
            DoorRealtimeStatus.opening => l10n.homeDoorStateOpening,
            DoorRealtimeStatus.closing => l10n.homeDoorStateClosing,
            DoorRealtimeStatus.running => l10n.deviceCommandDoorStateRunning,
            DoorRealtimeStatus.unknown => l10n.homeDoorStateUnknown,
          }
        : switch (fallbackState) {
            DoorState.open => l10n.homeDoorStateOpen,
            DoorState.opening => l10n.homeDoorStateOpening,
            DoorState.stopped => l10n.homeDoorStateStopped,
            DoorState.closing => l10n.homeDoorStateClosing,
            DoorState.closed => l10n.homeDoorStateClosed,
            DoorState.unknown || null => l10n.homeDoorStateUnknown,
          };
    if (positionPercent == null) {
      return stateLabel;
    }
    final roundedPositionPercent = positionPercent.clamp(0, 100).round();
    if (roundedPositionPercent == 0 || roundedPositionPercent == 100) {
      return stateLabel;
    }
    return l10n.deviceCommandDoorStateWithPercent(
      stateLabel,
      roundedPositionPercent,
    );
  }

  String _commandFeedbackMessage(
    AppLocalizations l10n,
    DeviceCommandFeedback feedback,
  ) {
    final action = switch (feedback.action) {
      DeviceCommandAction.openDoor => l10n.deviceCommandActionOpen,
      DeviceCommandAction.closeDoor => l10n.deviceCommandActionClose,
      DeviceCommandAction.stopDoor => l10n.deviceCommandActionStop,
      DeviceCommandAction.partialOpenDoor =>
        l10n.deviceCommandActionPartialOpen,
      DeviceCommandAction.turnLightOn => l10n.deviceCommandActionLedOn,
      DeviceCommandAction.turnLightOff => l10n.deviceCommandActionLedOff,
      DeviceCommandAction.pb => l10n.deviceCommandActionPb,
    };
    return switch (feedback.kind) {
      DeviceCommandFeedbackKind.sending => l10n.deviceCommandSending(
        action,
        feedback.action.controlCodeLabel,
      ),
      DeviceCommandFeedbackKind.succeeded => l10n.deviceCommandSucceeded(
        action,
        feedback.action.controlCodeLabel,
      ),
      DeviceCommandFeedbackKind.rejected => l10n.deviceCommandRejected(
        action,
        feedback.action.controlCodeLabel,
      ),
      DeviceCommandFeedbackKind.requiresBluetooth =>
        l10n.deviceCommandBluetoothRequired(action),
      DeviceCommandFeedbackKind.remoteFailed => l10n.deviceCommandRemoteFailed(
        action,
      ),
      DeviceCommandFeedbackKind.remoteUnconfirmed =>
        l10n.deviceCommandRemoteUnconfirmed(action),
      DeviceCommandFeedbackKind.remoteTimeout =>
        l10n.deviceCommandRemoteTimeout(action),
      DeviceCommandFeedbackKind.networkFailure =>
        l10n.deviceCommandNetworkFailure(action),
    };
  }
}

class _DeviceCommandLoadingPage extends StatelessWidget {
  const _DeviceCommandLoadingPage({required this.semanticsLabel});

  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey<String>('device-command-loading'),
      backgroundColor: AppColors.backgroundPrimary,
      body: Center(
        child: Semantics(
          label: semanticsLabel,
          child: const CircularProgressIndicator(),
        ),
      ),
    );
  }
}

class _DeviceCommandLoadFailurePage extends StatelessWidget {
  const _DeviceCommandLoadFailurePage({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      key: const ValueKey<String>('device-command-load-failure'),
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Semantics(
              liveRegion: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.deviceCommandLoadFailed,
                    textAlign: TextAlign.center,
                    style: AppTextTokens.deviceControlLoadError(
                      Theme.of(context).textTheme,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: onRetry,
                    child: Text(l10n.deviceCommandRetry),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

abstract final class _DeviceCommandAssetPaths {
  static const videoActive =
      'assets/icons/device_control/device_command_video_active.png';
  static const videoInactive =
      'assets/icons/device_control/device_command_video_inactive.png';
  static const dongleActive =
      'assets/icons/device_control/device_command_dongle_active.png';
  static const dongleInactive =
      'assets/icons/device_control/device_command_dongle_inactive.png';
  static const fboxActive =
      'assets/icons/device_control/device_command_fbox_active.png';
  static const fboxInactive =
      'assets/icons/device_control/device_command_fbox_inactive.png';
  static const evoActive =
      'assets/icons/device_control/device_command_evo_active.png';
  static const evoInactive =
      'assets/icons/device_control/device_command_evo_inactive.png';
  static const openerActive =
      'assets/icons/device_control/device_command_opener_active.png';
  static const openerInactive =
      'assets/icons/device_control/device_command_opener_inactive.png';
  static const bluetoothActive =
      'assets/icons/device_control/device_command_bluetooth_active_placeholder.png';
  static const bluetoothInactive =
      'assets/icons/device_control/device_command_bluetooth_inactive_placeholder.png';
  static const wifiActive =
      'assets/icons/device_control/device_command_wifi_active_placeholder.png';
  static const wifiInactive =
      'assets/icons/device_control/device_command_wifi_inactive_placeholder.png';
  static const led =
      'assets/icons/device_control/device_command_led_placeholder.png';
  static const autoClose =
      'assets/icons/device_control/device_command_auto_close_placeholder.png';
  static const partialOpen =
      'assets/icons/device_control/device_command_partial_open_placeholder.png';
  static const moreSetting =
      'assets/icons/device_control/device_command_more_setting_placeholder.png';
  static const openReminder =
      'assets/icons/device_settings/device_settings_door_open_reminder_icon.png';
}

class _DeviceConnectionStrip extends StatelessWidget {
  const _DeviceConnectionStrip({
    required this.devices,
    required this.connectionStatuses,
    required this.selectedDeviceId,
    required this.onDeviceTap,
  });

  final List<DoorDevice> devices;
  final Map<String, DeviceBleConnectionStatus> connectionStatuses;
  final String? selectedDeviceId;
  final ValueChanged<DoorDevice> onDeviceTap;

  DoorDevice? _deviceFor(String deviceType) {
    for (final device in devices) {
      if (device.deviceType.trim().toLowerCase() == deviceType) {
        return device;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 10),
      child: SizedBox(
        height: 36,
        child: Row(
          children: [
            _group(
              'dongle',
              _DeviceCommandAssetPaths.dongleActive,
              _DeviceCommandAssetPaths.dongleInactive,
            ),
            _group(
              'fbox',
              _DeviceCommandAssetPaths.fboxActive,
              _DeviceCommandAssetPaths.fboxInactive,
            ),
            _group(
              'opener',
              _DeviceCommandAssetPaths.openerActive,
              _DeviceCommandAssetPaths.openerInactive,
            ),
            _group(
              'video',
              _DeviceCommandAssetPaths.videoActive,
              _DeviceCommandAssetPaths.videoInactive,
            ),
            _group(
              'evolution',
              _DeviceCommandAssetPaths.evoActive,
              _DeviceCommandAssetPaths.evoInactive,
            ),
          ],
        ),
      ),
    );
  }

  Widget _group(String type, String activeAsset, String inactiveAsset) {
    final device = _deviceFor(type);
    final isActive = device != null;
    final isSelected = device?.deviceId == selectedDeviceId;
    final isBleConnected =
        device != null &&
        connectionStatuses[device.deviceId] ==
            DeviceBleConnectionStatus.connected;
    return Expanded(
      child: _ConnectionGroup(
        key: ValueKey<String>('connection-device-$type'),
        deviceActive: isActive,
        activeDeviceIconAsset: activeAsset,
        inactiveDeviceIconAsset: inactiveAsset,
        showBluetooth: type != 'video',
        bluetoothActive: isBleConnected,
        wifiActive: device?.isWifiConnected ?? false,
        hasConnectionBorder: isSelected,
        onTap: isActive ? () => onDeviceTap(device) : null,
      ),
    );
  }
}

class _ConnectionGroup extends StatelessWidget {
  const _ConnectionGroup({
    required this.deviceActive,
    required this.activeDeviceIconAsset,
    required this.inactiveDeviceIconAsset,
    required this.showBluetooth,
    required this.bluetoothActive,
    required this.wifiActive,
    required this.hasConnectionBorder,
    required this.onTap,
    super.key,
  });

  final bool deviceActive;
  final String activeDeviceIconAsset;
  final String inactiveDeviceIconAsset;
  final bool showBluetooth;
  final bool bluetoothActive;
  final bool wifiActive;
  final bool hasConnectionBorder;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: hasConnectionBorder
              ? Border.all(color: AppColors.deviceControlPrimaryAction)
              : null,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              children: [
                _DeviceControlAssetIcon(
                  assetPath: deviceActive
                      ? activeDeviceIconAsset
                      : inactiveDeviceIconAsset,
                ),
                if (showBluetooth) ...[
                  const SizedBox(width: 4),
                  _DeviceControlAssetIcon(
                    assetPath: bluetoothActive
                        ? _DeviceCommandAssetPaths.bluetoothActive
                        : _DeviceCommandAssetPaths.bluetoothInactive,
                  ),
                ],
                const SizedBox(width: 6),
                _DeviceControlAssetIcon(
                  assetPath: wifiActive
                      ? _DeviceCommandAssetPaths.wifiActive
                      : _DeviceCommandAssetPaths.wifiInactive,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CycleSummary extends StatelessWidget {
  const _CycleSummary({
    required this.operatedCycles,
    required this.remainingCycles,
    required this.textTheme,
  });

  final int? operatedCycles;
  final int? remainingCycles;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Row(
        children: [
          Expanded(
            child: _CycleMetric(
              label: AppLocalizations.of(context).deviceCommandOperatedCycles,
              value: operatedCycles?.toString() ?? '100',
              textTheme: textTheme,
            ),
          ),
          Padding(
            padding: EdgeInsetsGeometry.only(top: 10, bottom: 10),
            child: VerticalDivider(
              width: 58,
              thickness: 1,
              color: AppColors.deviceControlDivider,
            ),
          ),
          Expanded(
            child: _CycleMetric(
              label: AppLocalizations.of(context).deviceCommandRemainingCycles,
              value: remainingCycles?.toString() ?? '4900',
              textTheme: textTheme,
            ),
          ),
          const _CommandVideoButton(),
        ],
      ),
    );
  }
}

class _CycleMetric extends StatelessWidget {
  const _CycleMetric({
    required this.label,
    required this.value,
    required this.textTheme,
  });

  final String label;
  final String value;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            maxLines: 1,
            style: AppTextTokens.deviceControlMetricLabel(textTheme),
          ),
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            maxLines: 1,
            style: AppTextTokens.deviceControlMetricValue(textTheme),
          ),
        ),
      ],
    );
  }
}

class _CommandVideoButton extends StatelessWidget {
  const _CommandVideoButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      margin: const EdgeInsets.only(left: 8),
      decoration: const BoxDecoration(
        color: AppColors.deviceControlPanel,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        tooltip: AppLocalizations.of(context).deviceCommandVideoTooltip,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 30, height: 30),
        onPressed: () {},
        icon: const _DeviceControlAssetIcon(
          assetPath: _DeviceCommandAssetPaths.videoActive,
        ),
      ),
    );
  }
}

class _DeviceControlAssetIcon extends StatelessWidget {
  const _DeviceControlAssetIcon({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
    );
  }
}

class _DoorHeroImage extends StatefulWidget {
  const _DoorHeroImage({
    required this.doorType,
    required this.doorTypeWireValue,
    required this.positionPercent,
    required this.logger,
  });

  final DoorType doorType;
  final int? doorTypeWireValue;
  final double positionPercent;
  final AppLogger logger;

  @override
  State<_DoorHeroImage> createState() => _DoorHeroImageState();
}

class _DoorHeroImageState extends State<_DoorHeroImage> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precacheFrames();
    _logVisualTarget();
  }

  @override
  void didUpdateWidget(covariant _DoorHeroImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.doorType != widget.doorType) {
      _precacheFrames();
    }
    if (oldWidget.doorType != widget.doorType ||
        oldWidget.doorTypeWireValue != widget.doorTypeWireValue ||
        oldWidget.positionPercent != widget.positionPercent) {
      _logVisualTarget();
    }
  }

  void _precacheFrames() {
    final assets = _DoorHeroAssetPaths.forType(widget.doorType);
    for (final assetPath in assets.assetPaths) {
      unawaited(
        precacheImage(
          AssetImage(assetPath),
          context,
          onError: (error, stackTrace) {},
        ),
      );
    }
  }

  void _logVisualTarget() {
    final assets = _DoorHeroAssetPaths.forType(widget.doorType);
    final positionPercent = widget.positionPercent.clamp(0, 100).toDouble();
    widget.logger.info(
      'device_door_visual_target',
      tag: AppLogTag.ble,
      context: {
        'doorType': widget.doorType.name,
        'doorTypeWireValue': widget.doorTypeWireValue,
        'doorTypeResolved': widget.doorTypeWireValue != null,
        'positionPercent': positionPercent,
        'frameIndex': assets.frameIndexForPercent(positionPercent),
        'frameCount': assets.frameCount,
        'assetPath': assets.assetPathForPercent(positionPercent),
        'animationEnabled': assets.frameCount > 1,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final assets = _DoorHeroAssetPaths.forType(widget.doorType);
    final positionPercent = widget.positionPercent.clamp(0, 100).toDouble();
    final assetPath = assets.assetPathForPercent(positionPercent);
    return AspectRatio(
      aspectRatio: 1.95,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26),
        child: KeyedSubtree(
          key: const ValueKey<String>('door-hero-frame'),
          child: Image.asset(
            assetPath,
            fit: BoxFit.contain,
            gaplessPlayback: true,
            errorBuilder: (context, error, stackTrace) {
              return DecoratedBox(
                decoration: const BoxDecoration(
                  color: AppColors.backgroundPrimary,
                ),
                child: Center(
                  child: Image.asset(
                    assets.fallbackAssetPath,
                    width: 180,
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DoorHeroAssetPaths {
  const _DoorHeroAssetPaths._({
    required this.fallbackAssetPath,
    required this.frameAssetPrefix,
    required this.frameCount,
  });

  final String fallbackAssetPath;
  final String frameAssetPrefix;
  final int frameCount;

  Iterable<String> get assetPaths sync* {
    for (var frame = 1; frame <= frameCount; frame += 1) {
      yield '$frameAssetPrefix${frame.toString().padLeft(2, '0')}.png';
    }
  }

  String assetPathForPercent(double percent) {
    final frame = frameIndexForPercent(percent);
    return '$frameAssetPrefix${frame.toString().padLeft(2, '0')}.png';
  }

  int frameIndexForPercent(double percent) {
    if (frameCount == 1) {
      return 1;
    }
    return ((percent.clamp(0, 100) / 100) * (frameCount - 1)).round() + 1;
  }

  static _DoorHeroAssetPaths forType(DoorType doorType) {
    return switch (doorType) {
      DoorType.garage => const _DoorHeroAssetPaths._(
        frameAssetPrefix:
            'assets/images/device_control/device_control_garage_door_',
        frameCount: 20,
        fallbackAssetPath:
            'assets/images/device_control/device_control_garage_door_placeholder.png',
      ),
      DoorType.roller => const _DoorHeroAssetPaths._(
        frameAssetPrefix:
            'assets/images/device_control/device_control_roller_door_',
        frameCount: 20,
        fallbackAssetPath:
            'assets/images/device_control/device_control_roller_door_placeholder.png',
      ),
      DoorType.industrial => const _DoorHeroAssetPaths._(
        frameAssetPrefix:
            'assets/images/device_control/device_control_industrial_door_',
        frameCount: 20,
        fallbackAssetPath:
            'assets/images/device_control/device_control_industrial_door_placeholder.png',
      ),
      DoorType.swing => const _DoorHeroAssetPaths._(
        frameAssetPrefix:
            'assets/images/device_control/device_control_swing_door_',
        frameCount: 20,
        fallbackAssetPath:
            'assets/icons/add_device/add_new_doors_swing_gate.png',
      ),
      DoorType.sliding => const _DoorHeroAssetPaths._(
        frameAssetPrefix:
            'assets/images/device_control/device_control_sliding_door_',
        frameCount: 20,
        fallbackAssetPath:
            'assets/images/device_control/device_control_sliding_door_placeholder.png',
      ),
    };
  }
}

class _FBoxVideoHeader extends StatelessWidget {
  const _FBoxVideoHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacingTokens.deviceControlFBoxHeaderHeight,
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.only(
            top: AppSpacingTokens.deviceControlFBoxHeaderActionTop,
            right: AppSpacingTokens.deviceControlPageHorizontal,
          ),
          child: const _CommandVideoButton(),
        ),
      ),
    );
  }
}

class _DoorCommandRow extends StatelessWidget {
  const _DoorCommandRow({
    super.key,
    required this.enabled,
    required this.busy,
    required this.pendingAction,
    this.onPermissionDenied,
    required this.onClose,
    required this.onStop,
    required this.onOpen,
    this.buttonSize = AppSpacingTokens.deviceControlCommandButtonSize,
    this.buttonIconSize = AppSpacingTokens.deviceControlCommandButtonIconSize,
    this.buttonRadius = AppShapeTokens.deviceControlCommandButtonRadius,
    this.gap = 34,
  });

  final bool enabled;
  final bool busy;
  final DeviceCommandAction? pendingAction;
  final VoidCallback? onPermissionDenied;
  final VoidCallback onClose;
  final VoidCallback onStop;
  final VoidCallback onOpen;
  final double buttonSize;
  final double buttonIconSize;
  final double buttonRadius;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FlinxDoorCommandButton(
          tooltip: AppLocalizations.of(context).deviceCommandCloseTooltip,
          icon: Icons.keyboard_arrow_down,
          pending: pendingAction == DeviceCommandAction.closeDoor,
          size: buttonSize,
          iconSize: buttonIconSize,
          radius: buttonRadius,
          onPressed: enabled && !busy ? onClose : null,
          onDisabled: !enabled && !busy ? onPermissionDenied : null,
        ),
        SizedBox(width: gap),
        FlinxDoorCommandButton(
          tooltip: AppLocalizations.of(context).deviceCommandStopTooltip,
          icon: Icons.pause,
          pending: pendingAction == DeviceCommandAction.stopDoor,
          size: buttonSize,
          iconSize: buttonIconSize,
          radius: buttonRadius,
          onPressed: enabled && !busy ? onStop : null,
          onDisabled: !enabled && !busy ? onPermissionDenied : null,
        ),
        SizedBox(width: gap),
        FlinxDoorCommandButton(
          tooltip: AppLocalizations.of(context).deviceCommandOpenTooltip,
          icon: Icons.keyboard_arrow_up,
          pending: pendingAction == DeviceCommandAction.openDoor,
          size: buttonSize,
          iconSize: buttonIconSize,
          radius: buttonRadius,
          onPressed: enabled && !busy ? onOpen : null,
          onDisabled: !enabled && !busy ? onPermissionDenied : null,
        ),
      ],
    );
  }
}

class _FBoxPbControl extends StatelessWidget {
  const _FBoxPbControl({
    super.key,
    required this.tooltip,
    required this.onPressed,
    this.onDisabled,
    required this.pending,
  });

  final String tooltip;
  final VoidCallback? onPressed;
  final VoidCallback? onDisabled;
  final bool pending;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: tooltip,
      onTap: onPressed ?? onDisabled,
      child: ExcludeSemantics(
        child: SizedBox(
          width: AppSpacingTokens.fBoxWiringTestPbControlSize,
          height: AppSpacingTokens.fBoxWiringTestPbControlSize,
          child: FilledButton(
            onPressed: onPressed ?? onDisabled,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: AppColors.textHint,
              elevation: 0,
              padding: EdgeInsets.zero,
              shape: const CircleBorder(),
            ),
            child: pending
                ? const CircularProgressIndicator(color: AppColors.textHint)
                : Image.asset(
                    FlinxFBoxControlAssetPaths.pbControl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.image_not_supported_outlined,
                      color: AppColors.textHint,
                      size: 96,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _FBoxEntryRow extends StatelessWidget {
  const _FBoxEntryRow({
    required this.busy,
    required this.onControlMethod,
    required this.onAboutDevice,
  });

  final bool busy;
  final VoidCallback onControlMethod;
  final VoidCallback onAboutDevice;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      height: AppSpacingTokens.deviceControlFBoxEntryHeight,
      child: Row(
        children: [
          Expanded(
            child: _FBoxEntryCard(
              key: const ValueKey<String>('fbox-control-method-action'),
              icon: Icons.tune_outlined,
              label: l10n.deviceCommandControlMethod,
              textTheme: textTheme,
              onTap: busy ? null : onControlMethod,
            ),
          ),
          const SizedBox(width: AppSpacingTokens.deviceControlFBoxEntryGap),
          Expanded(
            child: _FBoxEntryCard(
              key: const ValueKey<String>('fbox-about-device-action'),
              assetPath: DeviceSettingsAssetPaths.aboutDevice,
              icon: Icons.info_outline,
              label: l10n.deviceSettingsAboutDevice,
              textTheme: textTheme,
              onTap: busy ? null : onAboutDevice,
            ),
          ),
        ],
      ),
    );
  }
}

class _FBoxEntryCard extends StatelessWidget {
  const _FBoxEntryCard({
    super.key,
    required this.icon,
    required this.label,
    required this.textTheme,
    required this.onTap,
    this.assetPath,
  });

  final String? assetPath;
  final IconData icon;
  final String label;
  final TextTheme textTheme;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _ControlCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacingTokens.deviceControlFBoxEntryHorizontalPadding,
        vertical: AppSpacingTokens.deviceControlFBoxEntryVerticalPadding,
      ),
      child: Row(
        children: [
          SizedBox(
            width: AppSpacingTokens.deviceControlFBoxEntryIconSize,
            height: AppSpacingTokens.deviceControlFBoxEntryIconSize,
            child: assetPath == null
                ? Icon(icon, color: AppColors.textPrimary)
                : Image.asset(
                    assetPath!,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(icon, color: AppColors.textPrimary),
                  ),
          ),
          const SizedBox(width: AppSpacingTokens.deviceControlFBoxEntryIconGap),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextTokens.deviceControlQuickActionTitle(textTheme),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommandFeedback extends StatelessWidget {
  const _CommandFeedback({
    required this.message,
    required this.icon,
    required this.foregroundColor,
  });

  final String message;
  final IconData icon;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.deviceControlPanel,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: foregroundColor, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: foregroundColor,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionGrid extends StatelessWidget {
  const _QuickActionGrid({
    required this.ledEnabled,
    required this.autoCloseEnabled,
    required this.openReminderEnabled,
    required this.openReminderMinutes,
    required this.partialOpenValueLabel,
    required this.ledAvailable,
    required this.autoCloseAvailable,
    required this.partialOpenAvailable,
    required this.partialOpenSettingAvailable,
    required this.openReminderAvailable,
    required this.ledPermissionDenied,
    required this.autoClosePermissionDenied,
    required this.openReminderPermissionDenied,
    required this.partialOpenPermissionDenied,
    required this.partialOpenSettingPermissionDenied,
    required this.busy,
    required this.settingsBusy,
    required this.partialOpenSettingBusy,
    required this.onLedChanged,
    required this.onAutoCloseChanged,
    required this.onOpenReminderChanged,
    required this.onPartialOpen,
    required this.onPartialOpenSetting,
    required this.onMoreSettings,
  });

  final bool ledEnabled;
  final bool autoCloseEnabled;
  final bool openReminderEnabled;
  final int openReminderMinutes;
  final String? partialOpenValueLabel;
  final bool ledAvailable;
  final bool autoCloseAvailable;
  final bool partialOpenAvailable;
  final bool partialOpenSettingAvailable;
  final bool openReminderAvailable;
  final VoidCallback? ledPermissionDenied;
  final VoidCallback? autoClosePermissionDenied;
  final VoidCallback? openReminderPermissionDenied;
  final VoidCallback? partialOpenPermissionDenied;
  final VoidCallback? partialOpenSettingPermissionDenied;
  final bool busy;
  final bool settingsBusy;
  final bool partialOpenSettingBusy;
  final ValueChanged<bool> onLedChanged;
  final ValueChanged<bool> onAutoCloseChanged;
  final ValueChanged<bool> onOpenReminderChanged;
  final VoidCallback onPartialOpen;
  final VoidCallback onPartialOpenSetting;
  final VoidCallback onMoreSettings;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      height: 270,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: _LedActionCard(
                    enabled: ledEnabled,
                    available: ledAvailable,
                    busy: busy,
                    textTheme: textTheme,
                    onChanged: onLedChanged,
                    onDisabled: !ledAvailable && !busy
                        ? ledPermissionDenied
                        : null,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: _ToggleActionCard(
                    switchKey: const ValueKey<String>('auto-close-switch'),
                    iconAssetPath: _DeviceCommandAssetPaths.autoClose,
                    title: AppLocalizations.of(
                      context,
                    ).deviceCommandAutoCloseTitle,
                    enabled: autoCloseEnabled,
                    available: autoCloseAvailable,
                    busy: busy || settingsBusy,
                    textTheme: textTheme,
                    onChanged: onAutoCloseChanged,
                    onDisabled: !autoCloseAvailable && !busy && !settingsBusy
                        ? autoClosePermissionDenied
                        : null,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: _ToggleActionCard(
                    key: const ValueKey<String>('open-reminder-action'),
                    switchKey: const ValueKey<String>('open-reminder-switch'),
                    iconAssetPath: _DeviceCommandAssetPaths.openReminder,
                    title: AppLocalizations.of(
                      context,
                    ).deviceCommandOpenReminderTitle,
                    subtitle: AppLocalizations.of(
                      context,
                    ).deviceCommandMinutes(openReminderMinutes),
                    enabled: openReminderEnabled,
                    available: openReminderAvailable,
                    busy: busy || settingsBusy,
                    textTheme: textTheme,
                    onChanged: onOpenReminderChanged,
                    onDisabled: !openReminderAvailable && !busy && !settingsBusy
                        ? openReminderPermissionDenied
                        : null,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  flex: 140,
                  child: _PartialOpenCard(
                    valueLabel: partialOpenValueLabel,
                    available: partialOpenAvailable,
                    busy: busy,
                    settingAvailable: partialOpenSettingAvailable,
                    settingBusy: busy || settingsBusy || partialOpenSettingBusy,
                    textTheme: textTheme,
                    onPressed: onPartialOpen,
                    onSettingPressed: onPartialOpenSetting,
                    onPermissionDenied: !partialOpenAvailable && !busy
                        ? partialOpenPermissionDenied
                        : null,
                    onSettingPermissionDenied:
                        !partialOpenSettingAvailable &&
                            !busy &&
                            !settingsBusy &&
                            !partialOpenSettingBusy
                        ? partialOpenSettingPermissionDenied
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  flex: 44,
                  child: _MoreSettingsCard(
                    busy: busy,
                    textTheme: textTheme,
                    onPressed: onMoreSettings,
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

class _LedActionCard extends StatelessWidget {
  const _LedActionCard({
    required this.enabled,
    required this.available,
    required this.busy,
    required this.textTheme,
    required this.onChanged,
    this.onDisabled,
  });

  final bool enabled;
  final bool available;
  final bool busy;
  final TextTheme textTheme;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onDisabled;

  @override
  Widget build(BuildContext context) {
    return _ControlCard(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _DeviceControlAssetIcon(
                assetPath: _DeviceCommandAssetPaths.led,
              ),
              const Spacer(),
              FlinxSwitch(
                key: const ValueKey<String>('led-switch'),
                value: enabled,
                enabled: available && !busy,
                onChanged: onChanged,
                onDisabled: onDisabled,
              ),
            ],
          ),
          const Spacer(),
          Padding(
            padding: EdgeInsetsGeometry.only(left: 4),
            child: Text(
              AppLocalizations.of(context).deviceCommandLedTitle,
              maxLines: 1,
              style: AppTextTokens.deviceControlQuickActionTitle(textTheme),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context).deviceCommandMinutes(1),
            maxLines: 1,
            style: AppTextTokens.deviceControlQuickActionMeta(textTheme),
          ),
        ],
      ),
    );
  }
}

class _ToggleActionCard extends StatelessWidget {
  const _ToggleActionCard({
    super.key,
    required this.iconAssetPath,
    required this.title,
    this.subtitle,
    required this.switchKey,
    required this.enabled,
    this.available = true,
    required this.busy,
    required this.textTheme,
    required this.onChanged,
    this.onDisabled,
  });

  final String iconAssetPath;
  final String title;
  final String? subtitle;
  final Key switchKey;
  final bool enabled;
  final bool available;
  final bool busy;
  final TextTheme textTheme;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onDisabled;

  @override
  Widget build(BuildContext context) {
    return _ControlCard(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _DeviceControlAssetIcon(assetPath: iconAssetPath),
              const Spacer(),
              FlinxSwitch(
                key: switchKey,
                value: enabled,
                enabled: available && !busy,
                onChanged: onChanged,
                onDisabled: onDisabled,
              ),
            ],
          ),
          const Spacer(),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextTokens.deviceControlQuickActionTitle(textTheme),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              maxLines: 1,
              style: AppTextTokens.deviceControlQuickActionMeta(textTheme),
            ),
          ],
        ],
      ),
    );
  }
}

class _PartialOpenCard extends StatelessWidget {
  const _PartialOpenCard({
    required this.valueLabel,
    required this.available,
    required this.busy,
    required this.settingAvailable,
    required this.settingBusy,
    required this.textTheme,
    required this.onPressed,
    required this.onSettingPressed,
    this.onPermissionDenied,
    this.onSettingPermissionDenied,
  });

  final bool busy;
  final String? valueLabel;
  final bool available;
  final bool settingAvailable;
  final bool settingBusy;
  final TextTheme textTheme;
  final VoidCallback onPressed;
  final VoidCallback onSettingPressed;
  final VoidCallback? onPermissionDenied;
  final VoidCallback? onSettingPermissionDenied;

  @override
  Widget build(BuildContext context) {
    return _ControlCard(
      key: const ValueKey<String>('partial-open-action'),
      child: Stack(
        children: [
          Positioned.fill(
            child: Semantics(
              button: true,
              enabled: available && !busy,
              label: AppLocalizations.of(context).deviceCommandPartialOpenTitle,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: available && !busy
                    ? onPressed
                    : !busy
                    ? onPermissionDenied
                    : null,
              ),
            ),
          ),
          IgnorePointer(
            child: Stack(
              children: [
                Center(
                  child: Container(
                    width: 82,
                    height: 82,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        width: 1.4,
                        color: AppColors.deviceControlPrimaryAction,
                      ),
                    ),
                    child: const Center(
                      child: _DeviceControlAssetIcon(
                        assetPath: _DeviceCommandAssetPaths.partialOpen,
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: const Alignment(0, 1),
                  child: Text(
                    AppLocalizations.of(context).deviceCommandPartialOpenTitle,
                    style: AppTextTokens.deviceControlQuickActionTitle(
                      textTheme,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (valueLabel != null)
            Align(
              alignment: Alignment.topRight,
              child: Semantics(
                button: true,
                enabled: settingAvailable && !settingBusy,
                label: AppLocalizations.of(
                  context,
                ).deviceSettingsPartialOpenHeight,
                child: GestureDetector(
                  key: const ValueKey<String>('partial-open-position-action'),
                  behavior: HitTestBehavior.opaque,
                  onTap: settingAvailable && !settingBusy
                      ? onSettingPressed
                      : !settingBusy
                      ? onSettingPermissionDenied
                      : null,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.deviceControlInactive.withValues(
                        alpha: 0.42,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      child: Text(
                        valueLabel!,
                        style: AppTextTokens.deviceControlBadge(textTheme),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MoreSettingsCard extends StatelessWidget {
  const _MoreSettingsCard({
    required this.busy,
    required this.textTheme,
    required this.onPressed,
  });

  final bool busy;
  final TextTheme textTheme;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return _ControlCard(
      key: const ValueKey<String>('more-settings-action'),
      onTap: busy ? null : onPressed,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          const _DeviceControlAssetIcon(
            assetPath: _DeviceCommandAssetPaths.moreSetting,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              AppLocalizations.of(context).deviceCommandMoreSettingsTitle,
              style: AppTextTokens.deviceControlQuickActionTitle(textTheme),
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlCard extends StatelessWidget {
  const _ControlCard({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(18),
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.deviceControlPanel,
      borderRadius: BorderRadius.circular(
        AppShapeTokens.deviceControlCardRadius,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          AppShapeTokens.deviceControlCardRadius,
        ),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
