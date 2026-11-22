# Sportwechsel bei geplanten Workouts

## Zweck

Der Sportwechsel ersetzt eine geplante Einheit durch ein Workout in einer anderen,
möglichst passenden Sportart. Das Trainingsziel und die wichtige Intervallstruktur
sollen soweit möglich erhalten bleiben. Die Umrechnung ist eine Schätzung der
kardiovaskulären Belastung. Sie belegt keine vollständige Gleichwertigkeit von
Technik, Muskelbeanspruchung oder mechanischer Belastung.

## Nutzerablauf

1. In den Details eines geplanten Workouts **Sport ändern** wählen.
2. Fjelia schlägt passende Ersatzsportarten vor und wählt eine sinnvolle Option
   vor. Die Auswahl bleibt änderbar.
3. Eine Vorschau zeigt Sport, geschätzte Dauer, Trainingsziel, Zonen und Schritte
   sowie relevante Hinweise.
4. Der Nutzer bestätigt die Änderung oder kehrt zurück. **Als Ruhe markieren**
   bleibt eine separate, gleichrangige Alternative; „My Choice“ gehört nicht in
   diesen Ablauf, da der Nutzer den Sport bereits im Sportwechsel auswählt.
5. Nach der Bestätigung wird die ursprüngliche Einheit als ersetzt/übersprungen
   kenntlich gemacht. Das Ersatztraining bleibt sichtbar und mit dem Original
   verknüpft.

## Geeignete Ersatzsportarten

Die Zuordnung ist ein Vorschlag für den aeroben Trainingsreiz, keine Aussage über
technische oder muskuläre Gleichwertigkeit.

| Geplante Sportart | Mögliche Ersatzsportarten | Hinweis |
|---|---|---|
| Laufen | Crosstrainer, Rad, Indoor-Rad, Rudern | Laufumfang und mechanische Belastung begrenzen |
| Trailrunning | Laufen, Steigungslaufband, Wandern, Stair Climber | Höhenmeter und Untergrund gehen nicht vollständig über |
| Rad | Indoor-Rad, Laufen, Crosstrainer, Rudern | Individuelle Laufverträglichkeit beachten |
| Schwimmen | Pool, Freiwasser | Technik und Wassergefühl bleiben sportartspezifisch |
| Rudern / Indoor Rowing | Rudern, SkiErg, Rad | Ruder- und SkiErg-Technik unterscheiden sich |
| SkiErg | Langlauf, Rudern, Indoor Rowing, Rad | Oberkörperbelastung kann abweichen |
| Langlauf | SkiErg, Rudern, Rad, Laufen | Schnee, Gelände und Technik gehen nicht über |
| Wandern | Gehen, Trailrunning, Steigungslaufband | Laufbelastung vorsichtig dosieren |
| Gehen | Wandern, lockeres Laufen, Rad | Mechanische Belastung beachten |
| Krafttraining | Krafttraining, Körpergewichtstraining | Nicht durch ein aerobes Workout ersetzen |
| Crosstrainer | Laufen, Rad, Rudern | Nur grobe aerobe Entsprechung |

Gibt es keine geeignete Ersatzsportart, soll Fjelia Ruhe oder eine passende
Alternative empfehlen, statt eine falsche Gleichwertigkeit vorzutäuschen.

## Dauer und Belastung

Stand 22.11.2026: Der Code (`workout_replacement_service.dart`) setzt bisher nur
den Belastungsvergleich unten um; dazu kommt die Grenze beim Wechsel zum Laufen.
Die Grenze für alle Zielsportarten, der Teilersatz und die Aufteilung sind
geplant und noch nicht gebaut.

### Ausgangsproblem

Eine geplante dreistündige Z2-Radfahrt wurde durch 160 Minuten Rudern ersetzt.
Für Herz und Kreislauf war das rechnerisch ähnlich, praktisch nicht: Nach einer
Stunde war der Athlet ermüdet, während drei Stunden auf dem Rad kein Problem
sind. Die Ausdauer der Muskeln, die Technik und die Gewöhnung gehören zur
Sportart. Gleiche Herzfrequenz heißt nicht gleicher Reiz. Grund im Code: Nur der
Wechsel zum Laufen ist begrenzt; für alle anderen Zielsportarten bestimmt allein
der Belastungsvergleich die Dauer (bis 240 Minuten).

