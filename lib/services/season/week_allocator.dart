import 'dart:math' as math;

import 'goal_set.dart';
import 'season_goal.dart';
import 'season_timeline.dart';

/// What the athlete has done in one sport recently: the numbers a long
/// session is held against.
class SportCapacity {
  const SportCapacity({
    required this.sessions,
    required this.longestMin,
    required this.medianMin,
    required this.yearLongestMin,
  });

  /// Sessions in the last 12 weeks.
  final int sessions;
  final double longestMin, medianMin;

  /// Longest session of the last year.
  final double yearLongestMin;

  bool get hasYearCapacity => yearLongestMin > longestMin * 1.2;

  /// How well the planner knows the athlete in this sport.
  String get confidence => sessions >= 6
      ? 'high'
      : sessions >= 2
      ? 'medium'
      : 'low';
}

/// One session the week should hold, before it is placed on a day.
class AllocatedSlot {
  const AllocatedSlot({
    required this.sport,
    required this.sessionType,
    this.subType,
    required this.zone,
    this.weekday = 0,
    required this.targetMin,
    required this.minMin,
    required this.maxMin,
    this.goalId,
    required this.role,
    required this.objective,
    required this.phase,
    required this.rank,
    this.maxZone,
  });

  final String sport;
  final String sessionType;
  final String? subType;
  final int zone;

  /// Preferred ISO weekday; 0 means any day.
  final int weekday;
  final int targetMin, minMin, maxMin;

  /// The goal it prepares for; null for optional variety.
  final String? goalId;

  /// `primary`, `maintenance`, `support` or `optional`.
  final String role;
  final String objective;

  /// Phase name the template is chosen for.
  final String phase;

  /// Lower is placed and kept first.
  final int rank;

  /// The highest zone the finished workout may reach, or null for no limit.
  /// Set for an athlete who rarely trains hard: the steps are held to it, not
  /// only the label.
  final int? maxZone;

  bool get isLong =>
      sessionType == 'long' && subType == 'endurance' && rank <= 1;

  AllocatedSlot copyWith({int? targetMin, int? weekday, int? rank}) =>
      AllocatedSlot(
        sport: sport,
        sessionType: sessionType,
        subType: subType,
        zone: zone,
        weekday: weekday ?? this.weekday,
        targetMin: targetMin ?? this.targetMin,
        minMin: minMin,
        maxMin: maxMin,
        goalId: goalId,
        role: role,
        objective: objective,
        phase: phase,
        rank: rank ?? this.rank,
        maxZone: maxZone,
      );
}

/// Everything the allocator needs for one week.
class AllocationInput {
  const AllocationInput({
    required this.needs,
    required this.budgetMin,
    required this.sessionCap,
    this.strengthDays = const [],
    this.recoveringFromEvent = false,
    this.partialWeek = false,
    this.capacities = const {},
    this.weekInRun = 0,
    this.weekIndex = 0,
    this.maxKeySessions,
    this.easyStart = false,
    this.varietySports = const [],
    this.footLongCap,
    this.allowedSports,
    this.events = const [],
    this.goalWeeks = const [],
    this.cycle = 4,
  });

  final List<SportNeed> needs;

  /// Minutes the week can hold, already shaped by the week's intent.
  final double budgetMin;

  /// Most sessions the athlete's days and sessions-per-day allow.
  final int sessionCap;

  /// The weekdays the athlete set for strength. Strength is planned inside
  /// the same time and session limits as the endurance work, not on top.
  final List<int> strengthDays;
  int get strengthSessions => strengthDays.length;

  /// A long event is just behind us, whichever goals share the sport: the
  /// week holds back long and hard sessions.
  final bool recoveringFromEvent;

  /// A week already begun, or one that ends at the last event: too few days
  /// are left for a long session to be a preparation that went missing.
  final bool partialWeek;
  final Map<String, SportCapacity> capacities;

  /// Weeks since this plan run began (long sessions grow with it).
  final int weekInRun;

  /// Weeks since the season anchor (alternation of long sessions).
  final int weekIndex;

  /// Most hard sessions the athlete's level allows in a week; null for no cap.
  final int? maxKeySessions;

  /// Rarely trains hard: key sessions are tempo, and one at most.
  final bool easyStart;

  /// Sports the athlete chose that have no goal; at most one easy session a
  /// week goes to them, and only when the week has room.
  final List<String> varietySports;

  /// Longest long session of a foot sport for a goal, from its distance and
  /// target.
  final int Function(SeasonGoal goal)? footLongCap;

  /// Sports the athlete allows; null allows every sport a goal brings.
  final Set<String>? allowedSports;

  /// Events inside the week. Their time is already taken off [budgetMin]:
  /// an event is real work, whatever its priority, and counted once.
  final List<({String name, int minutes})> events;

  /// Every goal's intent this week, also those a sport's need does not carry:
  /// a key long ride must not land next to another goal's event.
  final List<GoalWeek> goalWeeks;

  /// Weeks per block; the last is the unloading week.
  final int cycle;
}

