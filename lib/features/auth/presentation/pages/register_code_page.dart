import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
import '../../application/providers.dart';
import '../widgets/auth_alerts.dart';
import '../widgets/auth_flow_widgets.dart';
import 'register_password_page.dart';

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
    final state = ref.watch(registerCodeControllerProvider);
    final controller = ref.read(registerCodeControllerProvider.notifier);

    ref.listen(registerCodeControllerProvider, (previous, next) {
      if (_textController.text != next.code) {
        _textController.value = TextEditingValue(
          text: next.code,
          selection: TextSelection.collapsed(offset: next.code.length),
        );
      }
      if ((next.errorMessageKey != null || next.errorMessage != null) &&
          (next.errorMessageKey != previous?.errorMessageKey ||
              next.errorMessage != previous?.errorMessage)) {
        AppToast.error(
          context,
          registrationErrorMessage(
            context,
            next.errorMessageKey,
            userMessage: next.errorMessage,
          ),
        );
      }
    });

    return AuthFlowScaffold(
      appBar: const FlinxNavigationBar(title: '', showBottomDivider: false),
      title: l10n.registerCodeTitle,
      description: l10n.registerCodeDescription(maskedAuthEmail(widget.email)),
      children: [
        const SizedBox(height: 80),
        AuthVerificationCodeInput(
          inputKey: const ValueKey('register_code_input'),
          pinputKey: const ValueKey('register_code_pinput'),
          code: state.code,
          focusNode: _focusNode,
          textController: _textController,
          inputLabel: l10n.registerCodeInputLabel,
          onChanged: (value) async {
            controller.updateCode(value);
            if (value.replaceAll(RegExp(r'\D'), '').length >= 6) {
              final verified = await controller.verifyCode();
              if (verified && context.mounted) {
                context.push(RegisterPasswordPage.locationFor(widget.email));
              }
            }
          },
        ),
        const SizedBox(height: 24),
        TextButton(
          onPressed: state.canResend && !state.isResending
              ? () => controller.resendCode()
              : null,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 28),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            foregroundColor: AppColors.textCodeResend,
            disabledForegroundColor: AppColors.textCodeResendDisabled,
            textStyle: AppTextTokens.verificationResend(
              Theme.of(context).textTheme,
            ),
          ),
          child: Text(
            state.isResending
                ? l10n.registerCodeResending
                : state.canResend
                ? l10n.registerCodeResendAction
                : l10n.registerCodeResend(state.resendSecondsRemaining),
          ),
        ),
      ],
    );
  }
}
