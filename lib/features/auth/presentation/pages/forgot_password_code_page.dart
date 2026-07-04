import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../application/providers.dart';
import '../widgets/auth_flow_widgets.dart';
import 'forgot_password_reset_page.dart';

class ForgotPasswordCodePage extends ConsumerStatefulWidget {
  const ForgotPasswordCodePage({super.key, required this.email});

  static const routeName = 'forgot-password-code';
  static const routePath = '/forgot-password/code';

  final String email;

  static String locationFor(String email) {
    return Uri(path: routePath, queryParameters: {'email': email}).toString();
  }

  @override
  ConsumerState<ForgotPasswordCodePage> createState() =>
      _ForgotPasswordCodePageState();
}

class _ForgotPasswordCodePageState
    extends ConsumerState<ForgotPasswordCodePage> {
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
    final state = ref.watch(forgotPasswordCodeControllerProvider);
    final controller = ref.read(forgotPasswordCodeControllerProvider.notifier);

    ref.listen(forgotPasswordCodeControllerProvider, (previous, next) {
      if (_textController.text != next.code) {
        _textController.value = TextEditingValue(
          text: next.code,
          selection: TextSelection.collapsed(offset: next.code.length),
        );
      }
    });

    return AuthFlowScaffold(
      title: l10n.forgotPasswordCodeTitle,
      description: l10n.forgotPasswordCodeDescription(
        maskedAuthEmail(widget.email),
      ),
      children: [
        const SizedBox(height: 80),
        AuthVerificationCodeInput(
          inputKey: const ValueKey('forgot_password_code_input'),
          pinputKey: const ValueKey('forgot_password_code_pinput'),
          code: state.code,
          focusNode: _focusNode,
          textController: _textController,
          inputLabel: l10n.registerCodeInputLabel,
          onChanged: (value) {
            controller.updateCode(value);
            if (value.replaceAll(RegExp(r'\D'), '').length >= 6) {
              context.push(ForgotPasswordResetPage.locationFor(widget.email));
            }
          },
        ),
        const SizedBox(height: 24),
        TextButton(
          onPressed: state.canResend ? controller.resetResendCountdown : null,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 28),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            foregroundColor: AppColors.textCodeResend,
            disabledForegroundColor: AppColors.textCodeResend,
            textStyle: AppTextTokens.verificationResend(
              Theme.of(context).textTheme,
            ),
          ),
          child: Text(l10n.registerCodeResend(state.resendSecondsRemaining)),
        ),
      ],
    );
  }
}
