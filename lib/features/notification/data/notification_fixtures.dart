import '../domain/entities/app_notification.dart';

abstract final class NotificationFixtures {
  static const items = <AppNotification>[
    AppNotification(
      id: 'appointment-confirmed',
      kind: NotificationKind.appointmentConfirmed,
      title: 'The appointment for after-sales service has been confirmed',
      category: 'after-sales service',
      summary:
          'You have successfully booked the after-sales service for '
          '2026-07-05 14:00. The engineer will arrive on time.',
      timestamp: '2026-07-01 10:30',
      detail:
          'Your after-sales service appointment has been confirmed. '
          'Engineer Li Xue (ENG-2056) will arrive at 14:00. Please ensure '
          'that the device is accessible.',
      action: NotificationAction.viewDetails,
    ),
    AppNotification(
      id: 'appointment-reminder',
      kind: NotificationKind.appointmentReminder,
      title: 'Pre order after-sales service is about to begin',
      category: 'after-sales service',
      summary:
          'Your appointment service will start in 30 minutes, please be '
          'prepared',
      timestamp: '2026-07-01 09:00',
      detail:
          'Your appointment service is about to begin, please ensure that '
          'the device is in an operational state. Engineer Li Xue '
          '(ENG-2056) will arrive at 09:30. When arrived',
      action: NotificationAction.viewDetails,
    ),
    AppNotification(
      id: 'upgrade-prompt',
      kind: NotificationKind.upgrade,
      title: 'Upgrading to a new version prompt',
      category: 'Upgrade',
      summary:
          'The device "garage door machine GDO" has a new firmware version '
          'v2.2.0 available, please upgrade it in a timely manner',
      timestamp: '2026-06-30 18:20',
      detail:
          'Firmware version v2.2.0 is available for garage door machine GDO. '
          'Keep the device online while the upgrade is in progress.',
      action: NotificationAction.upgrade,
    ),
    AppNotification(
      id: 'low-battery',
      kind: NotificationKind.lowBattery,
      title: 'The device battery is low',
      category: 'equipment',
      summary:
          'The battery level of the "smart gateway" device is below 15%. '
          'Please charge or replace the battery in a timely manner.',
      timestamp: '2026-07-01 09:00',
      detail:
          'The battery level of Intelligent Gateway (SN-2024-012) is 12%, '
          'below the recommended threshold of 15%.',
      action: NotificationAction.appointmentAfterSales,
    ),
  ];

  static AppNotification? findById(String id) {
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }
}