/// What the week holds and what it could not.
class WeekAllocation {
  const WeekAllocation({
    required this.slots,
    required this.budgetMin,
    required this.minutesBySport,
    required this.tradeoffs,
    required this.unmet,
    required this.longTargets,
  });

  final List<AllocatedSlot> slots;
  final double budgetMin;
  final Map<String, int> minutesBySport;

  /// Limits to a secondary goal's preparation, in words.
  final List<String> tradeoffs;

  /// Preparation a goal needed and this week could not hold.
  final List<String> unmet;

  /// The long session each sport gets, in minutes.
  final Map<String, int> longTargets;

  int get plannedMin => slots.fold(0, (a, s) => a + s.targetMin);

  FeasibilityOutcome get outcome => unmet.isNotEmpty
      ? FeasibilityOutcome.requiresDecision
      : tradeoffs.isNotEmpty
      ? FeasibilityOutcome.feasibleWithTradeoffs
      : FeasibilityOutcome.feasible;

  Map<String, dynamic> toJson() => {
    'budgetMin': budgetMin.round(),
    'plannedMin': plannedMin,
    'minutesBySport': minutesBySport,
    if (longTargets.isNotEmpty) 'longTargets': longTargets,
    if (tradeoffs.isNotEmpty) 'tradeoffs': tradeoffs,
    if (unmet.isNotEmpty) 'unmet': unmet,
  };

  /// The same, read from the sessions that were really stored. The allocation
  /// is an intention: workouts that ran long, sessions made room for and
  /// sessions dropped change it, and the report must say what is stored.
  Map<String, dynamic> toJsonActual(
    List<({String sport, String type, String? sub, int minutes})> actual,
  ) {
    final bySport = <String, int>{};
    final longs = <String, int>{};
    for (final a in actual) {
      bySport[a.sport] = (bySport[a.sport] ?? 0) + a.minutes;
      if (a.type == 'long' && a.sub == 'endurance') {
        longs[a.sport] = math.max(longs[a.sport] ?? 0, a.minutes);
      }
    }
    return {
      'budgetMin': budgetMin.round(),
      'plannedMin': actual.fold<int>(0, (a, s) => a + s.minutes),
      'minutesBySport': bySport,
      if (longs.isNotEmpty) 'longTargets': longs,
      if (tradeoffs.isNotEmpty) 'tradeoffs': tradeoffs,
      if (unmet.isNotEmpty) 'unmet': unmet,
    };
  }
}

/// Shares one week's time between the goals' sports before any day is chosen.
///
/// Long sessions come first: they are what an endurance event is prepared
/// with and the first to be starved by a week built around one sport. Each
/// gets the length its goal and the athlete's history support. If together
/// they take more than the week can give, they are cut back together, and
/// when even that is not enough one goal's long session waits for next week
/// and the trade-off is written down. The rest of the time goes to quality and
/// easy sessions by each sport's weight. Time is counted once: a session
/// serves its goal, not several.
class WeekAllocator {
  const WeekAllocator();

  /// The share of a week long sessions may take together.
  static const _longShare = 0.62;

  /// Past this, the long sessions of two sports cannot share a week.
  static const _longShareLimit = 0.78;

  /// How much of the usual week the intents leave: an easy week, a recovery
  /// after an event and the week of an event take less than a build week.
  /// Read from every goal's intent, not from the sports' strongest need: a
  /// goal that shares its sport with a later one still has to be recovered
  /// from. Weighted, so a recovering goal does not shrink the week of another
  /// that is peaking.
  static double budgetFactor(List<GoalWeek> weeks) {
    if (weeks.isEmpty) return 1;
    double factor(GoalWeek n) => switch (n.intent) {
      GoalIntent.unload => 0.7,
      GoalIntent.sharpen => 0.7,
      GoalIntent.recover => n.goal.demand.planningMinutes >= 120 ? 0.7 : 0.9,
      GoalIntent.event => n.goal.demand.planningMinutes >= 240 ? 0.75 : 0.85,
      _ => 1.0,
    };
    final total = weeks.fold<double>(0, (a, n) => a + n.weight);
    var result =
        weeks.fold<double>(0, (a, n) => a + n.weight * factor(n)) / total;
    // After a long event, or in its week, the whole athlete is tired, not
    // only the event's sport: the week is lighter whatever else is asked.
    for (final n in weeks) {
      if (n.goal.demand.planningMinutes < 240) continue;
      if (n.intent == GoalIntent.recover && n.weeksToEvent >= -1) {
        result = math.min(result, 0.75);
      } else if (n.intent == GoalIntent.event) {
        result = math.min(result, 0.8);
      }
    }
    return result;
  }

  /// A long event just behind us: the first week after it holds back the
  /// other sports' long and hard sessions too.
  static bool isRecoveringFromLongEvent(List<GoalWeek> weeks) => weeks.any(
    (n) =>
        n.intent == GoalIntent.recover &&
        n.weeksToEvent >= -1 &&
        n.goal.demand.planningMinutes >= 240,
  );

