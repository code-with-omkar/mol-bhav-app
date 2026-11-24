import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/failure.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/mb_dimens.dart';
import '../../../core/utils/statuses.dart';
import '../../../shared/widgets/mb_app_bar.dart';
import '../../../shared/widgets/mb_button.dart';
import '../../../shared/widgets/mb_layout.dart';
import '../../../shared/widgets/mb_price.dart';
import '../../../shared/widgets/mb_select_field.dart';
import '../../../shared/widgets/mb_state_views.dart';
import '../../../shared/widgets/mb_text_field.dart';
import '../domain/admin_commodities.dart';
import '../domain/admin_products.dart';
import 'admin_products_cubit.dart';
import 'product_variants_sheet.dart';

/// The catalog's products. Search by name or code; tap one to change its
/// English, Hindi and Marathi names or switch it off.
class AdminProductsPage extends StatefulWidget {
  const AdminProductsPage({super.key});

  @override
  State<AdminProductsPage> createState() => _AdminProductsPageState();
}

class _AdminProductsPageState extends State<AdminProductsPage> {
  final _scroll = ScrollController();
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 300) {
        context.read<AdminProductsCubit>().loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _edit(BuildContext context, AdminProductSummary item) async {
    final cubit = context.read<AdminProductsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final result = await cubit.detail(item.id);
    if (!context.mounted) return;
    final product = result.fold((failure) {
      messenger.showSnackBar(
        SnackBar(content: Text(failureMessage(context, failure))),
      );
      return null;
    }, (p) => p);
    if (product == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(MbRadius.lg)),
      ),
      builder: (sheetContext) => _ProductSheet(
        product: product,
        onSave: cubit.save,
        onVariants: () => showProductVariants(
          sheetContext,
          cubit: cubit,
          productId: product.id,
        ),
      ),
    );
  }

  Future<void> _addNew(BuildContext context) async {
    final cubit = context.read<AdminProductsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final result = await cubit.targets();
    if (!context.mounted) return;
    final targets = result.fold((failure) {
      messenger.showSnackBar(
        SnackBar(content: Text(failureMessage(context, failure))),
      );
      return null;
    }, (t) => t);
    if (targets == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(MbRadius.lg)),
      ),
      builder: (_) => _NewProductSheet(targets: targets, onSave: cubit.create),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mbColors;
    final cubit = context.read<AdminProductsCubit>();
    return Scaffold(
      appBar: MbAppBar(title: l10n.adminProductsTitle),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MbSpacing.s4),
          child: MbButton(
            label: l10n.adminProductNew,
            block: true,
            onPressed: () => _addNew(context),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              MbSpacing.s4,
              MbSpacing.s3,
              MbSpacing.s4,
              0,
            ),
            child: MbTextField(
              controller: _search,
              hint: l10n.adminProductsSearchHint,
              textInputAction: TextInputAction.search,
              onSubmitted: (v) => cubit.load(search: v),
            ),
          ),
          Expanded(
            child: BlocBuilder<AdminProductsCubit, AdminProductsState>(
              builder: (context, state) {
                if (state.products.isEmpty) {
                  return switch (state.status) {
                    LoadStatus.failure => MbErrorView(
                      failure: state.failure!,
                      onRetry: cubit.load,
                    ),
                    LoadStatus.ready => MbEmptyView(
                      message: l10n.adminProductsEmpty,
                    ),
                    _ => const MbLoadingView(),
                  };
                }
                return RefreshIndicator(
                  onRefresh: cubit.load,
                  child: ListView.separated(
                    controller: _scroll,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: MbSpacing.screenPadding,
                    itemCount:
                        state.products.length + (state.loadingMore ? 1 : 0),
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: MbSpacing.s2),
                    itemBuilder: (context, i) => i >= state.products.length
                        ? const Padding(
                            padding: EdgeInsets.all(MbSpacing.s3),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : _ProductCard(
                            item: state.products[i],
                            onTap: () => _edit(context, state.products[i]),
                          ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: MbSpacing.s2),
            child: Text(
              l10n.adminProductsHint,
              style: context.mbText.caption.copyWith(color: c.inkMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.item, required this.onTap});

  final AdminProductSummary item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mbColors;
    final t = context.mbText;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(MbRadius.md),
      child: MbCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: t.title.copyWith(color: c.ink)),
                  Text(
                    '${item.code} · ${item.categoryCode} › '
                    '${item.subCategoryCode} · ${item.unitCode}',
                    style: t.caption.copyWith(color: c.inkMuted),
                  ),
                ],
              ),
            ),
            if (!item.isActive) ...[
              const SizedBox(width: MbSpacing.s2),
              MbBadge(label: l10n.adminPlanOff, tone: MbBadgeTone.neutral),
            ],
          ],
        ),
      ),
    );
  }
}

