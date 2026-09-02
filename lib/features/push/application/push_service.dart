import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/logging/providers.dart';
import '../../../platform_bridge/hardware_gateway.dart';
import '../../../platform_bridge/hardware_models.dart';
import '../../auth/application/providers.dart';
import '../../auth/domain/entities/auth_session.dart';
import '../../auth/domain/services/login_device_context_provider.dart';
import '../domain/entities/push_configuration.dart';
import '../domain/entities/push_event.dart';
import '../domain/entities/push_registration.dart';
import '../domain/services/push_gateway.dart';
import '../domain/use_cases/bind_push_registration_use_case.dart';
import '../domain/use_cases/unbind_push_registration_use_case.dart';
import 'dependencies.dart';
import 'push_registration_sync_guard.dart';

enum PushInitializationStatus {
  disabled,
  waitingForNotificationPermission,
  initializing,
  ready,
  failed,
}

class PushInitializationState {
  const PushInitializationState(this.status);

  const PushInitializationState.disabled()
    : status = PushInitializationStatus.disabled;

  const PushInitializationState.waitingForNotificationPermission()
    : status = PushInitializationStatus.waitingForNotificationPermission;

  const PushInitializationState.initializing()
    : status = PushInitializationStatus.initializing;

  const PushInitializationState.ready()
    : status = PushInitializationStatus.ready;

  const PushInitializationState.failed()
    : status = PushInitializationStatus.failed;

  final PushInitializationStatus status;

  bool get isReady => status == PushInitializationStatus.ready;
}

