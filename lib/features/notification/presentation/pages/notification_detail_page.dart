import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
import '../../application/notification_messages_controller.dart';
import '../../application/providers.dart';
import '../../domain/entities/app_notification.dart';

class NotificationDetailPage extends ConsumerWidget {
  const NotificationDetailPage({super.key, required this.notificationId});

  static const routeName = 'notification-detail';
  static const routePath = '/notifications/:notificationId';

  final String notificationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final detail = ref.watch(notificationDetailProvider(notificationId));
    ref.listen(notificationDetailProvider(notificationId), (_, next) {
      next.whenData((item) {
        ref
            .read(notificationMessagesControllerProvider.notifier)
            .synchronizeMessageReadState(
              messageId: item.id,
              isRead: item.isRead,
            );
      });
    });

    return Scaffold(
      backgroundColor: AppColors.notificationBackground,
      appBar: FlinxNavigationBar(
        title: l10n.notificationTitle,
        showBottomDivider: false,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: detail.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Center(child: Text(l10n.notificationNotFound)),
            data: (item) => ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [_DetailCard(notification: item)],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.notification});

  final AppNotificationDetail notification;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.notificationCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.title,
              style: AppTextTokens.notificationDetailTitle(textTheme),
            ),
            const SizedBox(height: 8),
            Text(
              notification.timestamp,
              style: AppTextTokens.notificationTimestamp(textTheme),
            ),
            const SizedBox(height: 18),
            Text(
              notification.content,
              style: AppTextTokens.notificationBody(textTheme),
            ),
          ],
        ),
      ),
    );
  }
}
