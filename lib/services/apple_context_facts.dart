/// Plain-language versions of the TOON lines the on-device model has to use.
///
/// The compact `[Tag:key:value,...]` format suits large cloud models. The small
/// on-device model reads it badly: it repeats the lines or invents numbers. The
/// lines that matter most for a chat about a session become short sentences
/// with the same figures; every other line stays as it is.
String appleFactLine(String line) {
  final parsed = _Toon.parse(line);
  if (parsed == null) return line;
  final f = parsed.fields;
  String? part(String key, String Function(String v) text) =>
      f[key] == null ? null : text(f[key]!);
  String join(Iterable<String?> items, [String sep = ', ']) =>
      items.whereType<String>().join(sep);

  switch (parsed.tag) {
    case 'Session':
      final facts = join([
        f['Sport'],
        f['Type'],
        part('Phase', (v) => '$v phase'),
        part('Week', (v) => 'week $v'),
        part('Duration', (v) => v.replaceFirst('min', ' min')),
        part('TRIMP', (v) => 'TRIMP $v'),
        part('Zone', (v) => 'main zone $v'),
      ]);
      final structure = part(
        'Structure',
        (v) => ' Structure: ${v.replaceAll('>', ', ')}.',
      );
      final zones = part(
        'HRZonePct',
        (v) =>
            ' Time in heart-rate zones 1 to 5 (percent): ${v.replaceAll('/', ', ')}.',
      );
      final reason = part(
        'SkipReason',
        (v) => ' It was cancelled because of: $v. Do not suggest making it up.',
      );
      return 'Session (${f['Status'] ?? 'unknown status'}) ${f['Date'] ?? ''}: '
          '$facts.${structure ?? ''}${zones ?? ''}${reason ?? ''}';
    case 'Activity':
      if (parsed.lead.isEmpty) return line;
      final facts = join([
        f['Sport'],
        part('Min', (v) => '$v min'),
        part('Km', (v) => '$v km'),
        part('Pace', (v) => 'pace $v'),
        part('Kmh', (v) => '$v km/h'),
        part('AvgHR', (v) => 'average heart rate $v bpm'),
        part('MaxHR', (v) => 'max heart rate $v bpm'),
        part('Load', (v) => 'training load $v'),
        part('ElevM', (v) => 'elevation gain $v m'),
        part('AvgW', (v) => 'average power $v W'),
        part('TE', (v) => 'training effect $v (aerobic/anaerobic)'),
      ]);
      return 'Activity on ${parsed.lead}: $facts.';
    case 'TrainingMonitor':
      final facts = join([
        part('CTL', (v) => 'fitness (CTL) $v'),
        part('ATL', (v) => 'fatigue (ATL) $v'),
        part('TSB', (v) => 'form (TSB) $v'),
        part('CurWeekH', (v) => 'this week $v h'),
        part('PrevWeekH', (v) => 'last week $v h'),
      ]);
      return 'Training monitor, estimated by a model and not measured: $facts.';
    case 'TodayWorkout':
      if (f['Status'] != 'cancelled') return line;
      return 'Today\'s planned workout was cancelled (${f['Reason'] ?? 'no reason given'}). '
          'This is not a plain rest day; illness or injury means NO training today.';
    case 'RaceGoal':
      final target = f['Target'] == null || f['Target'] == 'none'
          ? 'no target time set'
          : 'target ${f['Target']}'
                '${f['PaceSecKm'] == null || f['PaceSecKm'] == 'na' ? '' : ' (${_pace(f['PaceSecKm']!)})'}';
      final ahead = int.tryParse(f['GoalAheadOfEstimate%'] ?? '');
      return 'Race goal: ${f['DistKm']} km ${f['Sport']?.replaceAll('_', ' ')} '
          'on ${f['Date']}, ${f['Terrain']} course'
          '${f['ElevM'] == null || f['ElevM'] == 'na' ? '' : ' with ${f['ElevM']} m of climbing'}; '
          '$target'
          '${f['Estimate'] == null || f['Estimate'] == 'na' ? '' : ', current estimate ${f['Estimate']}'}'
          '${ahead != null && ahead >= 5 ? '. The goal is $ahead% faster than the estimate: a stretch.' : '.'}';
    case 'Cancelled':
      return '${f['Sessions'] ?? 'Some'} planned sessions around today were cancelled '
          '(reasons: ${(f['Reasons'] ?? 'unknown').replaceAll('/', ', ')}). '
          'Illness or injury means rest, never a replacement workout.';
    case 'DataStatus':
      return _dataStatus(parsed);
    case 'Compare':
      String unit(String v, String u) =>
          v.replaceFirstMapped(RegExp(r'^(\S+ vs \S+)'), (m) => '${m[1]} $u');
      final facts = join([
        part('Min', (v) => 'duration ${unit(v, 'min')}'),
        part('Km', (v) => 'distance ${unit(v, 'km')}'),
        part('Load', (v) => 'training load $v'),
        part('AvgHR', (v) => 'average heart rate $v'),
      ]);
      return 'This ${parsed.lead} session against the average of ${f['N'] ?? '?'} '
          'other ${parsed.lead} sessions in the last 30 days (this vs average): $facts.';
    case 'HRV':
      if (!parsed.raw.startsWith('AroundActivity')) return line;
      if (parsed.raw.contains('Unavailable')) {
        return 'No HRV was recorded around this activity; its effect on HRV is unknown.';
      }
      String pretty(String v) => v
          .replaceAllMapped(
            RegExp(r'^(-?\+?\d+)ms\((.*)\)$'),
            (m) => '${m[1]} ms (${m[2]!.replaceAll(',', ', ')})',
          )
          .replaceAllMapped(RegExp(r'^(-?\+?\d+)ms$'), (m) => '${m[1]} ms');
      String? field(String key, String label) =>
          f[key] == null ? null : '$label ${pretty(f[key]!)}';
      final night = join([
        field('PreNight', 'night before'),
        field('PostNight', 'night after'),
        field('NightChange', 'change'),
      ]);
      final spots = join([
        field('SpotBefore', 'before'),
        field('SpotAfter', 'after'),
        field('SpotChange', 'change'),
      ]);
      return 'HRV around this activity:'
          '${night.isEmpty ? '' : ' overnight (watch) $night.'}'
          '${f['WeeklyAvg'] == null ? '' : ' Weekly average ${pretty(f['WeeklyAvg']!)}.'}'
          '${spots.isEmpty ? '' : ' Polar H10 spot RMSSD $spots.'}'
          ' Overnight and spot values are measured differently: compare trends, not single values.';
    case 'Similar30d':
      final facts = join([
        part('AvgMin', (v) => 'on average $v min'),
        part('AvgKm', (v) => '$v km'),
        part('AvgHR', (v) => 'heart rate $v bpm'),
        part('AvgLoad', (v) => 'load $v'),
        part('Pace', (v) => 'pace $v'),
        part('Kmh', (v) => '$v km/h'),
      ]);
      return 'Other ${parsed.lead} sessions in the last 30 days: '
          '${f['N'] ?? '?'}${facts.isEmpty ? '' : ', $facts'}.';
    case 'Last30d':
      if (parsed.raw.startsWith('Weeks(')) {
        return 'Last 4 weeks, oldest to newest (hours / load): '
            '${parsed.raw.substring(parsed.raw.indexOf(':') + 1).replaceAll(';', ', ')}.';
      }
      if (f['Sports'] != null) {
        return 'Last 30 days by sport: ${f['Sports']!.replaceAll(';', ', ')}.';
      }
      if (parsed.lead.contains('..')) {
        final facts = join([
          part('Sessions', (v) => '$v sessions'),
          part('ActiveDays', (v) => 'on $v days'),
          part('H', (v) => '$v h'),
          part('Km', (v) => '$v km'),
          part('Load', (v) => 'load $v'),
        ]);
        return 'Last 30 days (${parsed.lead.replaceFirst('..', ' to ')}): $facts.';
      }
      return line;
    default:
      return line;
  }
}

