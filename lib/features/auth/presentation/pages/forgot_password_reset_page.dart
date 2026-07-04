import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/l10n/app_localizations.dart';
import '../../application/providers.dart';
import '../widgets/auth_flow_widgets.dart';
import 'forgot_password_success_page.dart';

class ForgotPasswordResetPage extends ConsumerStatefulWidget {
  const ForgotPasswordResetPage({super.key, required this.email});

  static const routeName = 'forgot-password-reset';
  static const routePath = '/forgot-password/reset';

  final String email;

  static String locationFor(String email) {
    return Uri(path: routePath, queryParameters: {'email': email}).toString();
  }

  @override
  ConsumerState<ForgotPasswordResetPage> createState() =>
      _ForgotPasswordResetPageState();
}

class _ForgotPasswordResetPageState
    extends ConsumerState<ForgotPasswordResetPage> {
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
    final state = ref.watch(forgotPasswordResetControllerProvider);
    final controller = ref.read(forgotPasswordResetControllerProvider.notifier);

    ref.listen(forgotPasswordResetControllerProvider, (previous, next) {
      _syncTextController(_passwordTextController, next.password);
      _syncTextController(_confirmPasswordTextController, next.confirmPassword);
    });

    return AuthFlowScaffold(
      title: l10n.forgotPasswordResetTitle,
      description: l10n.forgotPasswordResetDescription,
      dismissKeyboardOnTap: true,
      dismissAreaKey: const ValueKey(
        'forgot_password_reset_keyboard_dismiss_area',
      ),
      children: [
        const SizedBox(height: 44),
        AuthPasswordField(
          key: const ValueKey('forgot_password_reset_password_input'),
          controller: _passwordTextController,
          focusNode: _passwordFocusNode,
          hintText: l10n.registerPasswordPlaceholder,
          textInputAction: TextInputAction.next,
          onChanged: controller.updatePassword,
        ),
        const SizedBox(height: 36),
        AuthPasswordField(
          key: const ValueKey('forgot_password_reset_confirm_password_input'),
          controller: _confirmPasswordTextController,
          hintText: l10n.registerConfirmPasswordPlaceholder,
          textInputAction: TextInputAction.done,
          onChanged: controller.updateConfirmPassword,
          onSubmitted: (_) {
            if (state.canSubmit) {
              _openSuccessPage(context);
            }
          },
        ),
        const SizedBox(height: 55),
        AuthPrimaryButton(
          label: l10n.finishAction,
          onPressed: state.canSubmit ? () => _openSuccessPage(context) : null,
        ),
      ],
    );
  }

  void _openSuccessPage(BuildContext context) {
    context.push(ForgotPasswordSuccessPage.routePath);
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