  WeekAllocation allocate(AllocationInput input) {
    final needs = [
      for (final n in input.needs)
        if (input.allowedSports == null ||
            input.allowedSports!.contains(n.sport))
          n,
    ];
    final tradeoffs = <String>[];
    final unmet = <String>[];
    for (final e in input.events) {
      tradeoffs.add(
        '${e.name} is in this week: its ${(e.minutes / 60).toStringAsFixed(1)} h '
        'count as training, so the rest of the week is lighter.',
      );
    }
    if (needs.isEmpty) {
      return WeekAllocation(
        slots: const [],
        budgetMin: input.budgetMin,
        minutesBySport: const {},
        tradeoffs: tradeoffs,
        unmet: unmet,
        longTargets: const {},
      );
    }
    // Strength takes its time first; the goals share what is left, and the
    // whole week is held to the budget again at the end.
    final strengthMin = input.strengthSessions * 45;
    final budget = math.max(0.0, input.budgetMin - strengthMin);
    final totalWeight = needs.fold<double>(0, (a, n) => a + n.weight);

    // 1. The long session each sport wants, from its goal and history.
    // Straight after a long event they are held back, whichever sport.
    // In an event's week the other sports are held back the same way: the
    // event itself is the hard day.
    final recovering = input.recoveringFromEvent || input.events.isNotEmpty;
    final wanted = <String, int>{};
    final keyRides = <String>{};
    for (final n in needs) {
      if (!_wantsLong(n)) continue;
      // Another goal's event of the same kind is this week's long session:
      // a 200 km brevet is training for the 600, not a second long ride.
      final serving = _eventAsLong(n, input);
      if (serving != null) {
        tradeoffs.add(
          '${serving.name} is this week\'s long ${_noun(n.sport)} for '
          '${n.goal.name}.',
        );
        continue;
      }
      final long = _longWanted(n, input);
      if (long.key) keyRides.add(n.sport);
      wanted[n.sport] = recovering && n.intent != GoalIntent.recover
          ? math.max(45, (long.minutes * 0.75).round())
          : long.minutes;
    }

    // 2. Fit the long sessions into the week together.
    // The long sessions are fitted against the whole week: strength gives
    // way to them, not the other way round.
    final longs = _fitLongs(
      needs: needs,
      wanted: wanted,
      budget: input.budgetMin,
      weekIndex: input.weekIndex,
      keyRide: keyRides.isNotEmpty && wanted.length == 1,
      tradeoffs: tradeoffs,
      unmet: unmet,
    );

    // 3. The rest of the time by weight, then each sport's other sessions.
    final longTotal = longs.values.fold<int>(0, (a, b) => a + b);
    final rest = math.max(0.0, budget - longTotal);
    final slots = <AllocatedSlot>[];
    final minutesBySport = <String, int>{};
    var keysLeft = input.maxKeySessions ?? 99;
    if (input.easyStart || recovering) keysLeft = math.min(keysLeft, 1);
    if (input.events.isNotEmpty) keysLeft = 0;
    // The hard sessions go round the sports by weight, one each before any
    // takes a second: a sport with a goal never loses all its quality to
    // another.
    final share = List.filled(needs.length, 0);
    final wants = [for (final n in needs) _qualityKinds(n, input).length];
    for (var round = 1; round <= 2; round++) {
      for (var i = 0; i < needs.length && keysLeft > 0; i++) {
        if (wants[i] < round) continue;
        share[i]++;
        keysLeft--;
      }
    }
    var spare = 0;
    var longRank = 0;
    for (final (i, n) in needs.indexed) {
      final sportRest = rest * n.weight / totalWeight;
      final built = _sportSlots(
        need: n,
        long: longs[n.sport],
        keyRide: keyRides.contains(n.sport),
        restMin: sportRest,
        keysLeft: share[i] + spare,
        input: input,
        longRank: longRank,
        unmet: unmet,
        tradeoffs: tradeoffs,
      );
      spare += share[i] - built.keys;
      if (longs[n.sport] != null) longRank++;
      slots.addAll(built.slots);
      minutesBySport[n.sport] = built.slots.fold(0, (a, s) => a + s.targetMin);
    }

    // 4. Variety, only where there is room: it never takes a goal's time.
    final used = slots.fold<int>(0, (a, s) => a + s.targetMin);
    final room = budget - used;
    if (input.varietySports.isNotEmpty &&
        room >= 35 &&
        slots.length + input.strengthSessions < input.sessionCap &&
        needs.every((n) => n.intent != GoalIntent.event)) {
      final sport =
          input.varietySports[input.weekIndex % input.varietySports.length];
      final cap = input.capacities[sport];
      final minutes = (cap == null ? 40 : cap.medianMin.clamp(30, 60))
          .round()
          .clamp(30, math.min(60, room.floor()))
          .toInt();
      slots.add(
        AllocatedSlot(
          sport: sport,
          sessionType: 'recovery',
          zone: 1,
          targetMin: minutes,
          minMin: 20,
          maxMin: 75,
          role: 'optional',
          objective: 'Optional variety you chose in the settings',
          phase: 'base',
          rank: 5,
        ),
      );
      minutesBySport[sport] = (minutesBySport[sport] ?? 0) + minutes;
    }

    // Strength is part of the week, under the same limits.
    for (final day in input.strengthDays.take(2)) {
      slots.add(
        AllocatedSlot(
          sport: 'strength',
          sessionType: 'key',
          subType: 'strengthFull',
          zone: 3,
          weekday: day,
          targetMin: 45,
          minMin: 30,
          maxMin: 60,
          role: 'support',
          objective: 'Strength to support your training',
          phase: '',
          rank: 3,
        ),
      );
    }

    // 5. The limits of the athlete's days and hours hold: sessions first,
    // then time. What does not fit is named, never clipped on paper.
    var fitted = _trim(
      slots,
      math.max(1, input.sessionCap),
      needs,
      unmet,
      tradeoffs,
    );
    fitted = _fitBudget(fitted, input.budgetMin, needs, unmet, tradeoffs);
    // What a part week cannot hold is not preparation that went missing.
    if (input.partialWeek) unmet.clear();

    // The longest long session takes the first weekend day, the next the
    // second: a three hour ride is a weekend ride, a two hour run can be
    // midweek.
    final biggest = fitted.where((x) => x.isLong).toList()
      ..sort((a, b) => b.targetMin.compareTo(a.targetMin));
    for (var i = 0; i < biggest.length; i++) {
      final at = fitted.indexOf(biggest[i]);
      fitted[at] = biggest[i].copyWith(weekday: i == 0 ? 6 : 7, rank: i);
    }
    return WeekAllocation(
      slots: fitted,
      budgetMin: input.budgetMin,
      minutesBySport: {
        for (final s in fitted)
          s.sport: fitted
              .where((x) => x.sport == s.sport)
              .fold(0, (a, x) => a + x.targetMin),
      },
      tradeoffs: tradeoffs,
      unmet: unmet,
      longTargets: {
        for (final s in fitted)
          if (s.isLong) s.sport: s.targetMin,
      },
    );
  }

