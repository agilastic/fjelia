import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final userProfileProvider =
    AsyncNotifierProvider<UserProfileNotifier, UserProfile>(
      UserProfileNotifier.new,
    );

/// Athlete profile: demographics, health markers and training preferences.
class UserProfile {
  const UserProfile({
    this.birthYear,
    this.sex = 'm',
    this.heightCm,
    this.smokingStatus = 'never',
    this.yearsSinceQuit,
    this.cigarettesPerDay,
    this.alcoholDrinksPerMonth,
    this.debugMode = false,
    this.raceGoals,
    this.trainingDaysPerWeek = 5,
    this.restDays = const [7],
    this.preferredStrengthDays = const [3],
    this.maxSessionsPerDay = 1,
    this.hoursPerWeek = 8,
    this.weekStartsOnMonday = true,
    this.preferredSports = const ['running'],
    this.experienceLevel = 'beginner',
    this.waistCm,
    this.diabetesType,
    this.hba1cPercent,
    this.ldlCholesterol,
    this.hdlCholesterol,
    this.apoB,
    this.hsCrp,
    this.eGfr,
  });

  final int? birthYear;

  /// 'm' or 'f'.
  final String sex;
  final double? heightCm;

  /// 'never', 'former' or 'current'.
  final String smokingStatus;
  final int? yearsSinceQuit;
  final int? cigarettesPerDay;
  final int? alcoholDrinksPerMonth;
  final bool debugMode;

  /// Free-text race goals for the AI coach.
  final String? raceGoals;
  final int trainingDaysPerWeek;

  /// ISO weekdays (1 = Monday).
  final List<int> restDays;
  final List<int> preferredStrengthDays;
  final int maxSessionsPerDay;
  final double hoursPerWeek;
  final bool weekStartsOnMonday;
  final List<String> preferredSports;

  /// 'beginner', 'intermediate' or 'advanced'.
  final String experienceLevel;
  final double? waistCm;
  final String? diabetesType;
  final double? hba1cPercent;
  final double? ldlCholesterol;
  final double? hdlCholesterol;
  final double? apoB;
  final double? hsCrp;
  final double? eGfr;

  /// Age in fractional years (birth assumed mid-year).
  double? get age {
    final by = birthYear;
    if (by == null) return null;
    final now = DateTime.now();
    return (now.year - by) + (now.month - 6) / 12;
  }

  /// Tanaka (men) / Gulati (women) age-predicted max HR.
  int? get maxHrEstimate {
    final a = age;
    if (a == null) return null;
    return sex == 'f' ? (206 - 0.88 * a).round() : (208 - 0.7 * a).round();
  }

  Map<String, dynamic> toJson() => {
    'birthYear': birthYear,
    'sex': sex,
    'heightCm': heightCm,
    'smokingStatus': smokingStatus,
    'yearsSinceQuit': yearsSinceQuit,
    'cigarettesPerDay': cigarettesPerDay,
    'alcoholDrinksPerMonth': alcoholDrinksPerMonth,
    'debugMode': debugMode,
    'raceGoals': raceGoals,
    'trainingDaysPerWeek': trainingDaysPerWeek,
    'restDays': restDays,
    'preferredStrengthDays': preferredStrengthDays,
    'maxSessionsPerDay': maxSessionsPerDay,
    'hoursPerWeek': hoursPerWeek,
    'weekStartsOnMonday': weekStartsOnMonday,
    'preferredSports': preferredSports,
    'experienceLevel': experienceLevel,
    'waistCm': waistCm,
    'diabetesType': diabetesType,
    'hba1cPercent': hba1cPercent,
    'ldlCholesterol': ldlCholesterol,
    'hdlCholesterol': hdlCholesterol,
    'apoB': apoB,
    'hsCrp': hsCrp,
    'eGfr': eGfr,
  };

