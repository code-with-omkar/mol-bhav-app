import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
/// else): price sources grouped by procurement category — when each is pulled,
/// "Run all" per category, add/edit sources, backfill and CSV upload.
class AdminSchedulesPage extends StatelessWidget {
  const AdminSchedulesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: MbAppBar(title: l10n.adminSchedulesTitle),
      floatingActionButton:
          BlocBuilder<AdminSchedulesCubit, AdminSchedulesState>(
            buildWhen: (p, n) =>
                p.items != n.items ||
                p.categories != n.categories ||
                p.selectedCategory != n.selectedCategory,
            builder: (context, state) {
              final categories = state.visibleCategories;
              if (categories.isEmpty) return const SizedBox.shrink();
              return FloatingActionButton.extended(
                icon: const Icon(Icons.add),
                label: Text(l10n.addSourceAction),
                onPressed: () => _openSourceForm(
                  context,
                  categories: categories,
                  initialCategory: state.selectedCategory,
                ),
              );
            },
          ),
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
                  AdminActionKind.backfillQueued => l10n.backfillQueued(
                    '${state.queuedDays}',
                  ),
                  AdminActionKind.uploaded => l10n.uploadCompleted,
                  AdminActionKind.categoryRunQueued => l10n.categoryRunQueued(
                    '${state.queuedSources}',
                  ),
                  AdminActionKind.sourceCreated => l10n.sourceCreated,
                  AdminActionKind.sourceUpdated => l10n.sourceUpdated,
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
          final categories = state.visibleCategories;
          if (items.isEmpty && categories.isEmpty) {
            return MbEmptyView(
              message: l10n.adminNoSources,
              onRetry: cubit.load,
            );
          }
          return RefreshIndicator(
            onRefresh: cubit.load,
            child: ListView(
              padding: MbSpacing.screenPadding,
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Text(
                  l10n.adminSchedulesHint,
                  style: context.mbText.caption.copyWith(
                    color: context.mbColors.inkMuted,
                  ),
                ),
                const SizedBox(height: MbSpacing.s3),
                _CategoryChips(
                  categories: categories,
                  selected: state.selectedCategory,
                  onSelected: cubit.selectCategory,
                ),
                for (final (category, sources) in state.sections) ...[
                  const SizedBox(height: MbSpacing.s4),
                  _CategoryHeader(
                    category: category,
                    canRunAll: sources.any((s) => s.sourceIsActive),
                    busy: state.busyCategories.contains(category.code),
                    onRunAll: () => cubit.runCategory(category.code),
                  ),
                  const SizedBox(height: MbSpacing.s2),
                  if (sources.isEmpty)
                    _EmptyCategory(
                      onAdd: () => _openSourceForm(
                        context,
                        categories: categories,
                        initialCategory: category.code,
                      ),
                    ),
                  for (final item in sources) ...[
                    _SourceCard(
                      item: item,
                      categories: categories,
                      busy: state.busySourceIds.contains(item.sourceId),
                    ),
                    const SizedBox(height: MbSpacing.s3),
                  ],
                ],
                const SizedBox(height: 72),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// "All" plus one chip per category; filters the sections below.
class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<AdminCategory> categories;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Wrap(
      spacing: MbSpacing.s2,
      runSpacing: MbSpacing.s2,
      children: [
        ChoiceChip(
          label: Text(l10n.adminAllCategories),
          selected: selected == null,
          onSelected: (_) => onSelected(null),
        ),
        for (final c in categories)
          ChoiceChip(
            label: Text(c.name),
            selected: selected == c.code,
            onSelected: (_) => onSelected(c.code),
          ),
      ],
    );
  }
}

/// Category name with its "Run all" button.
class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({
    required this.category,
    required this.canRunAll,
    required this.busy,
    required this.onRunAll,
  });

  final AdminCategory category;
  final bool canRunAll;
  final bool busy;
  final VoidCallback onRunAll;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    return Row(
      children: [
        Expanded(
          child: Text(
            category.name,
            style: context.mbText.h2.copyWith(color: c.ink),
          ),
        ),
        TextButton.icon(
          icon: busy
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.play_circle_outline, size: 18),
          label: Text(context.l10n.runAllAction),
          onPressed: busy || !canRunAll ? null : onRunAll,
        ),
      ],
    );
  }
}

