import 'package:fjelia/services/renpho_ble_scale_service.dart';
import 'package:flutter_test/flutter_test.dart';

List<int> withSum(List<int> f) => [
  ...f,
  f.fold<int>(0, (a, b) => a + b) & 0xff,
];

void main() {
  final service = RenphoBleScaleService();
  const profile = RenphoUserProfile(heightCm: 180, age: 40, isMale: true);

  group('QN protocol', () {
    test('classic stable frame with impedance yields body composition', () {
      // 0x10, len 11, proto, weight 75.00 kg, stable, r1 = 500.
      final frame = withSum([
        0x10,
        0x0B,
        0xFF,
        0x1D,
        0x4C,
        0x01,
        0x01,
        0xF4,
        0x00,
        0x00,
      ]);
      final m = service.debugParseFrames([frame], profile: profile)!;
      expect(m.weightKg, closeTo(75.0, 1e-9));
      expect(m.raw['protocol'], 'renpho_qn');
      expect(m.bmi, closeTo(75 / (1.8 * 1.8), 1e-6));
      expect(m.bodyFatPct, isNotNull);
      expect(m.bodyFatPct, inInclusiveRange(1, 60));
      expect(m.bodyWaterPct, inInclusiveRange(20, 80));
      expect(m.boneMassKg, inInclusiveRange(0.5, 8));
      expect(m.bmrKcal, closeTo(m.fatFreeMassKg! * 21.6 + 370, 1e-6));
    });

    test('unstable frame does not produce a measurement', () {
      final frame = withSum([
        0x10,
        0x0B,
        0xFF,
        0x1D,
        0x4C,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
      ]);
      expect(service.debugParseFrames([frame]), isNull);
    });

    test('frame with wrong length byte is ignored', () {
      final frame = withSum([0x10, 0x09, 0xFF, 0x1D, 0x4C, 0x01, 0, 0, 0, 0]);
      expect(service.debugParseFrames([frame]), isNull);
    });

    test(
      'extended frame without body data keeps measuring (real scale log)',
      () {
        // Captured from a real Renpho-Scale: status 1 = weight locked, the
        // impedance bytes are still zero. Must not finish yet.
        final frame = [
          0x10,
          0x0e,
          0xff,
          0xfe,
          0x01,
          0x22,
          0x97,
          0,
          0,
          0,
          0,
          0,
          0,
          0xd5,
        ];
        final m = service.debugParseFrames([frame], profile: profile)!;
        expect(m.weightKg, closeTo(88.55, 1e-9));
        expect(m.bodyFatPct, isNull);
        expect(service.debugCompletes([frame], profile: profile), isFalse);
      },
    );

    test('the final extended frame (status 2) finishes with body values', () {
      final locked = [
        0x10,
        0x0e,
        0xff,
        0xfe,
        0x01,
        0x22,
        0x97,
        0,
        0,
        0,
        0,
        0,
        0,
        0xd5,
      ];
      final done = withSum([
        0x10,
        0x0e,
        0xff,
        0xfe,
        0x02,
        0x22,
        0x97,
        0x01,
        0xf4,
        0,
        0,
        0x00,
        0xa6,
      ]);
      expect(done.length, 14);
      expect(service.debugCompletes([locked, done], profile: profile), isTrue);
    });

    test(
      'extended frame: calculated fat wins, the scale figure is kept aside',
      () {
        // 0x10, len 14, proto, ?, status 2, weight 80.00, r1 500, ?, ?, fat 21.5
        final frame = withSum([
          0x10,
          0x0E,
          0xFF,
          0x00,
          0x02,
          0x1F,
          0x40,
          0x01,
          0xF4,
          0x00,
          0x00,
          0x00,
          0xD7,
        ]);
        final m = service.debugParseFrames([frame], profile: profile)!;
        expect(m.weightKg, closeTo(80.0, 1e-9));
        expect(m.raw['protocol'], 'renpho_qn_ext');
        expect(m.raw['scaleReportedFatPct'], closeTo(21.5, 1e-9));
        expect(m.bodyFatPct, isNot(closeTo(21.5, 1e-6)));
        expect(m.bodyFatPct, inInclusiveRange(5, 40));
      },
    );

    test('extended frame without a profile falls back to the scale fat', () {
      final frame = withSum([
        0x10,
        0x0E,
        0xFF,
        0x00,
        0x02,
        0x1F,
        0x40,
        0x01,
        0xF4,
        0x00,
        0x00,
        0x00,
        0xD7,
      ]);
      final m = service.debugParseFrames([frame])!;
      expect(m.bodyFatPct, closeTo(21.5, 1e-9));
    });

    test(
      'real measurement (192 cm, 44 y, male, r1 507) gives a plausible fat',
      () {
        const me = RenphoUserProfile(
          heightCm: 192,
          age: 44,
          isMale: true,
          hoursPerWeek: 25,
          waistCm: 88,
        );
        final frame = [
          0x10,
          0x0e,
          0xff,
          0xfe,
          0x02,
          0x22,
          0xe2,
          0x01,
          0xfb,
          0x01,
          0xf9,
          0x01,
          0x18,
          0x30,
        ];
        final m = service.debugParseFrames([frame], profile: me)!;
        expect(m.weightKg, closeTo(89.3, 1e-9));
        expect(m.raw['scaleReportedFatPct'], closeTo(28.0, 1e-9));
        expect(m.bodyFatPct, inInclusiveRange(15, 19));
        expect(m.visceralFat, closeTo(4, 0.5));
      },
    );
  });

  group('R-MSB protocol', () {
    test('measurement frame decodes scale-computed values', () {
      final payload = <int>[
        0x55, 0xAA, 0x35, 0x00, 0x11, 0x07, 0x11, 0x00, 0x01, // header
        0x00, 0x00, 0x1D, 0x4C, // weight 75.00
        0x01, 0xF4, // resistance
        0x00, 0xC8, // fat 20.0
        0x00, 0xE7, // bmi 23.1
        0x02, 0x26, // muscle 55.0
        0x00, 0x50, // visceral 8.0
      ];
      final m = service.debugParseFrames([withSum(payload)], rmsb: true)!;
      expect(m.weightKg, closeTo(75.0, 1e-9));
      expect(m.bodyFatPct, closeTo(20.0, 1e-9));
      expect(m.bmi, closeTo(23.1, 1e-9));
      expect(m.muscleMassKg, closeTo(55.0, 1e-9));
      expect(m.visceralFat, closeTo(8.0, 1e-9));
      expect(m.raw['protocol'], 'renpho_rmsb');
    });

    test('bad checksum is rejected', () {
      final f = withSum([
        0x55,
        0xAA,
        0x35,
        0,
        0x11,
        7,
        0x11,
        0,
        1,
        0,
        0,
        0x1D,
        0x4C,
        1,
        0xF4,
        0,
        0xC8,
        0,
        0xE7,
        2,
        0x26,
        0,
        0x50,
      ]);
      f[f.length - 1] ^= 0xFF;
      expect(service.debugParseFrames([f], rmsb: true), isNull);
    });
  });
}
