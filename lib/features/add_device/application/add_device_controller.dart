import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/logging/providers.dart';
import '../../../platform_bridge/hardware_gateway.dart';
import '../../../platform_bridge/hardware_models.dart';
import '../../home/application/providers.dart';
import '../../../platform_bridge/android_ble_permission_gateway.dart';
import '../domain/entities/add_door_draft.dart';
import '../domain/entities/onboarded_force_door.dart';
import '../domain/use_cases/add_force_door_use_case.dart';
import '../domain/use_cases/fetch_onboarding_device_key_use_case.dart';
import '../domain/use_cases/validate_binding_status_use_case.dart';
import 'ble_auth_token.dart';
import 'providers.dart';

class AddDeviceState {
  const AddDeviceState({
    required this.devices,
    required this.connectionStates,
    required this.isScanning,
    required this.isConnecting,
    required this.isAuthenticating,
    required this.isScanningWifi,
    required this.isProvisioningWifi,
    required this.wifiSsid,
    required this.wifiPassword,
    required this.wifiNetworks,
    this.selectedDevice,
    this.onboardedDoor,
    this.pendingDoorDraft,
    this.doorType,
    this.errorMessage,
    this.infoMessage,
    this.onboardingFlowId,
    this.onboardingDoorId,
    this.onboardingSceneId,
  });

  factory AddDeviceState.initial() {
    return const AddDeviceState(
      devices: <String, BleDevice>{},
      connectionStates: <String, BleConnectionState>{},
      isScanning: false,
      isConnecting: false,
      isAuthenticating: false,
      isScanningWifi: false,
      isProvisioningWifi: false,
      wifiSsid: '',
      wifiPassword: '',
      wifiNetworks: <WifiNetwork>[],
    );
  }

  final Map<String, BleDevice> devices;
  final Map<String, BleConnectionState> connectionStates;
  final bool isScanning;
  final bool isConnecting;
  final bool isAuthenticating;
  final bool isScanningWifi;
  final bool isProvisioningWifi;
  final String wifiSsid;
  final String wifiPassword;
  final List<WifiNetwork> wifiNetworks;
  final BleDevice? selectedDevice;
  final OnboardedForceDoor? onboardedDoor;
  final AddDoorDraft? pendingDoorDraft;
  final DoorType? doorType;
  final String? errorMessage;
  final String? infoMessage;
  final String? onboardingFlowId;
  final String? onboardingDoorId;
  final int? onboardingSceneId;

  List<BleDevice> sortedDevices() {
    final items = devices.values.toList();
    items.sort((a, b) => b.rssi.compareTo(a.rssi));
    return items;
  }

  BleConnectionState connectionStateFor(String deviceId) {
    return connectionStates[deviceId] ?? BleConnectionState.disconnected;
  }

  AddDeviceState copyWith({
    Map<String, BleDevice>? devices,
    Map<String, BleConnectionState>? connectionStates,
    bool? isScanning,
    bool? isConnecting,
    bool? isAuthenticating,
    bool? isScanningWifi,
    bool? isProvisioningWifi,
    String? wifiSsid,
    String? wifiPassword,
    List<WifiNetwork>? wifiNetworks,
    BleDevice? selectedDevice,
    bool clearSelectedDevice = false,
    OnboardedForceDoor? onboardedDoor,
    bool clearOnboardedDoor = false,
    AddDoorDraft? pendingDoorDraft,
    bool clearPendingDoorDraft = false,
    DoorType? doorType,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? infoMessage,
    bool clearInfoMessage = false,
    String? onboardingFlowId,
    bool clearOnboardingFlowId = false,
    String? onboardingDoorId,
    bool clearOnboardingDoorId = false,
    int? onboardingSceneId,
    bool clearOnboardingSceneId = false,
  }) {
    return AddDeviceState(
      devices: devices ?? this.devices,
      connectionStates: connectionStates ?? this.connectionStates,
      isScanning: isScanning ?? this.isScanning,
      isConnecting: isConnecting ?? this.isConnecting,
      isAuthenticating: isAuthenticating ?? this.isAuthenticating,
      isScanningWifi: isScanningWifi ?? this.isScanningWifi,
      isProvisioningWifi: isProvisioningWifi ?? this.isProvisioningWifi,
      wifiSsid: wifiSsid ?? this.wifiSsid,
      wifiPassword: wifiPassword ?? this.wifiPassword,
      wifiNetworks: wifiNetworks ?? this.wifiNetworks,
      selectedDevice: clearSelectedDevice
          ? null
          : selectedDevice ?? this.selectedDevice,
      onboardedDoor: clearOnboardedDoor
          ? null
          : onboardedDoor ?? this.onboardedDoor,
      pendingDoorDraft: clearPendingDoorDraft
          ? null
          : pendingDoorDraft ?? this.pendingDoorDraft,
      doorType: doorType ?? this.doorType,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
      infoMessage: clearInfoMessage ? null : infoMessage ?? this.infoMessage,
      onboardingFlowId: clearOnboardingFlowId
          ? null
          : onboardingFlowId ?? this.onboardingFlowId,
      onboardingDoorId: clearOnboardingDoorId
          ? null
          : onboardingDoorId ?? this.onboardingDoorId,
      onboardingSceneId: clearOnboardingSceneId
          ? null
          : onboardingSceneId ?? this.onboardingSceneId,
    );
  }
}