String _dataStatus(_Toon t) {
  final f = t.fields;
  if (f.containsKey('PreviousActivity')) {
    final prev = f['PreviousActivity']!;
    final text = prev == 'NoneInLoadedHistory'
        ? 'No earlier activity in the loaded history.'
        : 'Previous activity: $prev, ${f['DaysBefore'] ?? '?'} days before this one.';
    return '$text A missing record means unknown, not rest.';
  }
  final groups = <String>[];
  for (final name in ['Activities', 'HRV', 'Sleep', 'Daily']) {
    final g = t.groups[name];
    if (g == null) continue;
    if (g.isEmpty) {
      groups.add('$name none');
      continue;
    }
    groups.add('$name ${g['Last']} (${g['DaysAgo']} days ago)');
  }
  final gaps = f['Gaps'];
  return 'Newest records: ${groups.join(', ')}.'
      '${gaps == null ? '' : ' Gaps: ${gaps.replaceAll('/', ', ')}.'}'
      ' A missing record means unknown, not rest or no training.';
}

/// A parsed `[Tag:...]` line: loose parts, key:value fields and named groups
/// such as `Activities(Last:...,DaysAgo:...)`.
String _pace(String seconds) {
  final total = double.tryParse(seconds)?.round();
  return total == null
      ? seconds
      : '${total ~/ 60}:${(total % 60).toString().padLeft(2, '0')}/km';
}

