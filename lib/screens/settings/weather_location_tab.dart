import '../../l10n/formats.dart';
import '../../l10n/l10n_ext.dart';

import 'package:url_launcher/url_launcher.dart';

import 'weather_city_picker.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/heat_acclimation_provider.dart';
import '../../providers/weather_location_provider.dart';
import '../../services/heat_acclimation_settings.dart';
import '../../widgets/app_widgets.dart';

class WeatherLocationTab extends ConsumerWidget {
  const WeatherLocationTab({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => SheetPage(
    title: context.l10n.weatherLocation,
    child: ref
        .watch(heatAcclimationSettingsProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => DataError(e),
          data: (settings) => _LocationForm(settings: settings),
        ),
  );
}

class _LocationForm extends ConsumerStatefulWidget {
  const _LocationForm({required this.settings});
  final HeatAcclimationSettings settings;
  @override
  ConsumerState<_LocationForm> createState() => _LocationFormState();
}

class _LocationFormState extends ConsumerState<_LocationForm> {
  late final latitude = TextEditingController(
    text: widget.settings.fixedLatitude?.toString() ?? '',
  );
  late final longitude = TextEditingController(
    text: widget.settings.fixedLongitude?.toString() ?? '',
  );
  late HeatLocationMode mode = widget.settings.locationMode;
  bool busy = false;
  String? message;
  @override
  void dispose() {
    latitude.dispose();
    longitude.dispose();
    super.dispose();
  }

  Future<void> save(bool current) async {
    setState(() => busy = true);
    try {
      final actions = ref.read(weatherLocationActionsProvider);
      if (current) {
        final location = await actions.useCurrent();
        if (!mounted) return;
        setState(() {
          mode = HeatLocationMode.current;
          message = context.l10n
              .usingCurrentLocationTostringasfixedTostringasfixed2(
                location.latitude.fixed(4),
                location.longitude.fixed(4),
              );
        });
      } else {
        await actions.saveFixed(latitude.text, longitude.text);
        if (!mounted) return;
        FocusScope.of(context).unfocus();
        setState(() => message = context.l10n.fixedLocationSavedWeatherWill);
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Text(
        context.l10n.chooseTheLocationForThe,
        style: TextStyle(color: muted, fontSize: 13, height: 1.5),
      ),
      const SizedBox(height: 16),
      if (ref.watch(weatherPlaceNameProvider).valueOrNull
          case final String placeName)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              const Icon(Icons.location_on_outlined, color: mint, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  placeName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      SectionCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            ListTile(
              leading: Icon(
                mode == HeatLocationMode.none
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: mint,
              ),
              title: Text(context.l10n.none),
              subtitle: Text(
                context.l10n.disableLocalWeatherAndLocation,
                style: TextStyle(color: muted, fontSize: 12),
              ),
              onTap: busy
                  ? null
                  : () => runUiAction(context, () async {
                      setState(() => busy = true);
                      try {
                        await ref
                            .read(weatherLocationActionsProvider)
                            .useNone();
                        if (mounted) {
                          setState(() {
                            mode = HeatLocationMode.none;
                            message =
                                context.l10n.locationDisabledThePlanWeather;
                          });
                        }
                      } finally {
                        if (mounted) setState(() => busy = false);
                      }
                    }),
            ),
            ListTile(
              leading: Icon(
                mode == HeatLocationMode.current
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: mint,
              ),
              title: Text(context.l10n.currentLocation),
              subtitle: Text(
                context.l10n.followYourDeviceLocation,
                style: TextStyle(color: muted, fontSize: 12),
              ),
              onTap: busy ? null : () => runUiAction(context, () => save(true)),
            ),
            ListTile(
              leading: Icon(
                mode == HeatLocationMode.fixed
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: mint,
              ),
              title: Text(context.l10n.fixedLocation),
              subtitle: Text(
                context.l10n.chooseACityOrEnter,
                style: TextStyle(color: muted, fontSize: 12),
              ),
              onTap: busy
                  ? null
                  : () => setState(() {
                      mode = HeatLocationMode.fixed;
                      message = null;
                    }),
            ),
          ],
        ),
      ),
      if (mode == HeatLocationMode.fixed)
        SectionCard(
          title: context.l10n.chooseCity,
          child: WeatherCityPicker(
            onSelected: (place) async {
              await ref.read(weatherLocationActionsProvider).useCity(place);
              if (!mounted) return;
              setState(() {
                latitude.text = '${place.latitude}';
                longitude.text = '${place.longitude}';
                message = context.l10n.locationSetToName(place.name);
              });
            },
          ),
        ),
      if (mode == HeatLocationMode.fixed)
        SectionCard(
          title: context.l10n.coordinates,
          child: Column(
            children: [
              TextField(
                controller: latitude,
                decoration: InputDecoration(
                  labelText: context.l10n.latitude,
                  hintText: 'e.g. 39.8021',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: longitude,
                decoration: InputDecoration(
                  labelText: context.l10n.longitude,
                  hintText: 'e.g. 3.1191',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: busy
                    ? null
                    : () => runUiAction(context, () => save(false)),
                icon: const Icon(Icons.save_outlined),
                label: Text(context.l10n.saveLocation),
              ),
            ],
          ),
        ),
      if (mode == HeatLocationMode.current)
        OutlinedButton.icon(
          onPressed: busy ? null : () => runUiAction(context, () => save(true)),
          icon: const Icon(Icons.my_location),
          label: Text(context.l10n.refreshCurrentLocation),
        ),
      Wrap(
        children: [
          TextButton(
            onPressed: () => launchUrl(
              Uri.parse('https://open-meteo.com/en/docs/geocoding-api'),
            ),
            child: Text(
              context.l10n.citySearchOpenMeteoGeonames,
              style: TextStyle(fontSize: 9, color: muted),
            ),
          ),
          TextButton(
            onPressed: () =>
                launchUrl(Uri.parse('https://www.openstreetmap.org/copyright')),
            child: Text(
              context.l10n.cityNamesOpenstreetmap,
              style: TextStyle(fontSize: 9, color: muted),
            ),
          ),
        ],
      ),
      if (busy)
        const Padding(
          padding: EdgeInsets.all(16),
          child: LinearProgressIndicator(),
        ),
      if (message != null)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            message!,
            style: const TextStyle(color: mint, fontSize: 12),
          ),
        ),
    ],
  );
}
