import 'package:intl/intl.dart';

import '../l10n/l10n_ext.dart';

import '../db/database.dart';
import 'garmin_data.dart';
import 'planned_workout_presentation.dart';

enum CoachCardStatus {
  planned,
  adapted,
  completed,
  skipped;

  /// What the card says, in the app language.
  String get label => switch (this) {
    planned => tr.statusPlanned,
    adapted => tr.statusAdapted,
    completed => tr.statusCompleted,
    skipped => tr.statusRest,
  };
}

/// The session a coach chat is about: shown as a card at the top of the chat
/// and, for planned sessions, described to the model.
///
/// Names stay out of what is sent: [contextLine] has sport, type, length,
/// zone and structure, never the title of the session.
class CoachContextCard {
  const CoachContextCard({
    required this.sport,
    required this.title,
    required this.date,
    required this.status,
    this.facts = const [],
    this.contextLine = '',
    this.questions = const [],
  });

  final String sport, title;
  final DateTime date;
  final CoachCardStatus status;

  /// Short facts for the card, e.g. "35 min", "Z2".
  final List<String> facts;

  /// A TOON line that describes the session to the model.
  final String contextLine;

  /// Questions offered as one-tap starters.
  final List<String> questions;

  /// A planned session of the training plan.
  ///
  /// With [zoneTarget] each step names the range of its zone as of today, in
  /// heart rate and, where there is FTP, watts.
  factory CoachContextCard.planned(
    TrainingSession s, {
    String Function(int zone)? zoneTarget,
    String? skipReason,
  }) {
    final status = switch (s.status) {
      'completed' => CoachCardStatus.completed,
      'skipped' => CoachCardStatus.skipped,
      'adapted' => CoachCardStatus.adapted,
      _ => CoachCardStatus.planned,
    };
    final structure = [
      for (final l in plannedStepLines(
        s.stepsJson,
        primaryZone: s.primaryZone,
        zoneTarget: zoneTarget,
      ).take(14))
        '${l.amount} ${l.label}${l.target != null
                ? ' ${l.target}'
                : l.zone == null
                ? ''
                : ' Z${l.zone}'}'
            .trim(),
    ];
    return CoachContextCard(
      sport: s.sport,
      title: s.title,
      date: s.sessionDate,
      status: status,
      facts: ['${s.plannedDurationMin} min', 'Z${s.primaryZone}'],
      contextLine: _sessionLine(
        status: status.name,
        date: s.sessionDate,
        sport: s.sport,
        extra: [
          'Type:${s.sessionType}',
          'Phase:${s.phase}',
          'Week:${s.weekNumber}',
          'Duration:${s.plannedDurationMin}min',
          'TRIMP:${s.plannedTrimp}',
          'Zone:Z${s.primaryZone}',
          if (status == CoachCardStatus.skipped && skipReason != null)
            'SkipReason:${skipReason.replaceAll(RegExp(r'[,:\[\]]'), ' ')}',
          if (structure.isNotEmpty) 'Structure:${structure.join('>')}',
        ],
      ),
      questions: switch (status) {
        CoachCardStatus.completed => _completedQuestions,
        CoachCardStatus.skipped => const [
          'Why is this a rest day?',
          'What should I do instead?',
        ],
        _ => _plannedQuestions,
      },
    );
  }

  /// A workout synced from Garmin's calendar.
  factory CoachContextCard.scheduled({
    required String sport,
    required String title,
    required DateTime date,
    required String summary,
    required List<String> structure,
  }) => CoachContextCard(
    sport: sport,
    title: title,
    date: date,
    status: CoachCardStatus.planned,
    facts: [summary],
    contextLine: _sessionLine(
      status: 'planned',
      date: date,
      sport: sport,
      extra: [
        'Planned:$summary',
        if (structure.isNotEmpty) 'Structure:${structure.join('>')}',
      ],
    ),
    questions: _plannedQuestions,
  );

  /// A completed activity. Its numbers also come with the request context.
  factory CoachContextCard.completed(GarminActivity a) => CoachContextCard(
    sport: a.type,
    title: a.name,
    date: a.startTime,
    status: CoachCardStatus.completed,
    facts: [
      '${a.duration.inMinutes} min',
      if ((a.distanceMeters ?? 0) >= 100)
        '${(a.distanceMeters! / 1000).toStringAsFixed(1)} km',
      if (a.trainingLoad != null) tr.loadValue(a.trainingLoad!.round()),
    ],
    contextLine: _sessionLine(
      status: 'completed',
      date: a.startTime,
      sport: a.type,
      extra: [
        'Duration:${a.duration.inMinutes}min',
        if (a.hrZoneSeconds.isNotEmpty)
          'HRZonePct:${[for (var i = 1; i <= 5; i++) '${((a.hrZoneSeconds['zone$i'] ?? 0)).round()}'].join('/')}',
      ],
    ),
    questions: _completedQuestions,
  );

  /// The request context with the session described first.
  String withContext(String toon) =>
      contextLine.isEmpty ? toon : '$contextLine\n$toon';

  static const _plannedQuestions = [
    'How do I execute this workout?',
    'Why this workout today?',
    'Should I adjust it today?',
  ];
  static const _completedQuestions = [
    'How did this session go?',
    'What does it mean for my next days?',
    'How does it compare with similar sessions?',
  ];

  static String _sessionLine({
    required String status,
    required DateTime date,
    required String sport,
    required List<String> extra,
  }) =>
      '[Session:Status:$status,Date:${DateFormat('yyyy-MM-dd').format(date)} ${_weekdays[date.weekday - 1]},'
      'Sport:${sport.replaceAll('_', ' ')},${extra.join(',')}]';
}

/// English on purpose: the coach context is not shown in the app language.
const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