/// Edit a product's names and on/off. Stays open if the save is refused,
/// showing why.
class _ProductSheet extends StatefulWidget {
  const _ProductSheet({
    required this.product,
    required this.onSave,
    required this.onVariants,
  });

  final AdminProduct product;
  final Future<Failure?> Function(AdminProduct product) onSave;
  final VoidCallback onVariants;

  @override
  State<_ProductSheet> createState() => _ProductSheetState();
}

class _ProductSheetState extends State<_ProductSheet> {
  late final Map<String, TextEditingController> _names = {
    for (final lang in productNameLanguages)
      lang: TextEditingController(text: widget.product.nameIn(lang)),
  };
  late bool _isActive = widget.product.isActive;

  bool _showErrors = false;
  bool _saving = false;
  Failure? _failure;

  Map<String, String> get _values => {
    for (final e in _names.entries) e.key: e.value.text,
  };

  @override
  void dispose() {
    for (final c in _names.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (productNameProblems(_values).isNotEmpty) {
      setState(() => _showErrors = true);
      return;
    }
    setState(() {
      _saving = true;
      _failure = null;
    });
    final failure = await widget.onSave(
      widget.product.edited(names: _values, isActive: _isActive),
    );
    if (!mounted) return;
    if (failure == null) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _saving = false;
        _failure = failure;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mbColors;
    final t = context.mbText;
    final problems = _showErrors
        ? productNameProblems(_values)
        : <ProductNameProblem>{};
    final labels = {
      'en': l10n.adminProductNameEn,
      'hi': l10n.adminProductNameHi,
      'mr': l10n.adminProductNameMr,
    };

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(MbSpacing.s4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.adminProductEditTitle,
              style: t.title.copyWith(color: c.ink),
            ),
            Text(
              widget.product.code,
              style: t.caption.copyWith(color: c.inkMuted),
            ),
            for (final lang in productNameLanguages) ...[
              const SizedBox(height: MbSpacing.s3),
              MbTextField(
                controller: _names[lang],
                label: labels[lang],
                helper: lang == 'en' ? null : l10n.adminProductNameOptional,
                enabled: !_saving,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(productNameMaxLength),
                ],
                error:
                    lang == 'en' &&
                        problems.contains(ProductNameProblem.englishMissing)
                    ? l10n.adminProductErrEnglish
                    : null,
              ),
            ],
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                l10n.adminProductActive,
                style: t.body.copyWith(color: c.ink),
              ),
              subtitle: Text(
                l10n.adminProductActiveHint,
                style: t.caption.copyWith(color: c.inkMuted),
              ),
              value: _isActive,
              onChanged: _saving ? null : (v) => setState(() => _isActive = v),
            ),
            MbButton(
              label: l10n.adminVariantsButton(widget.product.variants.length),
              variant: MbButtonVariant.secondary,
              onPressed: _saving ? null : widget.onVariants,
            ),
            if (_failure != null) ...[
              const SizedBox(height: MbSpacing.s2),
              Text(
                failureMessage(context, _failure!),
                style: t.caption.copyWith(color: c.priceUp),
              ),
            ],
            const SizedBox(height: MbSpacing.s4),
            MbButton(
              label: l10n.adminProductSave,
              block: true,
              isLoading: _saving,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}

/// Add a product by hand: its code, names, sub-category and unit. Stays open
/// if the save is refused (for example the code is taken), showing why.
class _NewProductSheet extends StatefulWidget {
  const _NewProductSheet({required this.targets, required this.onSave});

  final CommodityTargets targets;
  final Future<Failure?> Function({
    required String code,
    required String subCategoryId,
    required String unitId,
    required Map<String, String> names,
  })
  onSave;

