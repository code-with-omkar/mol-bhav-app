import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/error/failure.dart';
import '../../../core/files/file_saver.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/locale/app_language.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/mb_dimens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/statuses.dart';
import '../../../shared/widgets/mb_app_bar.dart';
import '../../../shared/widgets/mb_button.dart';
import '../../../shared/widgets/mb_chip_group.dart';
import '../../../shared/widgets/mb_icon.dart';
import '../../../shared/widgets/mb_panels.dart';
import '../../../shared/widgets/mb_price.dart';
import '../../../shared/widgets/mb_select_field.dart';
import '../../../shared/widgets/mb_state_views.dart';
import '../../billing/presentation/widgets/subscription_guard.dart';
import '../../monetization/presentation/ads/interstitial_ads.dart';
import '../../monetization/presentation/unlock_sheet.dart';
import '../domain/tools.dart';
import 'tools_cubits.dart';

/// Generate a weekly PDF summary or a price-history CSV, then download it.
class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  late final StreamSubscription<DownloadedFile> _downloads;
  final _interstitials = getIt<InterstitialAds>();
  bool _downloaded = false;

  @override
  void initState() {
    super.initState();
    _downloads = context.read<ReportsCubit>().downloads.listen(_open);
    unawaited(_interstitials.warmUp());
  }

  @override
  void dispose() {
    _downloads.cancel();
    super.dispose();
  }

  Future<void> _open(DownloadedFile file) async {
    _downloaded = true;
    final opened = await saveAndOpenFile(
      name: file.name,
      mimeType: file.mimeType,
      bytes: file.bytes,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.fileSavedNoViewer(file.name))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Backing out of Reports after a download is a natural break for a
    // full-screen ad (the pacer keeps it rare). Only a user's own back
    // navigation counts — not a sign-out redirect or a deep link replacing
    // the stack, which also tear the page down.
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && _downloaded) unawaited(_interstitials.showIfDue());
      },
      child: Scaffold(
        appBar: MbAppBar(title: l10n.reportsTitle),
        body: BlocConsumer<ReportsCubit, ReportsState>(
          listenWhen: (p, n) =>
              (n.failure != null && p.failure != n.failure) ||
              (n.readyId != null && p.readyId != n.readyId),
          listener: (context, state) {
            final failure = state.failure;
            if (failure is LimitReachedFailure) {
              // A free user without a report unlock: watch ads (or go Pro),
              // then generate it after all.
              final cubit = context.read<ReportsCubit>();
              showUnlockSheet(context, failure.feature).then((unlocked) {
                if (unlocked && !cubit.isClosed) cubit.generate();
              });
            } else if (failure != null) {
              showFailureSnackBar(context, failure);
            } else if (state.readyId != null) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(l10n.reportReady)));
            }
          },
          builder: (context, state) {
            final cubit = context.read<ReportsCubit>();
            return RefreshIndicator(
              onRefresh: cubit.load,
              child: ListView(
                padding: MbSpacing.screenPadding,
                children: [
                  _GenerateForm(state: state),
                  const SizedBox(height: MbSpacing.s6),
                  MbSectionHeader(title: l10n.yourReports),
                  const SizedBox(height: MbSpacing.s3),
                  ..._list(context, state),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _list(BuildContext context, ReportsState state) {
    final l10n = context.l10n;
    final c = context.mbColors;
    final cubit = context.read<ReportsCubit>();
    final reports = state.reports.data;
    final locale = Localizations.localeOf(context).languageCode;
    if (reports == null) {
      return [
        if (state.reports.status == LoadStatus.failure)
          MbErrorView(failure: state.reports.failure!, onRetry: cubit.load)
        else
          const LinearProgressIndicator(minHeight: 2),
      ];
    }
    final known = [
      for (final r in reports)
        if (r.kind != null) r,
    ];
    if (known.isEmpty) {
      return [
        Text(
          l10n.reportsEmpty,
          style: context.mbText.body.copyWith(color: c.inkMuted),
        ),
      ];
    }
    return [
      MbGroup(
        children: [
          for (final r in known)
            MbListItem(
              icon: r.kind == ReportKind.weeklySummary
                  ? MbIcons.report
                  : MbIcons.compare,
              iconTone: r.status == ReportStatus.ready
                  ? MbTone.green
                  : MbTone.neutral,
              title: r.kind == ReportKind.weeklySummary
                  ? l10n.reportWeeklySummary
                  : l10n.reportPriceHistory,
              subtitle: _timings(context, r, locale),
              showChevron: false,
              trailing: switch (r.status) {
                ReportStatus.ready when state.downloadingId == r.id =>
                  const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ReportStatus.ready => MbIcon(
                  MbIcons.download,
                  size: 20,
                  color: c.primaryText,
                  semanticLabel: l10n.download,
                ),
                ReportStatus.pending => const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                ReportStatus.failed => MbBadge(
                  label: l10n.reportFailed,
                  tone: MbBadgeTone.neutral,
                ),
              },
              onTap: r.status == ReportStatus.ready
                  ? () => cubit.download(r)
                  : null,
            ),
        ],
      ),
    ];
  }
}

/// When it was asked for, how it ended, and when it was last downloaded —
/// each on its own line, in the device's timezone.
String _timings(BuildContext context, GeneratedReport report, String locale) {
  final l10n = context.l10n;
  return [
    l10n.reportRequestedAt(formatDateTime(report.requestedAt, locale)),
    switch (report.status) {
      ReportStatus.pending => l10n.reportGenerating,
      ReportStatus.failed => report.failureReason ?? l10n.reportFailed,
      ReportStatus.ready when report.completedAt != null =>
        l10n.reportGeneratedAt(formatDateTime(report.completedAt!, locale)),
      ReportStatus.ready => l10n.reportReadyLabel,
    },
    // A report that finished but was never opened says so, instead of showing nothing.
    if (report.status == ReportStatus.ready)
      report.lastDownloadedAt != null
          ? l10n.reportDownloadedAt(
              formatDateTime(report.lastDownloadedAt!, locale),
            )
          : l10n.reportNotDownloadedYet,
  ].join('\n');
}

class _GenerateForm extends StatelessWidget {
  const _GenerateForm({required this.state});

  final ReportsState state;

  Future<void> _pickRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365 * 2)),
      lastDate: now,
      initialDateRange: state.customFrom == null
          ? null
          : DateTimeRange(start: state.customFrom!, end: state.customTo!),
    );
    if (picked != null && context.mounted) {
      context.read<ReportsCubit>().setCustomRange(picked.start, picked.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final t = context.mbText;
    final l10n = context.l10n;
    final cubit = context.read<ReportsCubit>();
    final period = state.period;
    final locale = Localizations.localeOf(context).languageCode;
    const gap = SizedBox(height: MbSpacing.s4);
    final isPro = context.isProSubscriber;

    return Container(
      padding: const EdgeInsets.all(MbSpacing.s4),
      decoration: BoxDecoration(
        color: c.surfaceGreen,
        borderRadius: BorderRadius.circular(MbRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.generateReport, style: t.valueMd.copyWith(color: c.ink)),
          gap,
          MbChipGroup<ReportKind>.single(
            semanticLabel: l10n.reportTypeLabel,
            value: state.kind,
            onChanged: cubit.selectKind,
            options: [
              MbChipOption(
                value: ReportKind.weeklySummary,
                label: l10n.reportWeeklySummaryPdf,
              ),
              MbChipOption(
                value: ReportKind.priceHistoryCsv,
                label: l10n.reportPriceHistoryCsv,
              ),
            ],
          ),
          gap,
          Text(
            l10n.reportPeriodLabel,
            style: t.fieldLabel.copyWith(color: c.ink),
          ),
          const SizedBox(height: MbSpacing.s2),
          MbChipGroup<ReportRange>.single(
            semanticLabel: l10n.reportPeriodLabel,
            value: state.range,
            onChanged: (range) => range == ReportRange.custom
                ? _pickRange(context)
                : cubit.selectRange(range),
            options: [
              MbChipOption(value: ReportRange.week, label: l10n.lastDays(7)),
              MbChipOption(value: ReportRange.month, label: l10n.lastDays(30)),
              MbChipOption(
                value: ReportRange.quarter,
                label: l10n.lastDays(90),
              ),
              MbChipOption(value: ReportRange.custom, label: l10n.customRange),
            ],
          ),
          if (period != null) ...[
            const SizedBox(height: MbSpacing.s2),
            Text(
              '${formatDayMonth(period.$1, locale)} – '
              '${formatDayMonth(period.$2, locale)}',
              style: t.caption.copyWith(color: c.inkMuted),
            ),
          ],
          if (state.kind == ReportKind.priceHistoryCsv) ...[
            gap,
            // Pro-only on the API; a free user unlocks each one with ads
            // (the 403 opens the unlock sheet), so the form stays usable.
            if (!isPro) ...[
              Text(
                l10n.reportFreeUnlockHint,
                style: t.caption.copyWith(color: c.inkMuted),
              ),
              const SizedBox(height: MbSpacing.s3),
            ],
            ..._csvFields(context),
          ],
          gap,
          MbSelectField<String>(
            label: l10n.reportLanguageLabel,
            icon: MbIcons.language,
            value: state.language,
            onChanged: cubit.selectLanguage,
            items: [
              for (final language in AppLanguage.values)
                MbSelectItem(value: language.code, label: language.nativeName),
            ],
          ),
          gap,
          MbButton(
            label: state.isGenerating ? l10n.reportGenerating : l10n.generate,
            icon: MbIcons.report,
            block: true,
            isLoading: state.isGenerating,
            onPressed: state.canGenerate ? cubit.generate : null,
          ),
        ],
      ),
    );
  }

  List<Widget> _csvFields(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<ReportsCubit>();
    final products = state.products.data ?? const [];
    const gap = SizedBox(height: MbSpacing.s3);
    return [
      MbSelectField<String>(
        label: l10n.categoryLabel,
        hint: l10n.selectPlaceholder,
        value: state.categoryCode,
        onChanged: state.categories.isEmpty ? null : cubit.selectCategory,
        items: [
          for (final c in state.categories)
            MbSelectItem(value: c.code, label: c.name),
        ],
      ),
      gap,
      MbSelectField<String>(
        label: l10n.productLabel,
        hint: state.products.isLoading && state.categoryCode != null
            ? l10n.loading
            : l10n.selectPlaceholder,
        value: state.productId,
        onChanged: products.isEmpty ? null : cubit.selectProduct,
        items: [
          for (final p in products) MbSelectItem(value: p.id, label: p.name),
        ],
      ),
      gap,
      MbSelectField<String>(
        label: l10n.stateLabel,
        icon: MbIcons.market,
        hint: l10n.optionalAllMandis,
        value: state.stateId,
        onChanged: state.states.isEmpty ? null : cubit.selectState,
        items: [
          for (final s in state.states)
            MbSelectItem(value: s.id, label: s.name),
        ],
      ),
      if (state.stateId != null) ...[
        gap,
        MbSelectField<String>(
          label: l10n.districtLabel,
          hint: l10n.selectPlaceholder,
          value: state.districtId,
          onChanged: state.districts.status == LoadStatus.ready
              ? cubit.selectDistrict
              : null,
          items: [
            for (final d in state.districts.data ?? const [])
              MbSelectItem(value: d.id, label: d.name),
          ],
        ),
      ],
      if (state.districtId != null) ...[
        gap,
        // '' = all mandis in the report (the select can't emit null).
        MbSelectField<String>(
          label: l10n.marketLabel,
          value: state.mandiId ?? '',
          onChanged: state.mandis.status == LoadStatus.ready
              ? (id) => cubit.selectMandi(id.isEmpty ? null : id)
              : null,
          items: [
            MbSelectItem(value: '', label: l10n.allMandis),
            for (final m in state.mandis.data ?? const [])
              MbSelectItem(value: m.id, label: m.name),
          ],
        ),
      ],
      const SizedBox(height: MbSpacing.s2),
      Row(
        children: [
          MbBadge(
            label: l10n.proBadge,
            tone: MbBadgeTone.pro,
            icon: MbIcons.lock,
          ),
          const SizedBox(width: MbSpacing.s2),
          Expanded(
            child: Text(
              l10n.csvProNote,
              style: context.mbText.caption.copyWith(
                color: context.mbColors.inkMuted,
              ),
            ),
          ),
        ],
      ),
    ];
  }
}
