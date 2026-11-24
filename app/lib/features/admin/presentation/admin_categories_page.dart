import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/failure.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/mb_dimens.dart';
import '../../../core/utils/data_state.dart';
import '../../../core/utils/statuses.dart';
import '../../../shared/widgets/mb_app_bar.dart';
import '../../../shared/widgets/mb_button.dart';
import '../../../shared/widgets/mb_layout.dart';
import '../../../shared/widgets/mb_price.dart';
import '../../../shared/widgets/mb_state_views.dart';
import '../domain/admin_categories.dart';
import '../domain/admin_products.dart';
import 'admin_categories_cubit.dart';
import 'names_sheet.dart';

/// The catalog's categories with their sub-categories. Tap one to rename it or
/// switch it off; add a sub-category from its category's card, or a category
/// with the button below.
class AdminCategoriesPage extends StatelessWidget {
  const AdminCategoriesPage({super.key});

  Future<void> _open(
    BuildContext context, {
    required String title,
    required bool isNew,
    Map<String, String> names = const {},
    bool isActive = true,
    required Future<Failure?> Function(
      String code,
      Map<String, String> names,
      bool isActive,
    )
    onSave,
  }) => showNamesSheet(
    context,
    title: title,
    isNew: isNew,
    names: names,
    isActive: isActive,
    onSave: onSave,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mbColors;
    final cubit = context.read<AdminCategoriesCubit>();

    Map<String, String> namesOf(List<ProductTranslation> t) => {
      for (final lang in productNameLanguages)
        lang: t.where((x) => x.language == lang).firstOrNull?.name ?? '',
    };

    return Scaffold(
      appBar: MbAppBar(title: l10n.adminCategoriesTitle),
      body: BlocBuilder<AdminCategoriesCubit, DataState<List<AdminCategory>>>(
        builder: (context, state) {
          final categories = state.data;
          if (categories == null) {
            return state.status == LoadStatus.failure
                ? MbErrorView(failure: state.failure!, onRetry: cubit.load)
                : const MbLoadingView();
          }
          return RefreshIndicator(
            onRefresh: cubit.load,
            child: ListView(
              padding: MbSpacing.screenPadding,
              children: [
                Text(
                  l10n.adminCategoriesIntro,
                  style: context.mbText.body.copyWith(color: c.inkMuted),
                ),
                const SizedBox(height: MbSpacing.s3),
                if (categories.isEmpty)
                  MbEmptyView(message: l10n.adminCategoriesEmpty)
                else
                  for (final category in categories) ...[
                    _CategoryCard(
                      category: category,
                      onEdit: () => _open(
                        context,
                        title: l10n.adminCategoryEdit,
                        isNew: false,
                        names: namesOf(category.translations),
                        isActive: category.isActive,
                        onSave: (_, names, active) => cubit.updateCategory(
                          category.edited(names: names, isActive: active),
                        ),
                      ),
                      onAddSub: () => _open(
                        context,
                        title: l10n.adminSubCategoryNew,
                        isNew: true,
                        onSave: (code, names, _) =>
                            cubit.addSubCategory(category.id, code, names),
                      ),
                      onEditSub: (sub) => _open(
                        context,
                        title: l10n.adminSubCategoryEdit,
                        isNew: false,
                        names: namesOf(sub.translations),
                        isActive: sub.isActive,
                        onSave: (_, names, active) => cubit.updateSubCategory(
                          category.id,
                          sub.edited(names: names, isActive: active),
                        ),
                      ),
                    ),
                    const SizedBox(height: MbSpacing.s2),
                  ],
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MbSpacing.s4),
          child: MbButton(
            label: l10n.adminCategoryNew,
            block: true,
            onPressed: () => _open(
              context,
              title: l10n.adminCategoryNew,
              isNew: true,
              onSave: (code, names, _) => cubit.createCategory(code, names),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.onEdit,
    required this.onAddSub,
    required this.onEditSub,
  });

  final AdminCategory category;
  final VoidCallback onEdit;
  final VoidCallback onAddSub;
  final void Function(AdminSubCategory sub) onEditSub;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mbColors;
    final t = context.mbText;
    return MbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onEdit,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.label,
                        style: t.title.copyWith(color: c.ink),
                      ),
                      Text(
                        category.code,
                        style: t.caption.copyWith(color: c.inkMuted),
                      ),
                    ],
                  ),
                ),
                if (!category.isActive)
                  MbBadge(label: l10n.adminPlanOff, tone: MbBadgeTone.neutral),
              ],
            ),
          ),
          for (final sub in category.subCategories)
            InkWell(
              onTap: () => onEditSub(sub),
              child: Padding(
                padding: const EdgeInsets.only(top: MbSpacing.s2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '› ${sub.label}  ·  ${sub.code}',
                        style: t.body.copyWith(color: c.ink),
                      ),
                    ),
                    if (!sub.isActive)
                      MbBadge(
                        label: l10n.adminPlanOff,
                        tone: MbBadgeTone.neutral,
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: MbSpacing.s2),
          MbButton(
            label: l10n.adminSubCategoryNew,
            variant: MbButtonVariant.secondary,
            onPressed: onAddSub,
          ),
        ],
      ),
    );
  }
}
