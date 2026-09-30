import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/mb_dimens.dart';
import '../../../core/utils/statuses.dart';
import '../../../shared/widgets/mb_app_bar.dart';
import '../../../shared/widgets/mb_button.dart';
import '../../../shared/widgets/mb_icon.dart';
import '../../../shared/widgets/mb_panels.dart';
import '../../../shared/widgets/mb_price.dart';
import '../../../shared/widgets/mb_state_views.dart';
import '../../account/presentation/profile_cubit.dart';
import '../domain/support.dart';
import 'support_cubits.dart';
import 'support_links.dart';

/// FAQ, the ways to reach a person, and the two ticket entry points.
class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: MbAppBar(title: l10n.helpSupport),
      body: BlocBuilder<HelpSupportCubit, HelpSupportState>(
        builder: (context, state) {
          final cubit = context.read<HelpSupportCubit>();
          final faq = state.faq.data;
          final contact = state.contact.data;
          if (faq == null && contact == null) {
            return state.faq.status == LoadStatus.failure
                ? MbErrorView(failure: state.faq.failure!, onRetry: cubit.load)
                : const MbLoadingView();
          }
          return RefreshIndicator(
            onRefresh: cubit.load,
            child: ListView(
              padding: MbSpacing.screenPadding,
              children: [
                if (contact != null) ...[
                  MbSectionHeader(title: l10n.contactUs),
                  const SizedBox(height: MbSpacing.s3),
                  _ContactTiles(contact: contact),
                  const SizedBox(height: MbSpacing.s6),
                ],
                MbSectionHeader(title: l10n.faqTitle),
                const SizedBox(height: MbSpacing.s3),
                if (faq == null || faq.isEmpty)
                  Text(
                    l10n.faqEmpty,
                    style: context.mbText.body.copyWith(
                      color: context.mbColors.inkMuted,
                    ),
                  )
                else
                  MbGroup(
                    children: [
                      for (final (i, entry) in faq.indexed)
                        _FaqRow(
                          entry: entry,
                          expanded: state.expanded == i,
                          onTap: () => cubit.toggle(i),
                        ),
                    ],
                  ),
                const SizedBox(height: MbSpacing.s6),
                MbButton(
                  label: l10n.raiseTicket,
                  icon: MbIcons.edit,
                  block: true,
                  onPressed: () => context.push(AppRoutes.raiseTicket),
                ),
                const SizedBox(height: MbSpacing.s3),
                MbButton(
                  label: l10n.myTickets,
                  variant: MbButtonVariant.secondary,
                  block: true,
                  onPressed: () => context.push(AppRoutes.supportTickets),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ContactTiles extends StatelessWidget {
  const _ContactTiles({required this.contact});

  final SupportContact contact;

  /// Every channel is opened by the platform, so a device with no handler has
  /// to be told about rather than silently ignored.
  Future<void> _open(
    BuildContext context,
    Future<bool> Function() action,
  ) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    if (!await action()) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.cannotOpenLink)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final profile = context.select<ProfileCubit, String?>(
      (c) => c.state.data?.phoneNumberMasked,
    );

    return MbGroup(
      children: [
        MbListItem(
          icon: MbIcons.message,
          iconTone: MbTone.green,
          title: l10n.contactWhatsApp,
          subtitle: '+${contact.whatsAppNumber}',
          onTap: () => _open(
            context,
            () => SupportLinks.whatsApp(contact, l10n.supportWhatsAppPrefill),
          ),
        ),
        MbListItem(
          icon: MbIcons.phone,
          title: l10n.contactCall,
          subtitle: contact.phone,
          onTap: () => _open(context, () => SupportLinks.call(contact)),
        ),
        MbListItem(
          icon: MbIcons.email,
          title: l10n.contactEmail,
          subtitle: contact.email,
          onTap: () => _open(
            context,
            () => SupportLinks.email(
              contact,
              subject: l10n.supportEmailSubject,
              bodyIntro: l10n.supportEmailIntro,
              versionLabel: l10n.appVersionLabel,
              accountLabel: l10n.accountLabel,
              phoneMasked: profile,
            ),
          ),
        ),
      ],
    );
  }
}

class _FaqRow extends StatelessWidget {
  const _FaqRow({
    required this.entry,
    required this.expanded,
    required this.onTap,
  });

  final FaqEntry entry;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final t = context.mbText;

    return Semantics(
      button: true,
      expanded: expanded,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: MbSpacing.s4,
            vertical: MbSpacing.s3,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.question,
                      style: t.rowName.copyWith(color: c.ink),
                    ),
                  ),
                  const SizedBox(width: MbSpacing.s3),
                  MbIcon(
                    expanded ? MbIcons.close : MbIcons.chevronDown,
                    size: 18,
                    color: c.inkMuted,
                  ),
                ],
              ),
              if (expanded) ...[
                const SizedBox(height: MbSpacing.s2),
                Text(entry.answer, style: t.body.copyWith(color: c.inkMuted)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
