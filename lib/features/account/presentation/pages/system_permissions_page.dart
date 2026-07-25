import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
import '../../application/system_permissions_controller.dart';
import '../../domain/entities/system_permission.dart';

class SystemPermissionsPage extends ConsumerStatefulWidget {
  const SystemPermissionsPage({super.key});

  static const routeName = 'system-permissions';
  static const routePath = '/account/system-permissions';

  @override
  ConsumerState<SystemPermissionsPage> createState() =>
      _SystemPermissionsPageState();
}

class SystemPermissionsPageKeys {
  const SystemPermissionsPageKeys._();

  static ValueKey<String> card(SystemPermission permission) =>
      ValueKey('system-permissions-${permission.name}-card');
}

class _SystemPermissionsPageState extends ConsumerState<SystemPermissionsPage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(systemPermissionsControllerProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final viewState = ref.watch(systemPermissionsControllerProvider);
    final controller = ref.read(systemPermissionsControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: const FlinxNavigationBar(title: '', showBottomDivider: false),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacingTokens.systemPermissionsPageHorizontal,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(
                    height: AppSpacingTokens.systemPermissionsTitleTop,
                  ),
                  Text(
                    l10n.systemPermissionsPageTitle,
                    style: AppTextTokens.systemPermissionsTitle(
                      Theme.of(context).textTheme,
                    ),
                  ),
                  const SizedBox(
                    height: AppSpacingTokens.systemPermissionsTitleToList,
                  ),
                  if (viewState.isLoading)
                    const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: SystemPermission.values.length,
                        separatorBuilder: (_, index) => const SizedBox(
                          height: AppSpacingTokens.systemPermissionsCardGap,
                        ),
                        itemBuilder: (context, index) {
                          final permission = SystemPermission.values[index];
                          final state =
                              viewState.permissionFor(permission) ??
                              SystemPermissionState(
                                permission: permission,
                                status: SystemPermissionStatus.denied,
                              );
                          return _PermissionCard(
                            permission: permission,
                            state: state,
                            isPending:
                                viewState.pendingPermission == permission,
                            onTap: () => controller.activate(permission),
                          );
                        },
                      ),
                    ),
                  if (viewState.error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 16),
                      child: Text(
                        viewState.error!.messageKey ==
                                'systemPermissionsLoadError'
                            ? l10n.systemPermissionsLoadError
                            : l10n.systemPermissionsRequestError,
                        style: AppTextTokens.systemPermissionsCardStatus(
                          Theme.of(context).textTheme,
                        ),
                      ),
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

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
    required this.permission,
    required this.state,
    required this.isPending,
    required this.onTap,
  });

  final SystemPermission permission;
  final SystemPermissionState state;
  final bool isPending;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final granted = state.isGranted;
    final title = switch (permission) {
      SystemPermission.location => l10n.systemPermissionsLocation,
      SystemPermission.camera => l10n.systemPermissionsCamera,
      SystemPermission.microphone => l10n.systemPermissionsMicrophone,
      SystemPermission.storage => l10n.systemPermissionsStorage,
      SystemPermission.bluetooth => l10n.systemPermissionsBluetooth,
    };

    return Semantics(
      button: !granted,
      label: title,
      child: InkWell(
        key: SystemPermissionsPageKeys.card(permission),
        borderRadius: BorderRadius.circular(
          AppShapeTokens.systemPermissionsCardRadius,
        ),
        onTap: granted || isPending ? null : onTap,
        child: Container(
          height: AppSpacingTokens.systemPermissionsCardHeight,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacingTokens.systemPermissionsCardHorizontal,
          ),
          decoration: BoxDecoration(
            color: AppColors.systemPermissionsCard,
            borderRadius: BorderRadius.circular(
              AppShapeTokens.systemPermissionsCardRadius,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextTokens.systemPermissionsCardTitle(
                        Theme.of(context).textTheme,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      granted
                          ? l10n.systemPermissionsGranted
                          : l10n.systemPermissionsDenied,
                      style: AppTextTokens.systemPermissionsCardStatus(
                        Theme.of(context).textTheme,
                      ),
                    ),
                  ],
                ),
              ),
              if (isPending)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  granted ? Icons.check_rounded : Icons.close_rounded,
                  color: granted
                      ? AppColors.systemPermissionsGranted
                      : AppColors.systemPermissionsDenied,
                  size: AppSpacingTokens.systemPermissionsStatusIconSize,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
