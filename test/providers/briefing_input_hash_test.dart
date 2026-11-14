import 'package:flutter_test/flutter_test.dart';
import 'package:fjelia/providers/ai_coach_provider.dart';

void main() {
  String toon({
    String time = '07:12',
    int steps = 812,
    int bbLow = 41,
    int tempNow = 6,
    String sleep = '7.2',
    String workout = 'Warm10m:Z1+Main40m:Z2',
  }) => [
    '[Context:V4][Today:2026-11-14,Weekday:Sat,TimeNow:$time]'
        '[Range:60d,Grip:90d]',
    '[Sleep:Latest:2026-11-14,Dur:${sleep}h,Deep:1.1h]',
    '[Daily:Latest:2026-11-14,Steps:$steps,ActiveCal:120,TotalCal:1900,'
        'Floors:2,IntensityMin:5,BBHigh:88,BBLow:$bbLow,BBCharged:50,'
        'BBDrained:12,VO2maxRun:54,FitnessAge:38]',
    '[Weather:Today:TempNow:$tempNow°C,TempMin:2°C,TempMax:9°C,'
        'AvgHumidity:80%,WindKmh:12,WindChill:3°C,RainChance:40%,'
        'RainMm:1,WetBulb:4°C]',
    '- [Run,Planned:45min,Steps:$workout]',
  ].join('\n');

  test('intraday values do not make the briefing new', () {
    expect(
      briefingInputHash(
        toon(time: '15:40', steps: 9120, bbLow: 22, tempNow: 9),
      ),
      briefingInputHash(toon()),
    );
  });

  test('substantive changes still do', () {
    expect(
      briefingInputHash(toon(sleep: '5.9')),
      isNot(briefingInputHash(toon())),
    );
    // `Steps:` of a planned workout is its structure, not a step count.
    expect(
      briefingInputHash(toon(workout: 'Warm10m:Z1+Main20m:Z4')),
      isNot(briefingInputHash(toon())),
    );
  });
}
