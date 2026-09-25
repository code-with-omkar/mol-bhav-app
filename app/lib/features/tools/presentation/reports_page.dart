import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/locale/app_language.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/mb_dimens.dart';
import '../../../core/utils/data_state.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/statuses.dart';
import '../../../core/utils/timestamps.dart';
import '../../../shared/widgets/mb_app_bar.dart';
import '../../../shared/widgets/mb_button.dart';
import '../../../shared/widgets/mb_icon.dart';
import '../../../shared/widgets/mb_panels.dart';
import '../../../shared/widgets/mb_price.dart';
import '../../../shared/widgets/mb_state_views.dart';
import '../domain/tools.dart';
import 'tools_cubits.dart';

/// Weekly procurement summaries and Pro exports.
///
/// Opening or downloading files needs a file/URL package that is not in the
/// project yet, so download actions are not wired.
class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: MbAppBar(title: l10n.reportsTitle),
      body: BlocBuilder<ReportsCubit, DataState<ReportsOverview>>(
        builder: (context, state) {
          final cubit = context.read<ReportsCubit>();
          final data = state.data;
          return switch (state.status) {
            _ when data != null && data.isEmpty => MbEmptyView(
              message: l10n.reportsEmpty,
              onRetry: cubit.load,
            ),
            _ when data != null => _Content(data: data),
            LoadStatus.failure => MbErrorView(
              failure: state.failure!,
              onRetry: cubit.load,
            ),
            _ => const MbLoadingView(),
          };
        },
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.data});

  final ReportsOverview data;

  String _language(String code) =>
      AppLanguage.fromCode(code)?.nativeName ?? code;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final t = context.mbText;
    final l10n = context.l10n;
    final week = data.currentWeek;
    const gap = SizedBox(height: MbSpacing.s4);

    return ListView(
      padding: MbSpacing.screenPadding,
      children: [
        if (week != null) ...[
          Container(
            padding: const EdgeInsets.all(MbSpacing.s4),
            decoration: BoxDecoration(
              color: c.surfaceGreen,
              borderRadius: BorderRadius.circular(MbRadius.lg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.thisWeek(context.dateRange(week.start, week.end)),
                  style: t.link.copyWith(color: c.primaryText),
                ),
                const SizedBox(height: MbSpacing.s2),
                Text(
                  l10n.potentialSavingsFound(formatInr(week.potentialSavings)),
                  style: t.valueMd.copyWith(color: c.ink),
                ),
                const SizedBox(height: MbSpacing.s2),
                Text(
                  l10n.weekStats(
                    '${week.watchlistCount}',
                    '${week.alertCount}',
                    '${week.opportunityCount}',
                  ),
                  style: t.caption.copyWith(color: c.inkMuted),
                ),
                const SizedBox(height: MbSpacing.s2 + 6),
                MbButton(
                  label: l10n.downloadPdf(_language(week.language)),
                  icon: MbIcons.download,
                  size: MbButtonSize.sm,
                  onPressed: null,
                ),
              ],
            ),
          ),
          gap,
        ],
        if (data.weekly.isNotEmpty) ...[
          MbSectionHeader(title: l10n.weeklySummaries),
          gap,
          MbGroup(
            children: [
              for (final r in data.weekly)
                MbListItem(
                  icon: MbIcons.report,
                  iconTone: MbTone.green,
                  title: l10n.summaryTitle(context.dateRange(r.start, r.end)),
                  subtitle: l10n.summaryMeta(
                    _language(r.language),
                    '${r.pages}',
                  ),
                  trailing: MbIcon(
                    MbIcons.download,
                    size: 20,
                    color: c.inkMuted,
                    semanticLabel: l10n.download,
                  ),
                ),
            ],
          ),
          gap,
        ],
        if (data.exports.isNotEmpty) ...[
          MbSectionHeader(title: l10n.exportsTitle),
          gap,
          MbGroup(
            children: [
              for (final e in data.exports)
                MbListItem(
                  icon: MbIcons.compare,
                  title: e.title,
                  subtitle: e.subtitle,
                  trailing: e.isLocked
                      ? MbBadge(
                          label: l10n.proBadge,
                          tone: MbBadgeTone.pro,
                          icon: MbIcons.lock,
                        )
                      : MbIcon(
                          MbIcons.download,
                          size: 20,
                          color: c.inkMuted,
                          semanticLabel: l10n.download,
                        ),
                  onTap: e.isLocked
                      ? () => context.push(AppRoutes.subscription)
                      : null,
                ),
            ],
          ),
        ],
      ],
    );
  }
}
