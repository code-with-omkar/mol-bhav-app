import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:injectable/injectable.dart';

import 'ad_personalisation.dart';

/// Every ad request goes through here, so the personalisation choice applies
/// to all formats alike.
@lazySingleton
class AdRequestFactory {
  AdRequestFactory(this._personalisation);

  final AdPersonalisationCubit _personalisation;

  AdRequest build() => AdRequest(nonPersonalizedAds: !_personalisation.state);
}
