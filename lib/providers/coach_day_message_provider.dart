import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../db/database.dart';
import '../services/hr_zone_change_notice.dart';
import '../services/coach_day_message.dart';
import '../services/coach_language.dart';
import '../services/pro_analysis.dart' show proAnalysisPrompts;
import '../utils/log.dart';
import 'ai_coach_provider.dart';
import 'coach_messages_provider.dart';
import 'database_provider.dart';
import 'fjelia_pro_provider.dart' show proSubscribedProvider;
import 'user_profile_provider.dart';

const _enabledKey = 'coach_day_messages_v1';

/// The `kind` of a coach message during the day in `coach_messages`; its
/// `period` holds the [CoachDaySignal] name.
const coachDayKind = 'coach_day';

/// FjeliaPro: the coach writes a message when stress or energy changes
/// during the day (off until the athlete allows it; turning it on is the
/// consent to send the context to Fjelia AI Pro).
final coachDayMessagesEnabledProvider =
    AsyncNotifierProvider<CoachDayMessagesNotifier, bool>(
      CoachDayMessagesNotifier.new,
    );

class CoachDayMessagesNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async =>
      (await SharedPreferences.getInstance()).getBool(_enabledKey) ?? false;

  Future<void> set(bool value) async {
    await (await SharedPreferences.getInstance()).setBool(_enabledKey, value);
    state = AsyncData(value);
  }
}

/// Asks the coach after a sync when a signal of the day is due.
final coachDayMessageRunnerProvider = Provider(CoachDayMessageRunner.new);

class CoachDayMessageRunner {
  CoachDayMessageRunner(this._ref);
  final Ref _ref;
  bool _running = false;

  /// Returns the message written, or null when none was due or allowed.
  Future<String?> run({DateTime? now}) async {
    if (_running) return null;
    _running = true;
    try {
      if (!_ref.read(proSubscribedProvider) ||
          !proAnalysisPrompts.isAvailable ||
          !await _ref.read(coachDayMessagesEnabledProvider.future)) {
        return null;
      }
      final at = now ?? DateTime.now();
      final day = DateTime(at.year, at.month, at.day);
      final db = _ref.read(databaseProvider);
      final sent = {
        for (final m in await db.coachMessagesOn(day))
          if (m.kind == coachDayKind)
            ?CoachDaySignal.values.where((s) => s.name == m.period).firstOrNull,
      };
      final rows = await db.getHrvRange(8);
      bool sameDay(HrvRecord r) =>
          r.date.year == day.year &&
          r.date.month == day.month &&
          r.date.day == day.day;
      final today = rows.where(sameDay).lastOrNull;
      final week = [
        for (final r in rows)
          if (r.date.isBefore(day)) ?r.stressLevel,
      ];
      final usual = week.isEmpty
          ? null
          : week.reduce((a, b) => a + b) / week.length;
      final stress = today?.stressLevel, energy = today?.computedEnergie;
      final zoneChanges = await HrZoneChangeNotice.forCoach();
      final signal = dueCoachDaySignal(
        now: at,
        sentToday: sent,
        stress: stress,
        stressUsual: usual,
        energy: energy,
        zonesChanged: zoneChanges.isNotEmpty,
      );
      if (signal == null) return null;
      final profile = await _ref.read(userProfileProvider.future);
      final context = await _ref
          .read(toonCacheProvider.notifier)
          .getOrBuild(null, profile.raceGoals ?? '', null);
      final answer = await _ref
          .read(aiCoachClientProvider)
          .sendProAnalysis(
            '${proAnalysisPrompts.dayMessage}\n${coachLanguageDirective()}',
            'QUESTION: ${coachDayQuestion(signal, now: at, stress: stress, stressUsual: usual, energy: energy, zones: zoneChanges.firstOrNull)}',
            context,
            deep: false,
          )
          .timeout(const Duration(seconds: 40));
      final text = usableCoachDayMessage(answer.text);
      if (text == null) {
        log('[CoachDay] answer not usable (${answer.text.length} chars)');
        return null;
      }
      await db.archiveCoachMessage(
        day: day,
        kind: coachDayKind,
        period: signal.name,
        body: text,
        source: 'FjeliaPro',
        now: at,
      );
      _ref.invalidate(coachMessagesProvider);
      if (signal == CoachDaySignal.zones) await HrZoneChangeNotice.coachDone();
      log('[CoachDay] ${signal.name} message written');
      return text;
    } catch (e) {
      log('[CoachDay] $e');
      return null;
    } finally {
      _running = false;
    }
  }
}
