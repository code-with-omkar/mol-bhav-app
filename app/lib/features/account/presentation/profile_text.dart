import 'package:flutter/widgets.dart';

import '../../../core/l10n/l10n.dart';
import '../domain/account.dart';

/// `Caterer · Pune, Maharashtra`, leaving out whatever isn't set;
/// `null` when nothing is.
String? profileSubtitle(BuildContext context, AccountProfile profile) {
  final district = profile.districtName, state = profile.stateName;
  final place = switch ((district.isEmpty, state.isEmpty)) {
    (false, false) => context.l10n.placeLine(district, state),
    (false, true) => district,
    (true, false) => state,
    (true, true) => '',
  };
  final parts = [profile.businessTypeName, place].where((p) => p.isNotEmpty);
  return parts.isEmpty ? null : parts.join(' · ');
}
