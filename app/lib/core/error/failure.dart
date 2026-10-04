import 'package:equatable/equatable.dart';

/// Domain-level error. Data sources throw; repositories map to a [Failure].
/// Features may define their own subclasses (e.g. an invalid OTP).
abstract class Failure extends Equatable {
  const Failure();

  @override
  List<Object?> get props => [];
}

/// No connection, DNS failure or timeout.
final class NetworkFailure extends Failure {
  const NetworkFailure();
}

/// The session is missing or expired.
final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure();
}

/// The server rejected the request or failed. [message] is the server's
/// user-facing message when it sends one (already localised by the API).
final class ServerFailure extends Failure {
  const ServerFailure({this.statusCode, this.message});

  final int? statusCode;
  final String? message;

  @override
  List<Object?> get props => [statusCode, message];
}

/// A free-tier cap the user can lift by watching rewarded ads or going Pro.
enum LimitedFeature { watchlist, alertRules, proReport }

/// The API refused because a free-tier limit is used up (403 with an
/// `Entitlement.*LimitReached` or `Report.ProRequired` code). Screens answer
/// it with the unlock sheet rather than an error message.
final class LimitReachedFailure extends Failure {
  const LimitReachedFailure(this.feature, {this.message});

  final LimitedFeature feature;

  /// The server's message, used where no sheet can be shown.
  final String? message;

  @override
  List<Object?> get props => [feature, message];
}

/// Anything not otherwise classified (parsing errors, bugs).
final class UnexpectedFailure extends Failure {
  const UnexpectedFailure();
}
