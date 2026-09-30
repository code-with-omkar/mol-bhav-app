import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../account/presentation/profile_cubit.dart';

extension SubscriptionGuardX on BuildContext {
  /// Watches the shared profile, so a gate rebuilds when a payment refreshes
  /// it. Cosmetic only: the API enforces Pro on its own.
  bool get isProSubscriber =>
      select<ProfileCubit, bool>((c) => c.state.data?.isPro ?? false);
}
