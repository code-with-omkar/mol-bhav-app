import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../shared/widgets/mb_price.dart';
import 'subscription_guard.dart';

/// "Pro" or "Free", from the shared profile.
class SubscriptionBadge extends StatelessWidget {
  const SubscriptionBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return context.isProSubscriber
        ? MbBadge(label: l10n.proBadge, tone: MbBadgeTone.pro)
        : MbBadge(label: l10n.subscriptionFree, tone: MbBadgeTone.neutral);
  }
}
