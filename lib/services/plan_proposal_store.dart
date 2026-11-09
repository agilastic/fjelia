import 'package:shared_preferences/shared_preferences.dart';

const _askFirstKey = 'plan_changes_ask_first_v1';
const _decidedKey = 'readiness_proposal_decided_v1';
const _notifiedKey = 'plan_proposal_notified_v1';
const _proCoachKey = 'plan_proposal_pro_coach_v1';
const _revisionKey = 'plan_proposal_revision_v1';

String _dayKey(DateTime d) =>
    DateTime(d.year, d.month, d.day).toIso8601String().substring(0, 10);

/// What the athlete said about plan changes Fjelia proposes.
abstract final class PlanProposalStore {
  /// Ask before readiness changes the day or a trend rebuilds the plan. On
  /// by default.
  static Future<bool> askFirst() async =>
      (await SharedPreferences.getInstance()).getBool(_askFirstKey) ?? true;

  static Future<void> setAskFirst(bool value) async =>
      (await SharedPreferences.getInstance()).setBool(_askFirstKey, value);

  /// FjeliaPro: the coach writes the morning push. On by default for Pro;
  /// the switch in Settings → Training says what is sent and turns it off.
  static Future<bool> proCoach() async =>
      (await SharedPreferences.getInstance()).getBool(_proCoachKey) ?? true;

  static Future<void> setProCoach(bool value) async =>
      (await SharedPreferences.getInstance()).setBool(_proCoachKey, value);

  /// The coach's revision of [day] as it answered (JSON), kept so the push
  /// still opens it after the app was closed.
  static Future<String?> revision(DateTime day) async {
    final raw = (await SharedPreferences.getInstance()).getString(_revisionKey);
    if (raw == null || !raw.startsWith('${_dayKey(day)}|')) return null;
    return raw.substring(11);
  }

  static Future<void> saveRevision(DateTime day, String json) async =>
      (await SharedPreferences.getInstance()).setString(
        _revisionKey,
        '${_dayKey(day)}|$json',
      );

  static Future<void> clearRevision() async =>
      (await SharedPreferences.getInstance()).remove(_revisionKey);

  /// Whether the readiness proposal of [day] was answered (either way).
  static Future<bool> decided(DateTime day) async =>
      ((await SharedPreferences.getInstance()).getStringList(_decidedKey) ??
              const <String>[])
          .contains(_dayKey(day));

  static Future<void> decide(DateTime day) => _add(_decidedKey, _dayKey(day));

  /// When the notification about [key] was set to appear; each proposal
  /// gets one, however often the app goes to the background.
  static Future<DateTime?> notifiedAt(String key) async {
    for (final e in await notifications()) {
      if (e.key == key) return e.at;
    }
    return null;
  }

  static Future<List<({String key, DateTime at})>> notifications() async => [
    for (final raw
        in (await SharedPreferences.getInstance()).getStringList(
              _notifiedKey,
            ) ??
            const <String>[])
      if (raw.split('|') case [
        final key,
        final ms,
      ] when int.tryParse(ms) != null)
        (key: key, at: DateTime.fromMillisecondsSinceEpoch(int.parse(ms))),
  ];

  static Future<void> markNotified(String key, DateTime at) async {
    await forget(key);
    await _add(_notifiedKey, '$key|${at.millisecondsSinceEpoch}');
  }

  /// The notification about [key] was taken back before it appeared.
  static Future<void> forget(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_notifiedKey) ?? <String>[];
    list.removeWhere((raw) => raw.split('|').first == key);
    await prefs.setStringList(_notifiedKey, list);
  }

  static Future<void> _add(String prefsKey, String value) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(prefsKey) ?? <String>[];
    if (list.contains(value)) return;
    list.add(value);
    await prefs.setStringList(
      prefsKey,
      list.length > 30 ? list.sublist(list.length - 30) : list,
    );
  }
}
