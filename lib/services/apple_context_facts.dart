/// Plain-language versions of the TOON lines the on-device model has to use.
///
/// The compact `[Tag:key:value,...]` format suits large cloud models. The small
/// on-device model reads it badly: it repeats the lines or invents numbers. The
/// lines that matter most for a chat about a session become short sentences
/// with the same figures; every other line stays as it is.
String appleFactLine(String line) {
  if (line.startsWith('[Context:')) {
    // "[Context:V4][Today:2026-10-28,Weekday:Wed,TimeNow:20:58]..."
    final m = RegExp(
      r'Today:([\d-]+),Weekday:(\w+),TimeNow:([\d:]+)',
    ).firstMatch(line);
    return m == null
        ? line
        : 'Today is ${m[2]} ${m[1]}; the time now is ${m[3]}. '
              'This is the real current date: a record from another date is not today.';
  }
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
        part('TSB', (v) => 'current form (TSB) $v points; not a weekly change'),
        part('CurWeekH', (v) => 'this week $v h'),
        part('PrevWeekH', (v) => 'last week $v h'),
      ]);
      return 'Training monitor, estimated by a model and not measured: $facts.';
    case 'BP':
      return 'Blood pressure on ${f['Latest']}: ${f['Sys']}/${f['Dia']} mmHg. '
          'Blood pressure does not identify a training phase.';
    case 'TodayWorkout':
      if (f['Status'] == 'rest_day') {
        return 'No workout is scheduled for today. This does not erase training already completed today.';
      }
      if (f['Status'] == 'planned' || f['Status'] == 'options_available') {
        final plan = int.tryParse(f['PlanSessions'] ?? '') ?? 0;
        final garmin = int.tryParse(f['GarminScheduled'] ?? '') ?? 0;
        final count =
            int.tryParse(f['SessionCount'] ?? '') ?? (plan > 0 ? plan : garmin);
        return 'Today has $count scheduled training ${count == 1 ? 'session' : 'sessions'}. '
            'These are scheduled sessions, not alternatives. '
            'Fjelia plan sessions are primary; Garmin entries may be copies of them.';
      }
      if (f['Status'] != 'cancelled') return line;
      return 'Today\'s planned workout was cancelled (${f['Reason'] ?? 'no reason given'}). '
          'This is not a plain rest day; illness or injury means NO training today.';
    case 'RaceGoal':
      final target = f['Target'] == null || f['Target'] == 'none'
          ? 'no target time set'
          : 'target ${f['Target']}'
                '${f['PaceSecKm'] == null || f['PaceSecKm'] == 'na' ? '' : ' (${_pace(f['PaceSecKm']!)})'}';
      final ahead = int.tryParse(f['GoalAheadOfEstimate%'] ?? '');
      final priority = f['Priority'];
      return 'Race goal${priority == null || priority == 'A' ? '' : ' (priority $priority)'}: '
          '${f['DistKm']} km ${f['Sport']?.replaceAll('_', ' ')} '
          'on ${f['Date']}, ${f['Terrain']} course'
          '${f['ElevM'] == null || f['ElevM'] == 'na' ? '' : ' with ${f['ElevM']} m of climbing'}; '
          '$target'
          '${f['Estimate'] == null || f['Estimate'] == 'na' ? '' : ', current estimate ${f['Estimate']}'}'
          '${ahead != null && ahead >= 5 ? '. The goal is $ahead% faster than the estimate: a stretch.' : '.'}';
    case 'Season':
      String list(String? v) =>
          v == null || v == 'none' ? 'none' : v.replaceAll('|', '; ');
      return 'Season plan: outcome ${f['Outcome']}. Conflicts: ${list(f['Conflicts'])}. '
          'Trade-offs: ${list(f['Tradeoffs'])}.';
    case 'Cancelled':
      return '${f['Sessions'] ?? 'Some'} planned sessions around today were cancelled '
          '(reasons: ${(f['Reasons'] ?? 'unknown').replaceAll('/', ', ')}). '
          'Illness or injury means rest, never a replacement workout.';
    case 'DataStatus':
      return _dataStatus(parsed);
    case 'Analysis':
      return f['Text'] ?? line;
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
      if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(f['Latest'] ?? '')) {
        return 'Recovery measurements on ${f['Latest']}: ${join([part('Night', (v) => 'overnight watch HRV $v'), part('Weekly7d', (v) => 'watch HRV weekly average $v'), part('RHR', (v) => 'resting heart rate $v'), part('Stress', (v) => 'stress score $v (lower is better)'), part('Energy', (v) => 'energy score $v (higher is better)'), part('SpO2', (v) => 'SpO2 $v')])}.';
      }
      if (parsed.raw.startsWith('Pair')) return _hrvPairSentence(f);
      if (parsed.raw.startsWith('RecentPairs')) {
        return 'HRV around recent workouts (last ${f['Window'] ?? '7d'}): '
            '${f['WithReadings'] ?? '?'} of ${f['Workouts'] ?? '?'} workouts have readings, '
            '${f['Shown'] ?? '?'} listed. A workout that is not listed has no reading or was left out; it was not a rest day.';
      }
      if (parsed.raw.startsWith('Unassigned')) {
        return '${f['Count'] ?? 'Some'} HRV readings near this workout belong to no workout, so they are not a before and after pair.';
      }
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
      return 'HRV around this activity:'
          '${night.isEmpty ? '' : ' overnight (watch) $night.'}'
          '${f['WeeklyAvg'] == null ? '' : ' Weekly average ${pretty(f['WeeklyAvg']!)}.'}'
          ' Overnight watch values are measured differently from chest-strap spot RMSSD: never compare their values.';
    case 'Sleep':
      if (f['Latest'] == null) return line;
      final slept = double.tryParse((f['Dur'] ?? '').replaceFirst('h', ''));
      final need = double.tryParse((f['Need'] ?? '').replaceFirst('h', ''));
      final shortfall = slept == null || need == null
          ? 'Sleep shortfall is unknown.'
          : 'Shortfall relative to that need: ${(need > slept ? need - slept : 0).toStringAsFixed(1)} h.';
      return 'Sleep on ${f['Latest']}: slept ${f['Dur'] ?? 'unknown'} '
          '(duration; not missing sleep); need ${f['Need'] ?? 'unknown'}. '
          '$shortfall';
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

