/// One of Pete Pfitzinger's training zones with pace and HR ranges.
class PfitzingerZone {
  const PfitzingerZone({
    required this.number,
    required this.name,
    required this.description,
    required this.pace,
    required this.hr,
  });

  final int number;
  final String name;
  final String description;
  final String pace;
  final String hr;
}

/// Zones derived from LT2 (threshold) heart rate and pace. LT2 sits at
/// roughly 89 % of max HR; pace bands are offsets from LT2 pace.
abstract class PfitzingerZones {
  static String _pace(int? sec) {
    if (sec == null || sec <= 0) return '—';
    return '${sec ~/ 60}:${(sec % 60).toString().padLeft(2, '0')}/km';
  }

  static List<PfitzingerZone> calculate({
    required int lt2Hr,
    int? lt2PaceSec,
    int? vo2PaceSec,
  }) {
    final maxHr = (lt2Hr / 0.89).round();
    int bpm(double pct) => (maxHr * pct).round();
    final lt2 = lt2PaceSec != null && lt2PaceSec > 0 ? lt2PaceSec : null;
    final recovery = lt2 != null ? lt2 + 68 : null;
    final gaFast = lt2 != null ? lt2 + 28 : null;
    final mpFast = lt2 != null ? lt2 + 12 : null;
    final ltSlow = lt2 != null ? lt2 + 6 : null;
    final ltFast = lt2 != null ? lt2 - 6 : null;
    final vo2 = vo2PaceSec != null && vo2PaceSec > 0 ? vo2PaceSec : ltFast;

    String range(int? slow, int? fast) =>
        slow == null ? '—' : '${_pace(slow)} – ${_pace(fast)}';

    return [
      PfitzingerZone(
        number: 1,
        name: 'Recovery',
        description:
            'Very easy. Full recovery. Never skip this zone between hard days.',
        pace: recovery == null ? '—' : '> ${_pace(recovery)}',
        hr: '< ${bpm(0.75)} bpm',
      ),
      PfitzingerZone(
        number: 2,
        name: 'General Aerobic',
        description: 'Aerobic base. Most of your weekly volume lives here.',
        pace: range(recovery, gaFast),
        hr: '${bpm(0.75)} – ${bpm(0.81)} bpm',
      ),
      PfitzingerZone(
        number: 3,
        name: 'Marathon Pace',
        description: 'Target marathon race pace. Comfortably hard.',
        pace: range(gaFast, mpFast),
        hr: '${bpm(0.81)} – ${bpm(0.87)} bpm',
      ),
      PfitzingerZone(
        number: 4,
        name: 'Lactate Threshold',
        description:
            'Tempo effort. Breathing hard, not sprinting. Key fitness driver.',
        pace: range(ltSlow, ltFast),
        hr: '${bpm(0.87)} – ${bpm(0.92)} bpm',
      ),
      PfitzingerZone(
        number: 5,
        name: 'VO2max',
        description:
            'Interval pace. 3–5 km race effort. Develops aerobic ceiling.',
        pace: vo2 == null ? '—' : '< ${_pace(ltFast)}',
        hr: '${bpm(0.92)} – ${bpm(0.96)} bpm',
      ),
      PfitzingerZone(
        number: 6,
        name: 'Speed',
        description: 'Neuromuscular. Short reps only. Max speed work.',
        pace: vo2 == null ? '—' : '< ${_pace(vo2)}',
        hr: '> ${bpm(0.96)} bpm',
      ),
    ];
  }

  /// What the LT2-vs-VO2max pace gap says about the athlete's limiter.
  static String gapInsight(int lt2PaceSec, int vo2PaceSec) {
    final gap = lt2PaceSec - vo2PaceSec;
    if (gap <= 0) return 'VO2max pace ≥ LT2 pace — check test results.';
    if (gap < 15) {
      return 'Small gap ($gap s/km) — VO2max-limited. Focus on interval work (Zone 5).';
    }
    if (gap < 30) {
      return 'Moderate gap ($gap s/km) — balanced. Mix tempo and intervals.';
    }
    return 'Large gap ($gap s/km) — LT-limited. Focus on tempo runs (Zone 4).';
  }
}