  static UserProfile fromJson(Map<String, dynamic> json) {
    var birthYear = (json['birthYear'] as num?)?.toInt();
    // Older profiles stored an age instead of a birth year.
    if (birthYear == null && json['age'] != null) {
      birthYear = DateTime.now().year - (json['age'] as num).round();
    }
    return UserProfile(
      birthYear: birthYear,
      sex: json['sex'] as String? ?? 'm',
      heightCm: (json['heightCm'] as num?)?.toDouble(),
      smokingStatus: json['smokingStatus'] as String? ?? 'never',
      yearsSinceQuit: (json['yearsSinceQuit'] as num?)?.toInt(),
      cigarettesPerDay: (json['cigarettesPerDay'] as num?)?.toInt(),
      alcoholDrinksPerMonth: (json['alcoholDrinksPerMonth'] as num?)?.toInt(),
      debugMode: json['debugMode'] as bool? ?? false,
      raceGoals: json['raceGoals'] as String?,
      trainingDaysPerWeek: (json['trainingDaysPerWeek'] as num?)?.toInt() ?? 5,
      restDays: (json['restDays'] as List?)?.cast<int>() ?? const [7],
      preferredStrengthDays:
          (json['preferredStrengthDays'] as List?)?.cast<int>() ?? const [3],
      maxSessionsPerDay: (json['maxSessionsPerDay'] as num?)?.toInt() ?? 1,
      hoursPerWeek: (json['hoursPerWeek'] as num?)?.toDouble() ?? 8.0,
      weekStartsOnMonday: json['weekStartsOnMonday'] as bool? ?? true,
      preferredSports:
          (json['preferredSports'] as List?)?.cast<String>() ??
          const ['running'],
      experienceLevel: json['experienceLevel'] as String? ?? 'beginner',
      waistCm: (json['waistCm'] as num?)?.toDouble(),
      diabetesType: json['diabetesType'] as String?,
      hba1cPercent: (json['hba1cPercent'] as num?)?.toDouble(),
      ldlCholesterol: (json['ldlCholesterol'] as num?)?.toDouble(),
      hdlCholesterol: (json['hdlCholesterol'] as num?)?.toDouble(),
      apoB: (json['apoB'] as num?)?.toDouble(),
      hsCrp: (json['hsCrp'] as num?)?.toDouble(),
      eGfr: (json['eGfr'] as num?)?.toDouble(),
    );
  }

  /// Nullable health fields are replaced as given (pass the current value to
  /// keep it); the rest fall back to their current values.
  UserProfile copyWith({
    int? birthYear,
    String? sex,
    double? heightCm,
    String? smokingStatus,
    int? yearsSinceQuit,
    int? cigarettesPerDay,
    int? alcoholDrinksPerMonth,
    bool? debugMode,
    String? raceGoals,
    int? trainingDaysPerWeek,
    List<int>? restDays,
    List<int>? preferredStrengthDays,
    int? maxSessionsPerDay,
    double? hoursPerWeek,
    bool? weekStartsOnMonday,
    List<String>? preferredSports,
    String? experienceLevel,
    double? waistCm,
    String? diabetesType,
    double? hba1cPercent,
    double? ldlCholesterol,
    double? hdlCholesterol,
    double? apoB,
    double? hsCrp,
    double? eGfr,
  }) => UserProfile(
    birthYear: birthYear ?? this.birthYear,
    sex: sex ?? this.sex,
    heightCm: heightCm ?? this.heightCm,
    smokingStatus: smokingStatus ?? this.smokingStatus,
    yearsSinceQuit: yearsSinceQuit ?? this.yearsSinceQuit,
    cigarettesPerDay: cigarettesPerDay ?? this.cigarettesPerDay,
    alcoholDrinksPerMonth: alcoholDrinksPerMonth ?? this.alcoholDrinksPerMonth,
    debugMode: debugMode ?? this.debugMode,
    raceGoals: raceGoals ?? this.raceGoals,
    trainingDaysPerWeek: trainingDaysPerWeek ?? this.trainingDaysPerWeek,
    restDays: restDays ?? this.restDays,
    preferredStrengthDays: preferredStrengthDays ?? this.preferredStrengthDays,
    maxSessionsPerDay: maxSessionsPerDay ?? this.maxSessionsPerDay,
    hoursPerWeek: hoursPerWeek ?? this.hoursPerWeek,
    weekStartsOnMonday: weekStartsOnMonday ?? this.weekStartsOnMonday,
    preferredSports: preferredSports ?? this.preferredSports,
    experienceLevel: experienceLevel ?? this.experienceLevel,
    waistCm: waistCm ?? this.waistCm,
    diabetesType: diabetesType ?? this.diabetesType,
    hba1cPercent: hba1cPercent ?? this.hba1cPercent,
    ldlCholesterol: ldlCholesterol ?? this.ldlCholesterol,
    hdlCholesterol: hdlCholesterol ?? this.hdlCholesterol,
    apoB: apoB ?? this.apoB,
    hsCrp: hsCrp ?? this.hsCrp,
    eGfr: eGfr ?? this.eGfr,
  );
}

class UserProfileNotifier extends AsyncNotifier<UserProfile> {
  static const _storage = FlutterSecureStorage();
  static const _key = 'user_profile_v1';

  @override
  Future<UserProfile> build() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return const UserProfile();
    try {
      return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const UserProfile();
    }
  }

  Future<void> save(UserProfile profile) async {
    await _storage.write(key: _key, value: jsonEncode(profile.toJson()));
    state = AsyncData(profile);
  }
}
