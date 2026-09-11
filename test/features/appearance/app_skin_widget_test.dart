import '../../support/skin_qa.dart';
import 'dart:async';

import 'package:flinx/app/flinx_app.dart';
import 'package:flinx/app/router/app_router.dart';
import 'package:flinx/app/theme/app_design_tokens.dart';
import 'package:flinx/app/theme/app_skin_catalog.dart';
import 'package:flinx/app/theme/app_theme.dart';
import 'package:flinx/features/account/application/providers.dart';
import 'package:flinx/features/account/data/data_sources/app_locale_local_data_source.dart';
import 'package:flinx/features/appearance/application/providers.dart';
import 'package:flinx/features/appearance/data/data_sources/app_skin_local_data_source.dart';
import 'package:flinx/features/appearance/domain/entities/app_skin_id.dart';
import 'package:flinx/features/appearance/domain/repositories/app_skin_repository.dart';
import 'package:flinx/features/appearance/presentation/pages/skin_detail_page.dart';
import 'package:flinx/features/appearance/presentation/pages/skin_gallery_page.dart';
import 'package:flinx/shared/l10n/app_localizations.dart';
import 'package:flinx/shared/widgets/flinx_switch.dart';
import 'package:flinx/shared/widgets/flinx_door_command_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  setUpAll(loadSkinQaFont);
  testWidgets(
    'saving disables apply, shows localized failure and preserves the current skin',
    (tester) async {
      final repository = _PendingSaveRepository();
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const SkinDetailPage(skinId: AppSkinId.dark),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appSkinRepositoryProvider.overrideWithValue(repository),
            appRouterProvider.overrideWithValue(router),
          ],
          child: const FlinxApp(),
        ),
      );
      await tester.pumpAndSettle();
      final apply = find.byKey(const ValueKey('skin-apply-button'));
      await tester.scrollUntilVisible(
        apply,
        250,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(apply);
      await tester.pump();
      expect(tester.widget<FilledButton>(apply).onPressed, isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      repository.save.completeError(StateError('disk unavailable'));
      await tester.pumpAndSettle();
      expect(
        find.text('Unable to save this style. Please try again.'),
        findsOneWidget,
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(SkinDetailPage)),
      );
      expect(
        container.read(appSkinControllerProvider).value,
        AppSkinId.minimalist,
      );
      expect(tester.widget<FilledButton>(apply).onPressed, isNotNull);
      await tester.pump(const Duration(seconds: 3));
    },
  );

  testWidgets('theme animations follow changes to reduced-motion settings', (
    tester,
  ) async {
    final router = GoRouter(
      routes: [GoRoute(path: '/', builder: (_, _) => const Scaffold())],
    );
    addTearDown(router.dispose);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appRouterProvider.overrideWithValue(router)],
        child: const FlinxApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<MaterialApp>(find.byType(MaterialApp))
          .themeAnimationDuration,
      AppMotionTokens.themeTransitionDuration,
    );
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<MaterialApp>(find.byType(MaterialApp))
          .themeAnimationDuration,
      Duration.zero,
    );
  });

  testWidgets(
    'restores skin before constructing routes and preserves input on every switch',
    (tester) async {
      final load = Completer<AppSkinId?>();
      var routerBuilds = 0;
      var mounts = 0;
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => _StatefulPage(onMount: () => mounts++),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appSkinRepositoryProvider.overrideWithValue(
              _DelayedRepository(load.future),
            ),
            appLocaleLocalDataSourceProvider.overrideWithValue(
              InMemoryAppLocaleLocalDataSource(initialLanguageCode: 'en'),
            ),
            appRouterProvider.overrideWith((ref) {
              routerBuilds++;
              return router;
            }),
          ],
          child: const FlinxApp(),
        ),
      );
      await tester.pump();
      expect(routerBuilds, 0);
      load.complete(AppSkinId.dark);
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(TextField)),
      );
      expect(
        Theme.of(tester.element(find.byType(TextField))).brightness,
        Brightness.dark,
      );
      await tester.enterText(find.byType(TextField), 'keep this input');
      for (final skin in [
        AppSkinId.technologyWind,
        AppSkinId.minimalist,
        AppSkinId.dark,
      ]) {
        await container
            .read(appSkinControllerProvider.notifier)
            .applySkin(skin);
        await tester.pumpAndSettle();
        expect(find.text('keep this input'), findsOneWidget);
        expect(
          Theme.of(
            tester.element(find.byType(TextField)),
          ).extension<AppSkinTokens>()!.id,
          skin,
        );
      }
      expect(routerBuilds, 1);
      expect(mounts, 1);
    },
  );

  testWidgets('preview is isolated; apply changes current and previous pages', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: SkinGalleryPage.routePath,
      routes: [
        GoRoute(
          path: SkinGalleryPage.routePath,
          builder: (_, _) => const SkinGalleryPage(),
        ),
        GoRoute(
          path: SkinDetailPage.routePath,
          builder: (_, state) => SkinDetailPage(
            skinId: AppSkinId.fromStorageValue(state.pathParameters['skinId'])!,
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appSkinLocalDataSourceProvider.overrideWithValue(
            InMemoryAppSkinLocalDataSource(),
          ),
          appLocaleLocalDataSourceProvider.overrideWithValue(
            InMemoryAppLocaleLocalDataSource(initialLanguageCode: 'en'),
          ),
          appRouterProvider.overrideWithValue(router),
        ],
        child: const FlinxApp(),
      ),
    );
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SkinGalleryPage)),
    );
    router.push(SkinDetailPage.routePathFor(AppSkinId.dark));
    await tester.pumpAndSettle();
    expect(
      container.read(appSkinControllerProvider).value,
      AppSkinId.minimalist,
    );
    final apply = find.byKey(const ValueKey('skin-apply-button'));
    await tester.scrollUntilVisible(
      apply,
      250,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(apply);
    await tester.pumpAndSettle();
    expect(container.read(appSkinControllerProvider).value, AppSkinId.dark);
    expect(tester.widget<FilledButton>(apply).onPressed, isNull);
    router.pop();
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(SkinGalleryPage))).brightness,
      Brightness.dark,
    );
    expect(tester.takeException(), isNull);
  });

  for (final skinId in AppSkinId.values) {
    testWidgets('renders themed controls and appearance page for $skinId', (
      tester,
    ) async {
      tester.view.resetPhysicalSize();
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final key = GlobalKey();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appSkinLocalDataSourceProvider.overrideWithValue(
              InMemoryAppSkinLocalDataSource(skinId.storageValue),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.forSkin(skinId),
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: RepaintBoundary(key: key, child: const SkinGalleryPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      if (skinId == AppSkinId.dark) {
        expect(scaffold.backgroundColor, AppSkinCatalog.dark.pageBackground);
      }
      await captureSkinQa(tester, key, '${skinId.storageValue}_gallery');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.forSkin(skinId),
          home: Builder(
            builder: (context) => RepaintBoundary(
              key: key,
              child: Scaffold(
                body: DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.skin.pageBackground,
                    gradient: context.skin.deviceControlBackgroundGradient,
                  ),
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      Text(
                        'Door controls',
                        style: context.appText.navigationTitle(
                          Theme.of(context).textTheme,
                        ),
                      ),
                      const SizedBox(height: 24),
                      FlinxDoorCommandButton(
                        icon: Icons.keyboard_arrow_up,
                        tooltip: 'Open',
                        onPressed: () {},
                      ),
                      const SizedBox(height: 24),
                      FlinxSwitch(value: true, onChanged: (_) {}),
                      const SizedBox(height: 24),
                      const TextField(
                        decoration: InputDecoration(hintText: 'Device name'),
                      ),
                      const SizedBox(height: 24),
                      const FilledButton(
                        onPressed: null,
                        child: Text('Pending'),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Offline',
                        style: context.appText.safetySensorItemOffline(
                          Theme.of(context).textTheme,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await captureSkinQa(tester, key, '${skinId.storageValue}_controls');
    });
  }
}

class _DelayedRepository implements AppSkinRepository {
  const _DelayedRepository(this.value);
  final Future<AppSkinId?> value;
  @override
  Future<AppSkinId?> readSkin() => value;
  @override
  Future<void> saveSkin(AppSkinId skin) async {}
}

class _StatefulPage extends StatefulWidget {
  const _StatefulPage({required this.onMount});
  final VoidCallback onMount;
  @override
  State<_StatefulPage> createState() => _StatefulPageState();
}

class _StatefulPageState extends State<_StatefulPage> {
  @override
  void initState() {
    super.initState();
    widget.onMount();
  }

  @override
  Widget build(BuildContext context) => const Scaffold(body: TextField());
}

class _PendingSaveRepository implements AppSkinRepository {
  final save = Completer<void>();
  @override
  Future<AppSkinId?> readSkin() async => AppSkinId.minimalist;
  @override
  Future<void> saveSkin(AppSkinId skin) => save.future;
}
