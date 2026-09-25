import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/locale/app_language.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/mb_dimens.dart';
import '../../../../core/utils/statuses.dart';
import '../../../../shared/widgets/mb_app_bar.dart';
import '../../../../shared/widgets/mb_button.dart';
import '../../../../shared/widgets/mb_chip_group.dart';
import '../../../../shared/widgets/mb_icon.dart';
import '../../../../shared/widgets/mb_layout.dart';
import '../../../../shared/widgets/mb_select_field.dart';
import '../../../../shared/widgets/mb_state_views.dart';
import '../../domain/entities/onboarding_entities.dart';
import '../cubit/business_profile_cubit.dart';

/// Onboarding step 1: business type, state, district, preferred language.
class BusinessProfilePage extends StatelessWidget {
  const BusinessProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<BusinessProfileCubit>();

    return BlocConsumer<BusinessProfileCubit, BusinessProfileState>(
      listenWhen: (p, n) => p.submitStatus != n.submitStatus,
      listener: (context, state) {
        if (state.submitStatus == SubmitStatus.success) {
          context.push(AppRoutes.selectCategory);
        } else if (state.submitStatus == SubmitStatus.failure) {
          showFailureSnackBar(context, state.submitFailure!);
        }
      },
      builder: (context, state) {
        final ready = state.optionsStatus == LoadStatus.ready;
        return Scaffold(
          appBar: MbAppBar(title: l10n.profileTitle),
          body: switch (state.optionsStatus) {
            LoadStatus.initial || LoadStatus.loading => const MbLoadingView(),
            LoadStatus.failure => MbErrorView(
              failure: state.optionsFailure!,
              onRetry: cubit.load,
            ),
            LoadStatus.ready => _Form(state: state, options: state.options!),
          },
          bottomNavigationBar: ready
              ? MbFooter(
                  child: MbButton(
                    label: l10n.continueAction,
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

class _Form extends StatelessWidget {
  const _Form({required this.state, required this.options});

  final BusinessProfileState state;
  final ProfileOptions options;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final t = context.mbText;
    final l10n = context.l10n;
    final cubit = context.read<BusinessProfileCubit>();
    const gap = SizedBox(height: MbSpacing.s4);

    return ListView(
      padding: MbSpacing.screenPadding,
      children: [
        Text(l10n.profileStep, style: t.caption.copyWith(color: c.inkMuted)),
        gap,
        Text(
          l10n.businessTypeLabel,
          style: t.fieldLabel.copyWith(color: c.ink),
        ),
        const SizedBox(height: MbSpacing.s2),
        MbChipGroup<String>.single(
          semanticLabel: l10n.businessTypeLabel,
          value: state.businessTypeId,
          onChanged: cubit.selectBusinessType,
          options: [
            for (final type in options.businessTypes)
              MbChipOption(value: type.id, label: type.name),
          ],
        ),
        gap,
        MbSelectField<String>(
          label: l10n.stateLabel,
          icon: MbIcons.market,
          hint: l10n.selectPlaceholder,
          value: state.stateCode,
          onChanged: cubit.selectState,
          items: [
            for (final region in options.states)
              MbSelectItem(value: region.code, label: region.name),
          ],
        ),
        gap,
        _DistrictField(state: state),
        gap,
        MbSelectField<AppLanguage>(
          label: l10n.preferredLanguageLabel,
          icon: MbIcons.language,
          value: state.language,
          onChanged: cubit.selectLanguage,
          helper: l10n.preferredLanguageHelper,
          items: [
            for (final language in AppLanguage.values)
              MbSelectItem(value: language, label: language.nativeName),
          ],
        ),
      ],
    );
  }
}

class _DistrictField extends StatelessWidget {
  const _DistrictField({required this.state});

  final BusinessProfileState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<BusinessProfileCubit>();
    final failed = state.districtsStatus == LoadStatus.failure;
    final hint = switch (state.districtsStatus) {
      _ when state.stateCode == null => l10n.selectStateFirst,
      LoadStatus.loading => l10n.loading,
      _ => l10n.selectPlaceholder,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MbSelectField<String>(
          label: l10n.districtLabel,
          hint: hint,
          value: state.districtCode,
          error: failed ? l10n.districtsLoadError : null,
          onChanged: state.districtsStatus == LoadStatus.ready
              ? cubit.selectDistrict
              : null,
          items: [
            for (final district in state.districts)
              MbSelectItem(value: district.code, label: district.name),
          ],
        ),
        if (failed)
          MbTextLink(label: l10n.retry, onPressed: cubit.retryDistricts),
      ],
    );
  }
}
