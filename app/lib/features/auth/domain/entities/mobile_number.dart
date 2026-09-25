import 'package:equatable/equatable.dart';

/// An Indian mobile number: 10 digits starting 6–9.
class MobileNumber extends Equatable {
  const MobileNumber._(this.digits);

  /// Parses user input, ignoring spaces and other separators. Returns `null`
  /// when the input is not a valid Indian mobile number.
  static MobileNumber? tryParse(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(digits)) return null;
    return MobileNumber._(digits);
  }

  static const countryCode = '+91';

  /// The 10 national digits.
  final String digits;

  /// `+919876543210`, as sent to the API.
  String get e164 => '$countryCode$digits';

  /// `+91 98765 43210`, as shown to the user.
  String get display =>
      '$countryCode ${digits.substring(0, 5)} ${digits.substring(5)}';

  @override
  List<Object?> get props => [digits];
}
