import 'package:flutter/material.dart';

import '../../../core/error/failure.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/mb_dimens.dart';
import '../../../shared/widgets/mb_button.dart';
import '../../../shared/widgets/mb_price.dart';
import '../../../shared/widgets/mb_state_views.dart';
import '../domain/admin_products.dart';
import 'admin_products_cubit.dart';
import 'names_sheet.dart';

/// Opens a product's variants (its grades or forms) as a bottom sheet.
Future<void> showProductVariants(
  BuildContext context, {
  required AdminProductsCubit cubit,
  required String productId,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(MbRadius.lg)),
  ),
  builder: (_) => ProductVariantsSheet(cubit: cubit, productId: productId),
);

/// A product's variants: tap one to rename it or switch it off, or add one.
/// The list is read again from the server after every change.
class ProductVariantsSheet extends StatefulWidget {
  const ProductVariantsSheet({
    super.key,
    required this.cubit,
    required this.productId,
  });

  final AdminProductsCubit cubit;
  final String productId;

  @override
  State<ProductVariantsSheet> createState() => _ProductVariantsSheetState();
}

class _ProductVariantsSheetState extends State<ProductVariantsSheet> {
  AdminProduct? _product;
  Failure? _failure;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await widget.cubit.detail(widget.productId);
    if (!mounted) return;
    setState(() {
      _failure = null;
      result.fold((f) => _failure = f, (p) => _product = p);
    });
  }

  /// Reread after a save so the list matches the server.
  Future<Failure?> _saved(Future<Failure?> save) async {
    final failure = await save;
    if (failure == null) await _load();
    return failure;
  }

  Map<String, String> _namesOf(AdminVariant v) => {
    for (final lang in productNameLanguages) lang: v.nameIn(lang),
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mbColors;
    final t = context.mbText;
    final product = _product;

    Widget body;
    if (product == null) {
      body = _failure == null
          ? const Padding(
              padding: EdgeInsets.all(MbSpacing.s6),
              child: Center(child: CircularProgressIndicator()),
            )
          : MbErrorView(failure: _failure!, onRetry: _load);
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (product.variants.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: MbSpacing.s3),
              child: Text(
                l10n.adminVariantsEmpty,
                style: t.body.copyWith(color: c.inkMuted),
              ),
            )
          else
            for (final v in product.variants)
              InkWell(
                onTap: () => showNamesSheet(
                  context,
                  title: l10n.adminVariantEdit,
                  isNew: false,
                  names: _namesOf(v),
                  isActive: v.isActive,
                  onSave: (_, names, active) => _saved(
                    widget.cubit.updateVariant(
                      product.id,
                      v.edited(names: names, isActive: active),
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: MbSpacing.s2),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${v.label}  ·  ${v.code}',
                          style: t.body.copyWith(color: c.ink),
                        ),
                      ),
                      if (!v.isActive)
                        MbBadge(
                          label: l10n.adminPlanOff,
                          tone: MbBadgeTone.neutral,
                        ),
                    ],
                  ),
                ),
              ),
          const SizedBox(height: MbSpacing.s3),
          MbButton(
            label: l10n.adminVariantNew,
            variant: MbButtonVariant.secondary,
            onPressed: () => showNamesSheet(
              context,
              title: l10n.adminVariantNew,
              isNew: true,
              onSave: (code, names, _) =>
                  _saved(widget.cubit.addVariant(product.id, code, names)),
            ),
          ),
        ],
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(MbSpacing.s4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.adminVariantsTitle, style: t.title.copyWith(color: c.ink)),
          Text(
            l10n.adminVariantsIntro,
            style: t.caption.copyWith(color: c.inkMuted),
          ),
          const SizedBox(height: MbSpacing.s2),
          body,
        ],
      ),
    );
  }
}
