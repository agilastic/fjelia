import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../db/database.dart';
import '../l10n/app_localizations.dart';
import 'package:fjelia_core/utils/log.dart';
import 'hr_zone_history.dart';
import 'notifications/local_notification_gateway.dart';

/// The one notification id of a zone change.
const hrZoneNoticeId = 7800000;

/// A tap opens Settings → HF-Zonen.
class HrZonesPayload {
  const HrZonesPayload();

  String encode() => jsonEncode({'v': 1, 'feature': 'hr_zones'});

  static HrZonesPayload? decode(String? raw) {
    if (raw == null || raw.length > 100) return null;
    try {
      final j = jsonDecode(raw);
      return j is Map && j['v'] == 1 && j['feature'] == 'hr_zones'
          ? const HrZonesPayload()
          : null;
    } catch (_) {
      return null;
    }
  }
}

/// One sport's zones changed by the athlete's device.
class HrZoneChange {
  const HrZoneChange({
    required this.sport,
    required this.before,
    required this.after,
    required this.method,
    required this.at,
  });
  final String sport;
  final List<int>? before;
  final List<int> after;
  final String method;
  final DateTime at;

  Map<String, Object?> toJson() => {
    'sport': sport,
    'before': before,
    'after': after,
    'method': method,
    'at': at.toIso8601String(),
  };

  static HrZoneChange? fromJson(Object? j) {
    if (j is! Map) return null;
    List<int>? ints(Object? v) =>
        v is List ? [for (final x in v) (x as num).toInt()] : null;
    final after = ints(j['after']);
    final at = DateTime.tryParse('${j['at']}');
    if (after == null || at == null || j['sport'] is! String) return null;
    return HrZoneChange(
      sport: j['sport'] as String,
      before: ints(j['before']),
      after: after,
      method: '${j['method']}',
      at: at,
    );
  }
}

/// Zones the athlete's watch changed without them doing anything: a local
/// notification (at most one a day, all changes in it, only for sports
/// trained in the last 90 days) and, with FjeliaPro, a coach note on what
/// it means (CoachDaySignal.zones). Changes made in the app, by a test or
/// derived from running are not notified.
class HrZoneChangeNotice {
  HrZoneChangeNotice(this._db, this._gateway);
  final AppDatabase _db;
  final LocalNotificationGateway _gateway;

  static const _storage = FlutterSecureStorage();
  static const _pendingKey = 'hr_zone_changes_pending_v1';
  static const _coachKey = 'hr_zone_changes_coach_v1';
  static const _sentKey = 'hr_zone_notice_sent_v1';
  static const _enabledKey = 'hr_zone_change_notify_v1';

  static Future<bool> enabled() async {
    try {
      return (await SharedPreferences.getInstance()).getBool(_enabledKey) ??
          true;
    } catch (_) {
      return true;
    }
  }

  static Future<void> setEnabled(bool on) async =>
      (await SharedPreferences.getInstance()).setBool(_enabledKey, on);

  static Future<Map<String, HrZoneChange>> _read(String key) async {
    final raw = await _storage.read(key: key);
    if (raw == null) return {};
    try {
      return {
        for (final e in (jsonDecode(raw) as Map).entries)
          '${e.key}': ?HrZoneChange.fromJson(e.value),
      };
    } catch (_) {
      return {};
    }
  }

  static Future<void> _write(String key, Map<String, HrZoneChange> v) =>
      v.isEmpty
      ? _storage.delete(key: key)
      : _storage.write(
          key: key,
          value: jsonEncode({for (final e in v.entries) e.key: e.value}),
        );

  /// Remembers [change] for the next notice and the coach; a later change
  /// of the same sport keeps the first "before".
  static Future<void> add(HrZoneChange change) async {
    for (final key in [_pendingKey, _coachKey]) {
      final all = await _read(key);
      final earlier = all[change.sport];
      all[change.sport] = HrZoneChange(
        sport: change.sport,
        before: earlier?.before ?? change.before,
        after: change.after,
        method: change.method,
        at: change.at,
      );
      await _write(key, all);
    }
  }

  /// The changes the coach has not written about yet, newest first.
  static Future<List<HrZoneChange>> forCoach() async =>
      (await _read(_coachKey)).values.toList()
        ..sort((a, b) => b.at.compareTo(a.at));

  static Future<void> coachDone() => _storage.delete(key: _coachKey);

  /// Shows the notice when one is due: something changed, it is switched
  /// on, none went out today and a changed sport was trained lately.
  /// Returns whether one was shown.
  Future<bool> run(AppLocalizations l, {DateTime? now}) async {
    final pending = await _read(_pendingKey);
    if (pending.isEmpty) return false;
    final at = now ?? DateTime.now();
    final today = '${at.year}-${at.month}-${at.day}';
    if (!await enabled()) {
      await _write(_pendingKey, {});
      return false;
    }
    if (await _storage.read(key: _sentKey) == today) return false;
    final trained = await _trainedSports(at);
    final lines = [
      for (final c in pending.values)
        if (trained.contains(c.sport)) ?_line(l, c),
    ];
    await _write(_pendingKey, {});
    if (lines.isEmpty) return false;
    try {
      await _gateway.schedule(
        ScheduledNotification(
          id: hrZoneNoticeId,
          at: at.add(const Duration(seconds: 2)),
          payload: const HrZonesPayload().encode(),
          title: l.hrZoneNoticeTitle,
          body: lines.join('\n'),
          feature: NotificationFeature.hrZones,
          actionLabels: {'channel': l.hrZoneNoticeChannel},
        ),
      );
      await _storage.write(key: _sentKey, value: today);
      log('[HrZones] change notice: ${lines.join(' | ')}');
      return true;
    } catch (e) {
      log('[HrZones] notice not shown: $e');
      return false;
    }
  }

  /// "Radfahren (von deiner Uhr): Z2 ab 122, Z4 ab 142": the zones whose
  /// lower limit moved, or null when none did.
  String? _line(AppLocalizations l, HrZoneChange c) {
    final changed = [
      for (var i = 1; i < 5; i++)
        if (c.before == null || c.before![i] != c.after[i])
          l.hrZoneNoticeFrom('Z${i + 1}', '${c.after[i]}'),
    ];
    if (changed.isEmpty) return null;
    final sport = switch (c.sport) {
      'cycling' => l.cycling,
      'swimming' => l.swimming,
      _ => l.running,
    };
    return l.hrZoneNoticeLine(sport, l.zoneSourceDevice, changed.join(', '));
  }

  /// The zone sports of the workouts of the last 90 days.
  Future<Set<String>> _trainedSports(DateTime now) async {
    final rows =
        await (_db.selectOnly(_db.activityRecords, distinct: true)
              ..addColumns([_db.activityRecords.type])
              ..where(
                _db.activityRecords.startDate.isBiggerOrEqualValue(
                  now.subtract(const Duration(days: 90)),
                ),
              ))
            .get();
    return {
      for (final r in rows) ?zoneSport(r.read(_db.activityRecords.type) ?? ''),
    };
  }
}
