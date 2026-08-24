import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../core/errors/app_error.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
import '../../application/providers.dart';
import '../../../home/application/providers.dart';
import '../../../home/domain/entities/home_scene.dart';
import '../../../home/presentation/pages/device_share_page.dart';
import '../../../device_control/presentation/pages/already_added_devices_page.dart';
import '../../../device_control/presentation/pages/device_command_page.dart';
import 'add_new_doors_page.dart';

class SmartOpenerConnectionSuccessPage extends ConsumerStatefulWidget {
  const SmartOpenerConnectionSuccessPage({super.key});

  static const routeName = 'smart-opener-connection-success';
  static const routePath = '/add-device/smart-opener/success';

  @override
  ConsumerState<SmartOpenerConnectionSuccessPage> createState() =>
      _SmartOpenerConnectionSuccessPageState();
}

class _SmartOpenerConnectionSuccessPageState
    extends ConsumerState<SmartOpenerConnectionSuccessPage> {
  late final TextEditingController _nameController;
  late final FocusNode _nameFocusNode;
  String _savedName = '';
  String? _renameError;
  HomeScene? _selectedScene;
  var _isRenaming = false;
  var _isMovingScene = false;

  @override
  void initState() {
    super.initState();
    final initialName =
        ref.read(addDeviceControllerProvider).onboardedDoor?.name?.trim() ?? '';
    _savedName = initialName;
    _nameController = TextEditingController(text: initialName);
    _nameFocusNode = FocusNode()..addListener(_onNameFocusChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(addDeviceControllerProvider.notifier).logSuccessPageEntered();
      }
    });
  }

  @override
  void dispose() {
    _nameFocusNode
      ..removeListener(_onNameFocusChanged)
      ..dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _onNameFocusChanged() {
    if (!_nameFocusNode.hasFocus) {
      unawaited(_saveName());
    }
  }

  Future<void> _saveName() async {
    if (_isRenaming) {
      return;
    }
    final doorId = ref.read(addDeviceControllerProvider).onboardedDoor?.id;
    final name = _nameController.text.trim();
    if (doorId == null || name.isEmpty || name == _savedName) {
      return;
    }

    setState(() {
      _isRenaming = true;
      _renameError = null;
    });
    final requestId =
        'onboarding-rename-door-$doorId-${DateTime.now().toUtc().microsecondsSinceEpoch}';
    try {
      await ref.read(renameHomeDoorUseCaseProvider)(
        doorId: doorId,
        name: name,
        requestId: requestId,
      );
      _savedName = name;
      ref.invalidate(homeDevicesProvider);
      if (mounted) {
        setState(() {
          _renameError = null;
        });
      }
    } catch (error) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        setState(() {
          _renameError =
              error is AppError && error.code == AppErrorCode.networkUnavailable
              ? l10n.smartOpenerRenameNetworkUnavailable
              : l10n.smartOpenerRenameFailed;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRenaming = false;
        });
      }
    }
  }

  Future<void> _showSceneSheet() async {
    final scene = await showModalBottomSheet<HomeScene>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.overlaySoft,
      isScrollControlled: true,
      builder: (context) =>
          _SceneSelectionSheet(selectedSceneId: _selectedScene?.id),
    );
    if (!mounted || scene == null) {
      return;
    }
    await _moveToScene(scene);
  }

  Future<void> _moveToScene(HomeScene scene) async {
    if (_isMovingScene) {
      return;
    }
    final doorId = ref.read(addDeviceControllerProvider).onboardedDoor?.id;
    if (doorId == null) {
      return;
    }

    setState(() {
      _isMovingScene = true;
    });
    final requestId =
        'onboarding-move-door-$doorId-to-${scene.id}-${DateTime.now().toUtc().microsecondsSinceEpoch}';
    try {
      await ref.read(moveHomeDoorToSceneUseCaseProvider)(
        doorId: doorId,
        sceneId: scene.id,
        requestId: requestId,
      );
      _selectedScene = scene;
      ref.invalidate(homeScenesProvider);
      ref.invalidate(homeDevicesProvider);
    } catch (error) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        final message =
            error is AppError && error.code == AppErrorCode.networkUnavailable
            ? l10n.chooseSceneMoveNetworkUnavailable
            : l10n.chooseSceneMoveFailed;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isMovingScene = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final addDeviceState = ref.watch(addDeviceControllerProvider);
    final onboardedDoor = addDeviceState.onboardedDoor;
    final deviceId = addDeviceState.selectedDevice?.id ?? '';
    final isAddingChildDevice =
        addDeviceState.onboardingDoorId?.trim().isNotEmpty == true;
    final showName = !isAddingChildDevice;
    final showScene = showName && addDeviceState.onboardingSceneId == null;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: const FlinxNavigationBar(title: '', showBottomDivider: false),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final topGap = constraints.maxHeight < 760 ? 34.0 : 70.0;

          return SafeArea(
            top: false,
            child: ListView(
              padding: EdgeInsets.fromLTRB(20, topGap, 20, 34),
              children: [
                const Center(child: _SuccessCheck()),
                const SizedBox(height: 20),
                Text(
                  l10n.smartOpenerConnectionSuccessTitle,
                  textAlign: TextAlign.center,
                  style: AppTextTokens.smartOpenerConnectingTitle(textTheme),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.smartOpenerConnectionSuccessDescription,
                  textAlign: TextAlign.center,
                  style: AppTextTokens.smartOpenerBodyCenter(textTheme),
                ),
                SizedBox(height: 80),
                if (showName) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 10, right: 10),
                    child: _SuccessNameField(
                      controller: _nameController,
                      focusNode: _nameFocusNode,
                      enabled: !_isRenaming,
                      hintText: l10n.smartOpenerDeviceNamePlaceholder,
                    ),
                  ),
                  if (_renameError != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                      child: Text(
                        _renameError!,
                        style: TextStyle(color: AppColors.toastError),
                      ),
                    ),
                ],
                if (showScene)
                  Padding(
                    padding: const EdgeInsets.only(left: 10, right: 10),
                    child: _SuccessFormRow(
                      icon: Icons.view_in_ar_outlined,
                      label: _selectedScene?.name.trim().isNotEmpty == true
                          ? _selectedScene!.name
                          : l10n.smartOpenerSelectScenePlaceholder,
                      trailing: Icons.chevron_right,
                      onTap: _isMovingScene ? null : _showSceneSheet,
                    ),
                  ),
                SizedBox(height: 80),
                Text(
                  l10n.smartOpenerInviteFamilyTip,
                  textAlign: TextAlign.center,
                  style: AppTextTokens.smartOpenerBodyCenter(textTheme),
                ),
                const SizedBox(height: 13),
                Padding(
                  padding: EdgeInsetsGeometry.only(left: 10, right: 10),
                  child: _SuccessActionButton(
                    label: l10n.smartOpenerShareAction,
                    isPrimary: false,
                    onPressed: () =>
                        _showShareDialog(context, doorId: onboardedDoor?.id),
                  ),
                ),
                const SizedBox(height: 19),
                Padding(
                  padding: EdgeInsetsGeometry.only(left: 10, right: 10),
                  child: _SuccessActionButton(
                    label: l10n.smartOpenerTryAction,
                    onPressed: onboardedDoor == null
                        ? null
                        : () => _openDeviceCommand(
                            context,
                            doorId: onboardedDoor.id.toString(),
                            deviceId: deviceId,
                            onboardingFlowId:
                                addDeviceState.onboardingFlowId ?? '',
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openDeviceCommand(
    BuildContext context, {
    required String doorId,
    required String deviceId,
    required String onboardingFlowId,
  }) {
    ref.read(addDeviceControllerProvider.notifier).logDeviceDetailNavigation();

    final router = GoRouter.of(context);
    final navigator = Navigator.of(context);
    String? flowBoundaryRouteName;
    final location =
        '${DeviceCommandPage.routePath}'
        '?doorId=${Uri.encodeQueryComponent(doorId)}'
        '&deviceId=${Uri.encodeQueryComponent(deviceId)}'
        '&onboardingFlowId=${Uri.encodeQueryComponent(onboardingFlowId)}';

    navigator.popUntil((route) {
      final routeName = route.settings.name;
      if (routeName == AddNewDoorsPage.routeName ||
          routeName == AlreadyAddedDevicesPage.routeName) {
        flowBoundaryRouteName = routeName;
        return true;
      }
      return route.isFirst;
    });

    if (flowBoundaryRouteName == AlreadyAddedDevicesPage.routeName &&
        navigator.canPop()) {
      navigator.pop(deviceId);
      return;
    }

    router.pushReplacement(location);
  }

  Future<void> _showShareDialog(
    BuildContext context, {
    required int? doorId,
  }) async {
    final shouldShare = await showDialog<bool>(
      context: context,
      barrierColor: AppColors.overlayStrong,
      builder: (context) => const _ShareDeviceDialog(),
    );
    if (!mounted || shouldShare != true || doorId == null) {
      return;
    }
    await context.pushNamed(DeviceSharePage.routeName, extra: doorId);
  }
}

class _SuccessCheck extends StatelessWidget {
  const _SuccessCheck();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: const BoxDecoration(
        color: AppColors.smartOpenerSuccess,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.check, color: Colors.white, size: 40),
    );
  }
}

class _SuccessFormRow extends StatelessWidget {
  const _SuccessFormRow({
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final IconData? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      child: Container(
        height: 66,
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.smartOpenerDivider),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: AppColors.textIcon),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextTokens.smartOpenerFormText(textTheme),
              ),
            ),
            if (trailing != null)
              Icon(trailing, size: 24, color: AppColors.textPrimary),
          ],
        ),
      ),
    );
  }
}

