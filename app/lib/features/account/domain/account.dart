import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/result.dart';

class AccountProfile extends Equatable {
  const AccountProfile({
    required this.name,
    required this.businessTypeName,
    required this.districtName,
    required this.stateName,
    required this.categoryNames,
    required this.isPro,
    required this.proMonthlyPrice,
    required this.pushEnabled,
    required this.whatsappEnabled,
  });

  final String name;
  final String businessTypeName;
  final String districtName;
  final String stateName;
  final List<String> categoryNames;
  final bool isPro;
  final num? proMonthlyPrice;
  final bool pushEnabled;
  final bool whatsappEnabled;

  AccountProfile withNotifications({bool? push, bool? whatsapp}) =>
      AccountProfile(
        name: name,
        businessTypeName: businessTypeName,
        districtName: districtName,
        stateName: stateName,
        categoryNames: categoryNames,
        isPro: isPro,
        proMonthlyPrice: proMonthlyPrice,
        pushEnabled: push ?? pushEnabled,
        whatsappEnabled: whatsapp ?? whatsappEnabled,
      );

  @override
  List<Object?> get props => [
    name,
    businessTypeName,
    districtName,
    stateName,
    categoryNames,
    isPro,
    proMonthlyPrice,
    pushEnabled,
    whatsappEnabled,
  ];
}

enum BillingPeriod { month, year }

class SubscriptionPlan extends Equatable {
  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.period,
    required this.features,
    required this.isFeatured,
    required this.isCurrent,
  });

  final String id;
  final String name;
  final num price;
  final BillingPeriod? period;

  /// Entitlements are data-driven: the API sends the feature lines.
  final List<String> features;
  final bool isFeatured;
  final bool isCurrent;

  @override
  List<Object?> get props => [
    id,
    name,
    price,
    period,
    features,
    isFeatured,
    isCurrent,
  ];
}

abstract interface class AccountRepository {
  Future<Result<AccountProfile>> getProfile();

  Future<Result<void>> updateNotifications({
    required bool push,
    required bool whatsapp,
  });

  Future<Result<List<SubscriptionPlan>>> getPlans();

  /// Clears the stored session.
  Future<void> signOut();
}

@injectable
class GetAccountProfile {
  const GetAccountProfile(this._repository);

  final AccountRepository _repository;

  Future<Result<AccountProfile>> call() => _repository.getProfile();
}

@injectable
class UpdateNotifications {
  const UpdateNotifications(this._repository);

  final AccountRepository _repository;

  Future<Result<void>> call({required bool push, required bool whatsapp}) =>
      _repository.updateNotifications(push: push, whatsapp: whatsapp);
}

@injectable
class GetPlans {
  const GetPlans(this._repository);

  final AccountRepository _repository;

  Future<Result<List<SubscriptionPlan>>> call() => _repository.getPlans();
}

@injectable
class SignOut {
  const SignOut(this._repository);

  final AccountRepository _repository;

  Future<void> call() => _repository.signOut();
}
