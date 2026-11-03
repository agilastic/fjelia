# TestFlight: What to Test, build 50

Build numbers are the git commit count (`scripts/release-ios.sh`). This build
follows Release 1.3.0 (build 43, `e732e37`) and covers the app commits
`23c580e`, `d979d6f`, `e6910fa` and `5797ccb`. Website-only commits are not
listed. Both texts stay under TestFlight's 4,000-character limit.

## English

```text
NEW: STRAVA ARCHIVE IMPORT
- + → Import → Strava archive (ZIP), or Settings → System → Activities. Choose the ZIP from strava.com (Settings → My Account → Download or delete your account) as it is, without unpacking.
- Check the preview (activities, photos, duplicates, deleted), then the progress, Cancel and the summary.
- Activities come with route, curves and photos. Run it again: nothing should be added twice. Workouts already synced from Garmin/COROS/Polar get only their missing photos.

ACTIVITIES
- Rename: tap the title in an activity. The name must stay after the next sync; "Use original title" goes back.
- Delete: the activity must not come back after syncing. Undo in the message, or Settings → System → Recently deleted → restore (route and curves are fetched again).
- PLAN list view: swipe left on a past activity to delete, right to ask the coach. Scroll down: older activities load, years back.
- Import FIT, GPX and TCX files (also ZIP) from the share sheet or Settings.
- Photos and videos on activities, race goals and planned sessions; share cards in 15 styles; race season as an image.
- COROS: full route, heart-rate curve, max heart rate and active time.

AI COACH
- Shorter, trainer-like answers, no tables.
- Asking about an activity uses its details, the day, the plan and the sessions around it.
- New chat button top right; question chips in your language.
- The cloud briefing asks for consent only after changing the AI provider or model.

HEALTH & TRAINING
- Waist circumference with history, WHtR and WHR (+ menu).
- Blood pressure: ESH 2023 categories incl. LOW.
- Polar H10 battery in the measurement and in Connections.
- Thresholds overview (LT1, LT2, FTP from all sources) from the LOAD training monitor; DFA alpha1 from beat-to-beat data.
- Germany: DWD weather, rain radar nowcast, sun and moon.
- Planned durations over 60 min as hours and minutes; the PLAN speaks your language throughout.

Please report anything that looks wrong via the feedback button (top of Home).
```

## Deutsch

```text
NEU: STRAVA-ARCHIV IMPORTIEREN
- + → Importieren → Strava-Archiv (ZIP) oder Einstellungen → System → Aktivitäten. Die ZIP von strava.com (Einstellungen → Mein Konto → Account herunterladen oder löschen) so auswählen, wie sie ist, ohne Entpacken.
- Vorschau prüfen (Aktivitäten, Fotos, Duplikate, Gelöschte), dann Fortschritt, Abbrechen und Zusammenfassung.
- Aktivitäten kommen mit Strecke, Kurven und Fotos. Erneut ausführen: Nichts darf doppelt hinzukommen. Schon von Garmin/COROS/Polar synchronisierte Trainings bekommen nur ihre fehlenden Fotos.

AKTIVITÄTEN
- Umbenennen: in einer Aktivität auf den Titel tippen. Der Name muss nach dem nächsten Sync bleiben; „Ursprünglichen Titel verwenden“ setzt zurück.
- Löschen: Die Aktivität darf nach dem Sync nicht zurückkommen. Rückgängig in der Meldung oder Einstellungen → System → Zuletzt gelöscht → wiederherstellen (Strecke und Kurven werden neu geholt).
- PLAN-Listenansicht: vergangene Aktivität nach links wischen zum Löschen, nach rechts für den Coach. Nach unten scrollen: Ältere Aktivitäten laden, auch Jahre zurück.
- FIT-, GPX- und TCX-Dateien (auch ZIP) über Teilen oder die Einstellungen importieren.
- Fotos und Videos zu Aktivitäten, Wettkampfzielen und geplanten Einheiten; Share-Karten in 15 Stilen; Wettkampfsaison als Bild.
- COROS: komplette Strecke, Herzfrequenzkurve, maximale Herzfrequenz und aktive Zeit.

KI-COACH
- Kürzere Antworten wie von einem Trainer, ohne Tabellen.
- Fragen zu einer Aktivität nutzen ihre Details, den Tag, den Plan und die Einheiten drumherum.
- Neuer-Chat-Knopf oben rechts; Frage-Chips in deiner Sprache.
- Das Cloud-Briefing fragt nur nach einem Wechsel von KI-Anbieter oder Modell nach Zustimmung.

GESUNDHEIT & TRAINING
- Taillenumfang mit Verlauf, WHtR und WHR (+ Menü).
- Blutdruck: ESH-2023-Kategorien inkl. NIEDRIG.
- Polar-H10-Akku in der Messung und unter Verbindungen.
- Schwellen-Übersicht (LT1, LT2, FTP aus allen Quellen) im LOAD-Trainingsmonitor; DFA alpha1 aus Schlag-zu-Schlag-Daten.
- Deutschland: DWD-Wetter, Regenradar-Nowcast, Sonne und Mond.
- Geplante Dauer über 60 Min. in Stunden und Minuten; der PLAN spricht durchgehend deine Sprache.

Bitte alles, was falsch aussieht, über den Feedback-Knopf (oben auf Home) melden.
```