  bool _wantsLong(SportNeed n) => switch (n.intent) {
    GoalIntent.foundation ||
    GoalIntent.build ||
    GoalIntent.specificPreparation ||
    GoalIntent.unload ||
    GoalIntent.maintain => true,
    GoalIntent.sharpen => n.weeksToEvent >= 1,
    _ => false,
  };

  static bool _isFoot(String sport) =>
      sport == 'running' || sport == 'trail_running' || sport == 'hiking';

  /// The longest session a sport's goal and the athlete's history support
  /// this week: the event's duration decides the target, history the limit.
  /// [key] marks the occasional key long session of an ultra event.
  ({int minutes, bool key}) _longWanted(SportNeed n, AllocationInput input) {
    final demand = n.goal.demand;
    final cap =
        input.capacities[n.sport] ?? input.capacities[_related(n.sport)];
    double target;
    var key = false;
    if (!_isFoot(n.sport) && demand.planningMinutes >= ultraEventMin) {
      final ultra = _ultraLong(n, input);
      target = ultra.minutes;
      key = ultra.key;
    } else if (_isFoot(n.sport) && input.footLongCap != null) {
      final footCap = input.footLongCap!(n.goal).toDouble();
      final ramp = switch (n.intent) {
        GoalIntent.maintain => 0.55,
        GoalIntent.sharpen => 0.6,
        GoalIntent.unload => (0.5 + 0.5 * n.progress) * 0.7,
        _ => 0.5 + 0.5 * n.progress,
      };
      target = footCap * ramp;
    } else {
      final ramp = switch (n.intent) {
        GoalIntent.maintain => 0.6,
        GoalIntent.sharpen => 0.65,
        GoalIntent.unload => (0.55 + 0.45 * n.progress) * 0.7,
        _ => 0.55 + 0.45 * n.progress,
      };
      target = _longPeak(demand) * ramp;
    }
    // History limits what can be added to what the athlete has done.
    double historyCap;
    if (cap != null && cap.longestMin >= 20) {
      final growth = cap.hasYearCapacity ? 0.08 : 0.05;
      historyCap = cap.longestMin * (1.12 + growth * input.weekInRun);
      if (cap.hasYearCapacity) {
        historyCap = math.min(
          historyCap,
          math.max(cap.yearLongestMin, cap.longestMin * 1.12),
        );
      }
    } else {
      // No history in this sport: start modestly and grow.
      historyCap = 75.0 + 6 * input.weekInRun;
    }
    final out = math.min(
      math.min(target, historyCap),
      longestSessionMin.toDouble(),
    );
    final minutes = out.round().clamp(45, longestSessionMin);
    // A key session that history holds back to an ordinary one is not a key
    // session.
    return (minutes: minutes, key: key && minutes > _ultraRegular(demand));
  }

