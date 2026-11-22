# Training plan generator: recap and rethink

As of 2026-11-22. Review of the code, checked against current research, with an implementation plan (section 6). No planner code was changed for this document.

## 1. What is there

About 15,400 lines in five layers:

| Layer | Files | Lines | Decides |
|---|---|---|---|
| Plan service | `lib/services/training_plan_service.dart` | 3,767 | Entry point, fitness snapshot, weekly templates, day placement, session length, template choice, watch delivery |
| Season | `lib/services/season/*.dart` | 2,213 | Goals (A/B/C), phases, intent per goal and week, the week allocator |
| Workout library | `lib/services/workout_template_library.dart` | 5,226 | 176 workout templates (intervals 58, endurance 44, tempo 37, hills 13, threshold 10, pool swim 10, …); the strength programmes come from `strength_templates.dart` |
| Strength | `lib/services/strength/*.dart` | 3,068 | Programmes by focus and phase, progression proposals, gym mode |
| Adaptation | `session_adaptation_service.dart`, `plan_rebalance.dart`, `missed_workout_planner.dart` | 1,168 | Morning readiness, missed sessions |

### 1.1 Two generators, chosen by the number of goals

`_generatePlan` (`training_plan_service.dart:1471`) picks the path:

- **One goal** → weekly template path. A fixed week per sport (`_weekTemplates`, line 159), phases from `seasonPhase`, session lengths from `_ctlScaledDuration`.
- **Two or more active goals, or one finished within its recovery days** → season allocator (`WeekAllocator`, `season/week_allocator.dart`). The template is not used.

Both paths then share day placement, template choice, steps, ramp test and delivery.

Consequence: adding a C race to a marathon plan switches the whole logic, including long-run length, taper and strength.

### 1.2 Inputs

| Input | Source | Used for |
|---|---|---|
| CTL / ATL / TSB | 42/7-day EWMA of `dayScoreRecords.strainScore` (summed Banister TRIMP since the migration), line 895 | tier (CTL < 35 beginner, ≥ 50 advanced), prepended recovery week (TSB < −20), readiness factor |
| Weekly load | `effectiveLoad` of activities, last 6 weeks | weekly load cap for key sessions |
| History | `_TrainingHistory` (6 / 12 / 52 weeks) | weekly minutes, 4-week peak, per sport longest/median/year-longest session, share of zone 4–5 time |
| Level | self-reported, replaced by data tier once ≥ 12 sessions in ≥ 6 weeks | key sessions, ramp, recovery cycle |
| Zones | stored HR zone floors (Friel %LTHR, or LT1 applied as top of zone 2); else LTHR × 0.76/0.82/0.88/0.92; else age (Tanaka/Gulati × 0.68/0.78/0.86/0.93) | every HR target |
| Readiness | today's HRV / 7-day baseline, sleep score | readiness factor, week 0 only |

### 1.3 Periodisation

`seasonPhase` (`season_timeline.dart:10`), counted from the season anchor:

- taper: last 2 weeks (1 if the plan is shorter than 8 weeks)
- peak: 20 % of the weeks; build: 35 %; base: the rest
- every 4th week of base/build is a recovery week (every 3rd for beginners and age ≥ 50)
- no race: base with recovery weeks, built 29 days ahead

Multi-goal: each goal gets a `GoalIntent` per week (foundation, build, specificPreparation, sharpen, event, recover, unload, maintain, deprioritised) with weights 0.8 / 1.0 / 1.0 / 0.6 / 0.35 / 0.3 / 0.7 / 0.45 / 0.15, times the priority weight (A 1.0, B 0.85, C 0.5). C goals get no block (maintain, sharpen only if ≥ 4 h). Recovery after an event: 1–7 days by duration.

### 1.4 Volume

- Target: the athlete's hours per week.
- Ramp from the last-6-week average: 8 % per week (beginner), 10 % (others), 15 % if the target is within 105 % of last year's best 4-week block. Without history: start at 70 % of the target.
- Single path: recovery and taper weeks ×0.7. Multi path: `budgetFactor` (unload/sharpen 0.7, recover 0.7–0.9, event week 0.75–0.85, after events ≥ 4 h at most 0.75).