class _SuccessNameField extends StatelessWidget {
  const _SuccessNameField({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.hintText,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      height: 66,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.smartOpenerDivider)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.door_front_door_outlined,
            size: 24,
            color: AppColors.textIcon,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: enabled,
              textInputAction: TextInputAction.done,
              style: AppTextTokens.smartOpenerFormText(textTheme),
              decoration: InputDecoration.collapsed(
                hintText: hintText,
                hintStyle: AppTextTokens.smartOpenerFormText(textTheme),
              ),
              onEditingComplete: focusNode.unfocus,
            ),
          ),
        ],
      ),
    );
  }
}

class _SceneSelectionSheet extends ConsumerWidget {
  const _SceneSelectionSheet({required this.selectedSceneId});

  final int? selectedSceneId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scenesState = ref.watch(homeScenesProvider);
    return Material(
      color: AppColors.backgroundPrimary,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: scenesState.when(
            loading: () => const SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => SizedBox(
              height: 180,
              child: Center(
                child: TextButton.icon(
                  onPressed: () => ref.invalidate(homeScenesProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(l10n.addDoorSceneLoadFailed),
                ),
              ),
            ),
            data: (scenes) => scenes.isEmpty
                ? SizedBox(
                    height: 180,
                    child: Center(child: Text(l10n.addDoorSceneEmpty)),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: scenes.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final scene = scenes[index];
                      return ListTile(
                        title: Text(
                          scene.name.trim().isEmpty
                              ? l10n.addDoorSceneDefault
                              : scene.name,
                        ),
                        trailing: scene.id == selectedSceneId
                            ? const Icon(Icons.check)
                            : null,
                        onTap: () => Navigator.of(context).pop(scene),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}

class _SuccessActionButton extends StatelessWidget {
  const _SuccessActionButton({
    required this.label,
    required this.onPressed,
    this.isPrimary = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      height: 50,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: isPrimary
              ? AppColors.brandPrimary
              : AppColors.smartOpenerSecondaryButton,
          foregroundColor: isPrimary ? Colors.white : AppColors.textPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(34),
          ),
        ),
        child: Text(
          label,
          style: isPrimary
              ? AppTextTokens.smartOpenerActionButton(textTheme)
              : AppTextTokens.smartOpenerSecondaryActionButton(textTheme),
        ),
      ),
    );
  }
}

class _ShareDeviceDialog extends StatelessWidget {
  const _ShareDeviceDialog();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      backgroundColor: AppColors.backgroundPrimary,
      insetPadding: const EdgeInsets.symmetric(horizontal: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.smartOpenerShareDialogTitle,
                style: AppTextTokens.smartOpenerShareDialogTitle(textTheme),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.smartOpenerShareDialogDescription,
                style: AppTextTokens.smartOpenerShareDialogDescription(
                  textTheme,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 38,
                child: TextField(
                  keyboardType: TextInputType.emailAddress,
                  style: AppTextTokens.smartOpenerShareDialogAccountHint(
                    textTheme,
                  ),
                  decoration: InputDecoration(
                    hintText: l10n.smartOpenerShareDialogAccountHint,
                    hintStyle: AppTextTokens.smartOpenerShareDialogAccountHint(
                      textTheme,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: const BorderSide(
                        color: AppColors.deviceShareFieldBorder,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: const BorderSide(
                        color: AppColors.brandPrimary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _ShareDialogActionButton(
                      label: l10n.smartOpenerCancelAction,
                      backgroundColor: AppColors.deviceShareCancelButton,
                      foregroundColor: AppColors.textPrimary,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 30),
                  Expanded(
                    child: _ShareDialogActionButton(
                      label: l10n.smartOpenerShareNowAction,
                      backgroundColor: AppColors.brandPrimary,
                      foregroundColor: Colors.white,
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShareDialogActionButton extends StatelessWidget {
  const _ShareDialogActionButton({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onPressed,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          shape: const StadiumBorder(),
          textStyle: AppTextTokens.smartOpenerShareDialogAccountHint2(
            Theme.of(context).textTheme,
          ).copyWith(fontWeight: FontWeight.w500),
        ),
        child: Text(label),
      ),
    );
  }
}
