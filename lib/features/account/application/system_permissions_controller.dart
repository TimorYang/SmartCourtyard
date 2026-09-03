import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../../push/application/providers.dart';
import '../domain/entities/system_permission.dart';
import '../domain/use_cases/open_system_permission_settings_use_case.dart';
import '../domain/use_cases/read_system_permissions_use_case.dart';
import '../domain/use_cases/request_system_permission_use_case.dart';
import 'providers.dart';

final systemPermissionsControllerProvider =
    NotifierProvider<SystemPermissionsController, SystemPermissionsViewState>(
      SystemPermissionsController.new,
    );

class SystemPermissionsController extends Notifier<SystemPermissionsViewState> {
  late final ReadSystemPermissionsUseCase _readPermissions;
  late final RequestSystemPermissionUseCase _requestPermission;
  late final OpenSystemPermissionSettingsUseCase _openSettings;
  late final PushService _pushService;
  var _requestCounter = 0;

  @override
  SystemPermissionsViewState build() {
    _readPermissions = ref.watch(readSystemPermissionsUseCaseProvider);
    _requestPermission = ref.watch(requestSystemPermissionUseCaseProvider);
    _openSettings = ref.watch(openSystemPermissionSettingsUseCaseProvider);
    _pushService = ref.watch(pushServiceProvider.notifier);
    Future.microtask(refresh);
    return const SystemPermissionsViewState(isLoading: true);
  }

  Future<void> refresh() async {
    final previousPermissions = state.permissions;
    state = SystemPermissionsViewState(
      permissions: previousPermissions,
      isLoading: previousPermissions.isEmpty,
      isRefreshing: previousPermissions.isNotEmpty,
    );
    try {
      final permissions = await _readPermissions(
        requestId: _nextRequestId('read'),
      );
      state = SystemPermissionsViewState(permissions: permissions);
    } catch (_) {
      state = SystemPermissionsViewState(
        permissions: previousPermissions,
        error: const AppError(
          code: AppErrorCode.unknown,
          messageKey: 'systemPermissionsLoadError',
          action: AppErrorAction.retry,
          retryable: true,
        ),
      );
    }
  }

  Future<void> activate(SystemPermission permission) {
    return _requestPermissionIfAllowed(
      permission,
      openSettingsWhenBlocked: true,
    );
  }

  Future<void> requestIfDenied(SystemPermission permission) {
    return _requestPermissionIfAllowed(
      permission,
      openSettingsWhenBlocked: false,
    );
  }

  Future<void> _requestPermissionIfAllowed(
    SystemPermission permission, {
    required bool openSettingsWhenBlocked,
  }) async {
    final current = state.permissionFor(permission);
    if (current == null ||
        current.isGranted ||
        state.pendingPermission != null) {
      return;
    }
    if (current.status == SystemPermissionStatus.blocked) {
      if (openSettingsWhenBlocked) {
        await _openSettings(requestId: _nextRequestId('settings'));
      }
      return;
    }

    state = state.copyWith(pendingPermission: permission, clearError: true);
    try {
      final permissions = await _requestPermission(
        permission: permission,
        requestId: _nextRequestId('request'),
      );
      state = SystemPermissionsViewState(
        permissions: permissions,
        pendingPermission: null,
      );
      if (permission == SystemPermission.notification) {
        await _pushService.retryInitialization();
      }
    } catch (_) {
      state = state.copyWith(
        clearPendingPermission: true,
        error: const AppError(
          code: AppErrorCode.permissionDenied,
          messageKey: 'systemPermissionsRequestError',
          action: AppErrorAction.openSettings,
        ),
      );
    }
  }

  Future<SystemPermissionStatus?> readStatus(
    SystemPermission permission,
  ) async {
    try {
      final permissions = await _readPermissions(
        requestId: _nextRequestId('read'),
      );
      return _statusFor(permissions, permission);
    } catch (_) {
      return null;
    }
  }

  Future<void> openSettings() {
    return _openSettings(requestId: _nextRequestId('settings'));
  }

  SystemPermissionStatus? _statusFor(
    List<SystemPermissionState> permissions,
    SystemPermission permission,
  ) {
    for (final item in permissions) {
      if (item.permission == permission) return item.status;
    }
    return null;
  }

  String _nextRequestId(String action) {
    _requestCounter += 1;
    return 'system-permissions-$action-${DateTime.now().millisecondsSinceEpoch}-$_requestCounter';
  }
}

class SystemPermissionsViewState {
  const SystemPermissionsViewState({
    this.permissions = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.pendingPermission,
    this.error,
  });

  final List<SystemPermissionState> permissions;
  final bool isLoading;
  final bool isRefreshing;
  final SystemPermission? pendingPermission;
  final AppError? error;

  SystemPermissionState? permissionFor(SystemPermission permission) {
    for (final item in permissions) {
      if (item.permission == permission) return item;
    }
    return null;
  }

  SystemPermissionsViewState copyWith({
    List<SystemPermissionState>? permissions,
    bool? isLoading,
    bool? isRefreshing,
    SystemPermission? pendingPermission,
    bool clearPendingPermission = false,
    AppError? error,
    bool clearError = false,
  }) {
    return SystemPermissionsViewState(
      permissions: permissions ?? this.permissions,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      pendingPermission: clearPendingPermission
          ? null
          : pendingPermission ?? this.pendingPermission,
      error: clearError ? null : error ?? this.error,
    );
  }
}
