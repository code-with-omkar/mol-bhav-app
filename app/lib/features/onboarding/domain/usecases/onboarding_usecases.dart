import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/onboarding_entities.dart';
import '../repositories/onboarding_repository.dart';

@injectable
class GetProfileOptions {
  const GetProfileOptions(this._repository);

  final OnboardingRepository _repository;

  Future<Result<ProfileOptions>> call() => _repository.getProfileOptions();
}

@injectable
class GetDistricts {
  const GetDistricts(this._repository);

  final OnboardingRepository _repository;

  Future<Result<List<Region>>> call(String stateCode) =>
      _repository.getDistricts(stateCode);
}

@injectable
class SaveBusinessProfile {
  const SaveBusinessProfile(this._repository);

  final OnboardingRepository _repository;

  Future<Result<void>> call(BusinessProfile profile) =>
      _repository.saveBusinessProfile(profile);
}

@injectable
class GetCategories {
  const GetCategories(this._repository);

  final OnboardingRepository _repository;

  Future<Result<List<ProcurementCategory>>> call() =>
      _repository.getCategories();
}

@injectable
class SaveCategories {
  const SaveCategories(this._repository);

  final OnboardingRepository _repository;

  Future<Result<void>> call(Set<String> categoryIds) =>
      _repository.saveCategories(categoryIds);
}
