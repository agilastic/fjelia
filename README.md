# Fjelia

Fjelia is a personal training and health app for endurance athletes, written in
Flutter. It combines data from your watch, scale and health sources in one place
and turns it into recovery, sleep, load and training-plan guidance — with an AI
coach that prefers **on-device Apple Intelligence** and offers Free AI when
it is unavailable.

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
  when available, otherwise Free AI without a personal API key. Free AI is
  also selectable on supported Apple devices. Optional: [local Qwen3.5 2B or 4B](docs/local-model.md)
  on compatible iPhones (1749 / 3061 MB download), or OpenAI, Anthropic, Gemini,
  Mistral or DeepSeek with your own API key.
  The local 4B option is available on iPhone 18 and newer.
- **Heat acclimation** with weather data, home-screen widgets, backup and export.
- **Data sources** — Garmin Connect, Polar, Suunto, COROS, Apple Health, Renpho
  scales (Bluetooth), Aktiia and Hilo blood-pressure devices.

## Privacy

Health data is stored locally on the device (SQLite) and personal credentials
in the system keychain. Data is shared with the services you connect (for
example Garmin Connect). Cloud AI, including Free AI through
`ai.fjelia.com`, receives your messages and a health/training summary
after your explicit confirmation. Chat asks before each message or session;
Free AI briefings are generated on request after confirmation. Apple Intelligence
and downloaded Qwen models run on the device.
Free AI also sends a random installation ID for usage and spend attribution.
It contains no account or hardware identifiers and is excluded from Fjelia
backup export and restore. Apple platforms keep it in non-synchronizing,
device-only Keychain storage.

## Requirements

- Flutter (stable channel), Xcode for iOS/macOS builds.
- iOS 17 or later is the primary target; macOS builds too. Apple Intelligence
  needs a supported device with iOS/macOS 26 or later. Local Qwen uses MLX on
  compatible iPhones with A14 or newer; see [device requirements](docs/local-model.md#device-requirements).

## Build and run

```bash
flutter pub get
bash scripts/ensure-metal-toolchain.sh            # before iOS builds
python3 scripts/trust-mlx-plugin.py              # once per Mac, before iOS builds
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
everything else works. Personal integrations use the user's **own** account.
The build scripts pass the app's `secrets.json` to Flutter. Free AI access is
provided by the private service package and needs no user account or API key.

Apple Intelligence remains the default when it is available on the device.
Otherwise the coach selects **Free AI**, which is also the first provider in
**Settings → AI & More**. Existing Qwen and cloud provider selections are kept.
Free AI uses the `default` model served by the endpoint; chat and briefings use
the existing cloud data-sharing confirmation before sending health context.
Temporary gateway and connection failures are retried automatically, with up
to three attempts and pauses of one and two seconds.
Chat and all four briefings send the same persisted installation ID as the
top-level `user` field, including on retries. Request logs include this ID so
it can be matched to LiteLLM's end-user records. It is usage attribution, not
proof of a genuine installation; shared-key budgets and rate limits remain
the server-side protection.

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

Free AI credentials belong to the private `fjelia-service` package. Its
`secrets.json` stays ignored there and is compiled into official builds. The
helper scripts also load `../fjelia-service/secrets.json` when present. For a
manual build, pass that file with an additional `--dart-define-from-file`.
The public stub always supplies an empty Free AI credential; the shared key
does not belong in this repository, its example configuration, or user settings.

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
