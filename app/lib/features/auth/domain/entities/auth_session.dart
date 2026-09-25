import 'package:equatable/equatable.dart';

/// A signed-in user. Tokens stay in the data layer.
class AuthSession extends Equatable {
  const AuthSession({required this.isOnboarded});

  /// Whether the business profile and categories are already set up.
  final bool isOnboarded;

  @override
  List<Object?> get props => [isOnboarded];
}
