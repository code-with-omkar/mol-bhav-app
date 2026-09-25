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
import '../../../shared/widgets/mb_icons.dart';
import '../../../shared/widgets/mb_layout.dart';
import '../../../shared/widgets/mb_panels.dart';
import '../../../shared/widgets/mb_price.dart';
import '../../../shared/widgets/mb_select_field.dart';
import '../../../shared/widgets/mb_state_views.dart';
import '../../../shared/widgets/mb_text_field.dart';
import '../domain/tools.dart';
import 'tools_cubits.dart';

/// Quantity-based procurement cost estimate from regional benchmarks.
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
              .showSnackBar(SnackBar(content: Text(l10n.estimateSaved)));
        } else if (state.saveStatus == SubmitStatus.failure) {
          showFailureSnackBar(context, state.saveFailure!);
        }
      },
      builder: (context, state) {
        final ready = state.options.status == LoadStatus.ready;
        return Scaffold(
          appBar: MbAppBar(title: l10n.costEstimatorTitle),
          body: switch (state.options.status) {
            LoadStatus.failure => MbErrorView(
              failure: state.options.failure!,
              onRetry: cubit.load,
            ),
            LoadStatus.ready => _Form(state: state),
            _ => const MbLoadingView(),
          },
          bottomNavigationBar: ready
              ? MbFooter(
                  child: MbButton(
                    label: l10n.saveEstimate,
                    icon: MbIcons.report,
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
    final options = state.options.data!;
    final material = state.material;
    const gap = SizedBox(height: 14);

    return ListView(
      padding: MbSpacing.screenPadding,
      children: [
        if (options.categories.length > 1) ...[
          MbSegmentedTabs<String>(
            stretch: true,
            value: state.categoryCode ?? '',
            onChanged: cubit.selectCategory,
            options: [
              for (final c in options.categories)
                MbTabOption(value: c.id, label: c.name),
            ],
          ),
          gap,
        ],
        MbSelectField<String>(
          label: l10n.materialLabel,
          icon: categoryIcon(state.categoryCode ?? ''),
          value: state.materialId,
          onChanged: cubit.selectMaterial,
          items: [
            for (final m in state.materials)
              MbSelectItem(value: m.id, label: m.name),
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
            Expanded(
              child: MbSelectField<String>(
                label: l10n.unitLabel,
                value: state.unitId,
                onChanged: cubit.selectUnit,
                items: [
                  for (final u in material?.units ?? const <NamedOption>[])
                    MbSelectItem(value: u.id, label: u.name),
                ],
              ),
            ),
          ],
        ),
        gap,
        MbSelectField<String>(
          label: l10n.deliverToLabel,
          icon: MbIcons.market,
          value: state.locationId,
          onChanged: cubit.selectLocation,
          items: [
            for (final l in options.locations)
              MbSelectItem(value: l.id, label: l.name),
          ],
        ),
        gap,
        ..._result(context),
      ],
    );
  }

  List<Widget> _result(BuildContext context) {
    final c = context.mbColors;
    final l10n = context.l10n;
    final estimate = state.estimate;
    final data = estimate.data;
    const gap = SizedBox(height: 14);

    if (estimate.status == LoadStatus.failure) {
      return [
        MbErrorView(
          failure: estimate.failure!,
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
    final perUnit = formatInr(data.lowestPrice);
    return [
      if (estimate.isLoading) const LinearProgressIndicator(minHeight: 2),
      MbHighlightPanel(
        label: l10n.estimatedCost,
        value: formatInr(data.estimatedCost),
        caption: l10n.estimateCaption(
          formatIndian(data.quantity),
          data.unitName,
          perUnit,
          data.lowestSourceName,
        ),
        body: Text(
          l10n.estimateSavings(
            formatInr(data.savings),
            '${formatInr(data.averagePrice)}/${data.priceUnit}',
          ),
        ),
      ),
      gap,
      MbPriceTable(
        nameHeader: l10n.columnSource,
        priceHeader: l10n.columnRupeePer(data.priceUnit),
        rows: [
          for (final b in data.benchmarks)
            MbPriceRow(
              name: b.name,
              meta: b.meta,
              price: formatInr(b.price),
              best: b.isLowest,
            ),
        ],
      ),
      gap,
      MbSourceNote(
        source: data.source,
        updated: context.updatedAt(data.updatedAt),
      ),
    ];
  }
}
