import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../auth/application/providers.dart';
import '../../../auth/presentation/pages/welcome_page.dart';
import '../../../home/application/providers.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
import '../../application/providers.dart';
import '../../domain/entities/account_profile.dart';
import 'account_profile_page.dart';

class AccountDetailsPage extends ConsumerWidget {
  const AccountDetailsPage({super.key});

  static const routeName = 'account-details';
  static const routePath = '/account/details';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref
        .watch(accountControllerProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);

    return Scaffold(
      appBar: const FlinxNavigationBar(title: '', showBottomDivider: false),
      backgroundColor: AppColors.accountProfileBackground,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: _AccountDetailsContent(
                profile: profile,
                maxHeight: constraints.maxHeight,
                onLogout: () async {
                  final authSessionController = ref.read(
                    activeAuthSessionProvider.notifier,
                  );
                  final accountController = ref.read(
                    accountControllerProvider.notifier,
                  );

                  ref.invalidate(homeScenesProvider);
                  ref.invalidate(homeDevicesProvider);
                  ref.invalidate(cachedAccountProfileProvider);
                  ref.invalidate(authSessionProvider);

                  await accountController.clearAccount();

                  // Clearing the active session redirects away from this page and
                  // disposes its WidgetRef. Do it only after all ref work is done.
                  authSessionController.clear();
                  if (!context.mounted) {
                    return;
                  }
                  context.go(WelcomePage.routePath);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class AccountDetailsAssetPaths {
  const AccountDetailsAssetPaths._();

  static const avatarOptions = [
    'assets/icons/account/account_avatar_option_01.png',
    'assets/icons/account/account_avatar_option_02.png',
    'assets/icons/account/account_avatar_option_03.png',
    'assets/icons/account/account_avatar_option_04.png',
    'assets/icons/account/account_avatar_option_05.png',
    'assets/icons/account/account_avatar_option_06.png',
    'assets/icons/account/account_avatar_option_07.png',
    'assets/icons/account/account_avatar_option_08.png',
  ];
}

class _AccountDetailsContent extends StatelessWidget {
  const _AccountDetailsContent({
    required this.profile,
    required this.maxHeight,
    required this.onLogout,
  });

  final AccountProfile? profile;
  final double maxHeight;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final accountNumber = profile?.email ?? l10n.accountDetailsFallbackNumber;
    final fullName = profile?.nickname.isNotEmpty == true
        ? profile!.nickname
        : l10n.accountDetailsFallbackFullName;
    final mailbox = profile?.email ?? l10n.accountDetailsFallbackMailbox;

    return SafeArea(
      top: false,
      bottom: false,
      child: SizedBox(
        height: maxHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    const SizedBox(height: 27),
                    Text(
                      l10n.accountDetailsTitle,
                      style: AppTextTokens.accountDetailsTitle(textTheme),
                    ),
                    const SizedBox(height: 36),
                    _AccountDetailsRows(
                      rows: [
                        _AccountDetailsRowData(
                          label: l10n.accountDetailsHeadPortrait,
                          trailing: _AccountDetailsAvatar(
                            imageUrl: profile?.avatarUrl,
                          ),
                          showChevron: true,
                          onTap: () => _showAccountAvatarSheet(context),
                        ),
                        _AccountDetailsRowData(
                          label: l10n.accountDetailsAccountNumber,
                          value: accountNumber,
                        ),
                        _AccountDetailsRowData(
                          label: l10n.accountDetailsFullName,
                          value: fullName,
                          showChevron: true,
                          onTap: () => _showAccountRenameDialog(
                            context,
                            initialName: fullName,
                          ),
                        ),
                        _AccountDetailsRowData(
                          label: l10n.accountDetailsMailbox,
                          value: mailbox,
                        ),
                        _AccountDetailsRowData(
                          label: l10n.accountDetailsChangePassword,
                          showChevron: true,
                          onTap: () => _showAccountPasswordDialog(context),
                        ),
                        _AccountDetailsRowData(
                          label: l10n.accountDetailsForgotPassword,
                          showChevron: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: onLogout,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accountDetailsLogoutSurface,
                      foregroundColor: AppColors.textPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: Text(
                      l10n.accountDetailsLogout,
                      style: AppTextTokens.accountDetailsLogout(textTheme),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountDetailsRows extends StatelessWidget {
  const _AccountDetailsRows({required this.rows});

  final List<_AccountDetailsRowData> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < rows.length; index++) ...[
          _AccountDetailsRow(data: rows[index]),
          if (index < rows.length - 1)
            const Divider(
              height: 1,
              thickness: 1,
              color: AppColors.borderAccountDivider,
            ),
        ],
      ],
    );
  }
}

class _AccountDetailsRowData {
  const _AccountDetailsRowData({
    required this.label,
    this.value,
    this.trailing,
    this.showChevron = false,
    this.onTap,
  });

  final String label;
  final String? value;
  final Widget? trailing;
  final bool showChevron;
  final VoidCallback? onTap;
}

class _AccountDetailsRow extends StatelessWidget {
  const _AccountDetailsRow({required this.data});

  final _AccountDetailsRowData data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final onTap =
        data.onTap ??
        (data.showChevron
            ? () {
                AppToast.info(context, l10n.accountMenuComingSoon(data.label));
              }
            : null);

    return Semantics(
      button: onTap != null,
      label: data.label,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 72,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextTokens.accountDetailsLabel(textTheme),
                ),
              ),
              ?data.trailing,
              if (data.value case final value?)
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: AppTextTokens.accountDetailsValue(textTheme),
                ),
              if (data.showChevron) ...[
                const SizedBox(width: 2),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.navigationForeground,
                  size: 28,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _showAccountAvatarSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isDismissible: true,
    enableDrag: true,
    useSafeArea: true,
    isScrollControlled: true,
    barrierColor: AppColors.overlaySoft,
    backgroundColor: Colors.transparent,
    builder: (context) => const _AvatarBottomSheet(),
  );
}

Future<void> _showAccountRenameDialog(
  BuildContext context, {
  required String initialName,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: AppColors.overlaySoft,
    builder: (context) => _RenameDialog(initialName: initialName),
  );
}

Future<void> _showAccountPasswordDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: AppColors.overlaySoft,
    builder: (context) => const _PasswordDialog(),
  );
}

class _AccountCenterDialogFrame extends StatelessWidget {
  const _AccountCenterDialogFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding:
          viewInsets + const EdgeInsets.symmetric(horizontal: 30, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 390),
          child: Material(
            color: AppColors.accountDetailsSheetSurface,
            borderRadius: BorderRadius.circular(
              AppShapeTokens.accountDetailsDialogRadius,
            ),
            clipBehavior: Clip.antiAlias,
            child: child,
          ),
        ),
      ),
    );
  }
}

