import 'package:flutter/material.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
import '../../../device_control/presentation/widgets/device_detail_bottom_navigation.dart';

class OperationRecordPage extends StatelessWidget {
  const OperationRecordPage({required this.onTabSelected, this.records = demoOperationRecords, super.key});

  final ValueChanged<DeviceDetailTab> onTabSelected;
  final List<OperationRecordItem> records;

  static const demoOperationRecords = <OperationRecordItem>[
    OperationRecordItem(action: 'Partial open setting', occurredAt: '2026-07-09 13:34:52'),
    OperationRecordItem(action: 'LED close', occurredAt: '2026-07-09 09:18:03'),
    OperationRecordItem(action: 'LED open', occurredAt: '2026-07-09 09:18:02'),
    OperationRecordItem(action: 'LED close', occurredAt: '2026-07-09 09:18:00'),
    OperationRecordItem(action: 'LED open', occurredAt: '2026-07-09 09:17:59'),
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: const FlinxNavigationBar(title: '', showBottomDivider: false),
      bottomNavigationBar: DeviceDetailBottomNavigation(selectedTab: DeviceDetailTab.operationRecords, onSelected: onTabSelected),
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          key: const PageStorageKey<String>('operation-record-scroll'),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              sliver: SliverList.list(
                children: [
                  Text(l10n.operationRecordTitle, style: AppTextTokens.operationRecordTitle(textTheme)),
                  const SizedBox(height: 4),
                  Text(l10n.operationRecordLast14DaysDescription, style: AppTextTokens.operationRecordSubtitle(textTheme)),
                  const SizedBox(height: 42),
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.only(left: 20, right: 20),
              sliver: SliverList.builder(
                itemCount: records.length,
                itemBuilder: (context, index) {
                  return _OperationTimelineItem(record: records[index], isLast: index == records.length - 1);
                },
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }
}

class OperationRecordItem {
  const OperationRecordItem({required this.action, required this.occurredAt, this.deviceName = 'TestFoor', this.operatorEmail = '346054814@qq.com'});

  final String action;
  final String occurredAt;
  final String deviceName;
  final String operatorEmail;
}

class _OperationTimelineItem extends StatelessWidget {
  const _OperationTimelineItem({required this.record, required this.isLast});

  final OperationRecordItem record;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            child: Column(
              children: [
                const SizedBox(height: 5),
                const DecoratedBox(
                  decoration: BoxDecoration(color: AppColors.operationRecordTimeline, shape: BoxShape.circle),
                  child: SizedBox.square(dimension: 12),
                ),
                if (!isLast) Expanded(child: Container(width: 1, color: AppColors.operationRecordTimelineLine)),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 20, bottom: 46),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Text(record.action, style: AppTextTokens.operationRecordAction(textTheme))),
                      const SizedBox(width: 4),
                      Text(record.occurredAt, style: AppTextTokens.operationRecordTime(textTheme)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(record.deviceName, style: AppTextTokens.operationRecordMeta(textTheme)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 15,
                        backgroundColor: AppColors.operationRecordAvatarSurface,
                        child: Icon(Icons.person_outline, size: 18, color: AppColors.textMuted),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(record.operatorEmail, style: AppTextTokens.operationRecordMeta(textTheme))),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
