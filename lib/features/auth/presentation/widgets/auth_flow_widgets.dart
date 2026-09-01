import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../domain/entities/password_policy.dart';

class AuthFlowScaffold extends StatelessWidget {
  const AuthFlowScaffold({
    super.key,
    required this.title,
    required this.description,
    required this.children,
    this.appBar,
    this.headingTopSpacing,
    this.showBodyBackButton,
    this.dismissKeyboardOnTap = false,
    this.dismissAreaKey,
  });

  final String title;
  final String description;
  final List<Widget> children;
  final PreferredSizeWidget? appBar;
  final double? headingTopSpacing;
  final bool? showBodyBackButton;
  final bool dismissKeyboardOnTap;
  final Key? dismissAreaKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shouldShowBodyBackButton = showBodyBackButton ?? appBar == null;
    final effectiveHeadingTopSpacing =
        headingTopSpacing ?? (shouldShowBodyBackButton ? 124.0 : 0.0);
    final content = SafeArea(
      top: appBar == null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(30, 40, 30, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (shouldShowBodyBackButton)
              AuthBackButton(onPressed: () => context.pop()),
            SizedBox(height: effectiveHeadingTopSpacing),
            Text(title, style: AppTextTokens.authFlowTitle(theme.textTheme)),
            const SizedBox(height: 12),
            Text(
              description,
              style: AppTextTokens.authFlowDescription(theme.textTheme),
            ),
            ...children,
            const Spacer(),
          ],
        ),
      ),
    );

    return Scaffold(
      appBar: appBar,
      backgroundColor: AppColors.backgroundPrimary,
      resizeToAvoidBottomInset: true,
      body: dismissKeyboardOnTap
          ? GestureDetector(
              key: dismissAreaKey,
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              child: content,
            )
          : content,
    );
  }
}

class AuthBackButton extends StatelessWidget {
  const AuthBackButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 28, height: 28),
      icon: const AuthAssetIcon(
        assetPath: AuthAssetPaths.backArrowIcon,
        width: 22,
        height: 22,
        fallback: Icon(Icons.arrow_back_ios_new_rounded, size: 22),
      ),
    );
  }
}

class AuthVerificationCodeInput extends StatelessWidget {
  const AuthVerificationCodeInput({
    super.key,
    required this.code,
    required this.focusNode,
    required this.textController,
    required this.onChanged,
    required this.inputLabel,
    required this.inputKey,
    required this.pinputKey,
  });

  final String code;
  final FocusNode focusNode;
  final TextEditingController textController;
  final ValueChanged<String> onChanged;
  final String inputLabel;
  final Key inputKey;
  final Key pinputKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultPinTheme = PinTheme(
      width: 62,
      height: 44,
      textStyle: AppTextTokens.verificationDigit(theme.textTheme),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderCodeCell)),
      ),
    );
    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.brandPrimary)),
      ),
    );

    return Semantics(
      textField: true,
      label: inputLabel,
      value: code,
      child: SizedBox(
        key: inputKey,
        child: Pinput(
          key: pinputKey,
          controller: textController,
          focusNode: focusNode,
          length: 6,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.oneTimeCode],
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          defaultPinTheme: defaultPinTheme,
          focusedPinTheme: focusedPinTheme,
          submittedPinTheme: defaultPinTheme,
          followingPinTheme: defaultPinTheme,
          separatorBuilder: (index) => const SizedBox(width: 24),
          showCursor: true,
          cursor: const _CodeCursor(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.hintText,
    required this.icon,
    required this.onChanged,
    this.fieldKey,
    this.controller,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.autocorrect = true,
    this.autofocus = false,
    this.enableSuggestions = true,
    this.obscureText = false,
    this.inputFormatters,
    this.onSubmitted,
    this.onTapOutside,
    this.rightView,
    this.hasError = false,
    this.compact = true,
    this.ultraCompact = true,
  });

  final String hintText;
  final Widget icon;
  final ValueChanged<String> onChanged;
  final Key? fieldKey;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool autocorrect;
  final bool autofocus;
  final bool enableSuggestions;
  final bool obscureText;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onSubmitted;
  final TapRegionCallback? onTapOutside;
  final Widget? rightView;
  final bool hasError;
  final bool compact;
  final bool ultraCompact;

  Widget _buildRightView() {
    final rightView = this.rightView;
    if (rightView == null) {
      return const SizedBox.shrink();
    }

    final controller = this.controller;
    if (controller == null) {
      return rightView;
    }

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      child: rightView,
      builder: (context, value, child) {
        return Visibility(
          visible: value.text.isNotEmpty,
          maintainState: true,
          maintainAnimation: true,
          maintainSize: true,
          child: child!,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: hasError
                ? AppColors.authInputErrorBorder
                : AppColors.borderSubtle,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 26 : 30,
            height: compact ? 26 : 30,
            alignment: Alignment.center,
            child: SizedBox(
              width: compact ? 22 : 25,
              height: compact ? 22 : 25,
              child: icon,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              key: fieldKey,
              controller: controller,
              focusNode: focusNode,
              obscureText: obscureText,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              autocorrect: autocorrect,
              autofocus: autofocus,
              enableSuggestions: enableSuggestions,
              inputFormatters: inputFormatters,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              onTapOutside: onTapOutside,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hintText,
                hintStyle: AppTextTokens.loginInputHint.copyWith(
                  fontSize: ultraCompact ? 16 : 18,
                ),
                isDense: compact,
                contentPadding: EdgeInsets.symmetric(
                  vertical: ultraCompact ? 8 : 12,
                ),
              ),
            ),
          ),
          _buildRightView(),
        ],
      ),
    );
  }
}