  /// The longest session a shorter event prepares with, reached late in the
  /// preparation: a short race is ridden in training for its full length and
  /// a bit more, a longer one for a shrinking share of it, joining the ultra
  /// rule's half at [ultraEventMin]. A ride is never under two and a half
  /// hours: endurance on the bike is built in long rides whatever the race.
  static double _longPeak(GoalDemand d) {
    final m = d.planningMinutes;
    final share = (1.1 - 0.55 * (m - 180) / (ultraEventMin - 180)).clamp(
      0.55,
      1.1,
    );
    return d.isRide ? math.max(150.0, m * share) : m * share;
  }

  /// Events from this long are ultra events: a long session that grows a
  /// little every week until it reaches half the event would mean riding
  /// half a 600 km brevet every weekend.
  static const ultraEventMin = 480.0;

  /// The longest session the planner ever asks for.
  static const longestSessionMin = 900;

  /// The ordinary weekend long session of an ultra event: a quarter of the
  /// event, between three and five hours.
  static double _ultraRegular(GoalDemand d) =>
      (d.planningMinutes * 0.25).clamp(180.0, 300.0);

  /// Long sessions for an ultra event. Ordinary weeks hold the regular long
  /// session, a little shorter at the start of a block. Once a block, in its
  /// last loading week, a key long session steps up from block to block
  /// towards half the event (the 50 % rule), reached at 75 % of the
  /// preparation, about four weeks out.
  /// It never lands next to another goal's event; that block keeps the
  /// regular one.
  ({double minutes, bool key}) _ultraLong(SportNeed n, AllocationInput input) {
    final demand = n.goal.demand;
    final peak = demand.planningMinutes * 0.5;
    final regular = math.min(peak, _ultraRegular(demand));
    final blockWeek = input.weekIndex % math.max(2, input.cycle);
    final ramp = 0.6 + 0.4 * n.progress;
    switch (n.intent) {
      case GoalIntent.unload:
      case GoalIntent.sharpen:
        return (minutes: regular * 0.5, key: false);
      case GoalIntent.maintain:
        return (minutes: regular * 0.7, key: false);
      case GoalIntent.build:
      case GoalIntent.specificPreparation:
        final step = ((n.progress - 0.3) / 0.45).clamp(0.0, 1.0);
        if (blockWeek == math.max(2, input.cycle) - 2 &&
            step > 0 &&
            !_nearOtherEvent(n, input)) {
          return (minutes: regular + (peak - regular) * step, key: true);
        }
      default:
        break;
    }
    return (minutes: regular * ramp * (blockWeek == 0 ? 0.85 : 1), key: false);
  }

  /// Another goal is raced, sharpened for or recovered from this week, or
  /// raced next week: a key long session would take from it.
  static bool _nearOtherEvent(SportNeed n, AllocationInput input) =>
      input.events.isNotEmpty ||
      input.recoveringFromEvent ||
      input.goalWeeks.any(
        (w) =>
            w.goal.id != n.goal.id &&
            (w.intent == GoalIntent.event ||
                w.intent == GoalIntent.sharpen ||
                w.intent == GoalIntent.recover ||
                w.weeksToEvent == 1),
      );

  /// Another goal's event this week that is long enough, in a sport of the
  /// same kind, to be this week's long session for [n].
  static SeasonGoal? _eventAsLong(SportNeed n, AllocationInput input) {
    for (final w in input.goalWeeks) {
      if (w.goal.id == n.goal.id || w.intent != GoalIntent.event) continue;
      final ride = n.sport.startsWith('cycl');
      if (ride != w.goal.sport.startsWith('cycl') ||
          (!ride && _isFoot(n.sport) != _isFoot(w.goal.sport))) {
        continue;
      }
      final d = n.goal.demand;
      final regular = d.planningMinutes >= ultraEventMin
          ? _ultraRegular(d)
          : _longPeak(d) * 0.55;
      if (w.goal.demand.planningMinutes >= regular) return w.goal;
    }
    return null;
  }

  static String? _related(String sport) => switch (sport) {
    'cycling_gravel' || 'cycling_mtb' => 'cycling_road',
    'cycling_road' => 'cycling_gravel',
    'trail_running' => 'running',
    'running' => 'trail_running',
    _ => null,
  };