class _Toon {
  _Toon(this.tag, this.raw, this.lead, this.fields, this.groups);

  final String tag, raw, lead;
  final Map<String, String> fields;
  final Map<String, Map<String, String>> groups;

  static _Toon? parse(String line) {
    final t = line.trim();
    if (!t.startsWith('[') || !t.endsWith(']')) return null;
    final body = t.substring(1, t.length - 1);
    final colon = body.indexOf(':');
    if (colon < 0) return null;
    final tag = body.substring(0, colon);
    final raw = body.substring(colon + 1);
    final fields = <String, String>{};
    final groups = <String, Map<String, String>>{};
    var lead = '';
    for (final part in _split(raw)) {
      final paren = part.indexOf('(');
      if (paren > 0 && part.endsWith(')') && !part.contains(':')) {
        // Name(...) without a key: a group of fields.
        groups[part.substring(0, paren)] = {
          for (final p in _split(part.substring(paren + 1, part.length - 1)))
            if (p.contains(':'))
              p.substring(0, p.indexOf(':')): p.substring(p.indexOf(':') + 1),
        };
        continue;
      }
      if (paren > 0 && part.endsWith(')') && part.indexOf(':') > paren) {
        groups[part.substring(0, paren)] = {
          for (final p in _split(part.substring(paren + 1, part.length - 1)))
            if (p.contains(':'))
              p.substring(0, p.indexOf(':')): p.substring(p.indexOf(':') + 1),
        };
        continue;
      }
      final i = part.indexOf(':');
      if (i < 0) {
        if (lead.isEmpty) lead = part;
      } else {
        fields[part.substring(0, i)] = part.substring(i + 1);
      }
    }
    return _Toon(tag, raw, lead, fields, groups);
  }

  /// Splits at commas outside parentheses.
  static List<String> _split(String s) {
    final parts = <String>[];
    var depth = 0, start = 0;
    for (var i = 0; i < s.length; i++) {
      final c = s[i];
      if (c == '(') depth++;
      if (c == ')') depth--;
      if (c == ',' && depth == 0) {
        parts.add(s.substring(start, i));
        start = i + 1;
      }
    }
    parts.add(s.substring(start));
    return parts;
  }
}
