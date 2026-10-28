import '../../l10n/l10n_ext.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/weather_place.dart';
import '../../providers/weather_location_provider.dart';
import '../../widgets/app_widgets.dart';

class WeatherCityPicker extends ConsumerStatefulWidget {
  const WeatherCityPicker({super.key, required this.onSelected});
  final Future<void> Function(WeatherPlace) onSelected;
  @override
  ConsumerState<WeatherCityPicker> createState() => _CityPickerState();
}

class _CityPickerState extends ConsumerState<WeatherCityPicker> {
  final query = TextEditingController();
  List<WeatherPlace>? results;
  bool busy = false;
  @override
  void dispose() {
    query.dispose();
    super.dispose();
  }

  Future<void> search() async {
    if (query.text.trim().length < 2) return;
    setState(() => busy = true);
    try {
      final places = await ref
          .read(weatherLocationActionsProvider)
          .searchCities(query.text);
      if (mounted) setState(() => results = places);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextField(
        controller: query,
        decoration: InputDecoration(
          labelText: context.l10n.cityOrTown,
          hintText: context.l10n.eGHannoverOrPalma,
        ),
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => runUiAction(context, search),
      ),
      const SizedBox(height: 10),
      FilledButton.icon(
        onPressed: busy ? null : () => runUiAction(context, search),
        icon: const Icon(Icons.search, size: 18),
        label: Text(busy ? context.l10n.searching : context.l10n.searchCity),
      ),
      if (results != null && results!.isEmpty)
        Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Text(
            context.l10n.noCitiesFoundTryA,
            style: TextStyle(color: muted, fontSize: 12),
          ),
        ),
      for (final place in results ?? <WeatherPlace>[])
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.location_city_outlined, color: mint),
          title: Text(place.name, style: const TextStyle(fontSize: 12)),
          trailing: const Icon(Icons.chevron_right, size: 18),
          onTap: busy
              ? null
              : () => runUiAction(context, () async {
                  await widget.onSelected(place);
                  if (mounted && context.mounted) {
                    FocusScope.of(context).unfocus();
                    setState(() => results = null);
                  }
                }),
        ),
    ],
  );
}