class PushService extends Notifier<PushInitializationState>
    with WidgetsBindingObserver {
  late final PushConfiguration _configuration;
  late final PushGateway _gateway;
  late final HardwareGateway _hardwareGateway;
  late final AppLogger _logger;
  late final BindPushRegistrationUseCase _bindPushRegistration;
  late final UnbindPushRegistrationUseCase _unbindPushRegistration;
  late final LoginDeviceContextProvider _registrationContext;
  late final PushRegistrationSyncGuard _registrationSyncGuard;
  final StreamController<PushEvent> _eventController =
      StreamController<PushEvent>.broadcast();
  StreamSubscription<PushEvent>? _eventSubscription;
  Future<void>? _initialization;
  Future<void>? _notificationPermissionRequest;
  Future<void>? _registrationSync;
  Future<void>? _logoutOperation;
  AuthSession? _observedAuthSession;
  String? _lastBoundKey;
  var _requestCounter = 0;
  var _sessionGeneration = 0;
  var _sdkInitialized = false;
  var _logoutInProgress = false;
  var _disposed = false;

  Stream<PushEvent> get events => _eventController.stream;

  @override
  PushInitializationState build() {
    _configuration = ref.watch(pushConfigurationProvider);
    _gateway = ref.watch(pushGatewayProvider);
    _hardwareGateway = ref.watch(pushHardwareGatewayProvider);
    _logger = ref.watch(appLoggerProvider);
    _bindPushRegistration = ref.watch(bindPushRegistrationUseCaseProvider);
    _unbindPushRegistration = ref.watch(unbindPushRegistrationUseCaseProvider);
    _registrationContext = ref.watch(pushRegistrationContextProvider);
    _registrationSyncGuard = ref.watch(pushRegistrationSyncGuardProvider);
    WidgetsBinding.instance.addObserver(this);
    _eventSubscription = _gateway.events.listen(_handleEvent);
    ref.listen<AsyncValue<AuthSession>>(authSessionProvider, (_, next) {
      next.when(data: _handleAuthSession, loading: () {}, error: (_, _) {});
    }, fireImmediately: true);
    ref.onDispose(_dispose);

    if (!_configuration.isConfigured) {
      return const PushInitializationState.disabled();
    }

    Future.microtask(initialize);
    return const PushInitializationState.waitingForNotificationPermission();
  }

  Future<void> initialize() async {
    if (_disposed || !_configuration.isConfigured) return;
    if (_sdkInitialized) {
      await _syncRegistration();
      return;
    }
    final pending = _initialization;
    if (pending != null) return pending;

    final future = _initialize();
    _initialization = future;
    try {
      await future;
    } finally {
      if (identical(_initialization, future)) {
        _initialization = null;
      }
    }
  }

  Future<void> retryInitialization() async {
    if (_disposed || !_configuration.isConfigured) return;
    if (_sdkInitialized) {
      await _syncRegistration();
      return;
    }
    await initialize();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(retryInitialization());
    }
  }

  Future<void> _initialize() async {
    final requestId = _nextRequestId('initialize');
    _setState(const PushInitializationState.initializing());
    try {
      final permission = await _hardwareGateway.getNotificationPermission(
        requestId: requestId,
      );
      if (permission != PermissionStatus.granted) {
        _setState(
          const PushInitializationState.waitingForNotificationPermission(),
        );
        _logger.info(
          'push_waiting_for_notification_permission',
          tag: AppLogTag.push,
          requestId: requestId,
          context: <String, Object?>{'permissionStatus': permission.name},
        );
        return;
      }

      await _gateway.initialize(_configuration);
      _sdkInitialized = true;
      _setState(const PushInitializationState.ready());
      _logger.info(
        'push_initialized',
        tag: AppLogTag.push,
        requestId: requestId,
        context: <String, Object?>{
          'iosProduction': _configuration.iosProduction,
        },
      );
      unawaited(_syncRegistration());
    } catch (error, stackTrace) {
      _sdkInitialized = false;
      _setState(const PushInitializationState.failed());
      _logger.error(
        'push_initialization_failed',
        tag: AppLogTag.push,
        requestId: requestId,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void _handleEvent(PushEvent event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
    switch (event) {
      case PushConnectionChanged(:final connected):
        _logger.info(
          'push_connection_changed',
          tag: AppLogTag.push,
          context: <String, Object?>{'connected': connected},
        );
        if (connected) unawaited(_syncRegistration());
      case PushNotificationArrived(
        :final messageId,
        :final title,
        :final content,
        :final extras,
      ):
        _logMessageEvent(
          'push_notification_arrived',
          messageId: messageId,
          title: title,
          content: content,
          extras: extras,
        );
      case PushNotificationClicked(
        :final messageId,
        :final title,
        :final content,
        :final extras,
      ):
        _logMessageEvent(
          'push_notification_clicked',
          messageId: messageId,
          title: title,
          content: content,
          extras: extras,
        );
      case PushCustomMessageReceived(
        :final messageId,
        :final title,
        :final content,
        :final extras,
      ):
        _logMessageEvent(
          'push_custom_message_received',
          messageId: messageId,
          title: title,
          content: content,
          extras: extras,
        );
      case PushPlatformTokenReceived(:final token):
        _logger.info(
          'push_platform_token_received',
          tag: AppLogTag.push,
          context: <String, Object?>{'hasPlatformToken': token.isNotEmpty},
        );
      case PushDeviceTokenReceived(:final token):
        _logger.info(
          'push_device_token_received',
          tag: AppLogTag.push,
          context: <String, Object?>{'hasDeviceToken': token.isNotEmpty},
        );
    }
  }

  void _logMessageEvent(
    String message, {
    required String? messageId,
    required String? title,
    required String? content,
    required Map<String, Object?> extras,
  }) {
    _logger.info(
      message,
      tag: AppLogTag.push,
      context: <String, Object?>{
        'hasMessageId': messageId?.isNotEmpty == true,
        'hasTitle': title?.isNotEmpty == true,
        'hasContent': content?.isNotEmpty == true,
        'extraCount': extras.length,
      },
    );
  }

  void _handleAuthSession(AuthSession session) {
    if (_disposed) return;

    final previousUserId = _userIdFor(_observedAuthSession);
    final userId = _userIdFor(session);
    final becameAuthenticated = previousUserId == null && userId != null;
    _observedAuthSession = session;

    if (userId == null) {
      _sessionGeneration += 1;
      _lastBoundKey = null;
      _logoutInProgress = false;
      if (previousUserId != null) {
        _registrationSyncGuard.clearUser(previousUserId);
      }
      return;
    }

    if (previousUserId != userId) {
      _sessionGeneration += 1;
      _lastBoundKey = null;
      if (previousUserId != null) {
        _logoutInProgress = false;
      }
    }

    if (becameAuthenticated) {
      unawaited(_requestNotificationPermissionIfNeeded());
    }

    if (_sdkInitialized && !_logoutInProgress) {
      unawaited(_syncRegistration());
    }
  }

  Future<void> _requestNotificationPermissionIfNeeded() async {
    if (_disposed ||
        !_configuration.isConfigured ||
        _sdkInitialized ||
        _logoutInProgress ||
        _userIdFor(_observedAuthSession) == null) {
      return;
    }

    final pending = _notificationPermissionRequest;
    if (pending != null) return pending;

    final future = _requestNotificationPermissionIfNeededInternal();
    _notificationPermissionRequest = future;
    try {
      await future;
    } finally {
      if (identical(_notificationPermissionRequest, future)) {
        _notificationPermissionRequest = null;
      }
    }
  }

  Future<void> _requestNotificationPermissionIfNeededInternal() async {
    final userId = _userIdFor(_observedAuthSession);
    if (userId == null || _disposed || _logoutInProgress) return;

    final checkRequestId = _nextRequestId('notification-permission-check');
    var failureRequestId = checkRequestId;
    try {
      final permission = await _hardwareGateway.getNotificationPermission(
        requestId: checkRequestId,
      );
      _logger.info(
        'push_notification_permission_checked',
        tag: AppLogTag.push,
        requestId: checkRequestId,
        context: <String, Object?>{'permissionStatus': permission.name},
      );

      if (_disposed ||
          _logoutInProgress ||
          _userIdFor(_observedAuthSession) == null) {
        return;
      }

      if (permission != PermissionStatus.notDetermined) {
        if (permission == PermissionStatus.granted) {
          await retryInitialization();
        } else {
          _setState(
            const PushInitializationState.waitingForNotificationPermission(),
          );
        }
        return;
      }

      final requestId = _nextRequestId('notification-permission-request');
      failureRequestId = requestId;
      _logger.info(
        'push_notification_permission_request_started',
        tag: AppLogTag.push,
        requestId: requestId,
      );
      final requestedPermission = await _hardwareGateway
          .requestNotificationPermission(requestId: requestId);
      _logger.info(
        'push_notification_permission_request_completed',
        tag: AppLogTag.push,
        requestId: requestId,
        context: <String, Object?>{
          'permissionStatus': requestedPermission.name,
        },
      );

      if (_disposed ||
          _logoutInProgress ||
          _userIdFor(_observedAuthSession) == null) {
        return;
      }

      if (requestedPermission == PermissionStatus.granted) {
        await retryInitialization();
      } else {
        _setState(
          const PushInitializationState.waitingForNotificationPermission(),
        );
      }
    } catch (error, stackTrace) {
      if (!_disposed &&
          !_logoutInProgress &&
          _userIdFor(_observedAuthSession) != null) {
        _setState(
          const PushInitializationState.waitingForNotificationPermission(),
        );
      }
      _logger.error(
        'push_notification_permission_request_failed',
        tag: AppLogTag.push,
        requestId: failureRequestId,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _syncRegistration() async {
    final pending = _registrationSync;
    if (pending != null) return pending;

    final future = _syncRegistrationInternal();
    _registrationSync = future;
    try {
      await future;
    } finally {
      if (identical(_registrationSync, future)) {
        _registrationSync = null;
      }
    }
  }

  Future<void> _syncRegistrationInternal() async {
    final session = _observedAuthSession;
    final userId = _userIdFor(session);
    final generation = _sessionGeneration;
    if (!_canSync(session) || userId == null) return;

    final requestId = _nextRequestId('registration-id');
    try {
      final registrationId = await _gateway.getRegistrationId();
      final normalizedRegistrationId = registrationId?.trim();
      _logger.info(
        'push_registration_id_available',
        tag: AppLogTag.push,
        requestId: requestId,
        context: <String, Object?>{
          'hasRegistrationId': normalizedRegistrationId?.isNotEmpty == true,
        },
      );

      if (normalizedRegistrationId == null ||
          normalizedRegistrationId.isEmpty ||
          !_isCurrentSession(userId, generation)) {
        return;
      }

      final boundKey = _bindingKey(userId, normalizedRegistrationId);
      if (_lastBoundKey == boundKey) return;

      final context = await _registrationContext.read();
      if (!_isCurrentSession(userId, generation)) return;

      final deviceId = context.deviceId.trim();
      final platform = PushPlatform.fromWireValue(context.platform);
      if (deviceId.isEmpty || platform == null) {
        _logger.error(
          'push_registration_context_invalid',
          tag: AppLogTag.push,
          requestId: requestId,
          context: <String, Object?>{
            'hasDeviceId': deviceId.isNotEmpty,
            'hasPlatform': platform != null,
          },
        );
        return;
      }

      final bindRequestId = _nextRequestId('bind-registration-id');
      final syncResult = await _registrationSyncGuard.run(
        key: boundKey,
        operation: () => _bindPushRegistration(
          registration: PushRegistration(
            registrationId: normalizedRegistrationId,
            deviceId: deviceId,
            platform: platform,
          ),
          requestId: bindRequestId,
        ),
      );
      if (!_isCurrentSession(userId, generation)) return;

      _lastBoundKey = boundKey;
      if (syncResult != PushRegistrationSyncResult.performed) {
        _logger.info(
          'push_registration_bind_deduplicated',
          tag: AppLogTag.push,
          requestId: bindRequestId,
          context: <String, Object?>{'reason': syncResult.name},
        );
        return;
      }
      _logger.info(
        'push_registration_bound',
        tag: AppLogTag.push,
        requestId: bindRequestId,
        context: <String, Object?>{'platform': platform.wireValue},
      );
    } catch (error, stackTrace) {
      _logger.error(
        'push_registration_bind_failed',
        tag: AppLogTag.push,
        requestId: requestId,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> unbindForLogout() async {
    final pending = _logoutOperation;
    if (pending != null) return pending;

    final future = _unbindForLogoutInternal();
    _logoutOperation = future;
    try {
      await future;
    } finally {
      if (identical(_logoutOperation, future)) {
        _logoutOperation = null;
      }
    }
  }

  Future<void> _unbindForLogoutInternal() async {
    _logoutInProgress = true;
    _sessionGeneration += 1;
    _lastBoundKey = null;

    final pendingRegistrationSync = _registrationSync;
    if (pendingRegistrationSync != null) {
      try {
        await pendingRegistrationSync;
      } on Object catch (error, stackTrace) {
        _logger.error(
          'push_registration_bind_wait_failed',
          tag: AppLogTag.push,
          requestId: _nextRequestId('unbind-wait'),
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    AuthSession? session = _observedAuthSession;
    if (_userIdFor(session) == null) {
      try {
        session = await ref.read(authSessionProvider.future);
        _observedAuthSession = session;
      } on Object catch (error, stackTrace) {
        _logger.error(
          'push_logout_session_read_failed',
          tag: AppLogTag.push,
          requestId: _nextRequestId('unbind-session'),
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    final userId = _userIdFor(session);
    if (!_configuration.isConfigured || userId == null) {
      _logger.info(
        'push_registration_unbind_skipped',
        tag: AppLogTag.push,
        context: <String, Object?>{
          'configured': _configuration.isConfigured,
          'authenticated': userId != null,
        },
      );
      if (_userIdFor(_observedAuthSession) == null) {
        _logoutInProgress = false;
      }
      return;
    }

    final requestId = _nextRequestId('unbind-registration-id');
    try {
      await _unbindPushRegistration(requestId: requestId);
      _logger.info(
        'push_registration_unbound',
        tag: AppLogTag.push,
        requestId: requestId,
      );
    } catch (error, stackTrace) {
      _logger.error(
        'push_registration_unbind_failed',
        tag: AppLogTag.push,
        requestId: requestId,
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      _lastBoundKey = null;
      if (_userIdFor(_observedAuthSession) == null) {
        _logoutInProgress = false;
      }
    }
  }

  bool _canSync(AuthSession? session) {
    return !_disposed &&
        !_logoutInProgress &&
        _configuration.isConfigured &&
        _sdkInitialized &&
        _userIdFor(session) != null;
  }

  bool _isCurrentSession(String userId, int generation) {
    return _sessionGeneration == generation &&
        _canSync(_observedAuthSession) &&
        _userIdFor(_observedAuthSession) == userId;
  }

  String? _userIdFor(AuthSession? session) {
    final userId = session?.isAuthenticated == true ? session?.userId : null;
    final normalized = userId?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  String _bindingKey(String userId, String registrationId) =>
      '$userId\u0000$registrationId';

  void _setState(PushInitializationState next) {
    if (!_disposed) state = next;
  }

  String _nextRequestId(String action) {
    _requestCounter += 1;
    return 'push-$action-${DateTime.now().millisecondsSinceEpoch}-$_requestCounter';
  }

  void _dispose() {
    _disposed = true;
    _sdkInitialized = false;
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_eventSubscription?.cancel() ?? Future<void>.value());
    unawaited(_eventController.close());
    unawaited(_gateway.dispose());
  }
}