  /// Keeps the long sessions within the week. They are cut back together
  /// first. If even their floors do not fit, only as many as fit are planned
  /// and the sports take turns, the more important ones more often, however
  /// many sports there are; the week says whose turn it is.
  Map<String, int> _fitLongs({
    required List<SportNeed> needs,
    required Map<String, int> wanted,
    required double budget,
    required int weekIndex,
    bool keyRide = false,
    required List<String> tradeoffs,
    required List<String> unmet,
  }) {
    if (wanted.isEmpty) return {};
    if (budget < 45) {
      // Not enough time for any long session: that is a conflict, not a
      // quiet omission.
      for (final sport in wanted.keys) {
        final need = needs.firstWhere((n) => n.sport == sport);
        unmet.add(
          'The week holds ${budget.round()} min, too little for a long '
          '${_noun(sport)} for ${need.goal.name}.',
        );
      }
      return {};
    }
    final bySport = {for (final n in needs) n.sport: n};
    final order = wanted.keys.toList()
      ..sort((a, b) {
        final byWeight = bySport[b]!.weight.compareTo(bySport[a]!.weight);
        return byWeight != 0 ? byWeight : a.compareTo(b);
      });
    // How many floors (60 % of what a goal asks) fit together.
    var fit = 0;
    var floors = 0.0;
    for (final sport in order) {
      final floor = wanted[sport]! * 0.6;
      if (fit > 0 && floors + floor > budget * _longShareLimit) break;
      floors += floor;
      fit++;
    }
    var chosen = order;
    if (fit < order.length) {
      chosen = _turn(
        {for (final s in order) s: bySport[s]!.weight},
        fit,
        weekIndex,
      );
      final waiting = [
        for (final s in order)
          if (!chosen.contains(s)) s,
      ];
      tradeoffs.add(
        'A week of ${(budget / 60).toStringAsFixed(1)} h cannot hold every '
        'long session: this week holds '
        '${chosen.map((s) => s.replaceAll('_', ' ')).join(', ')}, '
        '${waiting.map((s) => s.replaceAll('_', ' ')).join(', ')} '
        '${waiting.length == 1 ? 'waits its turn' : 'wait their turn'}.',
      );
    }
    final picked = {for (final s in chosen) s: wanted[s]!};
    final total = picked.values.fold<int>(0, (a, b) => a + b);
    // A key long session alone in its week may take more of it: the rest of
    // that week is easy anyway.
    final limit = budget * (keyRide ? _longShareLimit : _longShare);
    if (total <= limit) return picked;
    final scale = limit / total;
    if (scale < 0.95 && fit == order.length) {
      tradeoffs.add(
        'The long sessions of ${_names(needs, picked.keys)} together would '
        'take ${(total / budget * 100).round()}% of a ${(budget / 60).toStringAsFixed(1)} h week, so each is '
        'shortened to ${(scale * 100).round()}% of what its goal would ask.',
      );
    }
    return {
      for (final e in picked.entries)
        e.key: math.max((e.value * 0.6).round(), (e.value * scale).round()),
    };
  }

  /// Which [count] of the sports hold their long session this week: a smooth
  /// weighted rotation, so each sport's share of the weeks follows its weight
  /// and nobody waits for ever. Deterministic from the week index.
  static List<String> _turn(Map<String, double> weights, int count, int week) {
    final names = weights.keys.toList();
    final total = weights.values.fold<double>(0, (a, b) => a + b);
    final credit = {for (final n in names) n: 0.0};
    var picked = <String>[];
    for (var round = 0; round <= week; round++) {
      for (final n in names) {
        credit[n] = credit[n]! + weights[n]!;
      }
      picked = [];
      for (var i = 0; i < count; i++) {
        String? best;
        for (final n in names) {
          if (picked.contains(n)) continue;
          if (best == null || credit[n]! > credit[best]! + 1e-9) best = n;
        }
        credit[best!] = credit[best]! - total;
        picked.add(best);
      }
    }
    return picked;
  }

  String _names(List<SportNeed> needs, Iterable<String> sports) => needs
      .where((n) => sports.contains(n.sport))
      .map((n) => n.goal.name)
      .toSet()
      .join(' and ');

