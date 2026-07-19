import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
import '../../data/notification_fixtures.dart';
import '../../domain/entities/app_notification.dart';
import 'after_sales_appointment_page.dart';
import 'after_sales_detail_page.dart';

class NotificationDetailPage extends StatelessWidget {
  const NotificationDetailPage({super.key, required this.notificationId});

  static const routeName = 'notification-detail';
  static const routePath = '/notifications/:notificationId';

  final String notificationId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final item = NotificationFixtures.findById(notificationId);

    return Scaffold(
      backgroundColor: AppColors.notificationBackground,
      appBar: FlinxNavigationBar(
        title: l10n.notificationTitle,
        showBottomDivider: false,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: item == null
              ? Center(child: Text(l10n.notificationNotFound))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    _DetailCard(notification: item),
                    const SizedBox(height: 28),
                    _NotificationActionButton(
                      label: _actionLabel(l10n, item.action),
                      onPressed: () => _handleAction(context, item),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  String _actionLabel(AppLocalizations l10n, NotificationAction action) =>
      switch (action) {
        NotificationAction.viewDetails => l10n.notificationViewDetails,
        NotificationAction.appointmentAfterSales =>
          l10n.notificationAppointmentAfterSales,
        NotificationAction.upgrade => l10n.notificationUpgrade,
      };

  void _handleAction(BuildContext context, AppNotification item) {
    switch (item.action) {
      case NotificationAction.viewDetails:
        context.pushNamed(AfterSalesDetailPage.routeName);
      case NotificationAction.appointmentAfterSales:
        context.pushNamed(AfterSalesAppointmentPage.routeName);
      case NotificationAction.upgrade:
        final l10n = AppLocalizations.of(context);
        AppToast.info(context, l10n.notificationUpgradeComingSoon);
    }
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.notification});

  final AppNotification notification;

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
              '${AppLocalizations.of(context).notificationAppointmentTime}: '
              '${_appointmentTime(notification)}',
              style: AppTextTokens.notificationTimestamp(textTheme),
            ),
            const SizedBox(height: 18),
            Text(
              notification.detail,
              style: AppTextTokens.notificationBody(textTheme),
            ),
          ],
        ),
      ),
    );
  }

  String _appointmentTime(AppNotification notification) {
    return notification.kind == NotificationKind.appointmentReminder
        ? '2026-07-01 09:30'
        : notification.timestamp;
  }
}

class _NotificationActionButton extends StatelessWidget {
  const _NotificationActionButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brandPrimary,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextTokens.notificationPrimaryButton(
            Theme.of(context).textTheme,
          ),
        ),
      ),
    );
  }
}
