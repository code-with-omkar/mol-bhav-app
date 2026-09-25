import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/locale/locale_cubit.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/mb_dimens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/statuses.dart';
import '../../../shared/widgets/mb_app_bar.dart';
import '../../../shared/widgets/mb_icons.dart';
import '../../../shared/widgets/mb_panels.dart';
import '../../../shared/widgets/mb_price.dart';
import '../../../shared/widgets/mb_state_views.dart';
import '../domain/account.dart';
import 'account_cubits.dart';

/// Account hub: profile, plan, categories, language, notifications, help.
class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<MoreCubit, MoreState>(
      listener: (context, state) {
        if (state.signedOut) {
          context.go(AppRoutes.login);
        } else if (state.actionFailure != null) {
          showFailureSnackBar(context, state.actionFailure!);
        }
      },
      builder: (context, state) {
        final cubit = context.read<MoreCubit>();
        final profile = state.profile.data;
        return Scaffold(
          appBar: MbAppBar(title: l10n.moreTitle),
          body: switch (state.profile.status) {
            _ when profile != null => _Content(profile: profile),
            LoadStatus.failure => MbErrorView(
              failure: state.profile.failure!,
              onRetry: cubit.load,
            ),
            _ => const MbLoadingView(),
          },
        );
      },
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.profile});

  final AccountProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<MoreCubit>();
    final language = context.watch<LocaleCubit>().state;
    final proPrice = profile.proMonthlyPrice;
    const gap = SizedBox(height: 14);

    return ListView(
      padding: MbSpacing.screenPadding,
      children: [
        MbGroup(
          children: [
            MbListItem(
              leading: MbAvatar(name: profile.name),
              title: profile.name,
              subtitle:
                  '${profile.businessTypeName} · '
                  '${l10n.placeLine(profile.districtName, profile.stateName)}',
              onTap: () => context.push(AppRoutes.businessProfile),
            ),
          ],
        ),
        gap,
        MbGroup(
          children: [
            MbListItem(
              icon: MbIcons.pro,
              iconTone: MbTone.navy,
              title: l10n.molbhavPro,
              subtitle: l10n.proSubtitle,
              trailing: profile.isPro || proPrice == null
                  ? null
                  : MbBadge(
                      label: l10n.pricePerMonth(formatInr(proPrice)),
                      tone: MbBadgeTone.opportunity,
                    ),
              onTap: () => context.push(AppRoutes.subscription),
            ),
            MbListItem(
              icon: MbIcons.others,
              title: l10n.myCategories,
              subtitle: profile.categoryNames.isEmpty
                  ? null
                  : profile.categoryNames.join(', '),
              onTap: () => context.push(AppRoutes.selectCategory),
            ),
            // Changing language here has no screen in the design yet; the
            // picker is on Login.
            MbListItem(
              icon: MbIcons.language,
              title: l10n.languageLabel,
              value: language.nativeName,
            ),
            MbListItem(
              icon: MbIcons.report,
              title: l10n.reportsTitle,
              onTap: () => context.go(AppRoutes.reports),
            ),
            // Not in the design's More list: the design gives the cost
            // estimator no entry point, so it is linked here.
            MbListItem(
              icon: MbIcons.estimator,
              title: l10n.costEstimatorTitle,
              onTap: () => context.push(AppRoutes.costEstimator),
            ),
          ],
        ),
        gap,
        MbGroup(
          children: [
            MbListItem(
              icon: MbIcons.alert,
              title: l10n.pushNotifications,
              trailing: MbToggle(
                value: profile.pushEnabled,
                onChanged: cubit.setPush,
                semanticLabel: l10n.pushNotifications,
              ),
            ),
            MbListItem(
              icon: MbIcons.message,
              iconTone: MbTone.green,
              title: l10n.whatsappAlerts,
              trailing: MbToggle(
                value: profile.whatsappEnabled,
                onChanged: cubit.setWhatsapp,
                semanticLabel: l10n.whatsappAlerts,
              ),
            ),
          ],
        ),
        gap,
        MbGroup(
          children: [
            // Help & support has no screen in the design yet.
            MbListItem(icon: MbIcons.help, title: l10n.helpSupport),
            MbListItem(
              icon: MbIcons.logout,
              title: l10n.logOut,
              danger: true,
              showChevron: false,
              onTap: cubit.signOut,
            ),
          ],
        ),
      ],
    );
  }
}
