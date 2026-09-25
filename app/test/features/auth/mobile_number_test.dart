import 'package:flutter_test/flutter_test.dart';
import 'package:mol_bhav/features/auth/domain/entities/mobile_number.dart';
import 'package:mol_bhav/features/auth/presentation/widgets/mobile_number_formatter.dart';

void main() {
  group('MobileNumber', () {
    test('parses grouped input', () {
      final number = MobileNumber.tryParse('98765 43210')!;
      expect(number.digits, '9876543210');
      expect(number.e164, '+919876543210');
      expect(number.display, '+91 98765 43210');
    });

    test('rejects short numbers and numbers not starting 6–9', () {
      expect(MobileNumber.tryParse('98765'), isNull);
      expect(MobileNumber.tryParse('58765 43210'), isNull);
      expect(MobileNumber.tryParse(''), isNull);
    });
  });

  group('MobileNumberFormatter', () {
    TextEditingValue format(String text) => const MobileNumberFormatter()
        .formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: text));

    test('groups digits 5 + 5 and caps at 10', () {
      expect(format('987654').text, '98765 4');
      expect(format('9876543210999').text, '98765 43210');
    });

    test('drops non-digits', () {
      expect(format('98-76a5').text, '98765');
    });
  });
}