### Zwei Größen statt eines Faktors

1. **Belastungsvergleich** (intern): die Dauer im Zielsport für eine ähnliche
   Herz-Kreislauf-Belastung (unten). Sie dient als Vergleichswert und zeigt,
   wie viel der ursprünglichen Einheit ein Ersatz abdeckt.
2. **Empfohlene Dauer**: was im Zielsport realistisch ist. Sie richtet sich nach
   der Historie im Zielsport (unten) und darf deutlich unter dem
   Belastungsvergleich liegen.

Die Vorschau zeigt die empfohlene Dauer. Der Belastungsvergleich erscheint nur
als ein Satz zur Einordnung, wenn er deutlich darüber liegt; keine weiteren
Vergleichsdauern oder Prozentwerte, die eine Genauigkeit vortäuschen, die es
nicht gibt.

**Kein MET-Vergleich.** Die MET-Werte des Compendium of Physical Activities
gelten für absolute Leistungsbereiche und Durchschnittspersonen. Z2 ist eine
relative Intensität (eigene Schwellen und Zonen); bei gleicher relativer
Intensität ist der Energieumsatz pro Minute in beiden Sportarten ähnlich, der
Vergleich ergäbe also etwa die Originaldauer. Fjelia hat bessere Daten:
Herzfrequenz, Leistung und die Zonen je Sportart.

### Belastungsvergleich (umgesetzt)

- Aktivitäten der letzten 180 Tage werden nach Sportfamilie ausgewertet.
- Herstellerwerte wie Garmin Training Load oder herstellerspezifische Zonenwerte
  werden nicht direkt miteinander verrechnet.
- Fjelia berechnet die Zeit in Herzfrequenzzonen aus verfügbaren Rohdaten neu,
  anhand der gespeicherten sportartspezifischen Fjelia-Zonen.
- Für eine Aktivität ohne Rohdaten kann der Durchschnittspuls einer Zone
  zugeordnet werden. Das ist eine gröbere Ein-Zonen-Näherung und wird in der
  Vorschau offengelegt.
- Erst ab fünf verwertbaren Aktivitäten der Zielsportart wird die persönliche
  Belastung pro Minute verwendet: geplante Belastung geteilt durch die typische
  (Median) Belastung pro Minute im Zielsport, zu 35 % gemischt mit dem Wert aus
  der eigenen Ausgangssportart. Bei weniger Daten nutzt Fjelia die Startwerte
  unten und weist auf die geringe Datenbasis hin.
- Die Lastschätzung nutzt dieselben Fjelia-Zonengewichte wie die geplante
  Trainingslast. Sie ist ein internes Vergleichsmaß, kein validierter Nachweis
  für identischen Trainingseffekt.

### Grobe Startwerte ohne ausreichende Historie

Die folgenden Faktoren sind Produktheuristiken, keine wissenschaftlich
abgesicherten Umrechnungsregeln. Sie werden nur ohne ausreichende Historie
genutzt, in der Vorschau so gekennzeichnet und durch die Grenze unten
gedeckelt:

| Wechsel | Startwert für die Dauer |
|---|---:|
| Laufen → Rad | 1,65 × Laufdauer |
| Rad → Laufen | 0,60 × Raddauer |
| Laufen → Crosstrainer | 1,10 × Laufdauer |
| Crosstrainer → Laufen | 0,85 × Crosstrainerdauer |
| Rad → Rudern | 0,75 × Raddauer |
| Rudern → SkiErg | 0,90 × Ruderdauer |
| SkiErg → Rudern | 1,10 × SkiErg-Dauer |
| Schwimmen → Rad | 1,20 × Schwimmdauer |
| andere Paare | 1,15 × Ausgangsdauer |

Zum Beispiel ergeben 100 Minuten Rad ohne persönliche Indoor-Rowing-Historie
zunächst ungefähr 75 Minuten Rudern; mit der geplanten Grenze ohne Historie
werden daraus höchstens 60 Minuten.

### Grenze im Zielsport (geplant)

Die empfohlene Dauer ist höchstens:

- **110–120 % der längsten Einheit im Zielsport in den letzten 30–60 Tagen**,
- **etwa 45–60 Minuten ohne solche Historie**,
- beim Wechsel zum Laufen zusätzlich wie bisher höchstens 60 Minuten und 75 %
  der ursprünglichen Dauer.

