import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_debug_tools/flutter_debug_tools.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:toastification/toastification.dart';

import '../shared/l10n/app_localizations.dart';
import '../core/diagnostics/diagnostic_logging.dart';
import '../features/account/application/providers.dart';
import '../features/account/domain/entities/app_locale_preference.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class FlinxApp extends ConsumerStatefulWidget {
  const FlinxApp({super.key});

  @override
  ConsumerState<FlinxApp> createState() => _FlinxAppState();
}

class _FlinxAppState extends ConsumerState<FlinxApp> {
  late final HttpOverrides? _httpOverridesBeforeFlutterLens;
  bool _restoredHttpOverrides = false;

  @override
  void initState() {
    super.initState();
    _httpOverridesBeforeFlutterLens = HttpOverrides.current;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(diagnosticLoggingControllerProvider);
    final router = ref.watch(appRouterProvider);
    final locale = ref
        .watch(appLocaleControllerProvider)
        .maybeWhen(
          data: (value) => value,
          orElse: () => ref.watch(systemAppLocaleProvider),
        );

    if (!kDebugMode) {
      return _buildApp(
        router: router,
        locale: locale,
        showPerformanceOverlay: false,
      );
    }

    return FlutterLens(
      builder: (context, showPerformanceOverlay, child) {
        // flutter_debug_tools 2.0.5 installs an incomplete HttpClient wrapper
        // that is incompatible with Dio's idleTimeout configuration.
        if (!_restoredHttpOverrides) {
          HttpOverrides.global = _httpOverridesBeforeFlutterLens;
          _restoredHttpOverrides = true;
        }
        return _buildApp(
          router: router,
          locale: locale,
          showPerformanceOverlay: showPerformanceOverlay,
        );
      },
    );
  }

  Widget _buildApp({
    required GoRouter router,
    required AppLocalePreference locale,
    required bool showPerformanceOverlay,
  }) {
    return ToastificationWrapper(
      child: MaterialApp.router(
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        theme: AppTheme.light(),
        themeMode: ThemeMode.light,
        locale: Locale(locale.languageCode),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
        builder: (context, child) => ToastificationConfigProvider(
          config: const ToastificationConfig(
            alignment: Alignment.topCenter,
            animationDuration: Duration(milliseconds: 220),
          ),
          child: child!,
        ),
        showPerformanceOverlay: showPerformanceOverlay,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
