import 'package:flutter/widgets.dart';

import '../../../core/l10n/l10n.dart';
import '../../../shared/widgets/mb_price.dart';
import '../domain/support.dart';

/// Localised labels and badge tones for a ticket's category and status, shared
/// by the raise, list and thread screens.
String ticketCategoryLabel(BuildContext context, TicketCategory? category) {
  final l10n = context.l10n;
  return switch (category) {
    TicketCategory.account => l10n.ticketCategoryAccount,
    TicketCategory.payment => l10n.ticketCategoryPayment,
    TicketCategory.data => l10n.ticketCategoryData,
    TicketCategory.other || null => l10n.ticketCategoryOther,
  };
}

String ticketStatusLabel(BuildContext context, TicketStatus status) {
  final l10n = context.l10n;
  return switch (status) {
    TicketStatus.open => l10n.ticketStatusOpen,
    TicketStatus.inProgress => l10n.ticketStatusInProgress,
    TicketStatus.resolved => l10n.ticketStatusResolved,
    TicketStatus.closed => l10n.ticketStatusClosed,
  };
}

/// Resolved reads as done, in-progress as active, and open/closed stay plain —
/// tone never carries the meaning on its own, the label always does.
MbBadgeTone ticketStatusTone(TicketStatus status) => switch (status) {
  TicketStatus.open => MbBadgeTone.neutral,
  TicketStatus.inProgress => MbBadgeTone.opportunity,
  TicketStatus.resolved => MbBadgeTone.best,
  TicketStatus.closed => MbBadgeTone.neutral,
};
