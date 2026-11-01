import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/mb_dimens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/statuses.dart';
import '../../../core/utils/timestamps.dart';
import '../../../shared/widgets/mb_app_bar.dart';
import '../../../shared/widgets/mb_layout.dart';
import '../../../shared/widgets/mb_price.dart';
import '../../../shared/widgets/mb_state_views.dart';
import '../domain/admin_ingestion.dart';
import '../domain/admin_jobs.dart';
import 'pull_history_cubit.dart';

/// Text for a run's outcome.
String jobStatusLabel(BuildContext context, IngestionJobStatus status) {
  final l10n = context.l10n;
  return switch (status) {
    IngestionJobStatus.running => l10n.jobStatusRunning,
    IngestionJobStatus.succeeded => l10n.jobStatusSucceeded,
    IngestionJobStatus.partiallySucceeded => l10n.jobStatusPartial,
    IngestionJobStatus.failed => l10n.jobStatusFailed,
  };
}

/// Text for how a run started.
String jobTriggerLabel(BuildContext context, JobTrigger trigger) {
  final l10n = context.l10n;
  return switch (trigger) {
    JobTrigger.scheduled => l10n.adminTriggerScheduled,
    JobTrigger.manual => l10n.adminTriggerManual,
    JobTrigger.upload => l10n.adminTriggerUpload,
  };
}

/// "12 saved, 1 failed" with ", 31 unchanged" when some rows were already stored.
String jobCountsText(BuildContext context, AdminJob job) {
  final l10n = context.l10n;
  final saved = l10n.jobCounts('${job.persisted}', '${job.failed}');
  return job.unchanged > 0
      ? '$saved, ${l10n.jobUnchanged('${job.unchanged}')}'
      : saved;
}

MbBadgeTone jobStatusTone(IngestionJobStatus status) => switch (status) {
  IngestionJobStatus.succeeded => MbBadgeTone.best,
  IngestionJobStatus.failed => MbBadgeTone.opportunity,
  _ => MbBadgeTone.neutral,
};

/// Recent price-feed runs, newest first. Filter by outcome; tap a run to see
/// why rows failed.
class PullHistoryPage extends StatefulWidget {
  const PullHistoryPage({super.key});

  @override
  State<PullHistoryPage> createState() => _PullHistoryPageState();
}

class _PullHistoryPageState extends State<PullHistoryPage> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 300) {
        context.read<PullHistoryCubit>().loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<PullHistoryCubit>();
    return Scaffold(
      appBar: MbAppBar(title: l10n.adminHistoryTitle),
      body: Column(
        children: [
          BlocBuilder<PullHistoryCubit, PullHistoryState>(
            buildWhen: (a, b) => a.filter != b.filter,
            builder: (context, state) => Padding(
              padding: const EdgeInsets.fromLTRB(
                MbSpacing.s4,
                MbSpacing.s3,
                MbSpacing.s4,
                0,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: MbSpacing.s2,
                  children: [
                    for (final f in JobListFilter.values)
                      ChoiceChip(
                        label: Text(switch (f) {
                          JobListFilter.all => l10n.filterAll,
                          JobListFilter.failed => l10n.jobStatusFailed,
                          JobListFilter.partial => l10n.jobStatusPartial,
                          JobListFilter.succeeded => l10n.jobStatusSucceeded,
                        }),
                        selected: state.filter == f,
                        onSelected: (_) => cubit.setFilter(f),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<PullHistoryCubit, PullHistoryState>(
              builder: (context, state) {
                if (state.jobs.isEmpty) {
                  return switch (state.status) {
                    LoadStatus.failure => MbErrorView(
                      failure: state.failure!,
                      onRetry: cubit.load,
                    ),
                    LoadStatus.ready => MbEmptyView(
                      message: l10n.adminHistoryEmpty,
                    ),
                    _ => const MbLoadingView(),
                  };
                }
                return RefreshIndicator(
                  onRefresh: cubit.load,
                  child: ListView.separated(
                    controller: _scroll,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: MbSpacing.screenPadding,
                    itemCount: state.jobs.length + (state.loadingMore ? 1 : 0),
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: MbSpacing.s2),
                    itemBuilder: (context, i) => i >= state.jobs.length
                        ? const Padding(
                            padding: EdgeInsets.all(MbSpacing.s3),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : _JobRow(job: state.jobs[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _JobRow extends StatelessWidget {
  const _JobRow({required this.job});

  final AdminJob job;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mbColors;
    final t = context.mbText;
    final locale = Localizations.localeOf(context).languageCode;
    final day = job.asOfDate;
    return InkWell(
      onTap: () => context.push(AppRoutes.adminJob(job.id)),
      borderRadius: BorderRadius.circular(MbRadius.md),
      child: MbCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    job.sourceCode,
                    style: t.title.copyWith(color: c.ink),
                  ),
                ),
                MbBadge(
                  label: jobStatusLabel(context, job.status),
                  tone: jobStatusTone(job.status),
                ),
              ],
            ),
            Text(
              [
                jobTriggerLabel(context, job.trigger),
                if (day != null) l10n.jobMarketDay(formatDayMonth(day, locale)),
                context.timestamp(job.startedAt),
              ].join(' · '),
              style: t.caption.copyWith(color: c.inkMuted),
            ),
            if (job.failureReason == null)
              Padding(
                padding: const EdgeInsets.only(top: MbSpacing.s1),
                child: Text(
                  jobCountsText(context, job),
                  style: t.body.copyWith(color: c.ink),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: MbSpacing.s1),
                child: Text(
                  job.failureReason!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: t.body.copyWith(color: c.ink),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
