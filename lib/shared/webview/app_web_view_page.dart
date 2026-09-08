import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../app/config/app_links.dart';
import '../../app/theme/app_design_tokens.dart';
import '../../core/localization/providers.dart';
import '../../core/network/dio_factory.dart';
import '../widgets/flinx_navigation_bar.dart';

class AppWebViewPage extends ConsumerStatefulWidget {
  const AppWebViewPage({
    required this.initialUrl,
    required this.title,
    super.key,
  });

  static const routeName = 'webview';
  static const routePath = '/webview';

  final Uri initialUrl;
  final String title;

  @override
  ConsumerState<AppWebViewPage> createState() => _AppWebViewPageState();
}

class _AppWebViewPageState extends ConsumerState<AppWebViewPage> {
  late final WebViewController _controller;
  var _progress = 0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setBackgroundColor(AppColors.backgroundPrimary)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) {
              setState(() => _progress = progress);
            }
          },
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri == null || !AppLinks.isAllowed(uri)) {
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(
        widget.initialUrl,
        headers: {
          NetworkHeaders.acceptLanguage: ref
              .read(currentAppLocaleStoreProvider)
              .value,
        },
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FlinxNavigationBar(title: widget.title),
      backgroundColor: AppColors.backgroundPrimary,
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_progress < 100) LinearProgressIndicator(value: _progress / 100),
        ],
      ),
    );
  }
}