Das ist eine vorläufige, vorsichtige Heuristik, keine validierte
Sicherheitsregel. Sie folgt dem Befund von Frandsen et al. 2025 (BJSM, 5.205
Läufer): Eine einzelne Einheit, die mehr als 10 % über der längsten der letzten
30 Tage liegt, erhöht das Risiko einer Überlastungsverletzung. Die Studie betrifft
nur das Laufen; für andere Sportarten ist die Grenze eine Übertragung und wird
später kalibriert (siehe Validierung). Der Trainingsplan deckelt lange Einheiten
nach demselben Prinzip; beide sollen dieselbe Funktion nutzen
(`docs/training-plan-rethink.md`, Abschnitt 3, Punkt 1).

### Teilersatz und Aufteilung (geplant)

Liegt der Belastungsvergleich deutlich über der empfohlenen Dauer, ersetzt der
Wechsel die Einheit nur teilweise. Die Vorschau sagt das und bietet an:

1. **Aufteilen:** die empfohlene Dauer im Zielsport plus der Rest in der
   ursprünglichen Sportart, auch indoor (Rad → Indoor-Rad, Laufen →
   Laufband). Der Rest ist die ursprüngliche Dauer mal dem Anteil, den der
   Ersatz nicht abdeckt.
2. **Kürzer trainieren:** nur die empfohlene Dauer im Zielsport.
3. **Als Ruhe markieren**, wie bisher.

Was nicht trainiert wird, gilt nicht als erledigt und wird nicht automatisch auf
andere Tage oder Sportarten verschoben.

Eine lange Ausdauereinheit (zum Beispiel die lange Radfahrt für ein Brevet) ist
in keiner anderen Sportart vollständig ersetzbar: Allgemeine aerobe Ausdauer
überträgt sich teilweise, Muskelausdauer und Technik der Sportart nicht. Bei
solchen Einheiten schlägt Fjelia die Aufteilung zuerst vor.

### Beispiel: 180 Minuten Rad Z2 → Rudern

| | |
|---|---:|
| Geplante Radfahrt | 180 min Z2 |
| Belastungsvergleich Rudern | etwa 160 min |
| Längste Rudereinheit der letzten 60 Tage | 55 min |
| Empfohlene Dauer (Grenze 110 %) | 60 min Rudern Z2 |
| Abgedeckt | etwa 60 / 160 ≈ 40 % |
| Aufteilung | 60 min Rudern + etwa 110 min Rad (oder Indoor-Rad) Z2 |
| Kürzer | nur 60 min Rudern |

Vorschautext:

> **60 Minuten Rudern Z2.** Deine längste Rudereinheit der letzten 60 Tage
> dauerte 55 Minuten. Für eine ähnliche Belastung wie die Radfahrt wären etwa
> 160 Minuten nötig; das ist für deine Rudermuskulatur zu viel auf einmal. Die
> lange Radausdauer wird nur teilweise ersetzt.
> [60 min Rudern + 110 min Indoor-Rad] [Nur 60 min Rudern] [Als Ruhe markieren]

Die Zahlen sind ein Beispiel für die Regel, keine validierte Einzeldosis.

### Validierung

1. Die Herzfrequenzbelastung je Sportart und Intensität auf stimmige Zonen und
   Messqualität prüfen.
2. Die Grenzen mit echten Daten kalibrieren: Rückmeldung nach dem Ersatz
   (Anstrengung, Beschwerden, Erholung am nächsten Tag).
3. Sonderfälle testen: keine Historie, seltene Sportart, lange Z2-Einheit, hohe
   Intensität, Rückkehr nach Pause, SkiErg und Rudern.
4. Erst wenn Ersatzvorschläge über längere Zeit gut vertragen werden, lässt sich
   etwas über die Güte der Regel sagen.

## Workout-Schritte und Intervalle

- Einheiten ohne harte Intervalle können proportional auf die geschätzte
  Zieldauer angepasst werden; die Trainingszone bleibt dabei erhalten.
- Wiederholte Belastungsintervalle und ihre Erholungsabschnitte bleiben in ihrer
  vorgesehenen Dauer erhalten. Sie werden nicht blind mit einem gemeinsamen
  Faktor verkürzt oder verlängert.
