import '../../../../core/error/result.dart';
import '../entities/onboarding_entities.dart';

abstract interface class OnboardingRepository {
  Future<Result<ProfileOptions>> getProfileOptions();

  Future<Result<List<Region>>> getDistricts(String stateCode);

  Future<Result<void>> saveBusinessProfile(BusinessProfile profile);

  Future<Result<List<ProcurementCategory>>> getCategories();

  Future<Result<void>> saveCategories(Set<String> categoryIds);
}
