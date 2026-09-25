import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/mb_dimens.dart';
import '../../../core/utils/data_state.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/statuses.dart';
import '../../../core/utils/timestamps.dart';
import '../../../shared/widgets/category_visuals.dart';
import '../../../shared/widgets/mb_app_bar.dart';
import '../../../shared/widgets/mb_button.dart';
import '../../../shared/widgets/mb_icon_button.dart';
import '../../../shared/widgets/mb_icons.dart';
import '../../../shared/widgets/mb_layout.dart';
import '../../../shared/widgets/mb_panels.dart';
import '../../../shared/widgets/mb_price.dart';
import '../../../shared/widgets/mb_state_views.dart';
import '../domain/markets_entities.dart';
import 'markets_cubits.dart';

/// Where to buy the required quantity, and how much it saves.
class BuyingOpportunityPage extends StatelessWidget {
  const BuyingOpportunityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<BuyingOpportunityCubit, DataState<BuyingOpportunity>>(
      builder: (context, state) {
        final data = state.data;
        final best = data?.best;
        return Scaffold(
          appBar: MbAppBar(
            title: l10n.buyingOpportunityTitle,
            actions: [
              // Sharing needs a share-sheet package; not wired yet.
              MbAppBarAction(
                icon: MbIcons.share,
                label: l10n.share,
                onPressed: null,
              ),
            ],
          ),
          body: switch (state.status) {
            LoadStatus.failure => MbErrorView(
              failure: state.failure!,
              onRetry: context.read<BuyingOpportunityCubit>().retry,
            ),
            LoadStatus.ready => _Content(data: data!),
            _ => const MbLoadingView(),
          },
          bottomNavigationBar: best == null
              ? null
              : MbFooter(
                  // No suppliers screen exists in the design yet.
                  child: MbButton(
                    label: l10n.viewSuppliers(best.marketName),
                    size: MbButtonSize.lg,
                    block: true,
                    onPressed: null,
                  ),
                ),
        );
      },
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.data});

  final BuyingOpportunity data;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final l10n = context.l10n;
    final best = data.best;
    final reference = data.reference;
    final quantity = '${formatIndian(data.quantity)} ${data.quantityUnit}';
    const gap = SizedBox(height: 14);

    return ListView(
      padding: MbSpacing.screenPadding,
      children: [
        MbGroup(
          children: [
            MbListItem(
              icon: categoryIcon(data.categoryCode),
              iconTone: categoryTint(data.categoryCode),
              title: data.commodityName,
              subtitle: l10n.requirementLine(quantity, data.deliverTo),
              // Editing the requirement has no screen in the design yet.
              trailing: MbIconButton(
                icon: MbIcons.edit,
                label: l10n.editRequirement,
                onPressed: null,
              ),
            ),
          ],
        ),
        gap,
        MbPriceTable(
          nameHeader: l10n.columnMarket,
          priceHeader: l10n.columnPricePer(data.priceUnit),
          rows: [
            for (final m in data.markets)
              MbPriceRow(
                name: m.marketName,
                price: formatInr(m.price),
                unit: data.priceUnit,
                best: m.marketId == data.bestMarketId,
                badge: m.marketId == data.bestMarketId
                    ? MbBadge(
                        label: l10n.bestPriceBadge,
                        tone: MbBadgeTone.bestSolid,
                      )
                    : null,
              ),
          ],
        ),
        gap,
        MbHighlightPanel(
          label: l10n.potentialDifference,
          value: formatInr(data.potentialDifference),
          caption: reference == null
              ? null
              : l10n.differenceCaption(quantity, reference.marketName),
          body: best == null || reference == null
              ? null
              : Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: l10n.howCalculated,
                        style: TextStyle(
                          color: c.ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const TextSpan(text: '\n'),
                      TextSpan(
                        text: l10n.calculationLine(
                          formatInr(reference.price),
                          formatInr(best.price),
                          quantity,
                          formatInr(data.potentialDifference),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        gap,
        MbSourceNote(
          source: data.source,
          updated: context.updatedAt(data.updatedAt),
        ),
      ],
    );
  }
}
