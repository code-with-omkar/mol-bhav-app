import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/mb_dimens.dart';
import '../../../core/utils/data_state.dart';
import '../../../core/utils/statuses.dart';
import '../../../shared/widgets/category_visuals.dart';
import '../../../shared/widgets/mb_app_bar.dart';
import '../../../shared/widgets/mb_chip_group.dart';
import '../../../shared/widgets/mb_icon.dart';
import '../../../shared/widgets/mb_panels.dart';
import '../../../shared/widgets/mb_price.dart';
import '../../../shared/widgets/mb_state_views.dart';
import '../../../shared/widgets/mb_text_field.dart';
import '../../catalog/domain/catalog.dart';
import 'watch_star.dart';
import 'watchlist_cubit.dart';

class WatchlistPickerState extends Equatable {
  const WatchlistPickerState({
    this.categories = const DataState(),
    this.categoryCode,
    this.query = '',
    this.products = const DataState(),
  });

  final DataState<List<CatalogCategory>> categories;
  final String? categoryCode;
  final String query;
  final DataState<List<CatalogProduct>> products;

  WatchlistPickerState copyWith({
    DataState<List<CatalogCategory>>? categories,
    String? categoryCode,
    String? query,
    DataState<List<CatalogProduct>>? products,
  }) => WatchlistPickerState(
    categories: categories ?? this.categories,
    categoryCode: categoryCode ?? this.categoryCode,
    query: query ?? this.query,
    products: products ?? this.products,
  );

  @override
  List<Object?> get props => [categories, categoryCode, query, products];
}

/// Category → product search for adding to the watchlist.
@injectable
class WatchlistPickerCubit extends Cubit<WatchlistPickerState> {
  WatchlistPickerCubit(this._catalog) : super(const WatchlistPickerState());

  final CatalogRepository _catalog;
  Timer? _debounce;

  Future<void> load() async {
    emit(state.copyWith(categories: const DataState.loading()));
    final categories = DataState.fromResult(await _catalog.getCategories());
    emit(state.copyWith(categories: categories));
    final first = categories.data?.firstOrNull;
    if (first != null) await selectCategory(first.code);
  }

  Future<void> selectCategory(String code) {
    emit(state.copyWith(categoryCode: code));
    return _search();
  }

  void queryChanged(String query) {
    emit(state.copyWith(query: query));
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _search);
  }

  Future<void> retry() => state.categories.data == null ? load() : _search();

  Future<CatalogProductDetail?> detail(String productId) async =>
      (await _catalog.getProduct(productId)).fold((_) => null, (d) => d);

  Future<void> _search() async {
    final code = state.categoryCode;
    if (code == null) return;
    final query = state.query;
    emit(
      state.copyWith(products: DataState.loading(data: state.products.data)),
    );
    final result = await _catalog.getProducts(code, search: query);
    if (isClosed || state.categoryCode != code || state.query != query) return;
    emit(state.copyWith(products: DataState.fromResult(result)));
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}

class WatchlistPickerPage extends StatelessWidget {
  const WatchlistPickerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: MbAppBar(title: l10n.addToWatchlistTitle),
      body: BlocBuilder<WatchlistPickerCubit, WatchlistPickerState>(
        builder: (context, state) {
          final cubit = context.read<WatchlistPickerCubit>();
          final categories = state.categories.data;
          if (categories == null) {
            return state.categories.status == LoadStatus.failure
                ? MbErrorView(
                    failure: state.categories.failure!,
                    onRetry: cubit.retry,
                  )
                : const MbLoadingView();
          }
          return ListView(
            padding: MbSpacing.screenPadding,
            children: [
              MbChipGroup<String>.single(
                semanticLabel: l10n.categoryLabel,
                value: state.categoryCode,
                onChanged: cubit.selectCategory,
                options: [
                  for (final c in categories)
                    MbChipOption(value: c.code, label: c.name),
                ],
              ),
              const SizedBox(height: MbSpacing.s4),
              MbTextField(
                hint: l10n.searchProductsHint,
                icon: MbIcons.search,
                textInputAction: TextInputAction.search,
                onChanged: cubit.queryChanged,
              ),
              const SizedBox(height: MbSpacing.s2),
              MbRevalidatingBar(active: state.products.isLoading),
              const SizedBox(height: MbSpacing.s2),
              ..._products(context, state),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _products(BuildContext context, WatchlistPickerState state) {
    final l10n = context.l10n;
    final products = state.products.data;
    if (state.products.status == LoadStatus.failure) {
      return [
        MbErrorView(
          failure: state.products.failure!,
          onRetry: context.read<WatchlistPickerCubit>().retry,
        ),
      ];
    }
    if (products == null) return const [];
    if (products.isEmpty) {
      return [
        Text(
          l10n.noMatches,
          style: context.mbText.body.copyWith(color: context.mbColors.inkMuted),
        ),
      ];
    }
    final code = state.categoryCode ?? '';
    return [
      MbGroup(
        children: [
          for (final p in products)
            MbListItem(
              leading: MbThumb(
                icon: categoryIcon(code),
                tone: categoryTint(code),
              ),
              title: p.name,
              subtitle: p.subCategoryName.isEmpty ? null : p.subCategoryName,
              showChevron: false,
              trailing: WatchStarButton(productId: p.id),
              onTap: () => _choose(context, p),
            ),
        ],
      ),
    ];
  }

  /// A product with varieties asks which one; otherwise it toggles directly.
  Future<void> _choose(BuildContext context, CatalogProduct product) async {
    final detail = await context.read<WatchlistPickerCubit>().detail(
      product.id,
    );
    if (!context.mounted) return;
    final variants = detail?.variants ?? const <CatalogVariant>[];
    if (variants.isEmpty) {
      await toggleWatch(context, product.id);
      return;
    }
    final choice = await showModalBottomSheet<_VariantChoice>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => _VariantSheet(
        product: product,
        variants: variants,
        watchlist: context.read<WatchlistCubit>(),
      ),
    );
    if (choice != null && context.mounted) {
      await toggleWatch(context, product.id, variantId: choice.variantId);
    }
  }
}

class _VariantChoice {
  const _VariantChoice(this.variantId);

  final String? variantId;
}

class _VariantSheet extends StatelessWidget {
  const _VariantSheet({
    required this.product,
    required this.variants,
    required this.watchlist,
  });

  final CatalogProduct product;
  final List<CatalogVariant> variants;
  final WatchlistCubit watchlist;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mbColors;

    Widget row(String title, String? variantId) {
      final watched =
          watchlist.state.itemFor(product.id, variantId: variantId) != null;
      return MbListItem(
        title: title,
        showChevron: false,
        trailing: MbIcon(
          MbIcons.watchlist,
          filled: watched,
          color: watched ? c.bhavAmber : c.inkMuted,
          semanticLabel: watched
              ? l10n.removeFromWatchlist
              : l10n.addToWatchlist,
        ),
        onTap: () => Navigator.of(context).pop(_VariantChoice(variantId)),
      );
    }

    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(
          MbSpacing.s4,
          0,
          MbSpacing.s4,
          MbSpacing.s4,
        ),
        children: [
          Text(product.name, style: context.mbText.appBarTitle),
          const SizedBox(height: MbSpacing.s3),
          MbGroup(
            children: [
              row(l10n.allVarieties, null),
              for (final v in variants) row(v.name, v.id),
            ],
          ),
        ],
      ),
    );
  }
}