class _AccountBottomSheetFrame extends StatelessWidget {
  const _AccountBottomSheetFrame({required this.child});

  static const _keyboardDockOverlap = 28.0;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final keyboardDockOverlap = viewInsets.bottom > 0
        ? _keyboardDockOverlap
        : 0.0;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: -keyboardDockOverlap,
                height: keyboardDockOverlap,
                child: const ColoredBox(
                  color: AppColors.accountDetailsSheetSurface,
                ),
              ),
              Material(
                color: AppColors.accountDetailsSheetSurface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
                clipBehavior: Clip.antiAlias,
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarBottomSheet extends StatefulWidget {
  const _AvatarBottomSheet();

  @override
  State<_AvatarBottomSheet> createState() => _AvatarBottomSheetState();
}

class _AvatarBottomSheetState extends State<_AvatarBottomSheet> {
  var _selectedIndex = 1;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return _AccountBottomSheetFrame(
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(37, 23, 37, 27),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 28,
                ),
                itemCount: AccountDetailsAssetPaths.avatarOptions.length,
                itemBuilder: (context, index) {
                  return _AvatarOptionButton(
                    assetPath: AccountDetailsAssetPaths.avatarOptions[index],
                    index: index,
                    selected: index == _selectedIndex,
                    onSelected: () => setState(() => _selectedIndex = index),
                  );
                },
              ),
              const SizedBox(height: 28),
              _AccountSheetActionButton(
                label: l10n.accountDetailsPhotoAlbumAction,
                foregroundColor: AppColors.textPrimary,
                backgroundColor: AppColors.accountDetailsSheetActionSurface,
                textTheme: textTheme,
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 18),
              _AccountSheetActionButton(
                label: l10n.accountDetailsPhotographAction,
                foregroundColor: AppColors.textPrimary,
                backgroundColor: AppColors.accountDetailsSheetActionSurface,
                textTheme: textTheme,
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 34),
              _AccountSheetActionButton(
                label: l10n.accountDetailsCancelAction,
                foregroundColor: AppColors.textPrimary,
                backgroundColor: AppColors.accountDetailsSheetActionSurface,
                textTheme: textTheme,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarOptionButton extends StatelessWidget {
  const _AvatarOptionButton({
    required this.assetPath,
    required this.index,
    required this.selected,
    required this.onSelected,
  });

  final String assetPath;
  final int index;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: AppLocalizations.of(
        context,
      ).accountDetailsAvatarOptionLabel(index + 1),
      child: InkResponse(
        onTap: onSelected,
        radius: 36,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? AppColors.brandPrimary
                      : AppColors.accountDetailsAvatarOptionBorder,
                  width: selected ? 2 : 1,
                ),
              ),
              child: ClipOval(
                child: Image.asset(
                  assetPath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const _AvatarOptionFallback();
                  },
                ),
              ),
            ),
            if (selected)
              const Positioned(
                right: -2,
                bottom: -2,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.authSuccess,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: Icon(
                      Icons.check_rounded,
                      color: AppColors.backgroundPrimary,
                      size: 18,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AvatarOptionFallback extends StatelessWidget {
  const _AvatarOptionFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.accountDetailsAvatarSurface,
      child: Icon(
        Icons.person_outline_rounded,
        color: AppColors.brandPrimary,
        size: 32,
      ),
    );
  }
}

