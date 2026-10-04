import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/mb_dimens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/statuses.dart';
import '../../../shared/widgets/mb_app_bar.dart';
import '../../../shared/widgets/mb_button.dart';
import '../../../shared/widgets/mb_layout.dart';
import '../../../shared/widgets/mb_state_views.dart';
import '../domain/admin_ingestion.dart';
import 'admin_schedules_cubit.dart';

/// Admin only (the entry is shown only to admins, and the API rejects anyone
/// else): when each price source is pulled from its government feed.
class AdminSchedulesPage extends StatelessWidget {
  const AdminSchedulesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: MbAppBar(title: l10n.adminSchedulesTitle),
      body: BlocConsumer<AdminSchedulesCubit, AdminSchedulesState>(
        listenWhen: (p, n) => p.actionSeq != n.actionSeq,
        listener: (context, state) {
          if (state.actionFailure case final failure?) {
            showFailureSnackBar(context, failure);
          } else if (state.lastAction case final action?) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(switch (action) {
                  AdminActionKind.saved => l10n.scheduleSaved,
                  AdminActionKind.ran => l10n.runCompleted,
                }),
              ),
            );
          }
        },
        builder: (context, state) {
          final cubit = context.read<AdminSchedulesCubit>();
          final items = state.items.data;
          if (items == null) {
            return state.items.status == LoadStatus.failure
                ? MbErrorView(
                    failure: state.items.failure!,
                    onRetry: cubit.load,
                  )
                : const MbLoadingView();
          }
          if (items.isEmpty) {
            return MbEmptyView(
              message: l10n.adminNoSources,
              onRetry: cubit.load,
            );
          }
          return RefreshIndicator(
            onRefresh: cubit.load,
            child: ListView.separated(
              padding: MbSpacing.screenPadding,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: items.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: MbSpacing.s3),
              itemBuilder: (context, i) => i == 0
                  ? Text(
                      l10n.adminSchedulesHint,
                      style: context.mbText.caption.copyWith(
                        color: context.mbColors.inkMuted,
                      ),
                    )
                  : _SourceCard(
                      item: items[i - 1],
                      busy: state.busySourceIds.contains(items[i - 1].sourceId),
                    ),
            ),
          );
        },
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({required this.item, required this.busy});

  final IngestionScheduleItem item;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mbColors;
    final t = context.mbText;
    final cubit = context.read<AdminSchedulesCubit>();
    final locale = Localizations.localeOf(context).toLanguageTag();
    final job = item.lastJob;

    return MbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.sourceName,
                  style: t.title.copyWith(color: c.ink),
                ),
              ),
              _StatusChip(item: item),
            ],
          ),
          Text(item.sourceCode, style: t.caption.copyWith(color: c.inkMuted)),
          const SizedBox(height: MbSpacing.s3),
          Text(
            scheduleSummary(context, item),
            style: t.body.copyWith(color: c.ink),
          ),
          if (item.isEnabled && item.nextRunAt != null) ...[
            const SizedBox(height: MbSpacing.s1),
            Text(
              l10n.scheduleNextRun(formatDateTime(item.nextRunAt!, locale)),
              style: t.caption.copyWith(color: c.inkMuted),
            ),
          ],
          if (job != null) ...[
            const SizedBox(height: MbSpacing.s1),
            Text(
              l10n.scheduleLastRun(
                formatDateTime(job.startedAt, locale),
                _jobStatusText(context, job),
              ),
              style: t.caption.copyWith(
                color: job.status == IngestionJobStatus.failed
                    ? c.priceDown
                    : c.inkMuted,
              ),
            ),
            if (job.failureReason case final reason?)
              Text(
                reason,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: t.caption.copyWith(color: c.priceDown),
              ),
          ],
          const SizedBox(height: MbSpacing.s3),
          Row(
            children: [
              if (item.isConfigured) ...[
                Switch(
                  value: item.isEnabled,
                  onChanged: busy ? null : (v) => cubit.setEnabled(item, v),
                ),
                const SizedBox(width: MbSpacing.s2),
              ],
              Expanded(
                child: MbButton(
                  label: l10n.editScheduleAction,
                  variant: MbButtonVariant.secondary,
                  size: MbButtonSize.sm,
                  onPressed: busy
                      ? null
                      : () => _openEditor(context, item, cubit),
                ),
              ),
              const SizedBox(width: MbSpacing.s2),
              Expanded(
                child: MbButton(
                  label: l10n.runNowAction,
                  size: MbButtonSize.sm,
                  isLoading: busy,
                  onPressed: busy || !item.sourceIsActive
                      ? null
                      : () => cubit.runNow(item.sourceId),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.item});

  final IngestionScheduleItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mbColors;
    final (label, on) = switch (item) {
      _ when !item.sourceIsActive => (l10n.sourceInactive, false),
      _ when !item.isConfigured => (l10n.scheduleStatusNone, false),
      _ when item.isEnabled => (l10n.scheduleStatusOn, true),
      _ => (l10n.scheduleStatusPaused, false),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MbSpacing.s2,
        vertical: MbSpacing.s1,
      ),
      decoration: BoxDecoration(
        color: on
            ? c.primary.withValues(alpha: 0.1)
            : c.border.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(MbRadius.pill),
      ),
      child: Text(
        label,
        style: context.mbText.label.copyWith(
          color: on ? c.primaryText : c.inkMuted,
        ),
      ),
    );
  }
}