  /// A sport's sessions for the week: its long session, its quality sessions
  /// and its easy ones, sized to its share of what is left.
  ({List<AllocatedSlot> slots, int keys}) _sportSlots({
    required SportNeed need,
    required int? long,
    bool keyRide = false,
    required double restMin,
    required int keysLeft,
    required AllocationInput input,
    required int longRank,
    required List<String> unmet,
    required List<String> tradeoffs,
  }) {
    final sport = need.sport;
    final goal = need.goal;
    final phase = need.intent.phase;
    final slots = <AllocatedSlot>[];
    var keys = 0;
    final ride = sport.startsWith('cycl');
    final role = need.intent == GoalIntent.maintain ? 'maintenance' : 'primary';
    final label = goal.name;

    if (long != null) {
      slots.add(
        AllocatedSlot(
          sport: sport,
          sessionType: 'long',
          subType: 'endurance',
          zone: 2,
          weekday: longRank == 0 ? 6 : 7,
          targetMin: long,
          minMin: 45,
          maxMin: longestSessionMin,
          goalId: goal.id,
          role: role,
          objective: keyRide
              ? 'Key long ${_noun(sport)} for $label'
              : 'Long ${_noun(sport)} for $label',
          phase: phase,
          rank: longRank,
        ),
      );
    }

    // Quality sessions: as many as the allowance from the allocation, of the
    // kinds [_qualityKinds] picks for the goal and the week.
    var kinds = _qualityKinds(need, input);
    // Fewer hard sessions allowed than the goal wants: they take turns.
    if (keysLeft > 0 && keysLeft < kinds.length) {
      final from = input.weekIndex % kinds.length;
      kinds = [...kinds.skip(from), ...kinds.take(from)];
    }
    kinds = kinds.take(math.max(0, keysLeft)).toList();
    var restLeft = restMin;
    var i = 0;
    for (final kind in kinds) {
      final first = i++ == 0;
      final cap = switch (kind) {
        _Quality.openers => 45,
        _Quality.vo2 => ride ? 75 : 60,
        _ => ride ? 100 : 75,
      };
      final minutes = restLeft < 60
          ? 0
          : math
                .max(45, math.min(restLeft * (first ? 0.45 : 0.4), cap))
                .round();
      if (minutes < 40) {
        if (need.weight >= 0.5 && keys == 0) {
          tradeoffs.add(
            'No room for a quality ${_noun(sport)} for $label this week.',
          );
        }
        break;
      }
      final noun = _noun(sport);
      final (subType, zone, objective) = switch (kind) {
        _Quality.steady => ('tempo', 3, 'Steady quality $noun for $label'),
        // Only the road bike has threshold workouts of its own; elsewhere
        // threshold is a tempo session ridden or run in zone 4.
        _Quality.threshold => (
          sport == 'cycling_road' ? 'threshold' : 'tempo',
          4,
          'Threshold $noun for $label',
        ),
        _Quality.vo2 => ('intervals', 5, 'Intervals for $label'),
        _Quality.hills => ('hills', 4, 'Hill $noun for $label'),
        _Quality.openers => ('intervals', 5, 'Openers for $label'),
      };
      slots.add(
        AllocatedSlot(
          sport: sport,
          sessionType: 'key',
          subType: subType,
          zone: zone,
          maxZone: input.easyStart ? 3 : null,
          weekday: first ? (ride ? 2 : 3) : 4,
          targetMin: minutes,
          minMin: 40,
          maxMin: ride ? 150 : 90,
          goalId: goal.id,
          role: role,
          objective: objective,
          phase: phase,
          rank: 2,
        ),
      );
      keys++;
      restLeft -= minutes;
    }

    // Easy sessions take what the sport has left: none below half an hour,
    // two only when each can be a real session.
    final easyCount = switch (need.intent) {
      GoalIntent.build ||
      GoalIntent.specificPreparation ||
      GoalIntent.foundation ||
      GoalIntent.unload =>
        restLeft >= 30 ? (restLeft / 45).floor().clamp(1, 2) : 0,
      GoalIntent.maintain || GoalIntent.sharpen => restLeft >= 30 ? 1 : 0,
      GoalIntent.event || GoalIntent.recover || GoalIntent.deprioritised => 1,
    };
    final recoveryWeek =
        need.intent == GoalIntent.recover ||
        need.intent == GoalIntent.event ||
        need.intent == GoalIntent.deprioritised;
    for (var i = 0; i < easyCount; i++) {
      final share = restLeft / (easyCount - i);
      // An easy session is never longer than the week's long one.
      final cap = recoveryWeek
          ? 45
          : math.min(
              ride ? 120 : 75,
              long == null ? 999 : math.max(30, (long * 0.8).round()),
            );
      final minutes = share.round().clamp(recoveryWeek ? 20 : 30, cap);
      slots.add(
        AllocatedSlot(
          sport: sport,
          sessionType: 'recovery',
          subType: null,
          zone: recoveryWeek ? 1 : 2,
          weekday: 0,
          targetMin: minutes,
          minMin: 20,
          maxMin: cap + 30,
          goalId: goal.id,
          role: recoveryWeek ? 'support' : role,
          objective: recoveryWeek
              ? 'Easy ${_noun(sport)}: recovery around $label'
              : 'Easy endurance ${_noun(sport)} for $label',
          phase: phase,
          rank: 4,
        ),
      );
      restLeft -= minutes;
    }
    return (slots: slots, keys: keys);
  }

  /// The quality sessions a sport's goal wants this week, most important
  /// first. Every endurance sport keeps some work near its ceiling, short
  /// intervals in zone 5, besides the work at race intensity. A long event
  /// raced to finish takes the two in turns and late in its build only race
  /// intensity; a shorter or ambitious one has both each build week. Hiking
  /// has hills in place of intervals.
  static List<_Quality> _qualityKinds(SportNeed n, AllocationInput input) {
    final goal = n.goal;
    final planning = goal.demand.planningMinutes;
    final hike = n.sport == 'hiking';
    // Long for the sport: beyond a marathon on foot, four hours elsewhere.
    final long = planning >= (_isFoot(n.sport) ? 360 : 240);
    final finish = goal.ambition == Ambition.finish;
    // Raced near threshold: an ambitious goal, a target time over a few
    // hours, or any race under three.
    final hard =
        goal.ambition == Ambition.performance ||
        (!finish && goal.targetSeconds != null && planning < 300) ||
        (!finish && planning < 180);
    final race = hike
        ? _Quality.hills
        : hard
        ? _Quality.threshold
        : _Quality.steady;
    final top = hike ? _Quality.hills : _Quality.vo2;
    final odd = input.weekIndex.isOdd;
    final kinds = switch (n.intent) {
      // Base: aerobic tempo, every other week a touch of the top end (on the
      // bike threshold, its base workouts).
      GoalIntent.foundation => [
        !odd
            ? _Quality.steady
            : n.sport.startsWith('cycl')
            ? _Quality.threshold
            : top,
      ],
      GoalIntent.build || GoalIntent.specificPreparation =>
        hike
            ? [race]
            : long && goal.ambition != Ambition.performance
            ? [n.progress >= 0.7 || !odd ? race : top]
            : [race, top],
      GoalIntent.maintain => input.weekIndex.isEven ? [race] : <_Quality>[],
      // Short openers keep a short race sharp; a long one only needs to feel
      // its pace.
      GoalIntent.sharpen => [long || hike ? _Quality.steady : _Quality.openers],
      _ => <_Quality>[],
    };
    // An athlete who rarely trains hard starts with one moderate session.
    if (input.easyStart) return kinds.isEmpty ? kinds : [_Quality.steady];
    return kinds;
  }