- Ist die Zieldauer länger als die konvertierte Schrittfolge, ergänzt Fjelia
  einen separaten lockeren Z2-Block vor dem Auslaufen. Die Intervallstruktur
  bleibt unverändert.
- Ist die Zieldauer kürzer, werden nur lockere Schritte außerhalb der
  Wiederholungsgruppe angepasst. Ein- und Auslaufen werden dabei mindestens
  fünf Minuten lang gehalten.
- Reicht das Kürzen der lockeren Abschnitte nicht, um die Zieldauer zu erreichen,
  bleibt die Intervallstruktur erhalten. Die Vorschau zeigt die tatsächlich
  längere Dauer und erklärt den Grund.
- Beim Wechsel zu Laufen gilt eine strengere Grenze: höchstens 60 Minuten und
  höchstens 75 % der ursprünglichen Dauer. Passt die Intervallstruktur nicht
  darunter, schlägt Fjelia stattdessen einen lockeren Lauf innerhalb der Grenze
  vor und weist darauf hin.
- Distanzschritte werden anhand einer groben Zielsport-Pace in Zeit umgewandelt.
  Sportartspezifische Pace- und Leistungsziele werden entfernt; die Zonen und
  Wiederholungsgruppen bleiben soweit unterstützt erhalten.

### Beispiel

Eine 60-minütige Radeinheit besteht aus:

- 10 Minuten Einrollen in Z2
- 5 × (4 Minuten Z4 + 3 Minuten Z2)
- 15 Minuten Ausrollen

Die Schritte ergeben 60 Minuten. Ergibt die Belastungsschätzung für Indoor
Rowing 45 Minuten, bleiben die 35 Minuten der fünf Belastungs- und
Erholungsblöcke erhalten. Ein- und Ausrollen werden auf je fünf Minuten
verkürzt. So bleibt die Qualität der Intervalle erhalten, während der Umfang
der lockeren Abschnitte angepasst wird.

## Sicherheits- und Planhinweise

Die Vorschau berücksichtigt und markiert, soweit Daten verfügbar sind:

- Laufbegrenzung und lange Laufeinheiten
- Wettkampf-, Taper- und Schlüsseltraining
- weitere harte Workouts innerhalb von 72 Stunden
- geplante Wochenbelastung
- jüngste Belastung im Vergleich zu den vorherigen sieben Tagen, nur bei
  ausreichender HR-Datenabdeckung
- zuletzt gespeicherte Erholung
- Unterschiede bei Schwimmtechnik sowie Kraft- und Ausdauertraining

Warnungen ändern andere Einheiten nicht automatisch. Der Nutzer prüft die
Vorschau und bestätigt die Ersetzung selbst.

## Grenzen und ehrliche Darstellung

- Es gibt keinen universellen, wissenschaftlich bewiesenen Faktor, der etwa
  Rad-, Lauf- und Ruderzeit vollständig gleichsetzt.
- Herzfrequenzzonen helfen, den kardiovaskulären Reiz innerhalb von Fjelia
  vergleichbar zu schätzen. Sie bilden Technik, lokale Muskelermüdung,
  Stoßbelastung und Bewegungsökonomie nicht vollständig ab.
- Fehlende Schwellen oder Herzfrequenzdaten verringern die Aussagekraft.
- Ein langer Lauf, ein wettkampfspezifisches Workout, Schwimmtechnik und
  Krafttraining lassen sich nicht vollständig durch eine andere Sportart
  ersetzen.
- Die App sollte von **geschätzter ähnlicher Herz-Kreislauf-Belastung** sprechen,
  nicht von wissenschaftlich exakter Gleichwertigkeit.

## Implementierungsorte

- Berechnung, Sportfamilien, Warnungen und Schrittanpassung:
  `lib/services/workout_replacement_service.dart`
- Vorschau und Bestätigung im Trainingsplan:
  `lib/screens/planner/plan_session_sheet.dart`
- Zonen-basierte Trainingslast:
  `lib/providers/training_load_provider.dart`
- Sportartspezifische Herzfrequenz-Zonen:
  `lib/services/athlete_thresholds_service.dart`
- HR-Rohdaten zu Zeit-in-Zone:
  `lib/services/hr_zone_model.dart`
