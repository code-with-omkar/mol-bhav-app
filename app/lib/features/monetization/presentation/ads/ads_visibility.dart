import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/ads/ads_config.dart';
import '../../../account/presentation/profile_cubit.dart';

extension AdsVisibilityX on BuildContext {
  /// Ads only for known free users on a supported platform: until the profile
  /// has loaded we can't tell a Pro user apart, so nothing is shown.
  bool get showsAds =>
      AdsConfig.isSupported &&
      select<ProfileCubit, bool>((c) => c.state.data?.isPro == false);
}
