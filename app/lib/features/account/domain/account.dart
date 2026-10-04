import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/result.dart';

class AccountProfile extends Equatable {
  const AccountProfile({
    required this.name,
    required this.phoneNumberMasked,
    required this.userId,
    required this.businessTypeName,
    required this.districtName,
    required this.stateName,
    this.stateId,
    this.districtId,
    this.preferredLanguage,
    required this.categoryCodes,
    required this.categoryNames,
    required this.isPro,
    required this.pushEnabled,
    required this.whatsappEnabled,
    this.isAdmin = false,
  });

  /// Empty until the user enters one.
  final String name;

  /// `******3210` — the API never sends the full number back.
  final String phoneNumberMasked;

  /// Used only to derive the invite ref code; never shown.
  final String userId;
  final String businessTypeName;
  final String districtName;
  final String stateName;

  /// Market-master ids of the saved state/district, when they match one.
  final String? stateId;
  final String? districtId;

  /// Language code for alerts, WhatsApp and reports.
  final String? preferredLanguage;
  final List<String> categoryCodes;
  final List<String> categoryNames;
  final bool isPro;
  final bool pushEnabled;
  final bool whatsappEnabled;

  /// Shows the Admin entry on More. A UI hint only: the API enforces the Admin
  /// role on every admin endpoint, and the role is granted only server-side.
  final bool isAdmin;

  AccountProfile withNotifications({bool? push, bool? whatsapp}) =>
      AccountProfile(
        name: name,
        phoneNumberMasked: phoneNumberMasked,
        userId: userId,
        businessTypeName: businessTypeName,
        districtName: districtName,
        stateName: stateName,
        stateId: stateId,
        districtId: districtId,
        preferredLanguage: preferredLanguage,
        categoryCodes: categoryCodes,
        categoryNames: categoryNames,
        isPro: isPro,
        pushEnabled: push ?? pushEnabled,
        whatsappEnabled: whatsapp ?? whatsappEnabled,
        isAdmin: isAdmin,
      );

  @override
  List<Object?> get props => [
    name,
    phoneNumberMasked,
    userId,
    businessTypeName,
    districtName,
    stateName,
    stateId,
    districtId,
    preferredLanguage,
    categoryCodes,
    categoryNames,
    isPro,
    pushEnabled,
    whatsappEnabled,
    isAdmin,
  ];
}

abstract interface class AccountRepository {
  /// Cached profile first, then the live one (see `watchCachedApiCall`).
  Stream<Result<AccountProfile>> watchProfile();

  /// Drops cached copies of the profile and of screens built from it.
  Future<void> invalidateProfile();

  Future<Result<void>> updateNotifications({
    required bool push,
    required bool whatsapp,
  });

  /// Clears the stored session.
  Future<void> signOut();
}

@injectable
class WatchAccountProfile {
  const WatchAccountProfile(this._repository);

  final AccountRepository _repository;

  Stream<Result<AccountProfile>> call() => _repository.watchProfile();
}

@injectable
class InvalidateAccountProfile {
  const InvalidateAccountProfile(this._repository);

  final AccountRepository _repository;

  Future<void> call() => _repository.invalidateProfile();
}

@injectable
class UpdateNotifications {
  const UpdateNotifications(this._repository);

  final AccountRepository _repository;

  Future<Result<void>> call({required bool push, required bool whatsapp}) =>
      _repository.updateNotifications(push: push, whatsapp: whatsapp);
}

@injectable
class SignOut {
  const SignOut(this._repository);

  final AccountRepository _repository;

  Future<void> call() => _repository.signOut();
}
