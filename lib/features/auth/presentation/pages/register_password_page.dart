import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../application/providers.dart';

class RegisterPasswordPage extends ConsumerStatefulWidget {
  const RegisterPasswordPage({super.key, required this.email});

  static const routeName = 'register-password';
  static const routePath = '/register/password';

  final String email;

  static String locationFor(String email) {
    return Uri(path: routePath, queryParameters: {'email': email}).toString();
  }

  @override
  ConsumerState<RegisterPasswordPage> createState() =>
      _RegisterPasswordPageState();
}

class _RegisterPasswordPageState extends ConsumerState<RegisterPasswordPage> {
  late final TextEditingController _passwordTextController;
  late final TextEditingController _confirmPasswordTextController;
  late final FocusNode _passwordFocusNode;

  @override
  void initState() {
    super.initState();
    _passwordTextController = TextEditingController();
    _confirmPasswordTextController = TextEditingController();
    _passwordFocusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _passwordFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _passwordTextController.dispose();
    _confirmPasswordTextController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(registerPasswordControllerProvider);
    final controller = ref.read(registerPasswordControllerProvider.notifier);

    ref.listen(registerPasswordControllerProvider, (previous, next) {
      _syncTextController(_passwordTextController, next.password);
      _syncTextController(_confirmPasswordTextController, next.confirmPassword);
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        key: const ValueKey('register_password_keyboard_dismiss_area'),
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 10, 32, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 28,
                    height: 28,
                  ),
                  icon: Image.asset(
                    _RegisterPasswordAssetPaths.backArrowIcon,
                    width: 22,
                    height: 22,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
                  ),
                ),
                const SizedBox(height: 124),
                Text(
                  l10n.registerPasswordTitle,
                  style: AppTextTokens.registerPasswordTitle(theme.textTheme),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.registerPasswordDescription,
                  style: AppTextTokens.registerPasswordDescription(
                    theme.textTheme,
                  ),
                ),
                const SizedBox(height: 44),
                _RegisterPasswordField(
                  key: const ValueKey('register_password_input'),
                  controller: _passwordTextController,
                  focusNode: _passwordFocusNode,
                  hintText: l10n.registerPasswordPlaceholder,
                  textInputAction: TextInputAction.next,
                  onChanged: controller.updatePassword,
                ),
                const SizedBox(height: 36),
                _RegisterPasswordField(
                  key: const ValueKey('register_confirm_password_input'),
                  controller: _confirmPasswordTextController,
                  hintText: l10n.registerConfirmPasswordPlaceholder,
                  textInputAction: TextInputAction.done,
                  onChanged: controller.updateConfirmPassword,
                  onSubmitted: (_) {
                    if (state.canSubmit) {
                      _showPendingMessage(context);
                    }
                  },
                ),
                const SizedBox(height: 55),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: state.canSubmit
                        ? () => _showPendingMessage(context)
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brandPrimary,
                      disabledBackgroundColor: AppColors.brandPrimaryDisabled,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(54),
                      shape: const StadiumBorder(),
                      textStyle: AppTextTokens.registerPasswordPrimaryButton(
                        theme.textTheme,
                      ),
                    ),
                    child: Text(l10n.loginAction),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPendingMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).registerPasswordPending),
      ),
    );
  }

  static void _syncTextController(
    TextEditingController textController,
    String text,
  ) {
    if (textController.text == text) {
      return;
    }

    textController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _RegisterPasswordField extends StatelessWidget {
  const _RegisterPasswordField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.textInputAction,
    required this.onChanged,
    this.focusNode,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hintText;
  final TextInputAction textInputAction;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 28,
            height: 34,
            child: Center(
              child: _RegisterPasswordAssetIcon(
                assetPath: _RegisterPasswordAssetPaths.passwordLockIcon,
                width: 24,
                height: 24,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: TextInputType.number,
              textInputAction: textInputAction,
              style: TextStyle(fontSize: 15),
              autocorrect: false,
              obscureText: true,
              enableSuggestions: false,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(8),
              ],
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hintText,
                hintStyle: AppTextTokens.registerPasswordInputHint,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RegisterPasswordAssetIcon extends StatelessWidget {
  const _RegisterPasswordAssetIcon({
    required this.assetPath,
    required this.width,
    required this.height,
  });

  final String assetPath;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) =>
          SizedBox(width: width, height: height),
    );
  }
}

class _RegisterPasswordAssetPaths {
  const _RegisterPasswordAssetPaths._();

  static const backArrowIcon = 'assets/icons/auth/register_back_arrow.png';
  static const passwordLockIcon =
      'assets/icons/auth/register_password_lock_icon.png';
}
