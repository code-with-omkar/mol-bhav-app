import 'package:flutter_test/flutter_test.dart';
import 'package:mol_bhav/core/utils/formatters.dart';

void main() {
  test('formatPaise shows rupees with Indian grouping', () {
    expect(formatPaise(49900), '₹499.00');
    expect(formatPaise(1234567800), '₹1,23,45,678.00');
    expect(formatPaise(0), '₹0.00');
  });
}
