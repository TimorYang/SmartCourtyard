import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../../../platform_bridge/hardware_gateway.dart';
import '../../../platform_bridge/hardware_models.dart';
import '../domain/use_cases/add_force_door_use_case.dart';
import '../domain/use_cases/fetch_onboarding_device_key_use_case.dart';
import 'ble_auth_token.dart';
import 'providers.dart';

const String addDeviceBleNamePrefix = 'opener_';

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
    this.errorMessage,
    this.infoMessage,
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
  final String? errorMessage;
  final String? infoMessage;

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
    String? errorMessage,
    bool clearErrorMessage = false,
    String? infoMessage,
    bool clearInfoMessage = false,
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
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
      infoMessage: clearInfoMessage ? null : infoMessage ?? this.infoMessage,
    );
  }
}

class AddDeviceController extends Notifier<AddDeviceState> {
  late HardwareGateway _gateway;
  late FetchOnboardingDeviceKeyUseCase _fetchDeviceKeyUseCase;
  late AddForceDoorUseCase _addForceDoorUseCase;
  final List<StreamSubscription<Object?>> _subscriptions =
      <StreamSubscription<Object?>>[];
  int _requestCounter = 0;
  var _disposeHookRegistered = false;

  @override
  AddDeviceState build() {
    _cancelSubscriptions();
    _gateway = ref.watch(addDeviceHardwareGatewayProvider);
    _fetchDeviceKeyUseCase = ref.watch(fetchOnboardingDeviceKeyUseCaseProvider);
    _addForceDoorUseCase = ref.watch(addForceDoorUseCaseProvider);
    _subscriptions.addAll(<StreamSubscription<Object?>>[
      _gateway.bleScanResults.listen((device) {
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
        final nextStates = Map<String, BleConnectionState>.from(
          state.connectionStates,
        );
        nextStates[event.deviceId] = event.state;
        state = state.copyWith(connectionStates: nextStates);
      }),
      _gateway.nativeErrors.listen((error) {
        state = state.copyWith(
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
    state = state.copyWith(
      devices: const <String, BleDevice>{},
      connectionStates: const <String, BleConnectionState>{},
      clearSelectedDevice: true,
      clearErrorMessage: true,
      clearInfoMessage: true,
    );
  }

  void selectBleDevice(BleDevice device) {
    state = state.copyWith(
      selectedDevice: device,
      clearErrorMessage: true,
      clearInfoMessage: true,
    );
  }

  Future<void> startScan() async {
    state = state.copyWith(
      isScanning: true,
      clearErrorMessage: true,
      infoMessage: '正在扫描附近蓝牙设备...',
    );
    try {
      await _gateway.startBleScan(
        requestId: _nextRequestId('ble-scan'),
        filter: const BleScanFilter(
          namePrefix: addDeviceBleNamePrefix,
          allowDuplicates: false,
        ),
      );
    } catch (error) {
      state = state.copyWith(
        isScanning: false,
        errorMessage: error.toString(),
        clearInfoMessage: true,
      );
    }
  }

  Future<void> stopScan() async {
    if (!state.isScanning) {
      return;
    }
    try {
      await _gateway.stopBleScan(requestId: _nextRequestId('ble-stop'));
    } finally {
      if (ref.mounted) {
        state = state.copyWith(isScanning: false, infoMessage: '蓝牙扫描已停止');
      }
    }
  }

  Future<bool> connectAndAuthenticate(BleDevice device) async {
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
      isConnecting: true,
      isAuthenticating: false,
      clearErrorMessage: true,
      infoMessage: '正在连接 ${device.name ?? device.id} ...',
    );
    try {
      final connectResult = await _gateway.connectBleDevice(
        requestId: _nextRequestId('ble-connect'),
        deviceId: device.id,
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
      final deviceKey = await _fetchDeviceKeyUseCase(
        sn: sn,
        requestId: _nextRequestId('device-key'),
      );
      final authenticationToken = buildBleAuthenticationToken(deviceKey.aesKey);
      state = state.copyWith(
        isAuthenticating: true,
        infoMessage: '设备密钥获取成功，正在鉴权...',
      );
      final authResult = await _gateway.authenticateBleDevice(
        requestId: _nextRequestId('ble-auth'),
        deviceId: device.id,
        token: authenticationToken,
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
    } on FormatException {
      state = state.copyWith(
        isConnecting: false,
        isAuthenticating: false,
        errorMessage: '设备密钥格式错误，请重试',
        clearInfoMessage: true,
      );
      return false;
    } on AppError catch (error) {
      state = state.copyWith(
        isConnecting: false,
        isAuthenticating: false,
        errorMessage: _messageForAppError(error),
        clearInfoMessage: true,
      );
      return false;
    } catch (error) {
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
    try {
      final result = await _gateway.scanWifiNetworks(
        requestId: _nextRequestId('wifi-scan'),
        deviceId: device.id,
      );
      state = state.copyWith(
        isScanningWifi: false,
        wifiNetworks: result.networks,
        infoMessage: '已扫描到 ${result.networks.length} 个 Wi‑Fi',
      );
      return result.networks;
    } catch (error) {
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
    try {
      final result = await _gateway.configureWifi(
        requestId: _nextRequestId('wifi-provision'),
        deviceId: device.id,
        ssid: ssid,
        password: password,
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

      state = state.copyWith(infoMessage: '设备配网成功，正在绑定账号...');
      await _addForceDoorUseCase(
        sn: sn,
        requestId: _nextRequestId('bind-door'),
      );
      state = state.copyWith(isProvisioningWifi: false, infoMessage: '设备绑定成功');
      return true;
    } on AppError catch (error) {
      state = state.copyWith(
        isProvisioningWifi: false,
        errorMessage: _messageForAppError(error),
        clearInfoMessage: true,
      );
      return false;
    } catch (error) {
      state = state.copyWith(
        isProvisioningWifi: false,
        errorMessage: error.toString(),
        clearInfoMessage: true,
      );
      return false;
    }
  }

  String _nextRequestId(String prefix) {
    _requestCounter += 1;
    return '$prefix-${DateTime.now().millisecondsSinceEpoch}-$_requestCounter';
  }

  String _messageForAppError(AppError error) {
    return switch (error.messageKey) {
      'addDevice.deviceKeyFailed' => '获取设备密钥失败，请重试',
      'addDevice.deviceNotExists' => '设备不存在，请确认设备后重试',
      'addDevice.bindDoorFailed' => '设备绑定失败，请重试',
      _ => '设备添加失败，请重试',
    };
  }
}