class _EmptyCategory extends StatelessWidget {
  const _EmptyCategory({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MbCard(
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.categoryNoSources,
              style: context.mbText.body.copyWith(
                color: context.mbColors.inkMuted,
              ),
            ),
          ),
          TextButton(onPressed: onAdd, child: Text(l10n.addSourceAction)),
        ],
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({
    required this.item,
    required this.categories,
    required this.busy,
  });

  final IngestionScheduleItem item;
  final List<AdminCategory> categories;
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
              IconButton(
                tooltip: l10n.editSourceAction,
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: busy
                    ? null
                    : () => _openSourceForm(
                        context,
                        categories: categories,
                        source: item,
                      ),
              ),
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
            if (job.asOfDate case final day?)
              Text(
                job.isUpload
                    ? '${l10n.jobMarketDay(formatDayMonth(day, locale))} · ${l10n.jobFromUpload}'
                    : l10n.jobMarketDay(formatDayMonth(day, locale)),
                style: t.caption.copyWith(color: c.inkMuted),
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
          Wrap(
            spacing: MbSpacing.s2,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.history, size: 18),
                label: Text(l10n.backfillAction),
                onPressed: busy || !item.sourceIsActive
                    ? null
                    : () => _pickBackfill(context, item, cubit),
              ),
              TextButton.icon(
                icon: const Icon(Icons.upload_file, size: 18),
                label: Text(l10n.uploadCsvAction),
                onPressed: busy || !item.sourceIsActive
                    ? null
                    : () => _pickCsv(context, item, cubit),
              ),
              TextButton.icon(
                icon: const Icon(Icons.info_outline, size: 18),
                label: Text(l10n.csvTemplateAction),
                onPressed: () => _showCsvTemplate(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The standard template header, with a copy button.
Future<void> _showCsvTemplate(BuildContext context) {
  final l10n = context.l10n;
  final material = MaterialLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.csvTemplateTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.csvTemplateBody),
          const SizedBox(height: MbSpacing.s3),
          SelectableText(
            standardCsvHeader,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await Clipboard.setData(
              const ClipboardData(text: standardCsvHeader),
            );
            if (dialogContext.mounted) Navigator.of(dialogContext).pop();
            messenger.showSnackBar(
              SnackBar(content: Text(l10n.csvTemplateCopied)),
            );
          },
          child: Text(material.copyButtonLabel),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(material.closeButtonLabel),
        ),
      ],
    ),
  );
}

/// Add (no [source]) or edit a price source. The cubit is read from [context]
/// before the sheet opens, since the sheet's own context is outside the page's
/// BlocProvider scope on some routes.
void _openSourceForm(
  BuildContext context, {
  required List<AdminCategory> categories,
  IngestionScheduleItem? source,
  String? initialCategory,
}) {
  final cubit = context.read<AdminSchedulesCubit>();
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(MbRadius.lg)),
    ),
    builder: (_) => PriceSourceFormSheet(
      categories: categories,
      initial:
          source?.toSourceInput() ??
          PriceSourceInput(
            code: '',
            name: '',
            categoryCode: initialCategory ?? categories.first.code,
          ),
      isEdit: source != null,
      onSave: (input) => source == null
          ? cubit.createSource(input)
          : cubit.updateSource(source.sourceId, input),
    ),
  );
}

/// Code (create only), name, category and — when editing — the active flag.
class PriceSourceFormSheet extends StatefulWidget {
  const PriceSourceFormSheet({
    super.key,
    required this.categories,
    required this.initial,
    required this.isEdit,
    required this.onSave,
  });

  final List<AdminCategory> categories;
  final PriceSourceInput initial;
  final bool isEdit;

  /// Resolves true when saved; the sheet then closes.
  final Future<bool> Function(PriceSourceInput input) onSave;

  @override
  State<PriceSourceFormSheet> createState() => _PriceSourceFormSheetState();
}

