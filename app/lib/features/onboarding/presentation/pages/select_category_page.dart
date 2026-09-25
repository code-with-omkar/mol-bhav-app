import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/mb_dimens.dart';
import '../../../../core/utils/statuses.dart';
import '../../../../shared/widgets/mb_app_bar.dart';
import '../../../../shared/widgets/mb_button.dart';
import '../../../../shared/widgets/mb_category_card.dart';
import '../../../../shared/widgets/mb_layout.dart';
import '../../../../shared/widgets/mb_state_views.dart';
import '../../../../shared/widgets/category_visuals.dart';
import '../cubit/select_category_cubit.dart';

/// Onboarding step 2: pick one or more procurement categories.
class SelectCategoryPage extends StatelessWidget {
  const SelectCategoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<SelectCategoryCubit>();

    return BlocConsumer<SelectCategoryCubit, SelectCategoryState>(
      listenWhen: (p, n) => p.submitStatus != n.submitStatus,
      listener: (context, state) {
        if (state.submitStatus == SubmitStatus.success) {
          context.go(AppRoutes.home);
        } else if (state.submitStatus == SubmitStatus.failure) {
          showFailureSnackBar(context, state.submitFailure!);
        }
      },
      builder: (context, state) {
        final hasList =
            state.status == LoadStatus.ready && state.categories.isNotEmpty;
        return Scaffold(
          appBar: const MbAppBar(),
          body: switch (state.status) {
            LoadStatus.initial || LoadStatus.loading => const MbLoadingView(),
            LoadStatus.failure => MbErrorView(
              failure: state.failure!,
              onRetry: cubit.load,
            ),
            LoadStatus.ready when state.categories.isEmpty => MbEmptyView(
              message: l10n.categoriesEmpty,
              onRetry: cubit.load,
            ),
            LoadStatus.ready => _CategoryList(state: state),
          },
          bottomNavigationBar: hasList
              ? MbFooter(
                  child: MbButton(
                    label: l10n.continueSelected(state.selected.length),
                    size: MbButtonSize.lg,
                    block: true,
                    isLoading: state.submitStatus == SubmitStatus.submitting,
                    onPressed: state.canSubmit ? cubit.submit : null,
                  ),
                )
              : null,
        );
      },
    );
  }
}

class _CategoryList extends StatelessWidget {
  const _CategoryList({required this.state});

  final SelectCategoryState state;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final l10n = context.l10n;
    final cubit = context.read<SelectCategoryCubit>();

    return ListView.separated(
      padding: MbSpacing.screenPadding,
      itemCount: state.categories.length + 1,
      separatorBuilder: (_, index) =>
          SizedBox(height: index == 0 ? MbSpacing.s5 : MbSpacing.s3),
      itemBuilder: (context, index) {
        if (index == 0) {
          return MbPageHeading(
            title: l10n.selectCategoryTitle,
            lead: Text(
              l10n.selectCategorySubtitle,
              style: context.mbText.body.copyWith(color: c.inkMuted),
            ),
          );
        }
        final category = state.categories[index - 1];
        return MbCategoryRow(
          title: category.name,
          subtitle: category.isAvailable
              ? (category.highlights.isEmpty
                    ? null
                    : category.highlights.join(' · '))
              : l10n.categoryComingSoon,
          icon: categoryIcon(category.code),
          tone: categoryTone(category.code, available: category.isAvailable),
          selected: state.selected.contains(category.id),
          onTap: category.isAvailable ? () => cubit.toggle(category.id) : null,
        );
      },
    );
  }
}