class AddDeviceController extends Notifier<AddDeviceState> {
  late HardwareGateway _gateway;
  late FetchOnboardingDeviceKeyUseCase _fetchDeviceKeyUseCase;
  late ValidateBindingStatusUseCase _validateBindingStatusUseCase;
  late AddForceDoorUseCase _addForceDoorUseCase;
  late HomeDeviceListsInvalidator _invalidateHomeDeviceLists;
  late AppLogger _logger;
  final List<StreamSubscription<Object?>> _subscriptions =
      <StreamSubscription<Object?>>[];
  int _requestCounter = 0;
  String? _onboardingFlowId;
  String? _doorId;
  int? _sceneId;
  String? _targetBleName;
  var _disposeHookRegistered = false;

  /// 保存用户在添加流程开始前选择的门名称和场景归属。
  void setPendingDoorDraft(AddDoorDraft draft) {
    state = state.copyWith(pendingDoorDraft: draft);
  }

  @override
  AddDeviceState build() {
    _cancelSubscriptions();
    _gateway = ref.watch(addDeviceHardwareGatewayProvider);
    _fetchDeviceKeyUseCase = ref.watch(fetchOnboardingDeviceKeyUseCaseProvider);
    _validateBindingStatusUseCase = ref.watch(
      validateBindingStatusUseCaseProvider,
    );
    _addForceDoorUseCase = ref.watch(addForceDoorUseCaseProvider);
    _invalidateHomeDeviceLists = ref.watch(homeDeviceListsInvalidatorProvider);
    _logger = ref.watch(appLoggerProvider);
    _subscriptions.addAll(<StreamSubscription<Object?>>[
      _gateway.bleScanResults.listen((device) {
        final targetBleName = _targetBleName;
        if (targetBleName != null && device.sn?.trim() != targetBleName) {
          return;
        }
        _log(
          'ble_scan_result',
          requestId: device.requestId,
          deviceId: device.id,
          stage: 'scan',
          result: 'discovered',
          context: {'rssi': device.rssi, 'hasSerialNumber': device.sn != null},
        );
        if ((device.sn ?? '').trim().isEmpty) {
          return;
        }
        final nextDevices = Map<String, BleDevice>.from(state.devices);
        nextDevices[device.id] = device;
        state = state.copyWith(
          devices: nextDevices,
          clearErrorMessage: true,
          infoMessage: '已发现 ${nextDevices.length} 台蓝牙设备',
        );
      }),
      _gateway.bleConnectionEvents.listen((event) {
        _log(
          'ble_connection_state',
          requestId: event.requestId,
          deviceId: event.deviceId,
          stage: 'connect',
          result: event.state.name,
          context: {'nativeCode': event.nativeCode},
        );
        final nextStates = Map<String, BleConnectionState>.from(
          state.connectionStates,
        );
        nextStates[event.deviceId] = event.state;
        state = state.copyWith(connectionStates: nextStates);
      }),
      _gateway.nativeErrors.listen((error) {
        final isScanRequest = error.requestId?.contains(':ble-scan:') == true;
        _logError(
          'native_hardware_error',
          requestId: error.requestId,
          deviceId: error.deviceId,
          stage: 'hardware',
          result: 'failed',
          context: {'nativeCode': error.code, 'domainCode': error.domainCode},
        );
        state = state.copyWith(
          isScanning: isScanRequest ? false : state.isScanning,
          errorMessage: error.message ?? error.code,
          infoMessage: null,
        );
      }),
    ]);
    if (!_disposeHookRegistered) {
      _disposeHookRegistered = true;
      ref.onDispose(_cancelSubscriptions);
    }
    return AddDeviceState.initial();
  }

