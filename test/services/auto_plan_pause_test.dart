import 'package:fjelia/services/auto_plan_pause.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'deleting all workouts pauses the automatic plan until one is asked for',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      expect(await AutoPlanPause.isPaused, isFalse);
      await AutoPlanPause.pause();
      expect(await AutoPlanPause.isPaused, isTrue);
      await AutoPlanPause.resume();
      expect(await AutoPlanPause.isPaused, isFalse);
    },
  );
}
