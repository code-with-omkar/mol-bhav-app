import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/mb_dimens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/statuses.dart';
import '../../../core/utils/timestamps.dart';
import '../../../shared/widgets/category_visuals.dart';
import '../../../shared/widgets/mb_app_bar.dart';
import '../../../shared/widgets/mb_button.dart';
import '../../../shared/widgets/mb_icon.dart';
import '../../../shared/widgets/mb_icon_button.dart';
import '../../../shared/widgets/mb_layout.dart';
import '../../../shared/widgets/mb_panels.dart';
import '../../../shared/widgets/mb_price.dart';
import '../../../shared/widgets/mb_select_field.dart';
import '../../../shared/widgets/mb_state_views.dart';
import '../../../shared/widgets/mb_text_field.dart';
import '../domain/tools.dart';
import 'tools_cubits.dart';

/// Quantity-based procurement cost from current market and supplier prices.
class CostEstimatorPage extends StatelessWidget {
  const CostEstimatorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<CostEstimatorCubit>();
    return BlocConsumer<CostEstimatorCubit, CostEstimatorState>(
      listenWhen: (p, n) => p.saveStatus != n.saveStatus,
      listener: (context, state) {
        if (state.saveStatus == SubmitStatus.success) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(l10n.estimateSaved)));
        } else if (state.saveStatus == SubmitStatus.failure) {
          showFailureSnackBar(context, state.saveFailure!);
        }
      },
      builder: (context, state) {
        final ready = state.categories.status == LoadStatus.ready;
        return Scaffold(
          appBar: MbAppBar(title: l10n.costEstimatorTitle),
          body: switch (state.categories.status) {
            LoadStatus.failure => MbErrorView(
              failure: state.categories.failure!,
              onRetry: cubit.load,
            ),
            LoadStatus.ready => _Form(state: state),
            _ => const MbLoadingView(),
          },
          bottomNavigationBar: ready
              ? MbFooter(
                  child: MbButton(
                    label: state.isSaved
                        ? l10n.estimateSavedLabel
                        : l10n.saveEstimate,
                    icon: state.isSaved ? MbIcons.check : MbIcons.report,
                    size: MbButtonSize.lg,
                    block: true,
                    isLoading: state.saveStatus == SubmitStatus.submitting,
                    onPressed: state.canSave ? cubit.save : null,
                  ),
                )
              : null,
        );
      },
    );
  }
}

class _Form extends StatelessWidget {
  const _Form({required this.state});

  final CostEstimatorState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<CostEstimatorCubit>();
    final categories = state.categories.data!;
    final materials = state.materials.data ?? const <EstimatorMaterial>[];
    final material = state.material;
    const gap = SizedBox(height: 14);

