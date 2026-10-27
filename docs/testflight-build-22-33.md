# TestFlight: What to Test, builds 22 → 33

Build numbers are the git commit count (`scripts/release-ios.sh`), so this
covers commits 23–33 (`ff5f9a4` … `6464f27`). Commit 24 changed only the
website and is not listed. The gym-mode finish fix after the device review is
not part of build 33.

Both texts stay under TestFlight's 4,000-character limit. Button names in the
German text are in English because the app is not translated yet.

## English

```text
NEW: STRENGTH TRAINING
- Open a planned strength workout: exercises, sets, reps, rest and effort replace the heart-rate zones. Check summary, exercise cards and the looping exercise animations (also with Reduce Motion on).
- Edit exercises: add, duplicate, reorder, group as superset/circuit, remove with undo, save, and Save as template.
- "Last time" hints: after logging a workout, the next one suggests your previous loads – tap Use.
- Load suggestions: after two sessions at the top of the rep range with effort (RIR/RPE) recorded, a card offers the next increment. Try Apply, Keep current load and View supporting sets.
- Gym mode: Start workout → record sets with +/−, Done/Partial/Failed/Skip, rest timer (vibration at planned rest), close and resume, finish and complete the planned session.
- Completed strength activities: no distance/pace/route; sets, known volume, estimated 1RM, History chart per exercise; Add exercise details / Log from plan.
- Garmin: Push sends exercises, sets, reps and loads to the watch; sets recorded on the watch are imported at sync. Gym mode + watch recording of the same session should show as ONE activity.
- Polar/COROS: strength is shared as an exercise list, not uploaded.
- Settings → Training: kg/lb unit.

NEW: WORKOUT NUTRITION
- Planned workouts: carbohydrate, fluid and sodium strategy; edit and save.
- History: log what you actually ate/drank during a workout; reminder after the workout.
- Settings → Training: nutrition preferences.

POLAR
- Polar Flow import (exercise data, FIT/TCX) and sync fixes.
- Push planned workouts to Polar Flow (sign-in prompt when needed), update and removal.

PLAN & LOAD
- Completed workouts reconcile with the planned week; 12-week zone history, 5 weeks of polarisation.
- Form chart starts from all available load history.
- Race-date calendar respects your week start.
- PLAN weather: compact seven-day forecast.
- COROS: workout uploads always enabled when connected.
- Health metric cards: better readability.

Please report: crashes, anything that blocks finishing a workout, wrong numbers, layout problems with large text.
```

## Deutsch

```text
NEU: KRAFTTRAINING
- Geplantes Krafttraining öffnen: Übungen, Sätze, Wiederholungen, Pausen und Belastung statt Herzfrequenzzonen. Zusammenfassung, Übungskarten und die Übungsanimationen prüfen (auch mit „Bewegung reduzieren“).
- Übungen bearbeiten: hinzufügen, duplizieren, umsortieren, als Supersatz/Zirkel gruppieren, mit Rückgängig entfernen, speichern, „Als Vorlage speichern“.
- „Letztes Mal“-Hinweise: Nach einem protokollierten Training schlägt das nächste die vorherigen Gewichte vor – „Use“ tippen.
- Gewichtsvorschläge: Nach zwei Einheiten am oberen Ende des Wiederholungsbereichs mit erfasster Belastung (RIR/RPE) erscheint eine Karte mit der nächsten Steigerung. „Apply“, „Keep current load“ und „View supporting sets“ testen.
- Gym-Modus: „Start workout“ → Sätze mit +/− erfassen, Done/Partial/Failed/Skip, Pausentimer (Vibration bei geplanter Pause), schließen und fortsetzen, beenden und geplante Einheit abschließen.
- Abgeschlossene Krafteinheiten: keine Distanz/Pace/Route; Sätze, bekanntes Volumen, geschätztes 1RM, Verlaufsdiagramm pro Übung; „Add exercise details“ / „Log from plan“.
- Garmin: „Push“ sendet Übungen, Sätze, Wiederholungen und Gewichte an die Uhr; auf der Uhr erfasste Sätze werden beim Sync importiert. Gym-Modus + Uhraufzeichnung derselben Einheit sollen als EINE Aktivität erscheinen.
- Polar/COROS: Krafttraining wird als Übungsliste geteilt, nicht hochgeladen.
- Einstellungen → Training: Einheit kg/lb.

NEU: ERNÄHRUNG RUND UMS TRAINING
- Geplante Einheiten: Strategie für Kohlenhydrate, Flüssigkeit und Natrium; bearbeiten und speichern.
- Verlauf: tatsächliche Aufnahme während des Trainings erfassen; Erinnerung nach dem Training.
- Einstellungen → Training: Ernährungseinstellungen.

POLAR
- Polar-Flow-Import (Trainingsdaten, FIT/TCX) und Sync-Korrekturen.
- Geplante Einheiten an Polar Flow senden (Anmeldung bei Bedarf), aktualisieren und entfernen.

PLAN & BELASTUNG
- Abgeschlossene Einheiten werden mit der Planwoche abgeglichen; 12-Wochen-Zonenverlauf, 5 Wochen Polarisierung.
- Formkurve nutzt die gesamte verfügbare Belastungshistorie.
- Kalender für das Wettkampfdatum beachtet den Wochenstart.
- PLAN-Wetter: kompakte 7-Tage-Vorhersage.
- COROS: Trainings-Upload bei Verbindung immer aktiv.
- Gesundheitskarten: bessere Lesbarkeit.

Bitte melden: Abstürze, alles, was das Beenden eines Trainings verhindert, falsche Werte, Layoutprobleme bei großer Schrift.
```
