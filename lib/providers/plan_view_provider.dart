import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final planViewProvider = AsyncNotifierProvider<PlanViewNotifier, String>(
  PlanViewNotifier.new,
);

class PlanViewNotifier extends AsyncNotifier<String> {
  @override
  Future<String> build() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('plan_default_view') ?? 'list';
    return ['month', 'week', 'list'].contains(saved) ? saved : 'list';
  }

  Future<void> setView(String view) async {
    if (!['month', 'week', 'list'].contains(view)) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('plan_default_view', view);
    state = AsyncData(view);
  }
}