  @override
  State<_NewProductSheet> createState() => _NewProductSheetState();
}

class _NewProductSheetState extends State<_NewProductSheet> {
  final _code = TextEditingController();
  late final Map<String, TextEditingController> _names = {
    for (final lang in productNameLanguages) lang: TextEditingController(),
  };
  String? _subCategoryId;
  String? _unitId;

  bool _showErrors = false;
  bool _saving = false;
  Failure? _failure;

  Map<String, String> get _values => {
    for (final e in _names.entries) e.key: e.value.text,
  };

  Set<NewProductProblem> get _problems => newProductProblems(
    code: _code.text,
    names: _values,
    subCategoryId: _subCategoryId,
    unitId: _unitId,
  );

  @override
  void dispose() {
    _code.dispose();
    for (final c in _names.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_problems.isNotEmpty) {
      setState(() => _showErrors = true);
      return;
    }
    setState(() {
      _saving = true;
      _failure = null;
    });
    final failure = await widget.onSave(
      code: _code.text,
      subCategoryId: _subCategoryId!,
      unitId: _unitId!,
      names: _values,
    );
    if (!mounted) return;
    if (failure == null) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _saving = false;
        _failure = failure;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mbColors;
    final t = context.mbText;
    final problems = _showErrors ? _problems : <NewProductProblem>{};
    final labels = {
      'en': l10n.adminProductNameEn,
      'hi': l10n.adminProductNameHi,
      'mr': l10n.adminProductNameMr,
    };

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(MbSpacing.s4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.adminProductNew, style: t.title.copyWith(color: c.ink)),
            const SizedBox(height: MbSpacing.s3),
            MbTextField(
              controller: _code,
              label: l10n.adminProductCode,
              helper: l10n.adminProductCodeHint,
              enabled: !_saving,
              inputFormatters: [
                LengthLimitingTextInputFormatter(40),
                FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9-]')),
              ],
              error: problems.contains(NewProductProblem.codeInvalid)
                  ? l10n.adminProductErrCode
                  : null,
            ),
            for (final lang in productNameLanguages) ...[
              const SizedBox(height: MbSpacing.s3),
              MbTextField(
                controller: _names[lang],
                label: labels[lang],
                helper: lang == 'en' ? null : l10n.adminProductNameOptional,
                enabled: !_saving,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(productNameMaxLength),
                ],
                error:
                    lang == 'en' &&
                        problems.contains(NewProductProblem.englishMissing)
                    ? l10n.adminProductErrEnglish
                    : null,
              ),
            ],
            const SizedBox(height: MbSpacing.s3),
            MbSelectField<String>(
              label: l10n.adminCommoditiesSubCategory,
              hint: l10n.adminCommoditiesChooseSubCategory,
              items: [
                for (final s in widget.targets.subCategories)
                  MbSelectItem(value: s.id, label: s.label),
              ],
              value: _subCategoryId,
              onChanged: _saving
                  ? null
                  : (v) => setState(() => _subCategoryId = v),
            ),
            if (problems.contains(NewProductProblem.subCategoryMissing))
              Text(
                l10n.adminProductErrSubCategory,
                style: t.caption.copyWith(color: c.priceUp),
              ),
            const SizedBox(height: MbSpacing.s3),
            MbSelectField<String>(
              label: l10n.adminCommoditiesUnit,
              hint: l10n.adminCommoditiesChooseUnit,
              items: [
                for (final u in widget.targets.units)
                  MbSelectItem(value: u.id, label: u.label),
              ],
              value: _unitId,
              onChanged: _saving ? null : (v) => setState(() => _unitId = v),
            ),
            if (problems.contains(NewProductProblem.unitMissing))
              Text(
                l10n.adminProductErrUnit,
                style: t.caption.copyWith(color: c.priceUp),
              ),
            if (_failure != null) ...[
              const SizedBox(height: MbSpacing.s2),
              Text(
                failureMessage(context, _failure!),
                style: t.caption.copyWith(color: c.priceUp),
              ),
            ],
            const SizedBox(height: MbSpacing.s4),
            MbButton(
              label: l10n.adminProductSave,
              block: true,
              isLoading: _saving,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
