import 'package:fjelia/services/replan_triggers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('zoneTimeJump', () {
    test('reports growth above the threshold', () {
      expect(zoneTimeJump(120, 100), closeTo(20, 1e-9));
      expect(zoneTimeJump(115, 100), isNull);
      expect(zoneTimeJump(80, 100), isNull);
    });

    test('nothing to compare against gives no trigger', () {
      expect(zoneTimeJump(100, 0), isNull);
      expect(zoneTimeJump(double.nan, 100), isNull);
      expect(zoneTimeJump(100, double.infinity), isNull);
    });
  });

  group('hrvSuppressed', () {
    test('needs two low nights, one is not a trend', () {
      expect(hrvSuppressed([50, 52], 60), isTrue);
      expect(hrvSuppressed([50, 58], 60), isFalse);
      expect(hrvSuppressed([50], 60), isFalse);
    });

    test('a missing night or baseline is not suppression', () {
      expect(hrvSuppressed([50, null], 60), isFalse);
      expect(hrvSuppressed([null, null], 60), isFalse);
      expect(hrvSuppressed([50, 52], null), isFalse);
      expect(hrvSuppressed([50, 52], 0), isFalse);
    });
  });
}
