import 'package:flutter/services.dart';

/// Keeps up to 10 digits and groups them as `98765 43210`.
class MobileNumberFormatter extends TextInputFormatter {
  const MobileNumberFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 10) digits = digits.substring(0, 10);
    final text = digits.length > 5
        ? '${digits.substring(0, 5)} ${digits.substring(5)}'
        : digits;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