  static String _noun(String sport) {
    if (sport.startsWith('cycl')) return 'ride';
    if (sport == 'running' || sport == 'trail_running') return 'run';
    if (sport == 'swimming') return 'swim';
    if (sport == 'hiking') return 'hike';
    return sport.replaceAll('_', ' ');
  }

  /// Keeps the week to the sessions the athlete's days allow: variety first,
  /// then easy sessions of the least important sport, then quality. A goal's
  /// long session is the last to go, and if it goes, the week says so.
  List<AllocatedSlot> _trim(
    List<AllocatedSlot> slots,
    int cap,
    List<SportNeed> needs,
    List<String> unmet,
    List<String> tradeoffs,
  ) {
    if (slots.length <= cap) return slots;
    final weightOf = {for (final n in needs) n.goal.id: n.weight};
    final ordered = [...slots]
      ..sort((a, b) {
        final byRank = a.rank.compareTo(b.rank);
        if (byRank != 0) return byRank;
        return (weightOf[b.goalId] ?? 0).compareTo(weightOf[a.goalId] ?? 0);
      });
    final kept = ordered.take(cap).toList();
    for (final dropped in ordered.skip(cap)) {
      if (dropped.rank <= 1) {
        unmet.add(
          'Not enough training days for ${dropped.objective.toLowerCase()}.',
        );
      } else if (dropped.rank <= 3) {
        tradeoffs.add(
          'The training days hold $cap sessions, so '
          '${dropped.objective.toLowerCase()} is left out.',
        );
      }
    }
    return kept;
  }

  /// Holds the week to its minutes. Easy sessions shrink first, then
  /// strength, quality and the long sessions, each only to its own minimum;
  /// if that is still too much, sessions go from the least important, and a
  /// long session that goes is reported as unmet. The plan never shows more
  /// time than the athlete gave.
  List<AllocatedSlot> _fitBudget(
    List<AllocatedSlot> slots,
    double budget,
    List<SportNeed> needs,
    List<String> unmet,
    List<String> tradeoffs,
  ) {
    final list = [...slots];
    int total() => list.fold(0, (a, s) => a + s.targetMin);
    final limit = budget.floor();
    if (total() <= limit) return list;
    final weightOf = {for (final n in needs) n.goal.id: n.weight};

    // 1. Shrink towards each session's minimum, least important group first.
    for (final group in const [
      [5],
      [4],
      [3],
      [2],
      [0, 1],
    ]) {
      final over = total() - limit;
      if (over <= 0) break;
      final idx = [
        for (var i = 0; i < list.length; i++)
          if (group.contains(list[i].rank)) i,
      ];
      final room = idx.fold<int>(
        0,
        (a, i) => a + math.max(0, list[i].targetMin - list[i].minMin),
      );
      if (room <= 0) continue;
      final cut = math.min(over, room);
      var cutDone = 0;
      for (final i in idx) {
        final share = math.max(0, list[i].targetMin - list[i].minMin);
        final by = i == idx.last
            ? math.min(share, cut - cutDone)
            : math.min(share, (cut * share / room).round());
        list[i] = list[i].copyWith(targetMin: list[i].targetMin - by);
        cutDone += by;
      }
    }

    // 2. Still too much: sessions go, the least important first.
    while (total() > limit && list.isNotEmpty) {
      var worst = 0;
      for (var i = 1; i < list.length; i++) {
        final a = list[i], b = list[worst];
        final byRank = a.rank.compareTo(b.rank);
        if (byRank > 0 ||
            (byRank == 0 &&
                (weightOf[a.goalId] ?? 0) < (weightOf[b.goalId] ?? 0))) {
          worst = i;
        }
      }
      final dropped = list.removeAt(worst);
      final text = dropped.objective.toLowerCase();
      if (dropped.rank <= 1) {
        unmet.add(
          'The week holds ${(budget / 60).toStringAsFixed(1)} h, too little '
          'for $text.',
        );
      } else if (dropped.rank <= 3) {
        tradeoffs.add(
          'The week holds ${(budget / 60).toStringAsFixed(1)} h, so $text is '
          'left out.',
        );
      }
    }
    return list;
  }
}

/// What a quality session works on.
enum _Quality { steady, threshold, vo2, hills, openers }
