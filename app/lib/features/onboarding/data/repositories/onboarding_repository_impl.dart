import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../../core/network/api_call.dart';
import '../../../../core/session/session_manager.dart';
import '../../domain/entities/onboarding_entities.dart';
import '../../domain/repositories/onboarding_repository.dart';
import '../datasources/onboarding_remote_data_source.dart';
import '../models/onboarding_models.dart';

@LazySingleton(as: OnboardingRepository)
class OnboardingRepositoryImpl implements OnboardingRepository {
  OnboardingRepositoryImpl(this._remote, this._session);

  final OnboardingRemoteDataSource _remote;
  final SessionManager _session;

  @override
  Future<Result<ProfileOptions>> getProfileOptions() {
    return runApiCall(() async {
      // Future.wait rethrows the first original error, so the Dio mapping in
      // runApiCall still applies (Record.wait would wrap it).
      final results = await Future.wait<List<Object>>([
        _remote.getBusinessTypes(),
        _remote.getStates(),
      ]);
      final types = results[0] as List<BusinessTypeModel>;
      final states = results[1] as List<RegionModel>;
      return ProfileOptions(
        businessTypes: [for (final t in types) t.toEntity()],
        states: [for (final s in states) s.toEntity()],
      );
    });
  }

  @override
  Future<Result<List<Region>>> getDistricts(String stateCode) {
    return runApiCall(() async {
      final districts = await _remote.getDistricts(stateCode);
      return [for (final d in districts) d.toEntity()];
    });
  }

  @override
  Future<Result<void>> saveBusinessProfile(BusinessProfile profile) {
    return runApiCall(
      () => _remote.saveBusinessProfile(BusinessProfileRequest(profile)),
    );
  }

  @override
  Future<Result<List<ProcurementCategory>>> getCategories() {
    return runApiCall(() async {
      final categories = await _remote.getCategories();
      return [for (final c in categories) c.toEntity()];
    });
  }

  @override
  Future<Result<void>> saveCategories(Set<String> categoryIds) {
    // Choosing categories is the last onboarding step.
    return runApiCall(() async {
      await _remote.saveCategories(categoryIds.toList());
      await _session.completeOnboarding();
    });
  }
}
