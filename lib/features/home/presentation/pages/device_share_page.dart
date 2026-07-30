import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../core/validation/input_validators.dart';
import '../../../account/application/providers.dart';
import '../../../account/application/shared_door_member_actions_controller.dart';
import '../../../account/domain/entities/shared_device_share.dart';
import '../../../account/domain/entities/shared_door_members.dart';
import '../../../account/presentation/widgets/account_avatar_code_assets.dart';
import '../../application/door_share_controller.dart';
import '../../application/providers.dart';
import '../../domain/entities/door_share.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';

class ChooseSceneAssetPaths {
  const ChooseSceneAssetPaths._();

  static const deviceSharePageTime =
      'assets/icons/home/device_share_page_time.png';
  static const capabilitiesSelected =
      'assets/icons/home/garagePlaceholderCapabilitiesSelected.png';
  static const capabilitiesUnselected =
      'assets/icons/home/garagePlaceholderCapabilitiesNoSelected.png';
}

class DeviceSharePage extends ConsumerStatefulWidget {
  const DeviceSharePage({super.key, this.doorId, this.editingMember});

  static const routeName = 'device-share';
  static const routePath = '/device-share';

  /// When provided, the page renders the member-editing variant.
  final int? doorId;
  final SharedDoorMember? editingMember;

  @override
  ConsumerState<DeviceSharePage> createState() => _DeviceSharePageState();
}

/// Complete route context required to edit an outgoing door share.
class DeviceShareEditRouteData {
  const DeviceShareEditRouteData({required this.doorId, required this.member});

  final int doorId;
  final SharedDoorMember member;
}

enum _SharePermission { administrator, guest }

enum _SharePeriod { neverExpired, twoHours, customize }

class DeviceSharePageKeys {
  const DeviceSharePageKeys._();

  static const editMemberSummary = ValueKey('device-share-edit-member-summary');
  static const editDeleteAction = ValueKey('device-share-edit-delete-action');
}

class _DeviceSharePageState extends ConsumerState<DeviceSharePage> {
  final _emailController = TextEditingController();
  var _permission = _SharePermission.administrator;
  var _period = _SharePeriod.neverExpired;
  var _selectedCapabilities = <ShareCapability>{};
  DateTime? _periodEndsAt;
  var _showAddressFormatError = false;

  bool get _isEditing => widget.editingMember != null;
  int? get _doorId => widget.doorId;

  @override
  void initState() {
    super.initState();
    final member = widget.editingMember;
    if (member != null) {
      _emailController.text = member.email;
      _permission = member.role == SharedDoorMemberRole.administrator
          ? _SharePermission.administrator
          : _SharePermission.guest;
      _period = switch (member.expiryType) {
        SharedDoorMemberExpiryType.neverExpired => _SharePeriod.neverExpired,
        SharedDoorMemberExpiryType.twoHours => _SharePeriod.twoHours,
        SharedDoorMemberExpiryType.customize => _SharePeriod.customize,
      };
      _periodEndsAt = member.expiryType == SharedDoorMemberExpiryType.customize
          ? member.expiresAt
          : null;
      _selectedCapabilities = member.capabilityCodes
          .map(ShareCapability.fromWireValue)
          .whereType<ShareCapability>()
          .toSet();
    }
    _emailController.addListener(_onAddressChanged);
  }

