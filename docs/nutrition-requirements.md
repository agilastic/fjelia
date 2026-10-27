# Workout nutrition: plan, record, learn

The workout details show an editable fuelling strategy. History records what
the athlete actually consumed. These are separate records; an empty log never
means zero intake, and a later forecast must not rewrite the planned baseline.

## Requirements

- Cover road cycling, running, trail running, MTB, pool/open-water swimming,
  Nordic classic and skate skiing. Work from duration and intensity, with
  sport-specific opportunities to eat and drink. Prefer recorded elapsed time
  for intake rates, including stops; allow an elapsed-time correction when the
  imported timer or samples omit pauses.
- Show carbohydrate g/h, fluid ml/h and sodium mg/h, session totals, gel and
  bottle quantities, and guidance before, during and after the workout.
  Subtract carbohydrate supplied by drinks before calculating extra gels.
- Personalise product serving sizes, practised carbohydrate tolerance, measured
  sweat rate and sweat-sodium concentration. Higher carbohydrate targets require
  practice; never infer tolerance from fitness, HRV, age or an elite label.
- Use the forecast for the workout's date when available. Display missing
  weather, ascent and altitude honestly. Allow temperature, humidity, wind,
  ascent, altitude and surface overrides. Do not invent a route or infer climbing
  from a race goal. Weather and terrain inform fluid ranges and access/logistics,
  not an invented percentage increase in calories or salt.
- Address technical descents and hands-on riding, aid-station access and carried
  supplies, pool-deck breaks, supported open-water feeds, and frozen bottles /
  gloves in skiing. Encourage safe feeding opportunities and a practised backup.
- Keep targets editable. Do not prescribe fluid in excess of known sweat losses,
  promise prevention of cramps or hyponatraemia, prescribe supplements, or promote
  energy restriction. Report caffeine and protein intake without an automatic
  caffeine prescription.
- In activity history, log products and quantities before/during/after, optional
  minutes into the activity, water, carbohydrate, sodium, caffeine and protein.
  Preserve per-serving values with each entry. Support drafts, explicit no-intake,
  GI comfort, notes, corrections and a completed/declined state.
- Compare actual during-workout rates with a saved plan only when an explicit
  session/activity link exists or the athlete selects a saved strategy. Never
  match two same-day workouts just by date. Completed workout details show only
  an existing snapshot, rather than creating a retrospective plan.
- Send one local reminder after a recently imported endurance activity when the
  intake log remains unfinished. Use the existing notification permission, avoid
  automatic permission dialogs, respect 22:00–08:00 quiet hours, suppress old
  history backfills, cancel on completion/deletion, and support snooze/dismiss.
  A tap opens that activity's intake form after both warm and cold app launches.
  Nutrition reminders must remain independent of HRV sensors and HRV opt-in.
- Store plans, intake and reminder state on-device, with migration and reset
  support. Validate finite, non-negative quantities; keep unknown distinct from
  explicitly entered zero. Do not automatically transmit intake to AI or platforms.

## Related UI changes

PLAN uses a compact seven-day forecast: daily min/max temperature, rain amount,
peak UV (sun intensity), and maximum wind, with a link to the full forecast.
Connected COROS accounts always use workout upload; the experimental opt-in and
its Settings switch are removed, including reliance on old saved false flags.

## Evidence and limits

[AIS carbohydrate guidance](https://www.ausport.gov.au/ais/nutrition/supplements/group_a/sports-foods2/sports-drink/how-and-when-do-i-use-it)
distinguishes brief sessions, small amounts during sustained hard work,
30–60 g/h for endurance sessions, and up to 90 g/h for prolonged exercise with
practised carbohydrate combinations. These are starting ranges, not compulsory
intake. Drink carbohydrate counts toward the same total as food and gels.

[AIS electrolyte guidance](https://www.ausport.gov.au/ais/nutrition/supplements/group_a/sports-foods2/electrolyte-supplements/how-and-when-do-i-use-it)
supports individual fluid/electrolyte planning; measured losses and tolerance take
precedence over weather-based estimates. The app uses conservative editable
starting ranges and identifies unavailable measurements.

Acceptance checks cover product arithmetic, sport/condition differences, unknown
versus zero, persistence and migration, distinct same-day workouts, notification
deduplication/cancellation/deep links, compact phone layouts and legacy COROS flags.