### 1.5 Long sessions

| | Single path | Multi path |
|---|---|---|
| Base length | 90 min × CTL factor (0.7–1.3) × tier (0.9–1.1), together 0.6–1.4; ×0.7 in taper and recovery weeks | from the event: foot = race cap × (0.5 + 0.5 × progress); other = `_longPeak` (110 % of a 3 h event falling to 55 % at 8 h; rides ≥ 150 min) × ramp |
| Progression | none in base/build; ×1.4 in peak | grows with progress through the preparation |
| Race cap (foot) | 5k 60, 10k 90, half 120, marathon 180, ultra 600 min; with a target 85 % of it, within 70–120 % of the cap | same |
| History cap | longest of last 12 weeks × (1.12 + 0.05 per week of the current plan run, restarting at every replan; 0.08 towards last year's longest) | same |
| Ultra (≥ 8 h, not foot) | — | regular long = 25 % of event (3–5 h); key long once per block towards 50 % of the event, reached at 75 % of the preparation, never next to another event |
| Per week | two long slots (Sat + Sun) in most templates; trail running one; triathlon a long run Sat and a long ride Sun; beginners one; taper keeps only Saturday's | one long per goal sport, the longest on Saturday |

### 1.6 Intensity

- Hard sessions per week: beginner 1, advanced 2, intermediate = the template's count: 2 in most sports, 1 for hiking, 3 for trail running (Monday intervals, Wednesday hills, Thursday tempo) and triathlon (swim, run tempo, bike tempo).
- Athletes with < 5 % of their heart-rate zone time in zones 4–5 over 12 weeks: one tempo session, held to zone 3, in the first two weeks of a plan run. A run starts at every replan (finding 12).
- Single path templates: running = tempo Z4 Wednesday, intervals Z5 Thursday, two long runs at the weekend, one recovery run, yoga, strength. Hilly race: one tempo becomes hills in build/peak.
- Multi path `_qualityKinds`: base = steady (Z3) alternating with Z5 (bike: threshold); build/peak = race intensity + Z5 (long "finish" goals alternate, late build race intensity only); maintain = race intensity every other week; sharpen = openers, or steady for long events; hiking = hills.
- The week load cap (`weekTss × 1.1`) swaps a key workout for a lighter one; it is the only use of the progression factor and of the readiness factor.
- There is no target for the share of time per zone, and nothing measures it after the week is built.

### 1.7 Taper

- Single: last 2 weeks (1 week in plans shorter than 8 weeks). Only Saturday's long session stays, durations ×0.7, the weekly budget ×0.7 (it only shortens non-long sessions), so volume falls by roughly a third, more where the Sunday long session goes. The key sessions keep their zones. The day before the race is free.
- Multi: `sharpen` intent, budget ×0.7, openers (45 min) or steady for long events, a long session only while ≥ 1 week out.

### 1.8 Strength

| | Single path | Multi path |
|---|---|---|
| Sessions | every chosen strength day: base/build ≤ 3, peak ≤ 2, taper 1, race week 0, recovery core | first two strength days, 45 min each, every week |
| Content | programme by focus (run / trail / bike / full) and phase, A/B alternating. Main lifts: base 3 × 10–12 at RIR 3, build 4 × 4–6 at RIR 2 with 3 min rest, peak 3 × 3–5 at RIR 3 plus jump squats (first main lift, first accessory, core only), taper the two main lifts 2 × 5 plus core. Accessories lighter (base 3 × 12–15, build 3 × 6–8) | generic `strengthFull` template (3 × 8–10), no phase |
| Placement | the athlete's strength days | same |

### 1.9 Daily adaptation

- Morning readiness yellow: every zone one lower and 15 % shorter (or one repetition fewer). Red: a 30-minute easy zone 1 session instead, or no session when readiness says rest.
- Missed sessions: the rules (or the coach, checked against the same limits) propose a move to a later day, a bit easier or indoors on rain where that makes it fit, or dropping it when it is easy or nothing fits. A move never puts two hard sessions on one day, and a hard day next to another costs points. The athlete decides. A replan does not make up skipped sessions.
- Illness/injury absences: no sessions on those days, the first week back has no key or long sessions and at most 45 min a day.
- DFA α1 ramp test about every 28 days, in a rested week, as that week's only hard session.

## 2. What the reread found in the code

These are concrete issues, independent of any research debate.

1. **Planner CTL ignores days without a score row.** `_readFitnessSnapshot` loops over stored rows only (line 895), so a day without a row does not decay CTL/ATL. `DailyReadinessService._computeTsb` and the Form screen (`day_data_provider.dart:806`) walk every calendar day. After a break the planner sees more fitness and a different TSB than the app shows. It also uses `DateTime.now()` instead of `_now()`.
2. **Load units do not match the thresholds.** CTL is built from summed TRIMP, but the tier cut-offs (35 / 50), `isFatigued` (TSB < −20) and `_weeklyTssFactor` are TSS-style numbers. Banister TRIMP is usually higher than TSS for the same session, so athletes are likely labelled advanced sooner. This needs calibrating against real histories.
3. **No rule keeps two hard days apart, in either path.** The running template aims tempo at Wednesday and intervals at Thursday (road cycling, gravel, inline and skiing the same); the allocator aims its first quality session at Wednesday (rides Tuesday) and the second at Thursday. The only spacing cost (line 2326, multi path only) keeps hard sessions off the days next to a long session of about 150 min or more, not next to each other. (Moving a missed session does check hard neighbours; the generator does not.) Whether two hard days end up in a row depends on the settings: in a probe with strength on Wednesday and one session per day, the strength session took Wednesday and no hard pair appeared; strength on another day or two sessions per day was not tested.
4. **Two long sessions every weekend (single path).** Most templates give every non-beginner a long session on Saturday and on Sunday, also for a 5 km goal (trail running has one). With 90 min each that is most of an 8-hour week in two sessions.

    4a. **Three hard sessions for intermediate trail runners and triathletes.** `maxKeySessions` is null for intermediates, so the template count stands: 3 in these two templates, 2 elsewhere.
5. **The single-path long run does not build.** It is 90 min × CTL/tier factor all through base and build, jumps ×1.4 in peak, and is then cut by the history cap. A half and a full marathon get the same long run until the race cap applies. The multi path does build it.
6. **The readiness factor barely acts.** It scales `weekTss`, which is only used for the key-session load cap, in week 0. Durations do not change.
7. **Fallback HR zones disagree with the rest of the app.** Without stored zones but with an LTHR, the planner uses upper bounds of 76/82/88/92 % LTHR. The app's own model (`hr_zone_model.dart`) uses Friel floors of 85/90/95/100 % (running). In the fallback, zone 5 starts at 92 % of LTHR, i.e. below threshold, and zone 2 ends at 82 %.
8. **Strength depends on the path.** Single plans get the periodised programme, multi-goal plans a generic session every week, including taper weeks.
9. **Taper length lives in two places.** `sharpenDays` (A: 14 or 7 days, B: 7 or 4) is only used for C goals and conflicts; A and B tapers come from `seasonPhase` (2 weeks or 1).
10. **Triathlon: one swim a week, and a hard one (single path).** The `triathlon` template has a long run (Sat), a long ride (Sun), run tempo (Wed), bike tempo (Thu), core strength and exactly one swim: a zone 4 key session on Tuesday. No easy or technique swim. Swimming depends on frequency and technique; coach plans give it two to three sessions and about a quarter of the week (a beginner long-distance plan, weeks 1–5: 2:00–2:45 h swimming of 7–9 h). The multi path weights swimming 0.8 (`SeasonTimeline.sportsOf`); how many swims it plans was not checked.
11. **Triathlon long sessions are sized from the whole race (read from the code, not run).** A triathlon goal has one distance and one duration. Without a target time the duration is estimated at running pace over the total distance (`SeasonGoal._typicalSecondsPerMetre` has no triathlon case: 0.36 s/m), so a 226 km long distance counts as about 22 h. The multi path then treats swim and bike as an ultra event (`_ultraLong`: regular long session a quarter of the event, 3–5 h, key session towards half of it) and sizes the long run from the total distance (`maxLongRunMinutes` → category `ultra`, cap 600 min); the single path caps the long run the same way. Only the history caps keep these sessions realistic. A triathlon needs per-discipline demand: each leg's distance and expected time.
12. **Long-event series get almost no high intensity.** Three rules add up (multi path, `_qualityKinds` and `allocate` in `week_allocator.dart`, `easyStart` at `training_plan_service.dart:2044`):
    - *A cautious start that never ends.* With less than 5 % of the zone time of the last 12 weeks in zones 4–5, the first two weeks of a plan run have one quality session, a tempo held to zone 3. The weeks count from the last replan, and a plan is rebuilt whenever goals, the weekly schedule or absences change, the zone time jumps or HRV drops on two nights (the last two at most every 3 days). With frequent replans the start lasts. It also feeds itself: a plan without zone 4–5 keeps the share under 5 %, and 5 % is little for high volume (10 h a week with 30 min of intervals is about 5 %).
    - *Long goals raced to finish.* From 6 h on foot (4 h otherwise) without the ambition "performance", race intensity is a steady session in zone 3; zone 5 comes only every other build week and stops at 70 % of the preparation.
    - *Events take the weeks.* Before an A or B goal the last two weeks (one in a short preparation) sharpen with steady sessions only; the event week has no quality session; the recovery days after it (up to 7) give that goal's sport none, and after an event of 4 h or more the whole week at most one. C goals only "maintain": race intensity every other week. With a long event every one to two months, two to four ordinary weeks remain between them, and only every other one has zone 5.

    Read from the code, not run against a real plan; it matches an athlete's report (an 88 km run, then a long event every one to two months: almost only easy runs and road rides).
13. **A replan restarts the long-session growth.** The history cap grows by 5–8 % per week of the plan run (`weekInRun`), which starts at 0 at every replan. Completed long sessions raise the longest session itself, so the effect is smaller than it looks, but a session that is planned and not yet done no longer counts.

## 3. Against current research

### Keep

| Today | Evidence |
|---|---|
| Planning by event duration, not distance | Physiological demand follows time and climbing |
| Long sessions placed first, ultra key long session once per block | Matches common ultra practice; avoids weekly 50 % sessions |
| Zones anchored on LT1/LT2 (DFA α1 ramp, LT1 as top of zone 2), age formulas only as fallback | Thresholds individualise intensity better than % HRmax |
| Hard sessions capped by level (beginner 1, advanced 2; intermediates see finding 4a) | All successful distributions share a large low-intensity share |
| Strength periodised heavy → explosive (single path) | High-load (≥ 80 % 1RM) training and plyometrics improve running economy (Llanos-Lagos et al. 2024, moderate certainty); submaximal and isometric work less so |
| Morning readiness adjustment | HRV-guided training is at least as good as fixed plans; group benefits are small (SMD ≈ 0.2, n.s.), but there are fewer non-responders (Manresa-Rocamora 2021; Düking 2021) |

### Change

| # | Topic | Today | Evidence | Proposal |
|---|---|---|---|---|
| 1 | **Single-session spikes** | long session up to 12 % above the longest of 12 weeks, plus 5–8 % per plan week | Frandsen et al. 2025 (BJSM, 5,205 runners, 588,071 runs): a run more than 10 % longer than the longest run of the **last 30 days** raised overuse injury rate (HR 1.64 for +10–30 %, 2.28 for > +100 %). Weekly ratios did not explain it. Observational, self-reported injuries. | For foot sports: every session ≤ 110 % of the longest of the last 30 days (planned sessions count once done). Applies to all sessions, not only "long". The sport change of a session already uses such a cap in the target sport (`lib/services/single_session_cap.dart`: 110 % of the longest of 60 days, 60 min without; a 3 h ride had become 160 min of rowing; see `docs/workout-sport-replacement.md`); the planner should use the same function. |
| 2 | **Taper** | 2 weeks, volume about −30 % | Bosquet et al. 2007 (MSSE, 27 studies): best = 2 weeks, volume reduced **41–60 %**, progressively, **intensity and frequency kept**. Confirmed for endurance athletes in a 2023 meta-analysis (PLoS One). | Volume −40 to −60 % over the last 2 weeks (≈ −30 % then −50 %), the same number of sessions, short race-pace or Z5 doses also for long events. |
| 3 | **Intensity distribution** | counts hard sessions only | Polarised vs others: no significant difference overall (Rosenblat et al. 2025, IPD network meta-analysis); polarised slightly better for VO₂peak in shorter interventions (Oliveira et al. 2024). Recreational athletes may do better with pyramidal, competitive ones with polarised (Rosenblat 2025). | Target ≥ 75–80 % of time below LT1 every week; pyramidal for recreational athletes and in base/build, more polarised in the last 4–6 weeks for advanced athletes. Measure planned and done zone time, show it, adjust the next week. |
| 4 | **Weekly ramp / ACWR** | 8–15 % weekly ramp | The 10 % rule has no solid basis; the ACWR has methodological flaws (Impellizzeri et al. 2020) and did not predict injuries in Frandsen 2025 | Keep the weekly ramp as a coarse limit only. Steer by #1 and by readiness. |
| 5 | **Hard-day spacing** | Wed + Thu preferred for hard sessions in both paths, no rule against a hard pair | Common practice: ≥ 48 h between high-intensity sessions; long session counts as a load day | One rule for both paths: no key session the day before or after another key or the long session. |
| 6 | **Strength placement and dose** | athlete's days, regardless of key days; multi path generic | Concurrent-training reviews: strength on hard days (same day, endurance first, hours apart) protects easy days; 2/week to build, 1/week maintains | Same programme for both paths; strength on key days where possible, never the day before the long session; 1 maintenance session in peak and taper. |
| 7 | **Recovery after very long events** | at most 7 days | Muscle damage after marathon/ultra events lasts one to two weeks; little controlled data | Scale beyond 7 h (100 km trail, 400–600 km brevet) to 10–14 days, with climbing and descent as factors. |
| 8 | **Descents for hilly foot races** | hills = uphill | Repeated-bout effect: eccentric loading protects against later downhill damage | Downhill segments or eccentric strength in the build for ≥ 30 m/km courses, stopped 3 weeks before. |
| 9 | **Fixed recovery week** | every 3rd/4th week | Convention; HRV-guided training is about as good | Keep as default; bring it forward after several low-readiness days, allow later when fresh (not for beginners). |
| 10 | **Menstrual cycle** | not modelled | McNulty et al. 2020: trivial average effects, large individual variation | No cycle-based periodisation; let readiness and symptoms act. |

## 4. Target structure

One generator, one rule core.

1. **Retire the weekly-template path.** A single goal is a goal set of one and goes through the allocator. The templates survive only as the per-sport list of what kinds of session exist. This removes findings 4, 4a, 5, 8 and 9 at once; finding 3 needs its own rule in both paths.
2. **Rule core** (pure functions, unit-tested, one place):
   - *Event demand*: duration, climbing, descent, priority, ambition.
   - *Load guard*: 30-day single-session cap (#1), coarse weekly ramp (#4), readiness.
   - *Intensity distribution*: target per phase and level, checked after the week is built (#3).
   - *Spacing*: key/long/strength placement rules (#5, #6).
   - *Taper and recovery curves*: Bosquet parameters (#2), recovery by duration and climbing (#7).
   - *Strength dose*: by phase (#6).
3. **One load model.** One CTL/ATL function for planner, readiness and Form screen (finding 1), in one unit with calibrated thresholds (finding 2).
4. **Feedback loop.** Planned vs done per week (minutes, zone time, longest session) feeds the next week, which is what the planned closed-loop controller needs.

## 5. Order of work

| Step | Change | Size | Why first |
|---|---|---|---|
| 1 | One CTL/ATL function with gap days; recalibrate tiers | small | wrong inputs skew everything else |
| 2 | 30-day single-session cap for foot sports | small | strongest injury evidence |
| 3 | Hard-day spacing in both paths; one long session per week for short goals; at most 2 hard sessions for intermediates | small | clear defects |
| 4 | Taper −40 to −60 %, intensity and frequency kept | small | clear evidence, local change |
| 5 | Fallback LTHR zones from `hr_zone_model.dart` | small | one zone model |
| 6 | Single goal through the allocator; templates retired | large | before adding more rules |
| 7 | Weekly zone distribution target and check | medium | needs one path |
| 8 | Strength placement and phase dose for all plans | medium | |
| 9 | Long-event recovery, downhill work, HRV-shifted recovery week | medium | smaller evidence base |

Intensity in event series (finding 12) is small and comes with step 3: count the cautious start from the season, not from the replan, and judge it by zone time per week rather than share; give ordinary weeks between events at least one quality session, threshold and zone 5 in turn, independent of odd and even weeks.

Triathlon (findings 10, 11) comes before step 6: per-discipline demand from the leg distances, at least two swims a week (one easy or technique), and the hard-session cap of finding 4a.

Each step should come with a plan comparison on a few fixed athlete histories (beginner 10k, intermediate marathon, advanced ultra trail, brevet rider, triathlete), so changes in plans are visible before they ship.

## 6. Implementation plan

Derived from the code read on 2026-11-22; nothing of it is built yet. Each step is measured with the benchmark (step 0) before and after.

**Step 0 – Benchmark (test, not product code).** `test/plan_benchmark/plan_benchmark_test.dart` with fixed athletes: long-event series (an 88 km run, then a long event every one to two months, road bike as second sport), beginner 10 km, intermediate marathon, beginner long-distance triathlete, brevet rider. Per plan week: hours and sessions per sport, longest session per sport, hard sessions (zone ≥ 4), hard days in a row, recovery weeks, taper volume. Prints a table per athlete; asserts only clear rules (no hard days in a row, at least one quality session in ordinary weeks). Ranges from coach plans as in the benchmark section below.

**Step 1 – Intensity in event series (finding 12).**
- `training_plan_service.dart:2044`: count the cautious start from the season anchor (`g < 2`), not from the replan (`w < 2`).
- `_TrainingHistory.mostlyEasy`: judge by zone 4–5 minutes per week (e.g. under 10 min on average over 12 weeks) instead of a share of all zone time.
- `_qualityKinds` (`week_allocator.dart`): foundation threshold and zone 5 in turn instead of steady every other week; build for long finish goals race intensity and zone 5 each week when the hard-session cap allows two, else in turn, and a short zone 5 session every other week after 70 % instead of none; maintain one session every week, threshold and zone 5 in turn. Event, sharpen and recovery weeks stay as they are.

**Step 2 – Clear defects (small each).**
- Hard-day spacing in both paths (finding 3): `bestOffset`/`dist()` keeps a set of hard days and makes the neighbours of a hard or long day expensive, not only in the multi path.
- `PlanAthleteProfile.maxKeySessions`: 2 for intermediates (finding 4a).
- One long session per week for 5k/10k/half goals (finding 4): the Sunday long slot becomes easy.
- Fallback zones from LTHR via `zoneUpperBounds(lthrZoneFloors(...))` (finding 7).
- Multi-path strength by phase via `strengthProgrammeId` after `_slotOf`, counts per phase as in the single path (finding 8).

**Step 3 – One load model (findings 1, 2).** `lib/services/load_model.dart` with one CTL/ATL function that walks every calendar day; used by the planner, `DailyReadinessService`, the Form screen and `form_forecast.dart`. Recalibrate the tiers on real TRIMP histories, or derive the level from weekly hours and training years.

**Step 4 – Single-session cap in the planner (§3 #1, finding 13).** Use `single_session_cap.dart` instead of "+12 % plus 5–8 % per plan week" in `_longWanted` and the single path. The week loop keeps the longest session per sport, seeded from 60 days of history and raised by each planned week; the cap is that × 1.1. `weekInRun` growth goes, so a replan resets nothing. Running stricter: 30 days, every session.

**Step 5 – Taper (§3 #2).** Single path −30 % then −50 % instead of ×0.7, same number of sessions, intensity kept; `budgetFactor` for `sharpen` 0.7 two weeks out and 0.5 in the last week; a short race-pace dose also before long events.

**Step 6 – Triathlon (findings 10, 11).**
- Data: `RaceGoals.legsJson` (schema 72, nullable): per leg sport, distance, optional target seconds and elevation. Room for duathlon, aquathlon and swimrun later. Goals without legs get them inferred from the total distance (standard formats below), so no migration of existing goals is needed.
- Planner: `SeasonGoal.legs`; `GoalDemand` per discipline (leg distance, expected time from the leg target or typical speed); `SeasonTimeline.sportsOf` returns each discipline with its own demand; `_longWanted` uses the leg's demand, so no ultra rule for a 3.8 km swim. `_typicalSecondsPerMetre` gets a triathlon case for the total. At least two swims a week, one easy or technique: in the template and as a minimum in the allocator.
- Goal editor (`race_goal_editor.dart`): when the sport is triathlon, a row of format chips replaces the distance field: Sprint (0.75 / 20 / 5), Olympic (1.5 / 40 / 10), Middle / 70.3 (1.9 / 90 / 21.1), Long (3.8 / 180 / 42.2), Custom. A format fills the three legs, shown as one line ("1.5 km swim · 40 km bike · 10 km run"); Custom opens three distance fields. The total distance is their sum and is not edited directly. One total target time stays the default; "Targets per discipline (optional)" opens swim, bike and run targets plus bike and run climbing. A goal from the race library or Garmin preselects the format whose total is within 10 % of the given distance.
- races.fjelia.com (fjelia-service): today the extractor stores each leg of a triathlon as a race of its own (Triathlon Ingolstadt "SPRINTDISTANZ" as 0.75, 20 and 5 km; BerlinTriathlon "Mitteldistanz" as 1.9 and 19 km), so the typeahead would offer a 0.75 km triathlon. Change: `race.legs` (JSON: sport, distance, climbing per leg) with `distance_km` as their sum; the API returns `legs` for a race and the search hit (`docs/races/openapi.yaml`, `SPEC.md`); the extractor prompt asks for legs of multisport races (triathlon, duathlon, aquathlon, swimrun) and the verify rules check every leg distance on the page; the 14 triathlon/duathlon events are repaired by grouping rows with the same race name into one race with legs.
- The app's library fill (`_fillFromLibrary`, `race_library` client): takes `legs` when the race has them and sets format and legs; without them the format is inferred from the total distance as for older goals. The distance chooser lists one entry per format ("Sprint · 0.75 / 20 / 5 km"), never single legs.
- Onboarding (`training_plan_onboarding_screen.dart`): the same format chips (shared widget), without the custom fields; details later in the editor. The race search in onboarding fills the format from the library like the editor.
- Display: goal cards show the format and legs ("Olympic · 1.5 / 40 / 10 km").
- New texts (format names, leg labels, hint) in all 13 languages.

**Step 7 – One path (§4).** `SeasonPolicy.singleGoalThroughAllocator` routes a single goal through the allocator; benchmark with the switch on and off; then retire the templates.

**Step 8 – Zone distribution (§3 #3).** After a week is built, compute the planned time below LT1 from `WorkoutSemantics`; under 75 %, lengthen easy sessions or shorten a quality one. Later the done zone time feeds the next week (closed-loop controller).

**Step 9 – Readiness factor (finding 6).** Remove it; the morning adaptation does the work.

| Step | Size |
|---|---|
| 0 Benchmark | medium |
| 1 Intensity in event series | small |
| 2 Clear defects | small |
| 3 Load model | small to medium |
| 4 Single-session cap | medium |
| 5 Taper | small |
| 6 Triathlon (data, planner, editor, onboarding) | medium to large |
| 7 One path | large |
| 8 Zone distribution | medium |
| 9 Readiness factor | small |

### Benchmark against coach plans

A test, not product code: fixed example athletes go through the generator, and each plan week is measured against ranges taken from coach plans. A deviation is a prompt to look, not an error; coach plans are practice, not evidence.

| Measure per week | Example range (triathlon, beginner long distance, 8–10 h) |
|---|---|
| Hours per sport and share of the week | swim 20–30 %, bike 35–45 %, run 25–35 % |
| Sessions per sport | swim ≥ 2, bike ≥ 2, run ≥ 2 |
| Longest session per sport | growing with the plan, within the history caps |
| Recovery weeks | every 3rd or 4th week, volume clearly lower, short intensity kept |
| Taper | last 1–2 weeks, volume −40 to −60 %, intensity kept |
| Hard sessions | at most 2, zone time mostly below LT1 |

Example athletes: beginner long-distance triathlete (8–10 h), olympic distance (7–8 h), and the five histories above. References: a commercial beginner long-distance plan (34 weeks: preparation 5, base 16, build 10, race-specific 3; recovery every 3rd week; weeks 1–5 between 7:10 and 9:20 h) and the free DTU/TIME2TRI plans (sprint, olympic, middle distance; not yet looked at in detail). Only aggregate numbers go into the ranges; no coach plan is copied into the app or the repo.

## References

- Frandsen JSB et al. How much running is too much? Identifying high-risk running sessions in a 5200-person cohort study. *Br J Sports Med* 2025;59(17):1203–1210. [PMC12421110](https://pmc.ncbi.nlm.nih.gov/articles/PMC12421110)
- Bosquet L, Montpetit J, Arvisais D, Mujika I. Effects of tapering on performance: a meta-analysis. *Med Sci Sports Exerc* 2007. [PubMed 17762369](https://pubmed.ncbi.nlm.nih.gov/17762369/)
- Effects of tapering on performance in endurance athletes: a systematic review and meta-analysis. *PLoS One* 2023. [PubMed 37163550](https://pubmed.ncbi.nlm.nih.gov/37163550/)
- Oliveira PS et al. Comparison of polarized versus other types of endurance training intensity distribution: systematic review with meta-analysis. *Sports Med* 2024. [PMC11329428](https://pmc.ncbi.nlm.nih.gov/articles/PMC11329428)
- Rosenblat MA et al. Which training intensity distribution intervention will produce the greatest improvements in endurance performance? Network meta-analysis of individual participant data. *Sports Med* 2025.
- Llanos-Lagos C et al. Effect of strength training programs in middle- and long-distance runners' economy. *Sports Med* 2024;54(4):895–932. [PDF](https://repository.essex.ac.uk/37272/1/s40279-023-01978-y.pdf)
- Llanos-Lagos C et al. Effect of strength training on endurance performance in middle- and long-distance runners. *Sports Med* 2024;54(7):1801–1833.
- Manresa-Rocamora A et al. Heart rate variability-guided training: methodological systematic review with meta-analysis. *IJERPH* 2021. [PMC8507742](https://pmc.ncbi.nlm.nih.gov/articles/PMC8507742/)
- Düking P et al. Monitoring and adapting endurance training on the basis of heart rate variability: meta-analysis. 2021.
- Impellizzeri FM et al. Acute:chronic workload ratio: conceptual issues and fundamental pitfalls. *Int J Sports Physiol Perform* 2020.
- Casado A et al. Training periodization, methods, intensity distribution, and volume in highly trained and elite distance runners: a systematic review. *Int J Sports Physiol Perform* 2022.
- McNulty KL et al. The effects of menstrual cycle phase on exercise performance in eumenorrheic women: systematic review and meta-analysis. *Sports Med* 2020.

References without a link were not rechecked online for this document.
