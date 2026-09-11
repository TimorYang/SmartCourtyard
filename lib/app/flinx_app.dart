import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_debug_tools/flutter_debug_tools.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:toastification/toastification.dart';

import '../shared/l10n/app_localizations.dart';
import '../core/diagnostics/diagnostic_logging.dart';
import '../features/account/application/providers.dart';
import '../features/account/domain/entities/app_locale_preference.dart';
import '../features/appearance/application/providers.dart';
import '../features/appearance/domain/entities/app_skin_id.dart';
import '../features/push/application/providers.dart';
import 'router/app_router.dart';
import 'theme/app_design_tokens.dart';
import 'theme/app_theme.dart';
import 'theme/app_skin_catalog.dart';

class FlinxApp extends ConsumerStatefulWidget {
  const FlinxApp({super.key});

  @override
  ConsumerState<FlinxApp> createState() => _FlinxAppState();
}

class _FlinxAppState extends ConsumerState<FlinxApp>
    with WidgetsBindingObserver {
  late final HttpOverrides? _httpOverridesBeforeFlutterLens;
  bool _restoredHttpOverrides = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _httpOverridesBeforeFlutterLens = HttpOverrides.current;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAccessibilityFeatures() => setState(() {});

  @override
  Widget build(BuildContext context) {
    ref.watch(diagnosticLoggingControllerProvider);
    ref.watch(pushServiceProvider);
    final localeState = ref.watch(appLocaleControllerProvider);
    final locale = localeState.value;
    final skinState = ref.watch(appSkinControllerProvider);
    final skin = skinState.value;
    if (locale == null || skin == null) {
      return const ColoredBox(color: AppColors.backgroundPrimary);
    }

    final router = ref.watch(appRouterProvider);

    if (!kDebugMode) {
      return _buildApp(
        router: router,
        locale: locale,
        skin: skin,
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
          skin: skin,
          showPerformanceOverlay: showPerformanceOverlay,
        );
      },
    );
  }

  Widget _buildApp({
    required GoRouter router,
    required AppLocalePreference locale,
    required AppSkinId skin,
    required bool showPerformanceOverlay,
  }) {
    final theme = AppTheme.forSkin(skin);
    return ToastificationWrapper(
      child: MaterialApp.router(
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        theme: theme,
        themeMode: ThemeMode.light,
        themeAnimationDuration:
            WidgetsBinding
                .instance
                .platformDispatcher
                .accessibilityFeatures
                .disableAnimations
            ? Duration.zero
            : AppMotionTokens.themeTransitionDuration,
        locale: Locale(locale.languageCode),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
        builder: (context, child) {
          return ToastificationConfigProvider(
            config: const ToastificationConfig(
              alignment: Alignment.topCenter,
              animationDuration: Duration(milliseconds: 220),
            ),
            child: AnnotatedRegion<SystemUiOverlayStyle>(
              value: context.skin.systemOverlayStyle,
              child: child!,
            ),
          );
        },
        showPerformanceOverlay: showPerformanceOverlay,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