/// `Daily at 18:00 IST`, `Every Monday at 06:00 IST`, `Every 6 h from 06:00 IST`.
String scheduleSummary(BuildContext context, IngestionScheduleItem item) {
  final l10n = context.l10n;
  if (!item.isConfigured || item.frequency == null || item.timeOfDay == null) {
    return l10n.scheduleNotConfigured;
  }
  final time = item.timeOfDay!;
  return switch (item.frequency!) {
    ScheduleFrequency.daily => l10n.scheduleDaily(time),
    ScheduleFrequency.weekly => l10n.scheduleWeekly(
      dayName(context, item.dayOfWeek ?? scheduleDays.first),
      time,
    ),
    ScheduleFrequency.everyNHours => l10n.scheduleEveryNHours(
      '${item.intervalHours ?? 0}',
      time,
    ),
  };
}

/// Localised weekday for an API day name. 1 Jan 2024 was a Monday.
String dayName(BuildContext context, String apiDay) {
  final index = scheduleDays.indexOf(apiDay).clamp(0, 6);
  final locale = Localizations.localeOf(context).toLanguageTag();
  return DateFormat.EEEE(locale).format(DateTime(2024, 1, 1 + index));
}

String _jobStatusText(BuildContext context, IngestionLastJob job) {
  final l10n = context.l10n;
  final counts = l10n.jobCounts(
    '${job.recordsPersisted}',
    '${job.recordsFailed}',
  );
  return switch (job.status) {
    IngestionJobStatus.running => l10n.jobStatusRunning,
    IngestionJobStatus.succeeded => '${l10n.jobStatusSucceeded} · $counts',
    IngestionJobStatus.partiallySucceeded =>
      '${l10n.jobStatusPartial} · $counts',
    IngestionJobStatus.failed => l10n.jobStatusFailed,
  };
}

void _openEditor(
  BuildContext context,
  IngestionScheduleItem item,
  AdminSchedulesCubit cubit,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(MbRadius.lg)),
    ),
    builder: (_) => ScheduleEditorSheet(
      item: item,
      onSave: (input) => cubit.save(item.sourceId, input),
    ),
  );
}

/// Frequency, IST time, weekday or interval, and the on/off switch.
class ScheduleEditorSheet extends StatefulWidget {
  const ScheduleEditorSheet({
    super.key,
    required this.item,
    required this.onSave,
  });

  final IngestionScheduleItem item;
  final ValueChanged<ScheduleInput> onSave;

  @override
  State<ScheduleEditorSheet> createState() => _ScheduleEditorSheetState();
}

class _ScheduleEditorSheetState extends State<ScheduleEditorSheet> {
  late ScheduleInput _input = widget.item.toInput();

  Future<void> _pickTime() async {
    final parts = _input.timeOfDay.split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;
    final hh = picked.hour.toString().padLeft(2, '0');
    final mm = picked.minute.toString().padLeft(2, '0');
    setState(() => _input = _input.copyWith(timeOfDay: '$hh:$mm'));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mbColors;
    final t = context.mbText;

    return Padding(
      padding: EdgeInsets.only(
        left: MbSpacing.s5,
        right: MbSpacing.s5,
        top: MbSpacing.s5,
        bottom: MediaQuery.of(context).viewInsets.bottom + MbSpacing.s5,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.item.sourceName, style: t.h2.copyWith(color: c.ink)),
          const SizedBox(height: MbSpacing.s4),
          Text(
            l10n.scheduleFrequencyLabel,
            style: t.label.copyWith(color: c.inkMuted),
          ),
          const SizedBox(height: MbSpacing.s2),
          Wrap(
            spacing: MbSpacing.s2,
            children: [
              for (final f in ScheduleFrequency.values)
                ChoiceChip(
                  label: Text(switch (f) {
                    ScheduleFrequency.daily => l10n.frequencyDaily,
                    ScheduleFrequency.weekly => l10n.frequencyWeekly,
                    ScheduleFrequency.everyNHours => l10n.frequencyEveryNHours,
                  }),
                  selected: _input.frequency == f,
                  onSelected: (_) =>
                      setState(() => _input = _input.copyWith(frequency: f)),
                ),
            ],
          ),
          const SizedBox(height: MbSpacing.s4),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              l10n.scheduleTimeLabel,
              style: t.body.copyWith(color: c.ink),
            ),
            trailing: Text(
              _input.timeOfDay,
              style: t.title.copyWith(color: c.ink),
            ),
            onTap: _pickTime,
          ),
          if (_input.frequency == ScheduleFrequency.weekly)
            DropdownButtonFormField<String>(
              initialValue: _input.dayOfWeek,
              decoration: InputDecoration(labelText: l10n.scheduleDayLabel),
              items: [
                for (final d in scheduleDays)
                  DropdownMenuItem(value: d, child: Text(dayName(context, d))),
              ],
              onChanged: (d) {
                if (d != null) {
                  setState(() => _input = _input.copyWith(dayOfWeek: d));
                }
              },
            ),
          if (_input.frequency == ScheduleFrequency.everyNHours)
            DropdownButtonFormField<int>(
              initialValue: _input.intervalHours,
              decoration: InputDecoration(
                labelText: l10n.scheduleIntervalLabel,
              ),
              items: [
                for (final h in allowedIntervalHours)
                  DropdownMenuItem(
                    value: h,
                    child: Text(l10n.intervalHoursOption('$h')),
                  ),
              ],
              onChanged: (h) {
                if (h != null) {
                  setState(() => _input = _input.copyWith(intervalHours: h));
                }
              },
            ),
          const SizedBox(height: MbSpacing.s3),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.scheduleEnabledLabel,
                  style: t.body.copyWith(color: c.ink),
                ),
              ),
              Switch(
                value: _input.isEnabled,
                onChanged: (v) =>
                    setState(() => _input = _input.copyWith(isEnabled: v)),
              ),
            ],
          ),
          const SizedBox(height: MbSpacing.s4),
          MbButton(
            label: l10n.saveScheduleAction,
            block: true,
            onPressed: () {
              widget.onSave(_input);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
