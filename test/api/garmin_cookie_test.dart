import 'package:fjelia/api/garmin_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('splits merged Set-Cookie headers from Dart and Apple clients', () {
    const a = 'SESSION=abc; Path=/; HttpOnly';
    const b = 'GARMIN-SSO=1; Path=/; Secure';
    const c =
        'CASTGC=TGC-1; Expires=Wed, 21 Oct 2026 07:28:00 GMT; Path=/; Secure';
    // Dart's client joins with ",", URLSession with ", ".
    for (final sep in [',', ', ']) {
      expect(splitSetCookieHeader([a, b, c].join(sep)), [a, b, c]);
    }
    expect(splitSetCookieHeader(a), [a]);
  });
}
