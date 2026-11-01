import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/utils/timestamps.dart';
import '../../../shared/widgets/mb_price.dart';
import '../domain/admin_dashboard.dart';
import '../domain/admin_ingestion.dart';
import 'admin_stat_card.dart';

/// Health of the automatically refreshed price feeds: up to date or delayed,
/// when data last came in and how the latest pull ended.
class AdminFeedsCard extends StatelessWidget {
  const AdminFeedsCard({super.key, required this.feeds});

  final AdminFeedsSummary feeds;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final updated = feeds.lastSuccessAt;
    return AdminStatCard(
      title: l10n.adminFeedsTitle,
      badge: MbBadge(
        label: feeds.isDelayed ? l10n.adminFeedsDelayed : l10n.adminFeedsOk,
        tone: feeds.isDelayed ? MbBadgeTone.opportunity : MbBadgeTone.best,
      ),
      stats: [
        AdminStat(
          l10n.adminFeedsLastUpdated,
          updated == null ? '—' : context.timestamp(updated),
        ),
        AdminStat(l10n.adminFeedsLastAttempt, switch (feeds.lastAttemptStatus) {
          null => '—',
          IngestionJobStatus.running => l10n.jobStatusRunning,
          IngestionJobStatus.succeeded => l10n.jobStatusSucceeded,
          IngestionJobStatus.partiallySucceeded => l10n.jobStatusPartial,
          IngestionJobStatus.failed => l10n.jobStatusFailed,
        }),
      ],
    );
  }
}
