// Step 3 of docs/training-plan-rethink.md: the level a plan uses. Load and
// fitness say what an athlete can do, not how used they are to structured
// hard training.
import 'package:fjelia/services/training_plan_service.dart';
import 'package:flutter_test/flutter_test.dart';

String level(
  String own, {
  required String tier,
  bool enoughData = true,
  int activeWeeks = 0,
  bool mostlyEasy = false,
}) => PlanAthleteProfile(experienceLevel: own)
    .withDataLevel(
      tier: tier,
      enoughData: enoughData,
      activeWeeks: activeWeeks,
      mostlyEasy: mostlyEasy,
    )
    .experienceLevel;

void main() {
  test('fitness data alone does not make a beginner intermediate', () {
    // Twelve weeks of good running, no year of training behind it.
    expect(level('beginner', tier: 'advanced', activeWeeks: 12), 'beginner');
  });

  test('a year of regular training with intensity moves up one step', () {
    expect(
      level('beginner', tier: 'advanced', activeWeeks: 30),
      'intermediate',
    );
    expect(
      level('intermediate', tier: 'advanced', activeWeeks: 44),
      'advanced',
    );
    expect(
      level('intermediate', tier: 'advanced', activeWeeks: 30),
      'intermediate',
    );
  });

  test('a history that is almost all easy is no experience with intensity', () {
    expect(
      level('beginner', tier: 'advanced', activeWeeks: 50, mostlyEasy: true),
      'beginner',
    );
  });

  test('the data can lower the level', () {
    expect(level('advanced', tier: 'beginner'), 'beginner');
    final lowered = PlanAthleteProfile(
      experienceLevel: 'advanced',
    ).withDataLevel(tier: 'intermediate', enoughData: true);
    expect(lowered.experienceLevel, 'intermediate');
    expect(lowered.levelFromData, isTrue);
  });

  test('too little data leaves the athlete their own answer', () {
    expect(
      level('beginner', tier: 'advanced', enoughData: false, activeWeeks: 52),
      'beginner',
    );
    final kept = PlanAthleteProfile(
      experienceLevel: 'intermediate',
    ).withDataLevel(tier: 'intermediate', enoughData: true);
    expect(kept.levelFromData, isFalse);
  });

  test('a beginner gets one hard session a week', () {
    expect(
      const PlanAthleteProfile(experienceLevel: 'beginner').maxKeySessions,
      1,
    );
  });
}