class AuthTextFieldAction extends StatelessWidget {
  const AuthTextFieldAction({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox.square(
          dimension: 44,
          child: Icon(icon, color: AppColors.textIcon, size: 22),
        ),
      ),
    );
  }
}

class AuthPasswordField extends StatefulWidget {
  const AuthPasswordField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.textInputAction,
    required this.onChanged,
    this.focusNode,
    this.onSubmitted,
    this.hasError = false,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hintText;
  final TextInputAction textInputAction;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool hasError;

  @override
  State<AuthPasswordField> createState() => _AuthPasswordFieldState();
}

class _AuthPasswordFieldState extends State<AuthPasswordField> {
  bool _isPasswordObscured = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AuthTextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      hintText: widget.hintText,
      icon: const AuthAssetIcon(
        assetPath: AuthAssetPaths.passwordLockIcon,
        width: 22,
        height: 22,
        fallback: SizedBox(width: 22, height: 22),
      ),
      keyboardType: TextInputType.visiblePassword,
      textInputAction: widget.textInputAction,
      autocorrect: false,
      obscureText: _isPasswordObscured,
      enableSuggestions: false,
      hasError: widget.hasError,
      inputFormatters: [
        LengthLimitingTextInputFormatter(PasswordPolicy.maxLength),
      ],
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      rightView: AuthTextFieldAction(
        label: _isPasswordObscured
            ? l10n.loginShowPasswordAction
            : l10n.loginHidePasswordAction,
        icon: _isPasswordObscured
            ? Icons.visibility_off_outlined
            : Icons.visibility_outlined,
        onTap: () => setState(() {
          _isPasswordObscured = !_isPasswordObscured;
        }),
      ),
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brandPrimaryLight,
          disabledBackgroundColor: AppColors.brandPrimaryDisabled,
          foregroundColor: Colors.white,
          disabledForegroundColor:
              AppColors.authPrimaryButtonDisabledForeground,
          minimumSize: const Size.fromHeight(48),
          shape: const StadiumBorder(),
          textStyle: AppTextTokens.loginPrimaryButton(theme.textTheme),
        ),
        child: Text(label),
      ),
    );
  }
}

class AuthAssetIcon extends StatelessWidget {
  const AuthAssetIcon({
    super.key,
    required this.assetPath,
    required this.width,
    required this.height,
    required this.fallback,
  });

  final String assetPath;
  final double width;
  final double height;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => fallback,
    );
  }
}

class AuthAssetPaths {
  const AuthAssetPaths._();

  static const backArrowIcon = 'assets/icons/auth/register_back_arrow.png';
  static const accountFieldIcon = 'assets/icons/auth/login_account_icon.png';
  static const passwordFieldIcon = 'assets/icons/auth/login_password_icon.png';
  static const emailFieldIcon = 'assets/icons/auth/register_email_icon.png';
  static const passwordLockIcon =
      'assets/icons/auth/register_password_lock_icon.png';
}

String maskedAuthEmail(String email) {
  final trimmed = email.trim();
  final atIndex = trimmed.indexOf('@');

  if (atIndex <= 0 || atIndex == trimmed.length - 1) {
    return trimmed.isEmpty ? '***' : trimmed;
  }

  final local = trimmed.substring(0, atIndex);
  final domain = trimmed.substring(atIndex + 1);
  final visibleLocal = local.length <= 3 ? local : local.substring(0, 3);
  final domainFirst = domain[0];

  return '$visibleLocal*****@$domainFirst***';
}

class _CodeCursor extends StatelessWidget {
  const _CodeCursor();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 1.5,
        height: 28,
        margin: const EdgeInsets.only(top: 4),
        color: AppColors.brandPrimary,
      ),
    );
  }
}
