import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_skin_catalog.dart';

/// For full-screen pages without an AppBar, such as camera and welcome.
class FlinxSystemUi extends StatelessWidget {
  const FlinxSystemUi({
    required this.foregroundColor,
    required this.child,
    super.key,
  });
  final Color foregroundColor;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: context.skin.systemOverlayStyleForForeground(foregroundColor),
    child: child,
  );
}