/// Keep the calendar together when fitting the local model's context. Detailed
/// goal lines can otherwise be dropped one by one, leaving just the primary.
String? appleRaceCalendarFacts(Iterable<String> lines) {
  final goals = <_Toon>[];
  for (final line in lines) {
    final parsed = _Toon.parse(line);
    if (parsed?.tag == 'RaceGoal') goals.add(parsed!);
  }
  if (goals.isEmpty) return null;
  final entries = goals
      .map((goal) {
        final f = goal.fields;
        final target = f['Target'];
        return '${f['Date']} | ${f['Priority'] ?? '?'} | '
            '${f['Sport']?.replaceAll('_', ' ')} ${f['DistKm']} km'
            '${target == null || target == 'none' ? '' : ' | target $target'}';
      })
      .join('\n');
  return 'Race calendar: ${goals.length} listed goals (date | priority | sport/distance | target). '
      'A is higher priority than B then C. The primary goal is not the only goal. '
      'Do not infer a taper or training phase from a race date.\n$entries';
}

/// The HRV pair as sentences. Same figures and the same limits as the cloud
/// line; nothing is added and nothing is calculated here.
String _hrvPairSentence(Map<String, String> f) {
  String reading(String? v) {
    if (v == null || v == 'none') return 'none recorded';
    final p = v.split('/');
    final delay = p.firstWhere((x) => x.startsWith('after'), orElse: () => '');
    final minutes = delay.isEmpty
        ? ''
        : ', ${delay.substring(5).replaceFirst('min', '')} minutes after the workout ended';
    return '${p[0].replaceFirst('ms', ' ms')} at ${p[1]} (${p[2]}, ${p[3]}$minutes)';
  }

  const limitText = {
    'ambiguousActivity':
        'workouts overlap, so the readings may not belong to this one',
    'interveningWorkout': 'another workout followed',
    'unknownActualEnd': 'the actual end of the workout is not known',
    'clockUncertain': 'the clock was uncertain',
    'postureMismatch': 'before and after were taken in different positions',
    'durationMismatch': 'before and after used different recording lengths',
    'metricMismatch': 'before and after are different HRV measures',
    'invalidValue': 'a value was not usable',
    'invalidSignal': 'a signal was too weak',
    'missingPre': 'no reading before the workout',
    'missingPost': 'no reading after the workout',
    'postOutsideTargetBand':
        'the post reading was outside the usual 25 to 40 minutes',
    'legacyQualityUnknown': 'an older reading with unrecorded quality',
  };
  final limits = f['Limits'] == null || f['Limits'] == 'none'
      ? ''
      : ' Limits: ${f['Limits']!.split('|').map((l) => limitText[l] ?? l).join('; ')}.';
  final change = f['Change'] == null || f['Change'] == 'none'
      ? ' No valid change is available, so none is given.'
      : () {
          final c = f['Change']!.split('/');
          final fell =
              c[0].trim().startsWith('-') || c[0].trim().startsWith('−');
          return ' Change ${c[0].replaceFirst('ms', ' ms')} (${c[1]}).'
              ' HRV ${fell ? 'fell, the less favourable direction' : 'rose, the favourable direction (better recovery, not strain)'}.';
        }();
  final history = f['History'] == null
      ? ''
      : f['History']!.contains('insufficientData')
      ? ' The athlete has too few comparable workouts for a personal range yet (${f['History']!.split('/').first.replaceFirst('n=', '')} counted).'
      : ' Similar earlier workouts: ${f['History']!.replaceAll('/', ', ')}.';
  final unknown = f['Unknown'] == null
      ? ''
      : ' Unknown: ${f['Unknown']!.replaceAll('|', ', ')}.';
  return 'HRV before and after this ${f['Sport'] ?? 'workout'}'
      '${f['Date'] == null ? '' : ' on ${f['Date']}'} '
      '(workout ${f['WorkoutStart']} to ${f['WorkoutEnd']}, end from ${f['EndBasis']}; chest-strap RMSSD, association ${f['Assoc']}): '
      'before ${reading(f['Pre'])}; after ${reading(f['Post'])}.$change'
      ' ${f['Comparable'] == 'yes' ? 'The two are directly comparable.' : 'The two are NOT directly comparable.'}'
      '$limits$history${f['Rpe'] == null ? '' : ' RPE ${f['Rpe']}.'}$unknown'
      ' This is a description, not a score; it does not show full recovery.';
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
