import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fjelia/theme/activity_colors.dart';

void main() {
  test('device sport names resolve to matching sport styles', () {
    for (final sport in ['strength_training', 'strength', 'Krafttraining']) {
      expect(activitySportIcon(sport), Icons.fitness_center);
    }
    for (final sport in ['indoor_rowing', 'rowing', 'Indoor-Rudern']) {
      expect(activitySportIcon(sport), Icons.rowing);
    }
    for (final sport in ['road_biking', 'cycling_road', 'Rennradfahren']) {
      expect(activitySportIcon(sport), Icons.directions_bike);
    }
    expect(activitySportIcon('swimming'), Icons.pool);
    expect(activitySportIcon('hiking'), Icons.hiking);
    expect(activitySportIcon('unknown_activity'), Icons.sports);
    expect(
      completedActivityColor('strength_training'),
      isNot(completedActivityColor('running')),
    );
    expect(
      completedActivityColor('indoor_rowing'),
      isNot(completedActivityColor('running')),
    );
    expect(
      completedActivityColor('road_biking'),
      completedActivityColor('cycling'),
    );
  });
}
