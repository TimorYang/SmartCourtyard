import 'package:flutter/material.dart';

class FlinxNavigationBar extends StatelessWidget
    implements PreferredSizeWidget {
  const FlinxNavigationBar({
    super.key,
    required this.title,
    this.actions,
    this.automaticallyImplyLeading = true,
    this.showBottomDivider = true, //是否展示底部分割线
    this.isTransparent = false,
    this.foregroundColor,
    this.onBackPressed,
  });

  final String title;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;
  final bool showBottomDivider;
  final bool isTransparent;
  final Color? foregroundColor;
  final VoidCallback? onBackPressed;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final canPop = ModalRoute.of(context)?.canPop ?? false;

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: isTransparent ? Colors.transparent : null,
      foregroundColor: foregroundColor,
      iconTheme: foregroundColor == null
          ? null
          : IconThemeData(color: foregroundColor, size: 22),
      actionsIconTheme: foregroundColor == null
          ? null
          : IconThemeData(color: foregroundColor, size: 22),
      leadingWidth: 64,
      leading: automaticallyImplyLeading && canPop
          ? _FlinxNavigationBackButton(
              color: foregroundColor,
              onPressed: onBackPressed ?? () => Navigator.maybePop(context),
            )
          : null,
      title: Text(title),
      actions: actions,
      elevation: showBottomDivider && !isTransparent ? null : 0,
      scrolledUnderElevation: showBottomDivider && !isTransparent ? null : 0,
      shadowColor: showBottomDivider && !isTransparent
          ? null
          : Colors.transparent,
      surfaceTintColor: showBottomDivider && !isTransparent
          ? null
          : Colors.transparent,
      shape: showBottomDivider ? null : const Border(),
    );
  }
}

class _FlinxNavigationBackButton extends StatelessWidget {
  const _FlinxNavigationBackButton({this.color, required this.onPressed});

  final Color? color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: 24,
          height: 24,
          child: IconButton(
            onPressed: onPressed,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 24, height: 24),
            iconSize: 24,
            color: color,
            icon: const BackButtonIcon(),
          ),
        ),
      ),
    );
  }
}
