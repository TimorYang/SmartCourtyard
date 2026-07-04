import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/l10n/app_localizations.dart';
import '../../application/providers.dart';
import '../widgets/auth_flow_widgets.dart';

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
    final state = ref.watch(registerPasswordControllerProvider);
    final controller = ref.read(registerPasswordControllerProvider.notifier);

    ref.listen(registerPasswordControllerProvider, (previous, next) {
      _syncTextController(_passwordTextController, next.password);
      _syncTextController(_confirmPasswordTextController, next.confirmPassword);
    });

    return AuthFlowScaffold(
      title: l10n.registerPasswordTitle,
      description: l10n.registerPasswordDescription,
      dismissKeyboardOnTap: true,
      dismissAreaKey: const ValueKey('register_password_keyboard_dismiss_area'),
      children: [
        const SizedBox(height: 44),
        AuthPasswordField(
          key: const ValueKey('register_password_input'),
          controller: _passwordTextController,
          focusNode: _passwordFocusNode,
          hintText: l10n.registerPasswordPlaceholder,
          textInputAction: TextInputAction.next,
          onChanged: controller.updatePassword,
        ),
        const SizedBox(height: 36),
        AuthPasswordField(
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
        AuthPrimaryButton(
          label: l10n.loginAction,
          onPressed: state.canSubmit
              ? () => _showPendingMessage(context)
              : null,
        ),
      ],
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
