import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/ads/ad_personalisation.dart';
import '../../../core/di/injection.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/locale/locale_cubit.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/share/deep_link_config.dart';
import '../../../core/theme/mb_dimens.dart';
import '../../../core/utils/statuses.dart';
import '../../../shared/widgets/mb_app_bar.dart';
import '../../../shared/widgets/mb_icons.dart';
import '../../../shared/widgets/mb_panels.dart';
import '../../../shared/widgets/mb_price.dart';
import '../../../shared/widgets/mb_state_views.dart';
import '../domain/account.dart';
import 'account_cubits.dart';
import '../../billing/presentation/widgets/subscription_badge.dart';
import 'google_link_tile.dart';
import 'profile_text.dart';

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
              onRetry: cubit.retry,
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
    const gap = SizedBox(height: 14);

    return ListView(
      padding: MbSpacing.screenPadding,
      children: [
        MbGroup(
          children: [
            MbListItem(
              leading: MbAvatar(name: profile.name),
              title: profile.name.isEmpty ? l10n.addYourName : profile.name,
              subtitle: profileSubtitle(context, profile),
              // The edit flow refreshes the shared profile when it saves.
              onTap: () => context.push<bool>(AppRoutes.editProfile),
            ),
          ],
        ),
        gap,
        MbGroup(
          children: [
            MbListItem(
              icon: MbIcons.pro,
              iconTone: MbTone.navy,
              title: l10n.mySubscription,
              subtitle: l10n.proSubtitle,
              trailing: const SubscriptionBadge(),
              onTap: () => context.push(AppRoutes.billingSubscription),
            ),
            MbListItem(
              icon: MbIcons.others,
              title: l10n.myCategories,
              subtitle: profile.categoryNames.isEmpty
                  ? null
                  : profile.categoryNames.join(', '),
              onTap: () => context.push<bool>(AppRoutes.editCategories),
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
              onTap: () => context.go(AppRoutes.costEstimator),
            ),
          ],
        ),
        // Link or unlink Google sign-in (hidden while the server has it off).
        GoogleLinkTile(profile: profile),
        // Admin role is granted only server-side; the API enforces it too.
        if (profile.isAdmin) ...[
          gap,
          MbGroup(
            children: [
              MbListItem(
                icon: MbIcons.settings,
                iconTone: MbTone.navy,
                title: l10n.adminSchedulesTitle,
                subtitle: l10n.adminSchedulesSubtitle,
                onTap: () => context.go(AppRoutes.adminSchedules),
              ),
            ],
          ),
        ],
        gap,
        MbGroup(
          children: [
            MbListItem(
              icon: MbIcons.alert,
              title: l10n.notificationSettingsAction,
              onTap: () => context.push(AppRoutes.notificationPreferences),
            ),
            // Consent for ads based on activity: off by default (DPDP), and
            // using the app never depends on it.
            BlocBuilder<AdPersonalisationCubit, bool>(
              bloc: getIt<AdPersonalisationCubit>(),
              builder: (context, personalised) => MbListItem(
                icon: MbIcons.shield,
                title: l10n.adsPersonalisedTitle,
                subtitle: l10n.adsPersonalisedSubtitle,
                showChevron: false,
                trailing: MbToggle(
                  value: personalised,
                  semanticLabel: l10n.adsPersonalisedTitle,
                  onChanged: getIt<AdPersonalisationCubit>().set,
                ),
              ),
            ),
          ],
        ),
        gap,
        MbGroup(
          children: [
            MbListItem(
              icon: MbIcons.share,
              title: l10n.inviteFriend,
              subtitle: l10n.inviteFriendSubtitle,
              onTap: () => SharePlus.instance.share(
                ShareParams(
                  text:
                      '${l10n.inviteMessage}\n\n'
                      '${DeepLinkConfig.inviteLink(userId: profile.userId)}',
                ),
              ),
            ),
            MbListItem(
              icon: MbIcons.help,
              title: l10n.helpSupport,
              onTap: () => context.go(AppRoutes.helpSupport),
            ),
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
