import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../application/providers.dart';
import '../../application/shared_door_member_actions_controller.dart';
import '../../domain/entities/shared_door.dart';
import '../../domain/entities/shared_door_members.dart';
import '../../domain/entities/shared_device_share.dart'
    show SharedDeviceMemberAssetPaths;
import '../../../home/presentation/pages/device_share_page.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';

class SharedDeviceMemberManagementPage extends ConsumerStatefulWidget {
  const SharedDeviceMemberManagementPage({super.key, this.device});

  static const routeName = 'shared-device-member-management';
  static const routePath = '/account/shared-devices/members';

  final SharedDoor? device;

  @override
  ConsumerState<SharedDeviceMemberManagementPage> createState() =>
      _SharedDeviceMemberManagementPageState();
}

class _SharedDeviceMemberManagementPageState
    extends ConsumerState<SharedDeviceMemberManagementPage> {
  @override
  void initState() {
    super.initState();
    final doorId = widget.device?.doorId;
    if (doorId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.invalidate(sharedDoorMembersProvider(doorId));
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final doorId = widget.device?.doorId;
    final members = doorId == null
        ? const AsyncValue<SharedDoorMembers>.loading()
        : ref.watch(sharedDoorMembersProvider(doorId));

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: const FlinxNavigationBar(title: '', showBottomDivider: false),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: members.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) =>
                  Center(child: Text(l10n.sharedDevicesLoadFailed)),
              data: (share) => ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacingTokens.sharedDeviceMemberPageHorizontal,
                  AppSpacingTokens.sharedDeviceMemberPageTop,
                  AppSpacingTokens.sharedDeviceMemberPageHorizontal,
                  AppSpacingTokens.sharedDeviceMemberPageBottom,
                ),
                children: [
                  Text(
                    share.doorName,
                    style: AppTextTokens.sharedDeviceMemberPageTitle(textTheme),
                  ),
                  const SizedBox(
                    height: AppSpacingTokens.sharedDeviceMemberPageSubtitleGap,
                  ),
                  Text(
                    l10n.sharedDeviceMemberAdministrator,
                    style: AppTextTokens.sharedDeviceMemberSectionTitle(
                      textTheme,
                    ),
                  ),
                  const SizedBox(
                    height: AppSpacingTokens.sharedDeviceMemberSectionToCards,
                  ),
                  ..._memberCards(share.administrators),
                  const SizedBox(
                    height: AppSpacingTokens.sharedDeviceMemberSectionsGap,
                  ),
                  Text(
                    l10n.sharedDeviceMemberGuest,
                    style: AppTextTokens.sharedDeviceMemberSectionTitle(
                      textTheme,
                    ),
                  ),
                  const SizedBox(
                    height: AppSpacingTokens.sharedDeviceMemberSectionToCards,
                  ),
                  ..._memberCards(share.guests),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _memberCards(List<SharedDoorMember> members) {
    return [
      for (var index = 0; index < members.length; index++) ...[
        _SharedDeviceMemberCard(member: members[index]),
        if (index != members.length - 1)
          const SizedBox(height: AppSpacingTokens.sharedDeviceMemberCardGap),
      ],
    ];
  }
}

class SharedDeviceMemberManagementKeys {
  const SharedDeviceMemberManagementKeys._();

  static ValueKey<String> memberCard(String memberId) =>
      ValueKey('shared-device-member-card-$memberId');

  static ValueKey<String> editButton(String memberId) =>
      ValueKey('shared-device-member-edit-$memberId');

  static ValueKey<String> deleteButton(String memberId) =>
      ValueKey('shared-device-member-delete-$memberId');
}

class _SharedDeviceMemberCard extends ConsumerWidget {
  const _SharedDeviceMemberCard({required this.member});

  final SharedDoorMember member;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Container(
      key: SharedDeviceMemberManagementKeys.memberCard(member.id),
      height: AppSpacingTokens.sharedDeviceMemberCardHeight,
      padding: const EdgeInsets.only(left: 20, right: 15),
      decoration: const BoxDecoration(
        color: AppColors.sharedDeviceMemberCard,
        borderRadius: BorderRadius.all(
          Radius.circular(AppShapeTokens.sharedDeviceMemberCardRadius),
        ),
      ),
      child: Row(
        children: [
          _SharedDeviceMemberAvatar(member: member),
          const SizedBox(width: AppSpacingTokens.sharedDeviceMemberAvatarGap),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextTokens.sharedDeviceMemberEmail(textTheme),
                ),
                const SizedBox(
                  height: AppSpacingTokens.sharedDeviceMemberEmailToTime,
                ),
                Text(
                  _expiryLabel(l10n, member),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextTokens.sharedDeviceMemberMetadata(textTheme),
                ),
                const SizedBox(
                  height: AppSpacingTokens.sharedDeviceMemberTimeToStatus,
                ),
                Text(
                  l10n.sharedDeviceMemberAccepted,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextTokens.sharedDeviceMemberStatus(textTheme),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacingTokens.sharedDeviceMemberActionsGap),
          _MemberActionButton(
            key: SharedDeviceMemberManagementKeys.editButton(member.id),
            assetPath: SharedDeviceMemberAssetPaths.editAction,
            fallbackIcon: Icons.edit_outlined,
            label: l10n.sharedDeviceMemberEditLabel,
            onTap: () => context.pushNamed(
              DeviceSharePage.routeName,
              extra: DeviceShareEditRouteData(
                doorId: member.doorId,
                member: member,
              ),
            ),
          ),
          const SizedBox(width: AppSpacingTokens.sharedDeviceMemberActionGap),
          _MemberActionButton(
            key: SharedDeviceMemberManagementKeys.deleteButton(member.id),
            assetPath: SharedDeviceMemberAssetPaths.deleteAction,
            fallbackIcon: Icons.delete_outline,
            label: l10n.sharedDeviceMemberDeleteLabel,
            onTap: () async {
              final error = await ref
                  .read(sharedDoorMemberActionsControllerProvider.notifier)
                  .delete(shareId: member.shareId);
              if (error == null) ref.invalidate(sharedDoorMembersProvider);
            },
          ),
        ],
      ),
    );
  }

  String _expiryLabel(AppLocalizations l10n, SharedDoorMember member) {
    if (member.expiryType == SharedDoorMemberExpiryType.neverExpired) {
      return l10n.deviceShareNeverExpired;
    }
    final dateTime = member.expiresAt;
    if (dateTime == null) return '';
    String padded(int value) => value.toString().padLeft(2, '0');
    return '${dateTime.year}-${padded(dateTime.month)}-${padded(dateTime.day)} '
        '${padded(dateTime.hour)}:${padded(dateTime.minute)}:${padded(dateTime.second)}';
  }
}

