// Standalone login + connectivity test for the COROS Training Hub (web) API.
//
// Replicates exactly what `lib/services/coros_service.dart` `CorosService.login()`
// does, so it can be run in the Dart VM without the Flutter secure-storage /
// drift plugins. On a successful login it also hits the read endpoints the sync
// uses (dashboard, daily, activities) plus the *mobile* sleep endpoint, to show
// which parts of a sync actually work with the web token.
//
// Usage:
//   dart run tool/test_coros_login.dart <email> <password> [region]
//
// `region` is `eu` (default), `us`, or `cn`. Credentials are passed on the
// command line and are never stored or logged in full.

// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

String _base(String region) => switch (region) {
  'eu' => 'https://teameuapi.coros.com',
  'cn' => 'https://teamcnapi.coros.com',
  _ => 'https://teamapi.coros.com',
};

String _mobileBase(String region) => switch (region) {
  'eu' => 'https://apieu.coros.com',
  'cn' => 'https://apicn.coros.com',
  _ => 'https://api.coros.com',
};

String _md5(String s) => md5.convert(utf8.encode(s)).toString();

String _truncate(String s) {
  final oneLine = s.replaceAll(RegExp(r'\s+'), ' ').trim();
  return oneLine.length > 400 ? '${oneLine.substring(0, 400)}…' : oneLine;
}

Future<void> main(List<String> args) async {
  if (args.length < 2) {
    print('usage: dart run tool/test_coros_login.dart <email> <password> [region]');
    return;
  }
  final email = args[0];
  final password = args[1];
  final region = args.length > 2 ? args[2] : 'eu';

  print('=== COROS login test ===');
  print('email  : $email');
  print('region : $region');
  print('base   : ${_base(region)}');
  print('pwd md5: ${_md5(password)}');
  print('');

  final client = http.Client();
  try {
    // --- login ----------------------------------------------------------
    final login = await client
        .post(
          Uri.parse('${_base(region)}/account/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'account': email,
            'accountType': 2,
            'pwd': _md5(password),
          }),
        )
        .timeout(const Duration(seconds: 30));

    print('login HTTP ${login.statusCode}');
    print('login body: ${_truncate(login.body)}');

    final json = jsonDecode(login.body) as Map<String, dynamic>;
    final result = json['result'];
    print('result : $result ${json['message'] ?? ''}');

    if (result != '0000') {
      print('\nLOGIN FAILED (result=$result)');
      return;
    }

    final data = json['data'] as Map<String, dynamic>;
    final accessToken = data['accessToken'] as String;
    final userId = data['userId'].toString();
    final tokenPreview =
        '${accessToken.substring(0, accessToken.length.clamp(0, 12))}…(${accessToken.length} chars)';
    print('\nLOGIN OK');
    print('  userId  : $userId');
    print('  token   : $tokenPreview');
    print('  twoFactorRequired: ${data['twoFactorRequired']}');
    print('  mobileToken (needed for detailed sleep stages): ${data['mobileToken']}');
    print('  data keys: ${data.keys.toList()}');
    print('');

    // --- validate the token against the endpoints the sync uses ---------
    final headers = {
      'Content-Type': 'application/json',
      'accessToken': accessToken,
      'yfheader': jsonEncode({'userId': userId}),
    };
    final base = _base(region);

    String d(DateTime t) =>
        '${t.year}${t.month.toString().padLeft(2, '0')}${t.day.toString().padLeft(2, '0')}';
    final now = DateTime.now();
    final from = d(now.subtract(const Duration(days: 7)));
    final to = d(now);

    print('--- dashboard/query (carries sleepHrvData) ---');
    final dash = await client
        .get(Uri.parse('$base/dashboard/query'), headers: headers)
        .timeout(const Duration(seconds: 30));
    final dashJson = jsonDecode(dash.body) as Map<String, dynamic>;
    final shl =
        ((dashJson['data'] as Map?)?['summaryInfo'])?['sleepHrvData']
            ?['sleepHrvList'] as List?;
    print(
      '  HTTP ${dash.statusCode} result=${dashJson['result']} '
      'sleepHrvList=${shl?.length ?? 0}',
    );

    print('--- analyse/dayDetail/query ($from..$to) ---');
    final day = await client
        .get(
          Uri.parse('$base/analyse/dayDetail/query')
              .replace(queryParameters: {'startDay': from, 'endDay': to}),
          headers: headers,
        )
        .timeout(const Duration(seconds: 30));
    final dayJson = jsonDecode(day.body) as Map<String, dynamic>;
    final dayList = ((dayJson['data'] as Map?)?['dayList']) as List?;
    print(
      '  HTTP ${day.statusCode} result=${dayJson['result']} '
      'dayList=${dayList?.length ?? 0}',
    );

    print('--- activity/query (page 1, size 5) ---');
    final act = await client
        .get(
          Uri.parse('$base/activity/query').replace(
            queryParameters: {
              'size': '5',
              'pageNumber': '1',
              'orderKey': 'startTime',
              'orderType': '2',
              'modeList': '0',
            },
          ),
          headers: headers,
        )
        .timeout(const Duration(seconds: 30));
    final actJson = jsonDecode(act.body) as Map<String, dynamic>;
    final actData = (actJson['data'] as Map?) ?? const {};
    final rows = (actData['dataList'] as List?)?.cast<Map<String, dynamic>>();
    print(
      '  HTTP ${act.statusCode} result=${actJson['result']} '
      'count=${actData['count']} rows=${rows?.length ?? 0}',
    );
    for (final r in (rows ?? const <Map<String, dynamic>>[]).take(5)) {
      print(
        '    - ${r['name'] ?? '?'} sport=${r['sportName'] ?? r['sportType']} '
        'labelId=${r['labelId']}',
      );
    }

    print('--- [mobile] /coros/data/statistic/daily with the WEB token ---');
    final sleep = await client
        .post(
          Uri.parse('${_mobileBase(region)}/coros/data/statistic/daily'),
          headers: {'Content-Type': 'application/json', 'accesstoken': accessToken},
          body: jsonEncode({
            'allDeviceSleep': 1,
            'dataType': 5,
            'dataVersion': 0,
            'startTime': int.parse(from),
            'endTime': int.parse(to),
            'statisticType': 1,
          }),
        )
        .timeout(const Duration(seconds: 30));
    try {
      final sjson = jsonDecode(sleep.body) as Map<String, dynamic>;
      print(
        '  HTTP ${sleep.statusCode} result=${sjson['result']} '
        '${sjson['message'] ?? ''} (detailed sleep needs the mobile token)',
      );
    } catch (_) {
      print('  HTTP ${sleep.statusCode}  ${_truncate(sleep.body)}');
    }

    print('\n=== DONE ===');
  } catch (e, st) {
    print('\nEXCEPTION: $e');
    print(st.toString().split('\n').take(5).join('\n'));
  } finally {
    client.close();
  }
}
