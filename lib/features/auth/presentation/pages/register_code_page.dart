import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../application/providers.dart';

class RegisterCodePage extends ConsumerStatefulWidget {
  const RegisterCodePage({super.key, required this.email});

  static const routeName = 'register-code';
  static const routePath = '/register/code';

  final String email;

  static String locationFor(String email) {
    return Uri(path: routePath, queryParameters: {'email': email}).toString();
  }

  @override
  ConsumerState<RegisterCodePage> createState() => _RegisterCodePageState();
}

class _RegisterCodePageState extends ConsumerState<RegisterCodePage> {
  late final TextEditingController _textController;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(registerCodeControllerProvider);
    final controller = ref.read(registerCodeControllerProvider.notifier);

    ref.listen(registerCodeControllerProvider, (previous, next) {
      if (_textController.text != next.code) {
        _textController.value = TextEditingValue(
          text: next.code,
          selection: TextSelection.collapsed(offset: next.code.length),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
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
                  _RegisterCodeAssetPaths.backArrowIcon,
                  width: 22,
                  height: 22,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
                ),
              ),
              const SizedBox(height: 124),
              Text(
                l10n.registerCodeTitle,
                style: AppTextTokens.verificationTitle(theme.textTheme),
              ),
              const SizedBox(height: 14),
              Text(
                l10n.registerCodeDescription(_maskedEmail(widget.email)),
                style: AppTextTokens.verificationDescription(theme.textTheme),
              ),
              const SizedBox(height: 80),
              _VerificationCodeInput(
                code: state.code,
                focusNode: _focusNode,
                textController: _textController,
                onChanged: controller.updateCode,
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: state.canResend
                    ? controller.resetResendCountdown
                    : null,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 28),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: AppColors.textCodeResend,
                  disabledForegroundColor: AppColors.textCodeResend,
                  textStyle: AppTextTokens.verificationResend(theme.textTheme),
                ),
                child: Text(
                  l10n.registerCodeResend(state.resendSecondsRemaining),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  static String _maskedEmail(String email) {
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
}

class _VerificationCodeInput extends StatelessWidget {
  const _VerificationCodeInput({
    required this.code,
    required this.focusNode,
    required this.textController,
    required this.onChanged,
  });

  final String code;
  final FocusNode focusNode;
  final TextEditingController textController;
  final ValueChanged<String> onChanged;

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
      label: AppLocalizations.of(context).registerCodeInputLabel,
      value: code,
      child: SizedBox(
        key: const ValueKey('register_code_input'),
        child: Pinput(
          key: const ValueKey('register_code_pinput'),
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

class _RegisterCodeAssetPaths {
  const _RegisterCodeAssetPaths._();

  static const backArrowIcon = 'assets/icons/auth/register_back_arrow.png';
}
