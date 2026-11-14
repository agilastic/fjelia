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

### Persönliche Schätzung

- Aktivitäten der letzten 180 Tage werden nach Sportfamilie ausgewertet.
- Herstellerwerte wie Garmin Training Load oder herstellerspezifische Zonenwerte
  werden nicht direkt miteinander verrechnet.
- Fjelia berechnet die Zeit in Herzfrequenzzonen aus verfügbaren Rohdaten neu,
  anhand der gespeicherten sportartspezifischen Fjelia-Zonen.
- Für eine Aktivität ohne Rohdaten kann der Durchschnittspuls einer Zone
  zugeordnet werden. Das ist eine gröbere Ein-Zonen-Näherung und wird in der
  Vorschau offengelegt.
- Erst ab fünf verwertbaren Aktivitäten der Zielsportart wird die persönliche
  Belastung pro Minute zur Dauerschätzung verwendet. Bei weniger Daten nutzt
  Fjelia eine vorsichtige Sportpaar-Schätzung und weist auf die geringe
  Datenbasis hin.
- Die Lastschätzung nutzt dieselben Fjelia-Zonengewichte wie die geplante
  Trainingslast. Sie ist ein internes Vergleichsmaß, kein validierter Nachweis
  für identischen Trainingseffekt.

### Grobe Startwerte ohne ausreichende Historie

Die folgenden Faktoren sind Ausgangswerte und keine wissenschaftlich
abgesicherten Umrechnungsregeln:

| Wechsel | Startwert für die Dauer |
|---|---:|
| Laufen → Rad | 1,65 × Laufdauer |
| Rad → Laufen | 0,60 × Raddauer |
| Laufen → Crosstrainer | 1,10 × Laufdauer |
| Crosstrainer → Laufen | 0,85 × Crosstrainerdauer |
| Rad → Rudern | 0,75 × Raddauer |
| Rudern → SkiErg | 0,90 × Ruderdauer |
| SkiErg → Rudern | 1,10 × SkiErg-Dauer |

Zum Beispiel ergeben 100 Minuten Rad ohne persönliche Indoor-Rowing-Historie
zunächst ungefähr 75 Minuten Rudern. Mit ausreichender Historie kann Fjelia einen
anderen Wert vorschlagen.

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