class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.initialName});

  final String initialName;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName.toUpperCase());
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focusNode.requestFocus(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return _AccountCenterDialogFrame(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.accountDetailsRenameTitle,
              style: AppTextTokens.accountDetailsSheetTitle(textTheme),
            ),
            const SizedBox(height: 24),
            _AccountDetailsTextField(
              controller: _controller,
              focusNode: _focusNode,
              hintText: l10n.accountDetailsNameInputPlaceholder,
              prefixIcon: Icons.person_outline_rounded,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => Navigator.pop(context),
            ),
            const SizedBox(height: 31),
            _AccountSheetButtonRow(
              cancelLabel: l10n.accountDetailsCancelAction,
              confirmLabel: l10n.accountDetailsConfirmAction,
              onCancel: () => Navigator.pop(context),
              onConfirm: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog();

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;
  late final FocusNode _passwordFocusNode;
  late final FocusNode _confirmPasswordFocusNode;
  var _passwordVisible = false;
  var _confirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _passwordFocusNode = FocusNode();
    _confirmPasswordFocusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _passwordFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return _AccountCenterDialogFrame(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 26, 32, 38),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.accountDetailsChangePasswordTitle,
              style: AppTextTokens.accountDetailsSheetTitle(textTheme),
            ),
            const SizedBox(height: 26),
            _AccountDetailsTextField(
              controller: _passwordController,
              focusNode: _passwordFocusNode,
              hintText: l10n.accountDetailsNewPasswordPlaceholder,
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: !_passwordVisible,
              textInputAction: TextInputAction.next,
              suffix: _PasswordVisibilityButton(
                visible: _passwordVisible,
                onPressed: () {
                  setState(() => _passwordVisible = !_passwordVisible);
                },
              ),
              onSubmitted: (_) => _confirmPasswordFocusNode.requestFocus(),
            ),
            const SizedBox(height: 18),
            _AccountDetailsTextField(
              controller: _confirmPasswordController,
              focusNode: _confirmPasswordFocusNode,
              hintText: l10n.accountDetailsNewPasswordPlaceholder,
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: !_confirmPasswordVisible,
              textInputAction: TextInputAction.done,
              suffix: _PasswordVisibilityButton(
                visible: _confirmPasswordVisible,
                onPressed: () {
                  setState(
                    () => _confirmPasswordVisible = !_confirmPasswordVisible,
                  );
                },
              ),
              onSubmitted: (_) => Navigator.pop(context),
            ),
            const SizedBox(height: 28),
            _AccountSheetButtonRow(
              cancelLabel: l10n.accountDetailsCancelAction,
              confirmLabel: l10n.accountDetailsConfirmAction,
              onCancel: () => Navigator.pop(context),
              onConfirm: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountDetailsTextField extends StatelessWidget {
  const _AccountDetailsTextField({
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    required this.textInputAction,
    this.focusNode,
    this.obscureText = false,
    this.suffix,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hintText;
  final IconData prefixIcon;
  final TextInputAction textInputAction;
  final bool obscureText;
  final Widget? suffix;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      height: 48,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText,
        autocorrect: false,
        enableSuggestions: !obscureText,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        style: AppTextTokens.accountDetailsSheetInput(textTheme),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: AppTextTokens.accountDetailsSheetInput(textTheme),
          prefixIcon: Icon(
            prefixIcon,
            color: AppColors.accountDetailsSheetInputIcon,
            size: 24,
          ),
          suffixIcon: suffix,
          contentPadding: const EdgeInsets.symmetric(horizontal: 18),
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(28)),
            borderSide: BorderSide(
              color: AppColors.accountDetailsSheetInputBorder,
            ),
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(28)),
            borderSide: BorderSide(
              color: AppColors.accountDetailsSheetInputBorder,
            ),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(28)),
            borderSide: BorderSide(
              color: AppColors.accountDetailsSheetInputFocusedBorder,
            ),
          ),
        ),
      ),
    );
  }
}