    return ListView(
      padding: MbSpacing.screenPadding,
      children: [
        if (categories.length > 1) ...[
          MbSegmentedTabs<String>(
            stretch: true,
            value: state.categoryCode ?? '',
            onChanged: cubit.selectCategory,
            options: [
              for (final c in categories)
                MbTabOption(value: c.id, label: c.name),
            ],
          ),
          gap,
        ],
        MbSelectField<String>(
          label: l10n.materialLabel,
          icon: categoryIcon(state.categoryCode ?? ''),
          hint: state.materials.isLoading
              ? l10n.loading
              : l10n.selectPlaceholder,
          value: state.materialId,
          error: state.materials.status == LoadStatus.failure
              ? l10n.errorServer
              : null,
          onChanged: materials.isEmpty ? null : cubit.selectMaterial,
          items: [
            for (final m in materials) MbSelectItem(value: m.id, label: m.name),
          ],
        ),
        gap,
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: MbTextField(
                label: l10n.quantityLabel,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                onChanged: cubit.quantityChanged,
              ),
            ),
            const SizedBox(width: MbSpacing.s3),
            // Locked: the API prices requirements only in the product's
            // default unit.
            Expanded(
              child: MbSelectField<String>(
                label: l10n.unitLabel,
                value: material?.unit.id,
                helper: material == null ? null : l10n.unitLockedHelper,
                onChanged: null,
                items: [
                  if (material != null)
                    MbSelectItem(
                      value: material.unit.id,
                      label: material.unit.name,
                    ),
                ],
              ),
            ),
          ],
        ),
        gap,
        MbSelectField<String>(
          label: l10n.stateLabel,
          icon: MbIcons.market,
          hint: l10n.selectPlaceholder,
          value: state.stateId,
          onChanged: state.states.isEmpty ? null : cubit.selectState,
          items: [
            for (final s in state.states)
              MbSelectItem(value: s.id, label: s.name),
          ],
        ),
        gap,
        // '' stands for "any district" (the select can't emit null).
        MbSelectField<String>(
          label: l10n.deliverToLabel,
          hint: state.stateId == null
              ? l10n.selectStateFirst
              : l10n.anyDistrict,
          value: state.stateId == null ? null : state.districtId ?? '',
          onChanged: state.districts.status == LoadStatus.ready
              ? (id) => cubit.selectDistrict(id.isEmpty ? null : id)
              : null,
          items: [
            if (state.stateId != null)
              MbSelectItem(value: '', label: l10n.anyDistrict),
            for (final d in state.districts.data ?? const [])
              MbSelectItem(value: d.id, label: d.name),
          ],
        ),
        gap,
        ..._result(context),
        const SizedBox(height: MbSpacing.s6),
        _SavedList(state: state),
      ],
    );
  }

  List<Widget> _result(BuildContext context) {
    final c = context.mbColors;
    final l10n = context.l10n;
    final estimate = state.estimate;
    final data = estimate.data;
    final unit = state.material?.unit.name ?? '';
    final locale = Localizations.localeOf(context).languageCode;
    const gap = SizedBox(height: 14);

    if (estimate.status == LoadStatus.failure) {
      final failure = estimate.failure!;
      return [
        if (failure is NoPricesFailure)
          Text(
            l10n.estimateNoPrices,
            style: context.mbText.body.copyWith(color: c.inkMuted),
          )
        else
          MbErrorView(
            failure: failure,
            onRetry: context.read<CostEstimatorCubit>().retryEstimate,
          ),
      ];
    }
    if (data == null) {
      return [
        if (estimate.isLoading && state.request != null)
          const LinearProgressIndicator(minHeight: 2)
        else
          Text(
            l10n.estimatePrompt,
            style: context.mbText.caption.copyWith(color: c.inkMuted),
          ),
      ];
    }
    return [
      MbRevalidatingBar(active: estimate.isLoading),
      MbHighlightPanel(
        label: l10n.estimatedCost,
        value: formatInr(data.estimatedCost),
        caption: l10n.estimateCaption(
          formatIndian(data.quantity),
          unit,
          formatInr(data.lowestPrice),
          data.lowestSourceName,
        ),
        body: Text(
          l10n.estimateSavingsVsAverage(
            formatInr(data.savings),
            '${formatInr(data.averagePrice)}/$unit',
          ),
        ),
      ),
      gap,
      MbPriceTable(
        nameHeader: l10n.columnSource,
        priceHeader: l10n.columnRupeePer(unit),
        rows: [
          for (final b in data.benchmarks)
            MbPriceRow(
              name: b.name,
              meta: l10n.priceDate(formatDayMonth(b.recordDate, locale)),
              price: formatInr(b.price),
              best: b.isLowest,
            ),
        ],
      ),
      gap,
      MbSourceNote(updated: context.updatedAt(data.updatedAt)),
    ];
  }
}

class _SavedList extends StatelessWidget {
  const _SavedList({required this.state});

  final CostEstimatorState state;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final l10n = context.l10n;
    final cubit = context.read<CostEstimatorCubit>();
    final saved = state.saved;
    final items = saved.data;
    final locale = Localizations.localeOf(context).languageCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MbSectionHeader(title: l10n.savedEstimates),
        const SizedBox(height: MbSpacing.s3),
        if (items == null && saved.status == LoadStatus.failure)
          MbTextLink(label: l10n.retry, onPressed: cubit.retrySaved)
        else if (items == null)
          const LinearProgressIndicator(minHeight: 2)
        else if (items.isEmpty)
          Text(
            l10n.savedEstimatesEmpty,
            style: context.mbText.caption.copyWith(color: c.inkMuted),
          )
        else
          MbGroup(
            children: [
              for (final s in items)
                MbListItem(
                  icon: MbIcons.estimator,
                  iconTone: MbTone.green,
                  title: s.productName,
                  subtitle: [
                    '${formatIndian(s.quantity)} ${s.unitSymbol}',
                    ?s.districtName,
                    formatDayMonth(s.createdAt, locale),
                  ].join(' · '),
                  showChevron: false,
                  trailing: MbIconButton(
                    icon: MbIcons.close,
                    label: l10n.deleteEstimate,
                    color: c.inkMuted,
                    onPressed: () => cubit.deleteSaved(s),
                  ),
                  onTap: () => cubit.openSaved(s),
                ),
            ],
          ),
      ],
    );
  }
}
