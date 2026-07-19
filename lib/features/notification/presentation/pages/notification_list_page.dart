import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
import '../../data/notification_fixtures.dart';
import '../../domain/entities/app_notification.dart';
import 'notification_detail_page.dart';

class NotificationListPage extends StatelessWidget {
  const NotificationListPage({super.key});

  static const routeName = 'notifications';
  static const routePath = '/notifications';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.notificationBackground,
      appBar: FlinxNavigationBar(
        title: l10n.notificationTitle,
        showBottomDivider: false,
        actions: [
          TextButton(
            onPressed: () {
              AppToast.success(context, l10n.notificationAllReadMessage);
            },
            child: Text(
              l10n.notificationAllRead,
              style: AppTextTokens.notificationHeaderAction(
                Theme.of(context).textTheme,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              itemCount: NotificationFixtures.items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = NotificationFixtures.items[index];
                return _NotificationCard(
                  notification: item,
                  onTap: () => context.pushNamed(
                    NotificationDetailPage.routeName,
                    pathParameters: {'notificationId': item.id},
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final categoryColors = _categoryColors(notification.kind);

    return Semantics(
      button: true,
      label: notification.title,
      child: Material(
        color: AppColors.notificationCard,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          key: ValueKey('notification-card-${notification.id}'),
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.notificationIconSurface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: Image.asset(
                    _iconFor(notification.kind),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: AppTextTokens.notificationCardTitle(
                                textTheme,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Padding(
                            padding: EdgeInsets.only(top: 3),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: AppColors.notificationUnread,
                                shape: BoxShape.circle,
                              ),
                              child: SizedBox(width: 12, height: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: categoryColors.$1,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 4,
                          ),
                          child: Text(
                            notification.category,
                            style: AppTextTokens.notificationCategory(
                              textTheme,
                            ).copyWith(color: categoryColors.$2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        notification.summary,
                        style: AppTextTokens.notificationBody(textTheme),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        notification.timestamp,
                        style: AppTextTokens.notificationTimestamp(textTheme),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _iconFor(NotificationKind kind) => switch (kind) {
    NotificationKind.appointmentConfirmed =>
      'assets/icons/notification/notification_after_sales_confirmed_placeholder.png',
    NotificationKind.appointmentReminder =>
      'assets/icons/notification/notification_after_sales_reminder_placeholder.png',
    NotificationKind.upgrade =>
      'assets/icons/notification/notification_upgrade_prompt_placeholder.png',
    NotificationKind.lowBattery =>
      'assets/icons/notification/notification_low_battery_placeholder.png',
    NotificationKind.motorResetWarning =>
      'assets/icons/notification/notification_motor_reset_placeholder.png',
    NotificationKind.sensorAbnormality =>
      'assets/icons/notification/notification_sensor_abnormality_placeholder.png',
    NotificationKind.systemMaintenance =>
      'assets/icons/notification/notification_system_maintenance_placeholder.png',
  };

  (Color, Color) _categoryColors(NotificationKind kind) => switch (kind) {
    NotificationKind.upgrade => (
      AppColors.notificationUpgradeTag,
      AppColors.notificationUpgradeText,
    ),
    NotificationKind.lowBattery ||
    NotificationKind.motorResetWarning ||
    NotificationKind.sensorAbnormality => (
      AppColors.notificationEquipmentTag,
      AppColors.notificationEquipmentText,
    ),
    _ => (AppColors.notificationServiceTag, AppColors.notificationServiceText),
  };
}
