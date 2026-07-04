import 'package:flutter/material.dart';

class FlinxNavigationBar extends StatelessWidget
    implements PreferredSizeWidget {
  const FlinxNavigationBar({
    super.key,
    required this.title,
    this.actions,
    this.automaticallyImplyLeading = true,
  });

  final String title;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final canPop = ModalRoute.of(context)?.canPop ?? false;

    return AppBar(
      automaticallyImplyLeading: false,
      leadingWidth: 64,
      leading: automaticallyImplyLeading && canPop
          ? const _FlinxNavigationBackButton()
          : null,
      title: Text(title),
      actions: actions,
    );
  }
}

class _FlinxNavigationBackButton extends StatelessWidget {
  const _FlinxNavigationBackButton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: 24,
          height: 24,
          child: IconButton(
            onPressed: () => Navigator.maybePop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 24, height: 24),
            iconSize: 24,
            icon: const BackButtonIcon(),
          ),
        ),
      ),
    );
  }
}
