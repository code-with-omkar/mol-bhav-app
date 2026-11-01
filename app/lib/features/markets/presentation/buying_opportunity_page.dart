import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/share/deep_link_config.dart';
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
import '../../../shared/widgets/mb_text_field.dart';
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
              MbAppBarAction(
                icon: MbIcons.share,
                label: l10n.share,
                onPressed: data == null || best == null
                    ? null
                    : () => _share(context, data),
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
                  // The comparison for this product, with the best market
                  // highlighted: its prices, trend and share actions.
                  child: MbButton(
                    label: l10n.viewSuppliers(best.marketName),
                    size: MbButtonSize.lg,
                    block: true,
                    onPressed: data == null
                        ? null
                        : () => context.go(
                            AppRoutes.marketsFor(
                              commodityId: data.commodityId,
                              mandiId: best.marketId,
                            ),
                          ),
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
              trailing: MbIconButton(
                icon: MbIcons.edit,
                label: l10n.editRequirement,
                onPressed: () => _editQuantity(context, data),
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
          source: data.source.isEmpty ? null : data.source,
          updated: context.updatedAt(data.updatedAt),
        ),
      ],
    );
  }
}

void _share(BuildContext context, BuyingOpportunity data) {
  final l10n = context.l10n;
  final best = data.best!;
  final reference = data.reference;
  final quantity = '${formatIndian(data.quantity)} ${data.quantityUnit}';
  final text = l10n.opportunityShareText(
    data.commodityName,
    formatInr(best.price),
    data.priceUnit,
    best.marketName,
    formatInr(data.potentialDifference),
    quantity,
    reference?.marketName ?? data.deliverTo,
  );
  final link = DeepLinkConfig.productLink(
    data.commodityId,
    mandiId: best.marketId,
  );
  SharePlus.instance.share(ShareParams(text: '$text\n$link'));
}

Future<void> _editQuantity(BuildContext context, BuyingOpportunity data) async {
  final cubit = context.read<BuyingOpportunityCubit>();
  final quantity = await showModalBottomSheet<num>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(MbRadius.lg)),
    ),
    builder: (_) =>
        _QuantitySheet(initial: data.quantity, unit: data.quantityUnit),
  );
  if (quantity != null) cubit.setQuantity(quantity);
}

class _QuantitySheet extends StatefulWidget {
  const _QuantitySheet({required this.initial, required this.unit});

  final num initial;
  final String unit;

  @override
  State<_QuantitySheet> createState() => _QuantitySheetState();
}

class _QuantitySheetState extends State<_QuantitySheet> {
  late final _controller = TextEditingController(
    text: formatIndian(widget.initial).replaceAll(',', ''),
  );

  num? get _value {
    final v = num.tryParse(_controller.text.replaceAll(',', '').trim());
    return v != null && v > 0 ? v : null;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mbColors;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        MbSpacing.s4,
        MbSpacing.s4,
        MbSpacing.s4,
        MbSpacing.s4 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.editQuantityTitle,
            style: context.mbText.title.copyWith(color: c.ink),
          ),
          const SizedBox(height: MbSpacing.s3),
          MbTextField(
            controller: _controller,
            suffix: widget.unit,
            helper: l10n.editQuantityHelper,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: MbSpacing.s4),
          MbButton(
            label: l10n.applyAction,
            block: true,
            onPressed: _value == null
                ? null
                : () => Navigator.of(context).pop(_value),
          ),
        ],
      ),
    );
  }
}