  void _cancelSubscriptions() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _subscriptions.clear();
  }

  void updateWifiSsid(String value) {
    state = state.copyWith(wifiSsid: value, clearErrorMessage: true);
  }

  void updateWifiPassword(String value) {
    state = state.copyWith(wifiPassword: value, clearErrorMessage: true);
  }

  void selectWifiNetwork(String ssid) {
    state = state.copyWith(wifiSsid: ssid, clearErrorMessage: true);
  }

  void clearMessages() {
    state = state.copyWith(clearErrorMessage: true, clearInfoMessage: true);
  }

  void clearScanResults() {
    _targetBleName = null;
    _log('flow_reset', stage: 'scan', result: 'cleared');
    state = state.copyWith(
      devices: const <String, BleDevice>{},
      connectionStates: const <String, BleConnectionState>{},
      clearSelectedDevice: true,
      clearOnboardedDoor: true,
      clearErrorMessage: true,
      clearInfoMessage: true,
    );
  }

  void selectBleDevice(BleDevice device) {
    _ensureFlow();
    _log(
      'device_selected',
      requestId: device.requestId,
      deviceId: device.id,
      stage: 'scan',
      result: 'selected',
      context: {'rssi': device.rssi, 'sn': device.sn},
    );
    state = state.copyWith(
      selectedDevice: device,
      clearErrorMessage: true,
      clearInfoMessage: true,
    );
  }

  Future<bool> startScan({String? targetSn}) async {
    final flowId = _ensureFlow();
    final normalizedTargetSn = targetSn?.trim();
    _targetBleName = normalizedTargetSn?.isEmpty == true
        ? null
        : normalizedTargetSn;
    final requestId = _nextRequestId('ble-scan');
    final bluetoothReadiness =
        await AndroidBlePermissionGateway.requestBleScanReady();
    if (bluetoothReadiness == AndroidBleScanReadiness.cancelled) {
      return false;
    }
    if (bluetoothReadiness == AndroidBleScanReadiness.permissionDenied) {
      state = state.copyWith(
        isScanning: false,
        errorMessage: '请授予蓝牙权限后重试',
        clearInfoMessage: true,
      );
      return false;
    }
    _log(
      'ble_scan_started',
      requestId: requestId,
      stage: 'scan',
      result: 'started',
      context: {'targetSn': _targetBleName},
    );
    state = state.copyWith(
      onboardingFlowId: flowId,
      isScanning: true,
      clearErrorMessage: true,
      infoMessage: '正在扫描附近蓝牙设备...',
    );
    try {
      await _gateway.startBleScan(
        requestId: requestId,
        filter: BleScanFilter(
          exactName: _targetBleName,
          allowDuplicates: false,
        ),
      );
      return true;
    } catch (error) {
      _logError(
        'ble_scan_failed',
        requestId: requestId,
        stage: 'scan',
        result: 'failed',
        error: error,
      );
      state = state.copyWith(
        isScanning: false,
        errorMessage: error.toString(),
        clearInfoMessage: true,
      );
      return false;
    }
  }

  Future<void> stopScan() async {
    if (!state.isScanning) {
      return;
    }
    final requestId = _nextRequestId('ble-stop');
    try {
      await _gateway.stopBleScan(requestId: requestId);
      _log(
        'ble_scan_stopped',
        requestId: requestId,
        stage: 'scan',
        result: 'success',
      );
    } finally {
      if (ref.mounted) {
        state = state.copyWith(isScanning: false, infoMessage: '蓝牙扫描已停止');
      }
    }
  }

  Future<bool> disconnectConnectedBleDevices() async {
    final connectedDeviceIds = state.connectionStates.entries
        .where((entry) => entry.value == BleConnectionState.connected)
        .map((entry) => entry.key)
        .toList(growable: false);
    if (connectedDeviceIds.isEmpty) {
      return true;
    }

    var allDisconnected = true;
    final nextStates = Map<String, BleConnectionState>.from(
      state.connectionStates,
    );
    for (final deviceId in connectedDeviceIds) {
      final requestId = _nextRequestId('ble-disconnect');
      try {
        final event = await _gateway.disconnectBleDevice(
          requestId: requestId,
          deviceId: deviceId,
        );
        nextStates[deviceId] = event.state;
        _log(
          'ble_disconnect_completed',
          requestId: requestId,
          deviceId: deviceId,
          stage: 'disconnect',
          result: event.state.name,
        );
      } catch (_) {
        allDisconnected = false;
        _logError(
          'ble_disconnect_failed',
          requestId: requestId,
          deviceId: deviceId,
          stage: 'disconnect',
          result: 'failed',
        );
      }
    }
    state = state.copyWith(
      connectionStates: nextStates,
      infoMessage: allDisconnected ? '已断开当前蓝牙设备' : '部分蓝牙设备断开失败，仍将继续扫描',
    );
    return allDisconnected;
  }

  Future<bool> connectAndAuthenticate(BleDevice device) async {
    _ensureFlow();
    final sn = device.sn?.trim() ?? '';
    if (sn.isEmpty) {
      state = state.copyWith(
        errorMessage: '设备信息不完整，请重新扫描',
        clearInfoMessage: true,
      );
      return false;
    }

    state = state.copyWith(
      selectedDevice: device,
      isConnecting: false,
      isAuthenticating: false,
      clearErrorMessage: true,
      infoMessage: '正在验证设备序列号...',
    );
    final bindingStatusRequestId = _nextRequestId('binding-status');
    _log(
      'binding_status_validation_started',
      requestId: bindingStatusRequestId,
      deviceId: device.id,
      stage: 'binding_status',
      result: 'started',
      context: {'sn': sn},
    );
    try {
      await _validateBindingStatusUseCase(
        sn: sn,
        requestId: bindingStatusRequestId,
      );
      _log(
        'binding_status_validation_completed',
        requestId: bindingStatusRequestId,
        deviceId: device.id,
        stage: 'binding_status',
        result: 'success',
        context: {'sn': sn},
      );
      state = state.copyWith(
        isConnecting: true,
        infoMessage: '正在连接 ${device.name ?? device.id} ...',
      );
      final connectRequestId = _nextRequestId('ble-connect');
      final connectWatch = Stopwatch()..start();
      _log(
        'ble_connect_started',
        requestId: connectRequestId,
        deviceId: device.id,
        stage: 'connect',
        result: 'started',
      );
      final connectResult = await _gateway.connectBleDevice(
        requestId: connectRequestId,
        deviceId: device.id,
      );
      _log(
        'ble_connect_completed',
        requestId: connectRequestId,
        deviceId: device.id,
        stage: 'connect',
        result: connectResult.state.name,
        durationMs: connectWatch.elapsedMilliseconds,
        context: {'nativeCode': connectResult.nativeCode},
      );
      if (connectResult.state != BleConnectionState.connected) {
        state = state.copyWith(
          isConnecting: false,
          errorMessage: '蓝牙连接未成功建立',
          clearInfoMessage: true,
        );
        return false;
      }

      state = state.copyWith(
        isConnecting: false,
        isAuthenticating: true,
        infoMessage: '连接成功，正在获取设备密钥...',
      );
      final keyRequestId = _nextRequestId('device-key');
      final keyWatch = Stopwatch()..start();
      _log(
        'device_key_fetch_started',
        requestId: keyRequestId,
        deviceId: device.id,
        stage: 'device_key',
        result: 'started',
        context: {'sn': sn},
      );
      final deviceKey = await _fetchDeviceKeyUseCase(
        sn: sn,
        requestId: keyRequestId,
      );
      _log(
        'device_key_fetch_completed',
        requestId: keyRequestId,
        deviceId: device.id,
        stage: 'device_key',
        result: 'success',
        durationMs: keyWatch.elapsedMilliseconds,
        context: {
          'aesKeyVersion': deviceKey.aesKeyVersion,
          'keyFormatValid': RegExp(
            r'^[0-9a-fA-F]{32}$',
          ).hasMatch(deviceKey.aesKey.trim()),
        },
      );
      final authenticationToken = buildBleAuthenticationToken(deviceKey.aesKey);
      state = state.copyWith(
        isAuthenticating: true,
        infoMessage: '设备密钥获取成功，正在鉴权...',
      );
      final authRequestId = _nextRequestId('ble-auth');
      final authWatch = Stopwatch()..start();
      _log(
        'ble_authentication_started',
        requestId: authRequestId,
        deviceId: device.id,
        stage: 'authentication',
        result: 'started',
        context: {'aesKeyVersion': deviceKey.aesKeyVersion},
      );
      final authResult = await _gateway.authenticateBleDevice(
        requestId: authRequestId,
        deviceId: device.id,
        token: authenticationToken,
        aesKey: deviceKey.aesKey,
        aesKeyVersion: deviceKey.aesKeyVersion,
      );
      _log(
        'ble_authentication_completed',
        requestId: authRequestId,
        deviceId: device.id,
        stage: 'authentication',
        result: authResult.authenticated ? 'success' : 'rejected',
        durationMs: authWatch.elapsedMilliseconds,
        context: {
          'bindingState': authResult.bindingState,
          'nativeCode': authResult.nativeCode,
          'aesKeyVersion': deviceKey.aesKeyVersion,
        },
      );
      if (!authResult.authenticated) {
        state = state.copyWith(
          isAuthenticating: false,
          errorMessage: '鉴权失败，请确认 Token 是否正确',
          clearInfoMessage: true,
        );
        return false;
      }

      state = state.copyWith(
        isAuthenticating: false,
        infoMessage: '鉴权成功，准备进入 Wi‑Fi 配置',
      );
      return true;
    } on FormatException catch (error) {
      _logError(
        'device_key_format_invalid',
        deviceId: device.id,
        stage: 'device_key',
        result: 'failed',
        error: error,
      );
      state = state.copyWith(
        isConnecting: false,
        isAuthenticating: false,
        errorMessage: '设备密钥格式错误，请重试',
        clearInfoMessage: true,
      );
      return false;
    } on AppError catch (error) {
      _logError(
        'connect_or_authentication_failed',
        requestId: error.requestId,
        deviceId: device.id,
        stage: 'authentication',
        result: 'failed',
        error: error,
        context: {
          'nativeCode': error.nativeCode,
          'domainCode': error.code.name,
        },
      );
      state = state.copyWith(
        isConnecting: false,
        isAuthenticating: false,
        errorMessage: _messageForAppError(error),
        clearInfoMessage: true,
      );
      return false;
    } catch (error) {
      _logError(
        'connect_or_authentication_failed',
        deviceId: device.id,
        stage: 'authentication',
        result: 'failed',
        error: error,
      );
      state = state.copyWith(
        isConnecting: false,
        isAuthenticating: false,
        errorMessage: error.toString(),
        clearInfoMessage: true,
      );
      return false;
    }
  }

  Future<List<WifiNetwork>> scanWifiNetworks() async {
    final device = state.selectedDevice;
    if (device == null) {
      state = state.copyWith(errorMessage: '请先连接蓝牙设备');
      return const <WifiNetwork>[];
    }

    state = state.copyWith(
      isScanningWifi: true,
      clearErrorMessage: true,
      infoMessage: '正在扫描设备附近的 Wi‑Fi...',
    );
    final requestId = _nextRequestId('wifi-scan');
    final watch = Stopwatch()..start();
    _log(
      'wifi_scan_started',
      requestId: requestId,
      deviceId: device.id,
      stage: 'wifi_scan',
      result: 'started',
    );
    try {
      final result = await _gateway.scanWifiNetworks(
        requestId: requestId,
        deviceId: device.id,
      );
      _log(
        'wifi_scan_completed',
        requestId: requestId,
        deviceId: device.id,
        stage: 'wifi_scan',
        result: 'success',
        durationMs: watch.elapsedMilliseconds,
        context: {'networkCount': result.networks.length},
      );
      state = state.copyWith(
        isScanningWifi: false,
        wifiNetworks: result.networks,
        infoMessage: '已扫描到 ${result.networks.length} 个 Wi‑Fi',
      );
      return result.networks;
    } catch (error) {
      _logError(
        'wifi_scan_failed',
        requestId: requestId,
        deviceId: device.id,
        stage: 'wifi_scan',
        result: 'failed',
        error: error,
      );
      state = state.copyWith(
        isScanningWifi: false,
        errorMessage: error.toString(),
        clearInfoMessage: true,
      );
      return const <WifiNetwork>[];
    }
  }

  Future<bool> configureWifi({bool isWifiSkipped = false}) async {
    final device = state.selectedDevice;
    if (device == null) {
      state = state.copyWith(errorMessage: '请先完成蓝牙连接');
      return false;
    }

    final ssid = isWifiSkipped ? '' : state.wifiSsid.trim();
    final password = isWifiSkipped ? '' : state.wifiPassword;
    if (!isWifiSkipped && ssid.isEmpty) {
      state = state.copyWith(errorMessage: '请选择或输入 Wi‑Fi 名称');
      return false;
    }
    if (!isWifiSkipped && password.isEmpty) {
      state = state.copyWith(errorMessage: '请输入 Wi‑Fi 密码');
      return false;
    }

    state = state.copyWith(
      isProvisioningWifi: true,
      clearErrorMessage: true,
      infoMessage: '正在向设备发送 Wi‑Fi 配置...',
    );
    final provisionRequestId = _nextRequestId('wifi-provision');
    final provisionWatch = Stopwatch()..start();
    _log(
      'wifi_provision_started',
      requestId: provisionRequestId,
      deviceId: device.id,
      stage: 'wifi_provision',
      result: 'started',
      context: {
        'wifiSkipped': isWifiSkipped,
        'ssidProvided': ssid.isNotEmpty,
        'passwordProvided': password.isNotEmpty,
      },
    );
    try {
      final result = await _gateway.configureWifi(
        requestId: provisionRequestId,
        deviceId: device.id,
        ssid: ssid,
        password: password,
      );
      _log(
        'wifi_provision_completed',
        requestId: provisionRequestId,
        deviceId: device.id,
        stage: 'wifi_provision',
        result: result.success ? 'success' : 'failed',
        durationMs: provisionWatch.elapsedMilliseconds,
        context: {'nativeCode': result.nativeCode},
      );
      if (!result.success) {
        state = state.copyWith(
          isProvisioningWifi: false,
          errorMessage: 'Wi‑Fi 配网失败，请重试',
          clearInfoMessage: true,
        );
        return false;
      }

      final sn = device.sn?.trim() ?? '';
      if (sn.isEmpty) {
        state = state.copyWith(
          isProvisioningWifi: false,
          errorMessage: '设备信息不完整，请重新扫描',
          clearInfoMessage: true,
        );
        return false;
      }

      final candidateDoorId = _doorId?.trim();
      final doorId = candidateDoorId?.isEmpty ?? true ? null : candidateDoorId;
      final doorType = state.doorType ?? DoorType.garage;

      state = state.copyWith(infoMessage: '设备配网成功，正在绑定账号...');
      final bindRequestId = _nextRequestId('bind-door');
      final bindWatch = Stopwatch()..start();
      _log(
        'cloud_binding_started',
        requestId: bindRequestId,
        deviceId: device.id,
        stage: 'cloud_binding',
        result: 'started',
        context: {
          'sn': sn,
          'doorId': doorId,
          'sceneId': _sceneId,
          'doorType': doorType.wireValue,
        },
      );
      final onboardedDoor = await _addForceDoorUseCase(
        sn: sn,
        doorId: doorId,
        sceneId: _sceneId,
        doorType: doorType.wireValue,
        requestId: bindRequestId,
      );
      _log(
        'cloud_binding_completed',
        requestId: bindRequestId,
        deviceId: device.id,
        stage: 'cloud_binding',
        result: 'success',
        durationMs: bindWatch.elapsedMilliseconds,
        context: {'doorId': onboardedDoor.id},
      );
      state = state.copyWith(
        isProvisioningWifi: false,
        onboardedDoor: onboardedDoor,
        infoMessage: '设备绑定成功',
      );
      _invalidateHomeDeviceLists();
      return true;
    } on AppError catch (error) {
      _logError(
        'device_binding_failed',
        requestId: error.requestId,
        deviceId: device.id,
        stage: 'binding',
        result: 'failed',
        error: error,
        context: {
          'nativeCode': error.nativeCode,
          'domainCode': error.code.name,
        },
      );
      state = state.copyWith(
        isProvisioningWifi: false,
        errorMessage: _messageForAppError(error),
        clearInfoMessage: true,
      );
      return false;
    } catch (error) {
      _logError(
        'device_binding_failed',
        deviceId: device.id,
        stage: 'binding',
        result: 'failed',
        error: error,
      );
      state = state.copyWith(
        isProvisioningWifi: false,
        errorMessage: error.toString(),
        clearInfoMessage: true,
      );
      return false;
    }
  }

  String _nextRequestId(String operation) {
    final flowId = _ensureFlow();
    _requestCounter += 1;
    return '$flowId:$operation:$_requestCounter';
  }

  String _ensureFlow() {
    final current = _onboardingFlowId;
    if (current != null) {
      return current;
    }
    final random = Random.secure().nextInt(0x7fffffff).toRadixString(16);
    final flowId =
        'onboarding-${DateTime.now().toUtc().microsecondsSinceEpoch}-$random';
    _onboardingFlowId = flowId;
    state = state.copyWith(onboardingFlowId: flowId);
    _logger.info(
      'onboarding_flow_started',
      tag: AppLogTag.binding,
      flowId: flowId,
      context: const {'stage': 'add_device', 'result': 'started'},
    );
    return flowId;
  }

  void beginOnboardingFlow({
    String? doorId,
    int? sceneId,
    DoorType doorType = DoorType.garage,
  }) {
    if (_onboardingFlowId != null) {
      _log('onboarding_flow_superseded', stage: 'add_device', result: 'ended');
    }
    _onboardingFlowId = null;
    _doorId = doorId;
    _sceneId = sceneId;
    _requestCounter = 0;
    final flowId = _ensureFlow();
    state = state.copyWith(
      doorType: doorType,
      onboardingDoorId: doorId,
      clearOnboardingDoorId: doorId == null,
      onboardingSceneId: sceneId,
      clearOnboardingSceneId: sceneId == null,
    );
    _log(
      'add_device_flow_entered',
      stage: 'add_device',
      result: 'entered',
      context: {'onboardingFlowId': flowId, 'doorType': doorType.wireValue},
    );
  }

  void logSuccessPageEntered() {
    _log(
      'binding_success_page_entered',
      deviceId: state.selectedDevice?.id,
      stage: 'success_page',
      result: 'entered',
      context: {'doorId': state.onboardedDoor?.id},
    );
  }

  void logDeviceDetailNavigation() {
    _log(
      'device_detail_navigation',
      deviceId: state.selectedDevice?.id,
      stage: 'device_detail',
      result: 'started',
      context: {'doorId': state.onboardedDoor?.id},
    );
  }

  void _log(
    String event, {
    String? requestId,
    String? deviceId,
    required String stage,
    required String result,
    int? durationMs,
    Map<String, Object?> context = const {},
  }) {
    final flowId = _onboardingFlowId ?? state.onboardingFlowId;
    _logger.info(
      event,
      tag: AppLogTag.binding,
      flowId: flowId,
      requestId: requestId,
      context: {
        'deviceId': deviceId,
        'stage': stage,
        'result': result,
        'durationMs': durationMs,
        ...context,
      },
    );
  }

  void _logError(
    String event, {
    String? requestId,
    String? deviceId,
    required String stage,
    required String result,
    Object? error,
    Map<String, Object?> context = const {},
  }) {
    final flowId = _onboardingFlowId ?? state.onboardingFlowId;
    _logger.error(
      event,
      tag: AppLogTag.binding,
      flowId: flowId,
      requestId: requestId,
      error: error,
      context: {
        'deviceId': deviceId,
        'stage': stage,
        'result': result,
        ...context,
      },
    );
  }

  String _messageForAppError(AppError error) {
    return switch (error.messageKey) {
      'addDevice.deviceKeyFailed' => '获取设备密钥失败，请重试',
      'addDevice.deviceNotExists' => '设备不存在，请确认设备后重试',
      'addDevice.bindDoorFailed' => '设备绑定失败，请重试',
      'addDevice.bindingStatusFailed' =>
        error.userMessage?.trim().isNotEmpty == true
            ? error.userMessage!.trim()
            : '设备已被其他用户绑定',
      'hardware.authentication_decrypt_failed' => '蓝牙鉴权失败，设备密钥不匹配，请重试',
      _ =>
        error.userMessage?.trim().isNotEmpty == true
            ? error.userMessage!.trim()
            : '设备添加失败，请重试',
    };
  }
}