class _SharedDeviceMemberAvatar extends StatelessWidget {
  const _SharedDeviceMemberAvatar({required this.member});

  final SharedDoorMember member;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      image: true,
      label: l10n.sharedDeviceMemberAvatarPlaceholderLabel,
      child: SizedBox.square(
        dimension: AppSpacingTokens.sharedDeviceMemberAvatarSize,
        child: ClipOval(
          child: const ColoredBox(
            color: AppColors.sharedDeviceMemberAvatarPlaceholder,
            child: Center(
              child: Icon(
                Icons.person_outline,
                color: AppColors.sharedDeviceMemberAvatarPlaceholderIcon,
                size: AppSpacingTokens
                    .sharedDeviceMemberAvatarPlaceholderIconSize,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MemberActionButton extends StatelessWidget {
  const _MemberActionButton({
    required super.key,
    required this.assetPath,
    required this.fallbackIcon,
    required this.label,
    this.onTap,
  });

  final String assetPath;
  final IconData fallbackIcon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: AppSpacingTokens.sharedDeviceMemberActionSize,
          height: AppSpacingTokens.sharedDeviceMemberActionSize,
          child: Image.asset(
            assetPath,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Icon(
              fallbackIcon,
              color: AppColors.sharedDeviceMemberActionIcon,
            ),
          ),
        ),
      ),
    );
  }
}