class _PasswordVisibilityButton extends StatelessWidget {
  const _PasswordVisibilityButton({
    required this.visible,
    required this.onPressed,
  });

  final bool visible;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: visible
          ? AppLocalizations.of(context).accountDetailsHidePasswordAction
          : AppLocalizations.of(context).accountDetailsShowPasswordAction,
      onPressed: onPressed,
      icon: Icon(
        visible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        color: AppColors.textIcon,
        size: 24,
      ),
    );
  }
}

class _AccountSheetButtonRow extends StatelessWidget {
  const _AccountSheetButtonRow({
    required this.cancelLabel,
    required this.confirmLabel,
    required this.onCancel,
    required this.onConfirm,
  });

  final String cancelLabel;
  final String confirmLabel;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(
          child: _AccountSheetActionButton(
            label: cancelLabel,
            foregroundColor: AppColors.textPrimary,
            backgroundColor: AppColors.accountDetailsSheetActionSurface,
            textTheme: textTheme,
            onPressed: onCancel,
          ),
        ),
        const SizedBox(width: 52),
        Expanded(
          child: _AccountSheetActionButton(
            label: confirmLabel,
            foregroundColor: AppColors.backgroundPrimary,
            backgroundColor: AppColors.brandPrimary,
            textTheme: textTheme,
            onPressed: onConfirm,
          ),
        ),
      ],
    );
  }
}

class _AccountSheetActionButton extends StatelessWidget {
  const _AccountSheetActionButton({
    required this.label,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.textTheme,
    required this.onPressed,
  });

  final String label;
  final Color foregroundColor;
  final Color backgroundColor;
  final TextTheme textTheme;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          elevation: 0,
          shape: const StadiumBorder(),
          textStyle: AppTextTokens.accountDetailsSheetButton(textTheme),
        ),
        child: FittedBox(child: Text(label)),
      ),
    );
  }
}

class _AccountDetailsAvatar extends StatelessWidget {
  const _AccountDetailsAvatar({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = imageUrl?.trim();
    return SizedBox(
      width: 52,
      height: 52,
      child: ClipOval(
        child: avatarUrl == null || avatarUrl.isEmpty
            ? Image.asset(
                AccountProfileAssetPaths.avatarPlaceholder,
                fit: BoxFit.cover,
                errorBuilder: _buildFallback,
              )
            : Image.network(
                avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: _buildFallback,
              ),
      ),
    );
  }

  Widget _buildFallback(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    return const ColoredBox(
      color: AppColors.accountDetailsAvatarSurface,
      child: Icon(
        Icons.person,
        color: AppColors.accountDetailsAvatarForeground,
        size: 36,
      ),
    );
  }
}