  @override
  void dispose() {
    _emailController
      ..removeListener(_onAddressChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final doorId = _doorId;
    final capabilitiesAsync = doorId == null
        ? const AsyncValue<List<ShareCapability>>.data([])
        : ref.watch(doorShareCapabilitiesProvider(doorId));
    final submitState = ref.watch(doorShareControllerProvider);
    final isDeleting = ref.watch(sharedDoorMemberActionsControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: FlinxNavigationBar(
        title: '',
        showBottomDivider: false,
        actions: _isEditing
            ? [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Semantics(
                    label: l10n.sharedDeviceMemberDeleteLabel,
                    enabled: false,
                    child: GestureDetector(
                      onTap: submitState.isSubmitting || isDeleting
                          ? null
                          : _deleteMember,
                      child: SizedBox.square(
                        key: DeviceSharePageKeys.editDeleteAction,
                        dimension: AppSpacingTokens.deviceShareEditActionSize,
                        child: Image.asset(
                          SharedDeviceMemberAssetPaths.deleteAction,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.delete_outline,
                            color: AppColors.sharedDeviceMemberActionIcon,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ]
            : null,
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 27, 20, 25),
                    children: [
                      if (_isEditing) ...[
                        _DeviceShareEditMemberSummary(
                          member: widget.editingMember!,
                        ),
                        const SizedBox(
                          height: AppSpacingTokens.deviceShareEditSummaryToForm,
                        ),
                      ] else ...[
                        Text(
                          l10n.deviceShareTitle,
                          style: AppTextTokens.deviceShareTitle(textTheme),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          l10n.deviceShareSubtitle,
                          style: AppTextTokens.deviceShareSubtitle(textTheme),
                        ),
                        const SizedBox(height: 38),
                      ],
                      _ShareFormRow(
                        label: l10n.deviceSharePermissionsLabel,
                        child: _ShareSelectField(
                          value: _permissionLabel(l10n),
                          onTap: _selectPermission,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _ShareFormRow(
                        label: l10n.deviceShareEmailLabel,
                        child: _ShareTextField(
                          controller: _emailController,
                          hasError: _showAddressFormatError,
                          errorText: l10n.deviceShareAddressInvalid,
                          readOnly: _isEditing,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _ShareFormRow(
                        label: l10n.deviceSharePeriodLabel,
                        child: _ShareSelectField(
                          value: _periodLabel(l10n),
                          onTap: _selectPeriod,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SharePeriodSummary(
                        title: l10n.deviceShareTimeLabel,
                        value: _periodEndsAt == null
                            ? null
                            : _formatExpiry(_periodEndsAt!),
                        onTap: _period == _SharePeriod.customize
                            ? _selectCustomTimeFromSummary
                            : null,
                      ),
                      const SizedBox(height: 27),
                      Text(
                        l10n.deviceShareCapabilitiesTitle,
                        style: AppTextTokens.deviceShareSectionTitle(textTheme),
                      ),
                      const SizedBox(height: 8),
                      if (doorId == null && !_isEditing)
                        Text(
                          l10n.deviceShareDoorUnavailable,
                          style: AppTextTokens.deviceShareField(textTheme),
                        )
                      else
                        capabilitiesAsync.when(
                          loading: () => const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          error: (_, _) => TextButton(
                            onPressed: () => ref.invalidate(
                              doorShareCapabilitiesProvider(doorId!),
                            ),
                            child: Text(l10n.deviceShareCapabilitiesLoadFailed),
                          ),
                          data: (capabilities) {
                            _syncCapabilities(capabilities);
                            return _CapabilitiesPanel(
                              items: capabilities
                                  .map(
                                    (capability) => _CapabilityItem(
                                      capability: capability,
                                      label: _capabilityLabel(l10n, capability),
                                    ),
                                  )
                                  .toList(growable: false),
                              selectedCapabilities: _selectedCapabilities,
                              isEnabled:
                                  _isEditing ||
                                  _permission == _SharePermission.administrator,
                              onChanged: _toggleCapability,
                            );
                          },
                        ),
                      if (submitState.error != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _submitErrorLabel(l10n, submitState.error!),
                          style: AppTextTokens.deviceShareFieldError(textTheme),
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 16, 22),
                  child: Row(
                    children: [
                      Expanded(
                        child: _ShareActionButton(
                          label: l10n.deviceShareCancelAction,
                          foregroundColor: AppColors.textPrimary,
                          backgroundColor: AppColors.deviceShareCancelButton,
                          onPressed: () => context.pop(),
                        ),
                      ),
                      const SizedBox(width: 42),
                      Expanded(
                        child: _ShareActionButton(
                          label: l10n.deviceShareConfirmAction,
                          foregroundColor: Colors.white,
                          backgroundColor: _canSubmit
                              ? AppColors.brandPrimary
                              : AppColors.brandPrimaryDisabled,
                          onPressed: _canSubmit ? _confirm : null,
                          buttonKey: const Key('device_share_confirm'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectPermission(BuildContext anchorContext) async {
    final l10n = AppLocalizations.of(context);
    final selected = await _showShareOptionPopup<_SharePermission>(
      context: context,
      anchorContext: anchorContext,
      options: [
        _ShareOption(
          value: _SharePermission.administrator,
          label: l10n.deviceShareAdministratorRole,
        ),
        _ShareOption(
          value: _SharePermission.guest,
          label: l10n.deviceShareGuestRole,
        ),
      ],
    );
    if (selected == null) {
      return;
    }
    setState(() {
      _permission = selected;
      final available = _availableCapabilities;
      _selectedCapabilities = selected == _SharePermission.administrator
          ? available.toSet()
          : available.contains(ShareCapability.doorControl)
          ? {ShareCapability.doorControl}
          : {};
    });
  }

  Future<void> _selectPeriod(BuildContext anchorContext) async {
    final l10n = AppLocalizations.of(context);
    final selected = await _showShareOptionPopup<_SharePeriod>(
      context: context,
      anchorContext: anchorContext,
      options: [
        _ShareOption(
          value: _SharePeriod.neverExpired,
          label: l10n.deviceShareNeverExpired,
        ),
        _ShareOption(
          value: _SharePeriod.twoHours,
          label: l10n.deviceShareTwoHours,
        ),
        _ShareOption(
          value: _SharePeriod.customize,
          label: l10n.deviceShareCustomize,
        ),
      ],
    );
    if (selected == null) {
      return;
    }
    setState(() {
      _period = selected;
      _periodEndsAt = switch (selected) {
        _SharePeriod.neverExpired || _SharePeriod.customize => null,
        _SharePeriod.twoHours => DateTime.now().add(const Duration(hours: 2)),
      };
    });
    if (selected == _SharePeriod.customize) {
      await _selectCustomTimeFromSummary();
    }
  }

  Future<void> _selectCustomTimeFromSummary() async {
    final customTime = await _showCustomizeTimeDialog();
    if (customTime == null) {
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _periodEndsAt = customTime;
    });
  }

  Future<DateTime?> _showCustomizeTimeDialog() {
    return showDialog<DateTime>(
      context: context,
      barrierColor: AppColors.deviceShareDialogOverlay,
      builder: (context) {
        final now = DateTime.now();
        return _CustomizeTimeDialog(
          initialDateTime: _periodEndsAt != null && _periodEndsAt!.isAfter(now)
              ? _periodEndsAt!
              : now.add(const Duration(hours: 2)),
          minimumDateTime: now,
        );
      },
    );
  }

  String _permissionLabel(AppLocalizations l10n) {
    return switch (_permission) {
      _SharePermission.administrator => l10n.deviceShareAdministratorRole,
      _SharePermission.guest => l10n.deviceShareGuestRole,
    };
  }

  String _periodLabel(AppLocalizations l10n) {
    return switch (_period) {
      _SharePeriod.neverExpired => l10n.deviceShareNeverExpired,
      _SharePeriod.twoHours => l10n.deviceShareTwoHours,
      _SharePeriod.customize => l10n.deviceShareCustomize,
    };
  }

  bool get _canConfirm {
    return _emailController.text.trim().isNotEmpty &&
        (_period != _SharePeriod.customize || _periodEndsAt != null);
  }

  bool get _canSubmit {
    final doorId = _doorId;
    if (!_canConfirm || doorId == null) return false;
    final capabilities = ref.read(doorShareCapabilitiesProvider(doorId));
    final submitState = ref.read(doorShareControllerProvider);
    return capabilities.hasValue &&
        !submitState.isSubmitting &&
        !ref.read(sharedDoorMemberActionsControllerProvider);
  }

  void _onAddressChanged() {
    if (_showAddressFormatError) {
      setState(() {
        _showAddressFormatError = false;
      });
      return;
    }
    setState(() {});
  }

  void _toggleCapability(ShareCapability capability) {
    if (!_isEditing && _permission != _SharePermission.administrator) {
      return;
    }
    setState(() {
      if (_selectedCapabilities.contains(capability)) {
        _selectedCapabilities.remove(capability);
      } else {
        _selectedCapabilities.add(capability);
      }
    });
  }

  Future<void> _confirm() async {
    if (!InputValidators.isValidEmail(_emailController.text)) {
      setState(() {
        _showAddressFormatError = true;
      });
      return;
    }
    final doorId = _doorId;
    if (doorId == null) return;
    final role = _permission == _SharePermission.administrator
        ? DoorShareRole.administrator
        : DoorShareRole.guest;
    final expiryType = switch (_period) {
      _SharePeriod.neverExpired => DoorShareExpiryType.neverExpired,
      _SharePeriod.twoHours => DoorShareExpiryType.twoHours,
      _SharePeriod.customize => DoorShareExpiryType.customize,
    };
    final expiresAtUtcMillis = _period == _SharePeriod.customize
        ? _periodEndsAt?.toUtc().millisecondsSinceEpoch
        : null;
    final controller = ref.read(doorShareControllerProvider.notifier);
    final success = _isEditing
        ? await controller.update(
            shareId: widget.editingMember!.shareId,
            command: UpdateDoorShareCommand(
              role: role,
              expiryType: expiryType,
              expiresAtUtcMillis: expiresAtUtcMillis,
              capabilities: _selectedCapabilities.toList(growable: false),
            ),
          )
        : await controller.submit(
            doorId: doorId,
            command: CreateDoorShareCommand(
              receiverEmail: _emailController.text,
              role: role,
              expiryType: expiryType,
              expiresAtUtcMillis: expiresAtUtcMillis,
              capabilities: _selectedCapabilities.toList(growable: false),
            ),
          );
    if (success && mounted) {
      if (_isEditing) ref.invalidate(sharedDoorMembersProvider(doorId));
      context.pop();
    }
  }

  Future<void> _deleteMember() async {
    final doorId = _doorId;
    final member = widget.editingMember;
    if (doorId == null || member == null) return;
    final error = await ref
        .read(sharedDoorMemberActionsControllerProvider.notifier)
        .delete(shareId: member.shareId);
    if (error == null && mounted) {
      ref.invalidate(sharedDoorMembersProvider(doorId));
      context.pop();
    }
  }

  List<ShareCapability> get _availableCapabilities => _doorId == null
      ? const []
      : ref
            .read(doorShareCapabilitiesProvider(_doorId!))
            .maybeWhen(data: (value) => value, orElse: () => const []);

  void _syncCapabilities(List<ShareCapability> capabilities) {
    final valid = _selectedCapabilities.intersection(capabilities.toSet());
    if (_selectedCapabilities.isEmpty) {
      _selectedCapabilities = _permission == _SharePermission.administrator
          ? capabilities.toSet()
          : capabilities.contains(ShareCapability.doorControl)
          ? {ShareCapability.doorControl}
          : {};
    } else if (valid.length != _selectedCapabilities.length) {
      _selectedCapabilities = valid;
    }
  }

  String _capabilityLabel(AppLocalizations l10n, ShareCapability capability) =>
      switch (capability) {
        ShareCapability.doorControl => l10n.deviceShareCapabilityDoorControl,
        ShareCapability.partialOpen => l10n.deviceShareCapabilityPartialOpen,
        ShareCapability.partialOpenLevel =>
          l10n.deviceShareCapabilityPartialOpenLevel,
        ShareCapability.ledControl => l10n.deviceShareCapabilityLedControl,
        ShareCapability.ledOffDelay => l10n.deviceShareCapabilityLedDelay,
        ShareCapability.autoClose => l10n.deviceShareCapabilityAutoClose,
        ShareCapability.transmitterPairing =>
          l10n.deviceShareCapabilityTransmitterPairing,
        ShareCapability.forceMargin => l10n.deviceShareCapabilityDoorOpenForce,
        ShareCapability.doorOpenReminder =>
          l10n.deviceShareCapabilityDoorOpenReminder,
        ShareCapability.openingSpeed => l10n.deviceShareCapabilityDoorOpenSpeed,
      };

  String _submitErrorLabel(AppLocalizations l10n, Object _) =>
      l10n.deviceShareSubmitFailed;

  String _formatExpiry(DateTime value) {
    return DateFormat('HH:mm dd-MM-yyyy').format(value);
  }
}

class _DeviceShareEditMemberSummary extends ConsumerWidget {
  const _DeviceShareEditMemberSummary({required this.member});

  final SharedDoorMember member;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final avatarImage = ref.watch(
      homeDoorCoverImageSourceProvider(member.receiverAvatarFileId),
    );

    return Container(
      key: DeviceSharePageKeys.editMemberSummary,
      height: AppSpacingTokens.deviceShareEditSummaryHeight,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacingTokens.deviceShareEditSummaryHorizontal,
      ),
      decoration: const BoxDecoration(
        color: AppColors.deviceShareEditSummaryBackground,
        borderRadius: BorderRadius.all(
          Radius.circular(AppShapeTokens.deviceShareEditSummaryRadius),
        ),
      ),
      child: Row(
        children: [
          SizedBox.square(
            dimension: AppSpacingTokens.deviceShareEditSummaryAvatarSize,
            child: ClipOval(
              child: member.receiverAvatarCode != null
                  ? Image.asset(
                      member.receiverAvatarCode!.assetPath,
                      fit: BoxFit.cover,
                    )
                  : avatarImage == null
                  ? const _DeviceShareEditMemberAvatarPlaceholder()
                  : Image.network(
                      avatarImage.url,
                      headers: avatarImage.headers,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const _DeviceShareEditMemberAvatarPlaceholder(),
                    ),
            ),
          ),
          const SizedBox(
            width: AppSpacingTokens.deviceShareEditSummaryAvatarGap,
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextTokens.deviceShareEditSummaryEmail(textTheme),
                ),
                const SizedBox(
                  height: AppSpacingTokens.deviceShareEditSummaryTextGap,
                ),
                if (member.expiryType ==
                    SharedDoorMemberExpiryType.neverExpired)
                  Text(
                    l10n.deviceShareNeverExpired,
                    style: AppTextTokens.deviceShareEditSummaryMetadata(
                      textTheme,
                    ),
                  )
                else if (member.expiresAt != null)
                  Text(
                    DateFormat('yyyy-MM-dd HH:mm:ss').format(member.expiresAt!),
                    style: AppTextTokens.deviceShareEditSummaryMetadata(
                      textTheme,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceShareEditMemberAvatarPlaceholder extends StatelessWidget {
  const _DeviceShareEditMemberAvatarPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.sharedDeviceMemberAvatarPlaceholder,
      child: Center(
        child: Icon(
          Icons.person_outline,
          color: AppColors.sharedDeviceMemberAvatarPlaceholderIcon,
        ),
      ),
    );
  }
}

class _ShareFormRow extends StatelessWidget {
  const _ShareFormRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: AppTextTokens.deviceShareLabel(Theme.of(context).textTheme),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _ShareSelectField extends StatelessWidget {
  const _ShareSelectField({required this.value, required this.onTap});

  final String value;
  final ValueChanged<BuildContext> onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(context),
      child: _ShareFieldShell(
        child: Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: AppTextTokens.deviceShareInputValue(
                  Theme.of(context).textTheme,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.brandPrimary,
              size: 26,
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareTextField extends StatelessWidget {
  const _ShareTextField({
    required this.controller,
    required this.hasError,
    required this.errorText,
    required this.readOnly,
  });

  final TextEditingController controller;
  final bool hasError;
  final String errorText;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ShareFieldShell(
          borderColor: hasError
              ? AppColors.deviceShareFieldError
              : AppColors.deviceShareFieldBorder,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: TextField(
            controller: controller,
            readOnly: readOnly,
            style: AppTextTokens.deviceShareInputValue(
              Theme.of(context).textTheme,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isCollapsed: true,
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Text(
            errorText,
            style: AppTextTokens.deviceShareFieldError(
              Theme.of(context).textTheme,
            ),
          ),
        ],
      ],
    );
  }
}

class _ShareFieldShell extends StatelessWidget {
  const _ShareFieldShell({
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 14),
    this.borderColor = AppColors.deviceShareFieldBorder,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: padding,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.backgroundPrimary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }
}

class _SharePeriodSummary extends StatelessWidget {
  const _SharePeriodSummary({required this.title, this.value, this.onTap});

  final String title;
  final String? value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isEnabled = onTap != null;

    return GestureDetector(
      key: const Key('device_share_time'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.deviceShareFieldDisabled,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.deviceShareFieldBorder),
        ),
        child: Row(
          children: [
            Image.asset(
              ChooseSceneAssetPaths.deviceSharePageTime,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.schedule_rounded,
                  color: AppColors.iconHomeAction,
                  size: 22,
                );
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: AppTextTokens.deviceShareField(textTheme),
              ),
            ),
            if (value != null) ...[
              Text(
                value!,
                style: AppTextTokens.deviceShareInputValue(textTheme),
              ),
              const SizedBox(width: 8),
            ],
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: isEnabled
                  ? AppColors.brandPrimary
                  : AppColors.borderHomePlaceholder,
              size: 26,
            ),
          ],
        ),
      ),
    );
  }
}

class _CapabilitiesPanel extends StatelessWidget {
  const _CapabilitiesPanel({
    required this.items,
    required this.selectedCapabilities,
    required this.isEnabled,
    required this.onChanged,
  });

  final List<_CapabilityItem> items;
  final Set<ShareCapability> selectedCapabilities;
  final bool isEnabled;
  final ValueChanged<ShareCapability> onChanged;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundPrimary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.deviceShareFieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in items) ...[
            SizedBox(
              height: 26,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.label,
                      style: AppTextTokens.deviceShareField(
                        Theme.of(context).textTheme,
                      ),
                    ),
                  ),
                  _CapabilityAvailabilityIcon(
                    capability: item.capability,
                    isSelected: selectedCapabilities.contains(item.capability),
                    isEnabled: isEnabled,
                    onTap: () => onChanged(item.capability),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CapabilityItem {
  const _CapabilityItem({required this.capability, required this.label});

  final ShareCapability capability;
  final String label;
}

class _CapabilityAvailabilityIcon extends StatelessWidget {
  const _CapabilityAvailabilityIcon({
    required this.capability,
    required this.isSelected,
    required this.isEnabled,
    required this.onTap,
  });

  final ShareCapability capability;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: isEnabled,
      enabled: isEnabled,
      selected: isSelected,
      child: GestureDetector(
        key: Key('device_share_capability_${capability.name}'),
        behavior: HitTestBehavior.opaque,
        onTap: isEnabled ? onTap : null,
        child: Opacity(
          opacity: isEnabled ? 1 : AppOpacityTokens.deviceShareDisabled,
          child: SizedBox(
            width: 20,
            height: 20,
            child: Image.asset(
              isSelected
                  ? ChooseSceneAssetPaths.capabilitiesSelected
                  : ChooseSceneAssetPaths.capabilitiesUnselected,
              errorBuilder: (context, error, stackTrace) => Icon(
                isSelected ? Icons.check_rounded : Icons.close_rounded,
                color: isSelected
                    ? AppColors.deviceShareCheckbox
                    : AppColors.deviceShareUnavailable,
                size: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShareOption<T> {
  const _ShareOption({required this.value, required this.label});

  final T value;
  final String label;
}

Future<T?> _showShareOptionPopup<T>({
  required BuildContext context,
  required BuildContext anchorContext,
  required List<_ShareOption<T>> options,
}) {
  final anchorBox = anchorContext.findRenderObject()! as RenderBox;
  final anchorOffset = anchorBox.localToGlobal(Offset.zero);

  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: AppColors.deviceShareDialogOverlay,
    transitionDuration: const Duration(milliseconds: 120),
    pageBuilder: (context, animation, secondaryAnimation) {
      return Stack(
        children: [
          Positioned(
            left: anchorOffset.dx,
            top: anchorOffset.dy,
            width: anchorBox.size.width,
            child: _ShareOptionPopup<T>(options: options),
          ),
        ],
      );
    },
  );
}

class _ShareOptionPopup<T> extends StatelessWidget {
  const _ShareOptionPopup({required this.options});

  final List<_ShareOption<T>> options;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: AppColors.backgroundPrimary,
      elevation: 8,
      borderRadius: BorderRadius.circular(8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var index = 0; index < options.length; index++) ...[
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () =>
                        Navigator.of(context).pop(options[index].value),
                    child: SizedBox(
                      height: 50,
                      child: Center(
                        child: Text(
                          options[index].label,
                          style: AppTextTokens.deviceShareDialogOption(
                            textTheme,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (index != options.length - 1)
                    const Divider(
                      height: 1,
                      thickness: 1,
                      indent: 12,
                      endIndent: 12,
                      color: AppColors.deviceShareFieldBorder,
                    ),
                ],
              ],
            ),
            const Positioned(
              top: 8,
              right: 8,
              child: IgnorePointer(
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.brandPrimary,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomizeTimeDialog extends StatefulWidget {
  const _CustomizeTimeDialog({
    required this.initialDateTime,
    required this.minimumDateTime,
  });

  final DateTime initialDateTime;
  final DateTime minimumDateTime;

  @override
  State<_CustomizeTimeDialog> createState() => _CustomizeTimeDialogState();
}

class _CustomizeTimeDialogState extends State<_CustomizeTimeDialog> {
  late DateTime _visibleMonth;
  late DateTime _today;
  late DateTime _selectedDate;
  late int _selectedHour;

  @override
  void initState() {
    super.initState();
    final now = widget.minimumDateTime;
    final initial = widget.initialDateTime;
    _today = DateTime(now.year, now.month, now.day);
    _selectedDate =
        DateTime(initial.year, initial.month, initial.day).isBefore(_today)
        ? _today
        : DateTime(initial.year, initial.month, initial.day);
    _visibleMonth = DateTime(_selectedDate.year, _selectedDate.month);
    _selectedHour = _selectedDate == _today && initial.hour <= now.hour
        ? now.hour + 1
        : initial.hour;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 344),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        decoration: BoxDecoration(
          color: AppColors.backgroundPrimary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  color: AppColors.textIcon,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.deviceShareTimeLabel,
                    style: AppTextTokens.deviceShareSectionTitle(textTheme),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.brandPrimary,
                  size: 24,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _TimeTextBox(
                    value: _selectedHour.toString().padLeft(2, '0'),
                    onTap: _selectHour,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    ':',
                    style: AppTextTokens.deviceShareTimeSeparator(textTheme),
                  ),
                ),
                SizedBox(width: 64, child: _TimeTextBox(value: '00')),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      DateFormat('MMMM yyyy').format(_visibleMonth),
                      style: AppTextTokens.deviceShareCalendarTitle(textTheme),
                    ),
                  ),
                ),
                _CalendarNavButton(
                  icon: Icons.chevron_left_rounded,
                  onTap: _previousMonth,
                ),
                const SizedBox(width: 22),
                _CalendarNavButton(
                  icon: Icons.chevron_right_rounded,
                  onTap: _nextMonth,
                ),
              ],
            ),
            const SizedBox(height: 22),
            const _WeekdayHeader(),
            const SizedBox(height: 16),
            _CalendarGrid(
              visibleMonth: _visibleMonth,
              today: _today,
              selectedDate: _selectedDate,
              minimumDate: _today,
              onSelected: (date) {
                setState(() {
                  _selectedDate = date;
                  if (_selectedDate == _today &&
                      _selectedHour <= DateTime.now().hour) {
                    _selectedHour = DateTime.now().hour + 1;
                  }
                });
              },
            ),
            const SizedBox(height: 26),
            Row(
              children: [
                Expanded(
                  child: _ShareActionButton(
                    label: l10n.deviceShareCancelAction,
                    foregroundColor: AppColors.textMuted,
                    backgroundColor: AppColors.deviceShareCancelButton,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _ShareActionButton(
                    label: l10n.deviceShareConfirmAction,
                    foregroundColor: Colors.white,
                    backgroundColor: AppColors.brandPrimary,
                    onPressed: _selectedDateTime.isAfter(DateTime.now())
                        ? _confirm
                        : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _previousMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1);
    });
  }

  Future<void> _selectHour() async {
    final selected = await showDialog<int>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => _HourPickerDialog(
        selectedHour: _selectedHour,
        minimumHour: _selectedDate == _today ? DateTime.now().hour + 1 : 0,
      ),
    );
    if (selected == null) {
      return;
    }
    setState(() {
      _selectedHour = selected;
    });
  }

  void _confirm() {
    Navigator.of(context).pop(_selectedDateTime);
  }

  DateTime get _selectedDateTime => DateTime(
    _selectedDate.year,
    _selectedDate.month,
    _selectedDate.day,
    _selectedHour,
  );
}

class _TimeTextBox extends StatelessWidget {
  const _TimeTextBox({required this.value, this.onTap});

  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.backgroundPrimary,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.brandPrimaryLight),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                value,
                style: AppTextTokens.deviceShareField(
                  Theme.of(context).textTheme,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HourPickerDialog extends StatefulWidget {
  const _HourPickerDialog({
    required this.selectedHour,
    required this.minimumHour,
  });

  final int selectedHour;
  final int minimumHour;

  @override
  State<_HourPickerDialog> createState() => _HourPickerDialogState();
}

class _HourPickerDialogState extends State<_HourPickerDialog> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(
      initialScrollOffset: math.max(0, widget.selectedHour * 48.0 - 520),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final availableHeight = MediaQuery.sizeOf(context).height - 80;

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 38),
        child: Material(
          color: AppColors.backgroundPrimary,
          elevation: 4,
          child: SizedBox(
            width: 234,
            height: math.min(748, availableHeight),
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              child: ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.zero,
                itemCount: 24,
                itemBuilder: (context, index) {
                  final isSelected = index == widget.selectedHour;
                  final isEnabled = index >= widget.minimumHour;
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: isEnabled
                        ? () => Navigator.of(context).pop(index)
                        : null,
                    child: Container(
                      height: 48,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      color: isSelected
                          ? AppColors.deviceShareHourSelected
                          : AppColors.backgroundPrimary,
                      child: Opacity(
                        opacity: isEnabled
                            ? 1
                            : AppOpacityTokens.deviceShareDisabled,
                        child: Text(
                          index.toString().padLeft(2, '0'),
                          style: AppTextTokens.deviceShareHourOption(textTheme),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CalendarNavButton extends StatelessWidget {
  const _CalendarNavButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Icon(icon, color: AppColors.textIcon, size: 24),
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    const labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Row(
      children: [
        for (final label in labels)
          Expanded(
            child: Center(
              child: Text(
                label,
                style: AppTextTokens.deviceShareCalendarWeekday(textTheme),
              ),
            ),
          ),
      ],
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.visibleMonth,
    required this.today,
    required this.selectedDate,
    required this.minimumDate,
    required this.onSelected,
  });

  final DateTime visibleMonth;
  final DateTime today;
  final DateTime selectedDate;
  final DateTime minimumDate;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final days = _buildDays();

    return Column(
      children: [
        for (var row = 0; row < 6; row++) ...[
          Row(
            children: [
              for (var column = 0; column < 7; column++)
                Expanded(
                  child: _CalendarDayCell(
                    day: days[row * 7 + column],
                    today: today,
                    selectedDate: selectedDate,
                    minimumDate: minimumDate,
                    textTheme: textTheme,
                    onSelected: onSelected,
                  ),
                ),
            ],
          ),
          if (row != 5) const SizedBox(height: 9),
        ],
      ],
    );
  }

  List<DateTime?> _buildDays() {
    final firstDay = DateTime(visibleMonth.year, visibleMonth.month);
    final dayCount = DateTime(visibleMonth.year, visibleMonth.month + 1, 0).day;
    final days = <DateTime?>[
      for (var index = 0; index < firstDay.weekday % 7; index++) null,
      for (var day = 1; day <= dayCount; day++)
        DateTime(visibleMonth.year, visibleMonth.month, day),
    ];
    while (days.length < 42) {
      days.add(null);
    }
    return days;
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.day,
    required this.today,
    required this.selectedDate,
    required this.minimumDate,
    required this.textTheme,
    required this.onSelected,
  });

  final DateTime? day;
  final DateTime today;
  final DateTime selectedDate;
  final DateTime minimumDate;
  final TextTheme textTheme;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final value = day;
    if (value == null) {
      return const SizedBox(height: 32);
    }

    final isSelected =
        value.year == selectedDate.year &&
        value.month == selectedDate.month &&
        value.day == selectedDate.day;
    final isToday =
        value.year == today.year &&
        value.month == today.month &&
        value.day == today.day;
    final isEnabled = !DateTime(
      value.year,
      value.month,
      value.day,
    ).isBefore(minimumDate);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isEnabled ? () => onSelected(value) : null,
      child: SizedBox(
        height: 32,
        child: Center(
          child: Opacity(
            opacity: isEnabled ? 1 : AppOpacityTokens.deviceShareDisabled,
            child: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.brandPrimary : Colors.transparent,
                shape: BoxShape.circle,
                border: isSelected
                    ? null
                    : Border.all(
                        color: isToday
                            ? AppColors.brandPrimary
                            : Colors.transparent,
                        width: 1,
                      ),
              ),
              child: Text(
                '${value.day}',
                style: AppTextTokens.deviceShareCalendarDay(
                  textTheme,
                  isSelected: isSelected,
                  isToday: isToday,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShareActionButton extends StatelessWidget {
  const _ShareActionButton({
    required this.label,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.onPressed,
    this.buttonKey,
  });

  final String label;
  final Color foregroundColor;
  final Color backgroundColor;
  final VoidCallback? onPressed;
  final Key? buttonKey;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: Semantics(
        button: true,
        enabled: onPressed != null,
        child: GestureDetector(
          key: buttonKey,
          behavior: HitTestBehavior.opaque,
          onTap: onPressed,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(
              child: Text(
                label,
                style: AppTextTokens.deviceShareButton(
                  Theme.of(context).textTheme,
                ).copyWith(color: foregroundColor),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
