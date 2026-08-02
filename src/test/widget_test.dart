// Basic sanity tests for the BDT currency formatter. Feature-level tests
// (balance calculation, month filtering, category delete guard, form
// validation) are added alongside their providers in later phases.

import 'package:flutter_test/flutter_test.dart';

import 'package:expense_tracker/core/format.dart';

void main() {
  group('fmtBDT', () {
    test('formats small amounts without grouping', () {
      expect(fmtBDT(0), '৳0');
      expect(fmtBDT(350), '৳350');
    });

    test('groups using the last-3-then-2s convention', () {
      expect(fmtBDT(65000), '৳65,000');
      expect(fmtBDT(1234567), '৳12,34,567');
    });

    test('rounds and preserves the sign', () {
      expect(fmtBDT(-2200), '-৳2,200');
      expect(fmtBDT(120.6), '৳121');
    });
  });
}
