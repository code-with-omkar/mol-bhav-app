import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/mb_dimens.dart';
import '../../../core/utils/statuses.dart';
import '../../../shared/widgets/mb_app_bar.dart';
import '../../../shared/widgets/mb_layout.dart';
import '../../../shared/widgets/mb_state_views.dart';
import '../../app_features/domain/app_features.dart';
import 'admin_features_cubit.dart';

/// Turn optional parts of the app on or off for every user. A change shows in
/// the app within about ten minutes (sooner when it is reopened).
class AdminFeaturesPage extends StatelessWidget {
  const AdminFeaturesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<AdminFeaturesCubit>();
    return Scaffold(
      appBar: MbAppBar(title: l10n.adminFeaturesTitle),
      body: BlocConsumer<AdminFeaturesCubit, AdminFeaturesState>(
        listenWhen: (a, b) => b.saveFailure != null,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(failureMessage(context, state.saveFailure!)),
            ),
          );
          cubit.failureShown();
        },
        builder: (context, state) {
          final flags = state.flags.data;
          if (flags == null) {
            return state.flags.status == LoadStatus.failure
                ? MbErrorView(
                    failure: state.flags.failure!,
                    onRetry: cubit.load,
                  )
                : const MbLoadingView();
          }
          final c = context.mbColors;
          final t = context.mbText;
          return ListView(
            padding: MbSpacing.screenPadding,
            children: [
              Text(
                l10n.adminFeaturesIntro,
                style: t.body.copyWith(color: c.inkMuted),
              ),
              const SizedBox(height: MbSpacing.s3),
              MbCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: MbSpacing.s4,
                  vertical: MbSpacing.s2,
                ),
                // The tiles paint on the nearest Material; the card behind
                // them is a plain coloured box, which would hide their ink.
                child: Material(
                  type: MaterialType.transparency,
                  child: Column(
                    children: [
                      for (final feature in AppFeature.values)
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            _title(l10n, feature),
                            style: t.title.copyWith(color: c.ink),
                          ),
                          subtitle: Text(
                            _subtitle(l10n, feature),
                            style: t.caption.copyWith(color: c.inkMuted),
                          ),
                          value: flags[feature] ?? true,
                          onChanged: state.saving.contains(feature)
                              ? null
                              : (v) => cubit.setEnabled(feature, enabled: v),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _title(AppLocalizations l10n, AppFeature feature) =>
      switch (feature) {
        AppFeature.ads => l10n.adminFeatureAds,
        AppFeature.reports => l10n.adminFeatureReports,
        AppFeature.costEstimator => l10n.adminFeatureCostEstimator,
      };

  static String _subtitle(AppLocalizations l10n, AppFeature feature) =>
      switch (feature) {
        AppFeature.ads => l10n.adminFeatureAdsHint,
        AppFeature.reports => l10n.adminFeatureReportsHint,
        AppFeature.costEstimator => l10n.adminFeatureCostEstimatorHint,
      };
}
