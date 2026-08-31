import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
import '../../application/providers.dart';
import '../../application/register_password_controller.dart';
import '../widgets/auth_flow_widgets.dart';
import '../widgets/auth_alerts.dart';
import 'login_page.dart';
import 'register_page.dart';

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
      if (!mounted) return;
      if (ref.read(registrationFlowStoreProvider).registrationToken == null) {
        context.go(RegisterPage.routePath);
        return;
      }
      _passwordFocusNode.requestFocus();
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
        ),
        const SizedBox(height: 55),
        AuthPrimaryButton(
          label: l10n.loginAction,
          onPressed: state.canSubmit
              ? () => _submit(context, controller)
              : null,
        ),
        const SizedBox(height: 20),
        Text(
          l10n.registerPasswordRule,
          style: AppTextTokens.authPasswordRule(Theme.of(context).textTheme),
        ),
      ],
    );
  }

  Future<void> _submit(
    BuildContext context,
    RegisterPasswordController controller,
  ) async {
    final completed = await controller.submit();
    if (!completed || !context.mounted) return;
    AppToast.success(context, AppLocalizations.of(context).registerSucceeded);
    context.go(LoginPage.routePath);
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
