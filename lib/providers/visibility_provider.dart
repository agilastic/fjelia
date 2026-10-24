import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/visibility_settings_store.dart';

/// Cards on the Health page (key → settings label).
const healthItemLabels = <String, String>{
  'health_monitor': 'Health Monitor',
  'hr_timeline': 'HR Timeline',
  'grip_strength': 'Grip Strength',
  'body_composition': 'Body Composition',
  'bio_age': 'Biological Age',
};

/// Cards on the Load page.
const loadItemLabels = <String, String>{
  'heat_acclimation': 'Heat Acclimation',
  'day_load': 'Day Training Load',
  'weekday_load': 'Weekday Comparison',
  'weekly_load': 'Weekly Training Load',
  'zone_polarization': 'Zone Polarization',
  'elevation': 'Elevation Overview',
  'strain': 'Training Monitor',
  'form': 'ATL / CTL / TSB Form',
  'plan_banner': 'Training Plan Progress',
};

/// Tiles inside the Health Monitor grid.
const healthMonitorItemLabels = <String, String>{
  'rhr': 'RHR Sleep',
  'hrv': 'HRV Sleep',
  'spo2': 'SpO2 Sleep',
  'resp': 'Resp Rate',
  'stress': 'Stress',
  'skin_temp': 'Skin Temp',
  'steps': 'Steps',
  'sleep': "Tonight's Sleep",
  'bp': 'Blood Pressure',
};

final healthVisibilityProvider =
    AsyncNotifierProvider<_VisibilityNotifier, Map<String, bool>>(
      () => _VisibilityNotifier('health', healthItemLabels),
    );

final loadVisibilityProvider =
    AsyncNotifierProvider<_VisibilityNotifier, Map<String, bool>>(
      () => _VisibilityNotifier('load', loadItemLabels),
    );

final healthMonitorVisibilityProvider =
    AsyncNotifierProvider<_VisibilityNotifier, Map<String, bool>>(
      () => _VisibilityNotifier('health_monitor', healthMonitorItemLabels),
    );

class _VisibilityNotifier extends AsyncNotifier<Map<String, bool>> {
  _VisibilityNotifier(this._page, this._labels);

  final String _page;
  final Map<String, String> _labels;
  final _store = const VisibilitySettingsStore();

  @override
  Future<Map<String, bool>> build() =>
      _store.loadPage(_page, {for (final k in _labels.keys) k: true});

  Future<void> toggle(String item) async {
    final current = state.valueOrNull ?? <String, bool>{};
    final visible = !(current[item] ?? true);
    await _store.setVisible(_page, item, visible);
    state = AsyncData(Map<String, bool>.of(current)..[item] = visible);
  }
}
