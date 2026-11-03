import 'package:fjelia/models/waist_ratios.dart';
import 'package:fjelia/services/ai_context_toon_builder.dart';
import 'package:flutter_test/flutter_test.dart';

WaistPoint _p(DateTime at, double waist, [double? hip]) =>
    (at: at, waistCm: waist, hipCm: hip);

void main() {
  test('ratios need both values', () {
    expect(waistToHeight(88, 180), closeTo(.489, .001));
    expect(waistToHeight(88, null), isNull);
    expect(waistToHip(88, 100), closeTo(.88, 1e-9));
    expect(waistToHip(88, null), isNull);
  });

  test('cut-offs for WHtR, WHR and waist', () {
    expect(whtrRisk(.39), WaistRisk.low);
    expect(whtrRisk(.49), WaistRisk.healthy);
    expect(whtrRisk(.5), WaistRisk.increased);
    expect(whtrRisk(.6), WaistRisk.high);
    expect(whrRisk(.89, 'm'), WaistRisk.healthy);
    expect(whrRisk(.89, 'f'), WaistRisk.high);
    expect(waistRisk(93, 'm'), WaistRisk.healthy);
    expect(waistRisk(94, 'm'), WaistRisk.increased);
    expect(waistRisk(88, 'f'), WaistRisk.high);
  });

  test('change over a period and the newest hip', () {
    final history = [
      _p(DateTime(2025, 10, 1), 92, 101),
      _p(DateTime(2026, 8, 1), 90),
      _p(DateTime(2026, 10, 1), 89),
      _p(DateTime(2026, 11, 1), 88),
    ];
    expect(waistChange(history, const Duration(days: 30)), -1);
    expect(waistChange(history, const Duration(days: 90)), -2);
    expect(waistChange(history, const Duration(days: 365)), -4);
    expect(waistChange(history, const Duration(days: 800)), isNull);
    expect(latestHip(history), 101);
    expect(latestHip([_p(DateTime(2026), 88)]), isNull);
  });

  test('coach line: ratios and long-term change, never the height', () {
    final line = waistContextLine([
      _p(DateTime(2025, 11, 1), 92, 100),
      _p(DateTime(2026, 11, 1), 88),
    ], heightCm: 180)!;
    expect(line, contains('Latest:2026-11-01'));
    expect(line, contains('Cm:88,HipCm:100'));
    expect(line, contains('WHtR:0.49'));
    expect(line, contains('WHR:0.88'));
    expect(line, contains('Chg365d:-4cm'));
    expect(line, contains('First:2025-11-01:92cm'));
    expect(line, isNot(contains('180')));
  });

  test('coach line from the profile alone, or nothing', () {
    expect(
      waistContextLine(const [], profileWaistCm: 90),
      startsWith('[Waist:FromProfile,Date:na,Cm:90'),
    );
    expect(waistContextLine(const []), isNull);
  });
}
