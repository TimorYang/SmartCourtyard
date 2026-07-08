import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_debug_tools/flutter_debug_tools.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../shared/l10n/app_localizations.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class FlinxApp extends ConsumerWidget {
  const FlinxApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    if (!kDebugMode) {
      return _buildApp(router: router, showPerformanceOverlay: false);
    }

    return FlutterLens(
      builder: (context, showPerformanceOverlay, child) {
        return _buildApp(
          router: router,
          showPerformanceOverlay: showPerformanceOverlay,
        );
      },
    );
  }

  Widget _buildApp({
    required GoRouter router,
    required bool showPerformanceOverlay,
  }) {
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
      showPerformanceOverlay: showPerformanceOverlay,
      debugShowCheckedModeBanner: false,
    );
  }
}
