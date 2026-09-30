import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/mb_dimens.dart';
import '../../../shared/widgets/mb_app_bar.dart';
import '../../../shared/widgets/mb_panels.dart';
import '../../../shared/widgets/mb_price.dart';
import '../../../shared/widgets/mb_state_views.dart';
import '../domain/notification_prefs.dart';
import 'notification_prefs_cubit.dart';

class NotificationPreferencesPage extends StatelessWidget {
  const NotificationPreferencesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<NotificationPrefsCubit, NotificationPrefsState>(
      builder: (context, state) => Scaffold(
        appBar: MbAppBar(title: l10n.notificationSettingsTitle),
        body: switch (state) {
          NotificationPrefsLoading() => const MbLoadingView(),
          NotificationPrefsError(:final failure) => MbErrorView(
            failure: failure,
            onRetry: context.read<NotificationPrefsCubit>().load,
          ),
          NotificationPrefsLoaded(:final prefs) => _Content(prefs: prefs),
        },
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.prefs});

  final NotificationPrefs prefs;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<NotificationPrefsCubit>();
    const gap = SizedBox(height: 14);

    return ListView(
      padding: MbSpacing.screenPadding,
      children: [
        MbGroup(
          children: [
            MbListItem(
              title: l10n.pushNotificationsLabel,
              trailing: MbToggle(
                value: prefs.pushEnabled,
                onChanged: (on) => cubit.update(
                  prefs.copyWith(
                    pushEnabled: on,
                    // Turn off sub-toggles when master is turned off.
                    alertPushEnabled: on ? prefs.alertPushEnabled : false,
                    priceUpdatePushEnabled: on
                        ? prefs.priceUpdatePushEnabled
                        : false,
                  ),
                ),
                semanticLabel: l10n.pushNotificationsLabel,
              ),
            ),
            MbListItem(
              title: l10n.alertPushLabel,
              trailing: MbToggle(
                value: prefs.pushEnabled && prefs.alertPushEnabled,
                onChanged: prefs.pushEnabled
                    ? (on) => cubit.update(prefs.copyWith(alertPushEnabled: on))
                    : null,
                semanticLabel: l10n.alertPushLabel,
              ),
            ),
            MbListItem(
              title: l10n.priceUpdatePushLabel,
              trailing: MbToggle(
                value: prefs.pushEnabled && prefs.priceUpdatePushEnabled,
                onChanged: prefs.pushEnabled
                    ? (on) => cubit.update(
                        prefs.copyWith(priceUpdatePushEnabled: on),
                      )
                    : null,
                semanticLabel: l10n.priceUpdatePushLabel,
              ),
            ),
          ],
        ),
        gap,
        MbGroup(
          children: [
            MbListItem(
              title: l10n.whatsappNotificationsLabel,
              trailing: MbToggle(
                value: prefs.whatsAppEnabled,
                onChanged: (on) => cubit.update(
                  prefs.copyWith(
                    whatsAppEnabled: on,
                    alertWhatsAppEnabled: on
                        ? prefs.alertWhatsAppEnabled
                        : false,
                  ),
                ),
                semanticLabel: l10n.whatsappNotificationsLabel,
              ),
            ),
            MbListItem(
              title: l10n.alertWhatsappLabel,
              trailing: MbToggle(
                value: prefs.whatsAppEnabled && prefs.alertWhatsAppEnabled,
                onChanged: prefs.whatsAppEnabled
                    ? (on) =>
                          cubit.update(prefs.copyWith(alertWhatsAppEnabled: on))
                    : null,
                semanticLabel: l10n.alertWhatsappLabel,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
