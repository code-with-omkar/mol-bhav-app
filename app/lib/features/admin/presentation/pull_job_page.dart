import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/mb_dimens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/statuses.dart';
import '../../../core/utils/timestamps.dart';
import '../../../shared/widgets/mb_app_bar.dart';
import '../../../shared/widgets/mb_button.dart';
import '../../../shared/widgets/mb_layout.dart';
import '../../../shared/widgets/mb_price.dart';
import '../../../shared/widgets/mb_state_views.dart';
import '../domain/admin_jobs.dart';
import 'pull_history_page.dart';
import 'pull_job_cubit.dart';

/// One run: when and how it went, its counts, and the rows it could not use
/// with the reason and the source's data for each.
class PullJobPage extends StatelessWidget {
  const PullJobPage({super.key, required this.jobId});

  final String jobId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<PullJobCubit>();
    return Scaffold(
      appBar: MbAppBar(title: l10n.adminJobTitle),
      body: BlocBuilder<PullJobCubit, PullJobState>(
        builder: (context, state) {
          final job = state.job.data;
          if (job == null) {
            return state.job.status == LoadStatus.failure
                ? MbErrorView(
                    failure: state.job.failure!,
                    onRetry: () => cubit.load(jobId),
                  )
                : const MbLoadingView();
          }
          return ListView(
            padding: MbSpacing.screenPadding,
            children: [
              _Summary(job: job),
              if (job.failureReason != null) ...[
                const SizedBox(height: MbSpacing.s3),
                _Note(text: job.failureReason!),
              ],
              if (job.failed > 0) ...[
                const SizedBox(height: MbSpacing.s4),
                Text(
                  l10n.adminJobErrorsTitle,
                  style: context.mbText.title.copyWith(
                    color: context.mbColors.ink,
                  ),
                ),
                const SizedBox(height: MbSpacing.s2),
                for (final e in state.errors) ...[
                  _ErrorCard(error: e),
                  const SizedBox(height: MbSpacing.s2),
                ],
                if (state.errorsFailure != null)
                  _Note(text: l10n.adminJobErrorsFailed),
                if (state.loadingErrors)
                  const Padding(
                    padding: EdgeInsets.all(MbSpacing.s3),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (state.hasMoreErrors)
                  MbButton(
                    label: l10n.adminJobShowMore,
                    variant: MbButtonVariant.secondary,
                    block: true,
                    onPressed: () => cubit.loadMoreErrors(jobId),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.job});

  final AdminJob job;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mbColors;
    final t = context.mbText;
    final locale = Localizations.localeOf(context).languageCode;
    final day = job.asOfDate;
    final done = job.completedAt;
    return MbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(job.sourceCode, style: t.h2.copyWith(color: c.ink)),
              ),
              MbBadge(
                label: jobStatusLabel(context, job.status),
                tone: jobStatusTone(job.status),
              ),
            ],
          ),
          const SizedBox(height: MbSpacing.s2),
          Text(
            [
              jobTriggerLabel(context, job.trigger),
              if (day != null) l10n.jobMarketDay(formatDayMonth(day, locale)),
            ].join(' · '),
            style: t.caption.copyWith(color: c.inkMuted),
          ),
          Text(
            context.timestamp(job.startedAt) +
                (done == null ? '' : ' → ${context.timestamp(done)}'),
            style: t.caption.copyWith(color: c.inkMuted),
          ),
          const SizedBox(height: MbSpacing.s3),
          Text(
            jobCountsText(context, job),
            style: t.body.copyWith(color: c.ink),
          ),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    return Container(
      padding: const EdgeInsets.all(MbSpacing.s3),
      decoration: BoxDecoration(
        color: c.surfaceAmber,
        borderRadius: BorderRadius.circular(MbRadius.md),
      ),
      child: Text(text, style: context.mbText.body.copyWith(color: c.ink)),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.error});

  final AdminJobError error;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final t = context.mbText;
    return MbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(error.message, style: t.body.copyWith(color: c.ink)),
          if (error.rawPayload.isNotEmpty) ...[
            const SizedBox(height: MbSpacing.s1),
            SelectableText(
              error.rawPayload,
              maxLines: 4,
              style: t.caption.copyWith(color: c.inkMuted),
            ),
          ],
        ],
      ),
    );
  }
}
