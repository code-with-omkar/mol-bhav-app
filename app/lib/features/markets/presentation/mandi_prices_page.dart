import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/share/deep_link_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/mb_dimens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/statuses.dart';
import '../../../shared/widgets/mb_app_bar.dart';
import '../../../shared/widgets/mb_icons.dart';
import '../../../shared/widgets/mb_price.dart';
import '../../../shared/widgets/mb_select_field.dart';
import '../../../shared/widgets/mb_state_views.dart';
import '../domain/mandi_prices.dart';
import '../../monetization/presentation/ads/ad_interleave.dart';
import '../../monetization/presentation/ads/native_ad_slot.dart';
import '../../promotions/domain/promotions.dart';
import '../../promotions/presentation/ad_slot.dart';
import '../../watchlist/presentation/watch_star.dart';
import 'mandi_prices_cubit.dart';
import 'share/price_share.dart';
import 'share/price_share_data.dart';

/// Browse by mandi: state → district → mandi → latest price per product.
class MandiPricesPage extends StatelessWidget {
  const MandiPricesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: MbAppBar(
        title: l10n.browseByMandi,
        actions: [
          MbAppBarAction(
            icon: MbIcons.compare,
            label: l10n.browseByCommodity,
            onPressed: () => context.go(AppRoutes.markets),
          ),
        ],
      ),
      body: BlocBuilder<MandiPricesCubit, MandiPricesState>(
        builder: (context, state) {
          final cubit = context.read<MandiPricesCubit>();
          return switch (state.states.status) {
            LoadStatus.failure => MbErrorView(
              failure: state.states.failure!,
              onRetry: cubit.load,
            ),
            LoadStatus.ready => _Content(state: state),
            _ => const MbLoadingView(),
          };
        },
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.state});

  final MandiPricesState state;

  static List<MbSelectItem<String>> _items(List<LocationOption>? options) => [
    for (final o in options ?? const <LocationOption>[])
      MbSelectItem(value: o.id, label: o.name),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<MandiPricesCubit>();
    const gap = SizedBox(height: MbSpacing.s4);
    final mandis = state.mandis.data;

    return ListView(
      padding: MbSpacing.screenPadding,
      children: [
        MbSelectField<String>(
          label: l10n.stateLabel,
          icon: MbIcons.market,
          hint: l10n.selectPlaceholder,
          value: state.stateId,
          onChanged: cubit.selectState,
          items: _items(state.states.data),
        ),
        gap,
        MbSelectField<String>(
          label: l10n.districtLabel,
          icon: MbIcons.market,
          hint: l10n.selectPlaceholder,
          value: state.districtId,
          error: state.districts.status == LoadStatus.failure
              ? l10n.districtsLoadError
              : null,
          onChanged: state.districts.status == LoadStatus.ready
              ? cubit.selectDistrict
              : null,
          items: _items(state.districts.data),
        ),
        gap,
        MbSelectField<String>(
          label: l10n.mandiLabel,
          icon: MbIcons.market,
          hint: l10n.selectPlaceholder,
          value: state.mandiId,
          helper: mandis != null && mandis.isEmpty ? l10n.mandisEmpty : null,
          onChanged: state.mandis.status == LoadStatus.ready
              ? cubit.selectMandi
              : null,
          items: _items(mandis),
        ),
        const SizedBox(height: MbSpacing.s6),
        _Prices(state: state),
      ],
    );
  }
}

class _Prices extends StatelessWidget {
  const _Prices({required this.state});

  final MandiPricesState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mbColors;
    final cubit = context.read<MandiPricesCubit>();
    final locale = Localizations.localeOf(context).languageCode;

    if (state.mandiId == null) {
      return Text(
        l10n.mandiPricesHint,
        textAlign: TextAlign.center,
        style: context.mbText.body.copyWith(color: c.inkMuted),
      );
    }
    final prices = state.prices;
    return switch (prices.status) {
      LoadStatus.failure => MbErrorView(
        failure: prices.failure!,
        onRetry: cubit.retry,
      ),
      LoadStatus.ready when prices.data!.isEmpty => MbEmptyView(
        message: l10n.mandiPricesEmpty,
      ),
      // One native card per 8 rows, between groups — never inside one.
      LoadStatus.ready => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: interleaveAds(
          every: 8,
          group: (rows) => MbGroup(children: rows),
          // The first slot can carry a sponsor; the rest stay AdMob.
          ad: (i) => i == 0
              ? const AdSlot(placement: PromotionPlacement.mandiPrices)
              : const NativeAdSlot(),
          spacing: const SizedBox(height: MbSpacing.s3),
          rows: [
            for (final p in prices.data!)
              Row(
                children: [
                  Expanded(
                    child: MbPriceRow(
                      name: p.variantName == null
                          ? p.productName
                          : '${p.productName} · ${p.variantName}',
                      meta:
                          '${l10n.priceDate(formatDayMonth(p.recordDate, locale))}'
                          ' · ${p.source}',
                      price: formatInr(p.modalPrice),
                      unit: p.unitSymbol,
                      onShare: () => sharePriceCard(
                        context,
                        PriceShareData(
                          productName: p.productName,
                          variantName: p.variantName,
                          mandiName: state.mandiName ?? '',
                          minPrice: p.minPrice,
                          maxPrice: p.maxPrice,
                          modalPrice: p.modalPrice,
                          unitSymbol: p.unitSymbol,
                          recordDate: p.recordDate,
                          source: p.source,
                          link: DeepLinkConfig.productLink(
                            p.productId,
                            mandiId: state.mandiId,
                          ),
                        ),
                      ),
                      shareLabel: l10n.sharePrice,
                    ),
                  ),
                  WatchStarButton(
                    productId: p.productId,
                    variantId: p.variantId,
                  ),
                ],
              ),
          ],
        ),
      ),
      _ => const Padding(
        padding: EdgeInsets.all(MbSpacing.s6),
        child: MbLoadingView(),
      ),
    };
  }
}
