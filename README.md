# Fjelia

Fjelia is a personal training and health app for endurance athletes, written in
Flutter. It combines data from your watch, scale and health sources in one place
and turns it into recovery, sleep, load and training-plan guidance — with an AI
coach that runs **on your device** by default.

> Fjelia is a hobby project. It is **not a medical device** and gives no medical
> advice. See [Disclaimer](#disclaimer).

Website: <https://agilastic.github.io/fjelia/> (source in [`docs/`](docs/); served by GitHub Pages).

## Features

- **Health overview** — recovery, sleep (with stages), strain, energy, HRV,
  resting heart rate, blood pressure, weight and body composition.
- **Training load** — load per week and day, zone polarization, fitness and
  fatigue, race predictions.
- **Training plan** — periodised plans towards a race goal, calibrated on your
  own history (volume, long sessions, intensity) and adapted to daily readiness;
  workouts can be pushed to Garmin.
- **AI coach** — chat and daily briefings. Default: Apple Intelligence
  (on-device, iOS/macOS 26+). Optional: OpenAI, Anthropic, Gemini, Mistral or
  DeepSeek with your own API key.
- **Heat acclimation** with weather data, home-screen widgets, backup and export.
- **Data sources** — Garmin Connect, Polar, Suunto, COROS, Apple Health, Renpho
  scales (Bluetooth), Aktiia and Hilo blood-pressure devices.

## Privacy

Health data is stored locally on the device (SQLite) and credentials in the
system keychain. Nothing is sent to a Fjelia server — there is none. Data goes
only to the services you connect (for example Garmin Connect) and, if you
choose a cloud AI provider, to that provider with your explicit consent before
each message or session. Apple Intelligence runs on the device.

## Requirements

- Flutter (stable channel), Xcode for iOS/macOS builds.
- iOS is the primary target; macOS builds too. Apple Intelligence needs a
  supported device with iOS/macOS 26 or later.

## Build and run

```bash
flutter pub get
flutter run --dart-define-from-file=secrets.json   # see "Build-time credentials"
flutter test
```

Helper scripts are in [`scripts/`](scripts/README.md). Optional per-developer
settings (device, signing team) go in `scripts/local.env` (git-ignored).

## Build-time credentials

Some services identify the *app* with credentials that must not live in a public
repository. They are supplied at build time and never stored in the source:

```bash
cp secrets.example.json secrets.json   # git-ignored; fill in what you have
flutter run --dart-define-from-file=secrets.json
```

| Key | Used for |
| --- | --- |
| `POLAR_CLIENT_ID`, `POLAR_CLIENT_SECRET` | Polar AccessLink (register your own client at <https://admin.polaraccesslink.com>) |
| `RENPHO_AES_KEY` | Renpho cloud |
| `PIRATE_WEATHER_KEY`, `WEATHER_API_KEY` | optional extra weather providers |

A service whose credentials are missing is simply unavailable in that build;
everything else works. Users of a built app always sign in with their **own**
accounts — the credentials above only identify the app.

## Optional service package

Some integrations are not part of this repository. The app depends on the
package `fjelia_service`; this repository contains only a stub of it
(`packages/fjelia_service`), whose features report that they are unavailable.
The interfaces live in `packages/fjelia_service_api`. A build that has a real
implementation replaces the stub with a `pubspec_overrides.yaml` (git-ignored):

```yaml
dependency_overrides:
  fjelia_service:
    path: ../fjelia-service   # your own implementation of the same API
```

Without it everything else works as described above.

## Disclaimer

- **Not a medical device.** Values and recommendations (recovery, readiness,
  blood pressure, training advice) are informational. Talk to a doctor about
  health concerns and before changing your training because of this app.
- **Unofficial integrations.** Several services (Garmin Connect, Suunto, COROS,
  Aktiia, Renpho) are accessed through their apps' undocumented interfaces, which
  can change or stop working at any time and may be subject to those services'
  terms. Fjelia is **not affiliated with, endorsed by or sponsored by** Garmin,
  Polar, Suunto, COROS, Renpho, Aktiia, Hilo or Apple. All trademarks belong to
  their owners. Use at your own risk and with your own accounts only.

## Third-party code

`third_party/foundation_models_framework` is a vendored copy of the
`foundation_models_framework` Flutter plugin with local patches for newer
Xcode SDKs; see its [LICENSE](third_party/foundation_models_framework/LICENSE).
Other dependencies are listed in `pubspec.yaml` under their own licenses.

## License

Fjelia is free software: you can redistribute it and/or modify it under the
terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version (`GPL-3.0-or-later`). It is distributed in the hope that it will be
useful, but **without any warranty**; see [LICENSE](LICENSE).

Copyright (C) 2026 Alex Ebeling-Hoppe.

- **Name and logo.** The GPL covers the code and artwork in this repository. It
  does not grant the right to use the name "Fjelia" or its logo to identify a
  fork or derivative app — please choose your own name and icon.
- **Third-party code and data.** Dependencies keep their own licenses (BSD, MIT,
  Apache-2.0, MPL-2.0; all compatible with GPL-3.0). The app's *Licenses* page
  lists them. The vendored plugin in `third_party/` is MIT-licensed.