class _PriceSourceFormSheetState extends State<PriceSourceFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _code = TextEditingController(text: widget.initial.code);
  late final _name = TextEditingController(text: widget.initial.name);
  late String _categoryCode = widget.initial.categoryCode;
  late bool _isActive = widget.initial.isActive;
  bool _saving = false;

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final saved = await widget.onSave(
      PriceSourceInput(
        code: _code.text.trim().toLowerCase(),
        name: _name.text.trim(),
        categoryCode: _categoryCode,
        isActive: _isActive,
      ),
    );
    if (!mounted) return;
    if (saved) {
      Navigator.of(context).pop();
    } else {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mbColors;
    final t = context.mbText;
    final categoryCodes = widget.categories.map((x) => x.code).toSet();

    return Padding(
      padding: EdgeInsets.only(
        left: MbSpacing.s5,
        right: MbSpacing.s5,
        top: MbSpacing.s5,
        bottom: MediaQuery.of(context).viewInsets.bottom + MbSpacing.s5,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isEdit ? l10n.editSourceAction : l10n.addSourceAction,
              style: t.h2.copyWith(color: c.ink),
            ),
            const SizedBox(height: MbSpacing.s4),
            TextFormField(
              controller: _code,
              enabled: !widget.isEdit,
              maxLength: PriceSourceInput.codeMaxLength,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: l10n.sourceCodeLabel,
                helperText: widget.isEdit ? null : l10n.sourceCodeHint,
              ),
              validator: (v) {
                if (widget.isEdit) return null;
                final code = (v ?? '').trim().toLowerCase();
                return PriceSourceInput.codePattern.hasMatch(code)
                    ? null
                    : l10n.sourceCodeInvalid;
              },
            ),
            const SizedBox(height: MbSpacing.s2),
            TextFormField(
              controller: _name,
              maxLength: PriceSourceInput.nameMaxLength,
              decoration: InputDecoration(labelText: l10n.sourceNameLabel),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? l10n.sourceNameRequired : null,
            ),
            const SizedBox(height: MbSpacing.s2),
            DropdownButtonFormField<String>(
              initialValue: categoryCodes.contains(_categoryCode)
                  ? _categoryCode
                  : null,
              decoration: InputDecoration(labelText: l10n.sourceCategoryLabel),
              items: [
                for (final category in widget.categories)
                  DropdownMenuItem(
                    value: category.code,
                    child: Text(category.name),
                  ),
              ],
              validator: (v) => v == null ? l10n.sourceCategoryLabel : null,
              onChanged: (v) {
                if (v != null) setState(() => _categoryCode = v);
              },
            ),
            if (widget.isEdit) ...[
              const SizedBox(height: MbSpacing.s3),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.sourceActiveLabel,
                      style: t.body.copyWith(color: c.ink),
                    ),
                  ),
                  Switch(
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v),
                  ),
                ],
              ),
            ],
            const SizedBox(height: MbSpacing.s4),
            MbButton(
              label: l10n.saveSourceAction,
              block: true,
              isLoading: _saving,
              onPressed: _saving ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

/// Picks a CSV (MolBhav template, or the Agmarknet / data.gov.in export) and
/// uploads it. Works on web too: the bytes are read in memory, there is no
/// file path.
Future<void> _pickCsv(
  BuildContext context,
  IngestionScheduleItem item,
  AdminSchedulesCubit cubit,
) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final files = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['csv'],
  );
  if (files case [final file, ...]) {
    final bytes = await file.readAsBytes();
    if (bytes.length > maxUploadBytes) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.uploadTooLarge)));
      return;
    }
    await cubit.uploadCsv(item.sourceId, file.name, bytes);
  }
}

/// Date range for "Pull past days": up to [maxBackfillDays], ending today.
Future<void> _pickBackfill(
  BuildContext context,
  IngestionScheduleItem item,
  AdminSchedulesCubit cubit,
) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final range = await showDateRangePicker(
    context: context,
    firstDate: today.subtract(const Duration(days: 365)),
    lastDate: today,
    initialDateRange: DateTimeRange(
      start: yesterday.subtract(const Duration(days: 6)),
      end: yesterday,
    ),
    helpText: l10n.backfillPickerTitle,
  );
  if (range == null) return;
  final days = range.end.difference(range.start).inDays + 1;
  if (days > maxBackfillDays) {
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.backfillTooLong('$maxBackfillDays'))),
    );
    return;
  }
  await cubit.backfill(item.sourceId, range.start, range.end);
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
  final saved = l10n.jobCounts(
    '${job.recordsPersisted}',
    '${job.recordsFailed}',
  );
  final counts = job.recordsUnchanged > 0
      ? '$saved, ${l10n.jobUnchanged('${job.recordsUnchanged}')}'
      : saved;
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
