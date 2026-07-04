import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';

import '../../../../app/theme/app_design_tokens.dart';

class AuthFlowScaffold extends StatelessWidget {
  const AuthFlowScaffold({
    super.key,
    required this.title,
    required this.description,
    required this.children,
    this.headingTopSpacing = 124,
    this.dismissKeyboardOnTap = false,
    this.dismissAreaKey,
  });

  final String title;
  final String description;
  final List<Widget> children;
  final double headingTopSpacing;
  final bool dismissKeyboardOnTap;
  final Key? dismissAreaKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 10, 32, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AuthBackButton(onPressed: () => context.pop()),
            SizedBox(height: headingTopSpacing),
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

class AuthPasswordField extends StatelessWidget {
  const AuthPasswordField({
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
              child: AuthAssetIcon(
                assetPath: AuthAssetPaths.passwordLockIcon,
                width: 24,
                height: 24,
                fallback: SizedBox(width: 24, height: 24),
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
              style: AppTextTokens.authPasswordInput,
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
      child: FilledButton(
        onPressed: onPressed,
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
  static const passwordLockIcon =
      'assets/icons/auth/register_password_lock_icon.png';
  static const passwordResetSuccessIcon =
      'assets/icons/auth/password_reset_success_icon.png';
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
