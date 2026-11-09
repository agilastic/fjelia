# Fjelia Aurora: the app's design style

**Fjelia Aurora** is the visual language of Fjelia. The name comes from northern lights over a dark *fjell* (mountain):

- Calm, dark, flat surfaces carry the content.
- Light appears only as accents: a two-colour gradient, a soft glow from the top left, a tinted edge, a glowing orb.

It should feel energetic and young, but never loud or cluttered.

**DarkFjelia** (the default) and **LightFjelia** are the two colour modes of this one style (Settings → Display). Every rule below holds in both modes.

## Principles

1. **Calm base, light accents.** Pages and panels are plain. Colour lives in titles, icons, edges and glows, not in large filled areas. One accent pair per card.
2. **Same building blocks everywhere.** Build from `SectionCard`, `GradientTitle`, `SheetPage` and the theme's buttons. A new screen uses the existing blocks before it adds a new one.
3. **Buttons are standard.** Use the theme's `FilledButton`, `OutlinedButton` and `TextButton`. No custom gradient or glowing buttons. The "fancy" goes into the hero and the cards, never into the controls.
4. **Numbers are the heroes.** Key figures are big and bold (`FontWeight.w900`, tight letter spacing). Labels are small, muted, often upper case.
5. **Motion is short and purposeful.** Things enter with a scale or slide of 200–700 ms (`easeOutBack` / `easeOutCubic`). Nothing moves continuously except a deliberate spinner. A folded card may let its highlights take turns, with a short change every few seconds (the statistics card). Use no `Opacity` over blurred glows, because it trips Impeller; move or scale instead.
6. **Readable in both modes.** Accent colours go through `fjAccent()` for text and lines (on LightFjelia it deepens pale tones). Text uses the `fjInk…` getters, never `Colors.white…`.
7. **Honest.** No decoration that suggests data we do not have. Health findings stay findings (see the medical boundary in `memory.md`).

## Tokens (`lib/theme/fjelia_style.dart`, `lib/widgets/app_widgets.dart`)

| Token | Use |
| --- | --- |
| `fjBackground` | the page (`#111111` / `#F2F4F7`) |
| `fjPanel` / `panel` | cards and sheets (`#202020` / white) |
| `fjMuted` / `muted` | secondary text, hints, inactive icons |
| `fjInk`, `fjInk70` … `fjInk10` | text and lines in both modes |
| `duo(dark, light)` | a colour of its own per mode |
| `fjAccent(c)` | an accent colour used as text or line |
| `fjGlow(accent)` | the soft light from the top left of an accented card |
| `fjEdge(accent)` | the tinted edge of an accented card |
| `mint` (`#00D4A0`) | Fjelia's own green: done, good, primary actions |

### Accent pairs

| Pair | Colours | Where |
| --- | --- | --- |
| `coachGradient` / `planGradient` | violet `#9D7BFF` → cyan `#3EE0FF` | AI coach, FjeliaPro, plan |
| `doneGradient` | mint `#00D4A0` → lime `#C6FF4D` | completed, positive |
| heat / energy | amber `#FFB13D` → yellow `#FFE066` or pink `#FF4D8D` | load, heat, effort |
| pink → violet | `#FF7AD9` → `#9D7BFF` | highlights, memory, social |
| sky | `#6FA8FF` → `#3EE0FF` | weather, water, recovery |

One card gets one pair. A screen should not use more than about three pairs.

## Building blocks

- **`SectionCard(accent: pair)`**: the standard card, `panel` with a 16 radius. With an accent it gets a gradient title, `fjGlow` and `fjEdge`. Without one it is plain.
- **`GradientTitle`**: upper-case section titles in the card's accent pair. A larger size (18–24) for sheet heroes.
- **`SheetPage` / `showAppSheet`**: every detail view is a bottom sheet with a title bar.
- **Hero orb**: a circle filled with the accent gradient, with a soft double glow and a white icon. It scales in once. It is used in the empty coach chat (`_CoachOrb`) and the Pro sheet (`_Hero`).
- **Sky tiles**: weather days as a small painted sky (`WeatherSkyPainter`) with only the figures written on them. The chosen tile gets a gradient edge.
- **Neon tiles**: a figure card with a thin gradient border, a panel inside and a glow (weather detail `_NeonTile`). Use them sparingly, for a grid of 2–4 key figures.
- **Accordion card**: long content folds. Folded, it shows a title, its switches and one line of highlights that take turns. Tap anywhere on it (title, figures, empty space) to unfold, and tap the content again to fold. Switches and chips inside keep their own taps. It unfolds with `AnimatedSize`.
- **Chevron**: every foldable item uses the same chevron, like an `ExpansionTile`. It is `Icons.expand_more` at 26–28 in `fjInk`, centred vertically on the right of the folded item, never a small muted icon next to the chips. It turns half a turn when open. Examples: the season card on the plan, `SportStatsCard` on the LOAD screen.
- **Figures**: no decimals in overview figures; thousands separators; whole hours from 100 h. Long numbers sit two by two, never four in one row.
- **Chips**: glassy chips on painted backgrounds (`white` at 16 % with a 30 % border), plain `ChoiceChip`s elsewhere.

## One look on every tab

STATUS, PLAN, LOAD and COACH look like one app. A card on the LOAD tab must be indistinguishable in its frame, title, figures and controls from a card on STATUS. Only the accent pair and the content differ. The STATUS tab (health monitor, blood pressure) is the reference.

### Page

- Background `fjBackground`. Side gutter 16, 12 between cards, 100 at the bottom for the tab bar.
- The top bar is the same on every tab: menu, the date switch (`< HEUTE >`, the arrows on a 14-radius `fjInk10` square), actions as plain icons.
- Hero figures without a card (the day's gauges on STATUS) only at the top of a tab, once.

### Card (the only frame)

- Always `SectionCard`: `panel`, radius 16, padding 16, `fjEdge` + `fjGlow` of its accent pair, 12 below the title row.
- No own `Material`/`Container` frames, no other radii (12, 13, 14, 20), no `loadSurface`, no coloured `Colors.*Accent` borders.
- A card that folds is still a `SectionCard` (accordion, see below), never an `ExpansionTile` with its own frame.

### Title row

- Left: `GradientTitle` of the card's pair (upper case, 10.5, w900, letter spacing 1.4; `SectionCard(title:, accent:)` draws it). No icon before it and no plain bold title; an icon belongs to a tile, not to the title.
- Middle (optional): `ChoiceChip`s, compact, without checkmark.
- Right, one of:
  - **opens a sheet:** `Icons.chevron_right` as `SectionCard(onTap:)` draws it, in `fjAccent(pair.last)`, top right on the title row (blood pressure);
  - **folds:** `Icons.expand_more`, 28, `fjInk`, centred vertically on the folded card, turning half when open (statistics, season goals).
- The whole card is the tap target, not only the icon.

### Tiles inside a card

- A grid of key values uses the metric tile (`metric_card.dart`): radius 12, a faint tint of its own colour, a 1-px edge of the same colour at 16 %, padding 10–12, 8 apart, two columns (one with large text).
- Tile head: a 26–28 circle in the tint with a 12–14 icon in `fjAccent`, then the label (13–15, w600, `fjInk`).
- Tile value: figure 18–26, w800–w900, `fjInk`; unit after it, 10–13, `muted`; a trend arrow at the right (↓ ↑ in `mint` when good, → `muted` when flat).

### Figures

- **Hero figure** of a card (blood pressure, day load, form): 40–48, w900, letter spacing −1, `fjInk`; unit 14, `muted`.
- **Key figure** (grid, ticker): 20–26, w900.
- **Status word** beside a hero figure (HOCH-NORMAL): upper case, 11, w800, letter spacing 2, in its status colour; the comparison below it ("↑ vs. yesterday") 11, `muted`.
- Small labels (IN RUHE, Ø, SPITZE): upper case, 10, w700, letter spacing 1, `muted`.
- No decimals in overview figures; thousands separators; whole hours from 100 h.

### Colour

- Text: `fjInk`, `fjInk70`, `muted`; accents through `fjAccent`. No `Colors.lightBlue`, `Colors.amber`, `Colors.orange`, `Colors.redAccent` and no new hex values in screens.
- Status colours come from one set: good `mint`, attention amber `#FFB13D`, warning pink `#FF4D8D`, neutral `muted`.
- Charts use the card's pair; the load colours `loadBlue`/`loadRed` stay for the load scales only.

### Shared figure widgets (`lib/widgets/app_widgets.dart`)

Use these instead of writing font sizes in a card:

| Widget | Use |
| --- | --- |
| `KeyFigure(value, unit:)` | a key figure, 24 w900 with its unit in `muted` |
| `KeyFigure.hero(value, unit:)` | a card's hero figure, 44 w900 |
| `StatusWord(word, color:, detail:)` | the status beside a hero figure and its comparison |
| `HeroRow(value:, unit:, status:, statusColor:, detail:)` | hero figure left, status right (blood pressure, day load, form, heat) |
| `FigureLabel(text)` | the small upper-case label above a figure |
| `StatPair(label, value, unit:)` | label above a key figure (grip, body composition, heart rate) |
| `FigureTile` / `FigureGrid` | metric tiles two by two |

`LoadCard` is only a `SectionCard` (with `title`/`onTap`) kept for the LOAD files.

### Status 2026-11-09

All four tabs follow this: STATUS (briefing, blood pressure, heart rate, grip, body composition, sync card), PLAN (season goals and goal cards, plan adjustments, short sessions), LOAD (heat, day load, weekly load, form, monitor, zones, elevation, weekday, plan progress, statistics). Still own frames, by design: the day's gauges at the top of STATUS, the plan timeline entries (dashed planned / filled done) and the coach chat bubbles.

## Reference screens

- **AI coach chat:** the orb, gradient bubbles for the athlete and glowing panels for the coach (`lib/screens/ai_coach/ai_coach_screen.dart`).
- **FjeliaPro sheet:** a hero orb, an accent card for the benefits, plan cards with an accent edge when chosen, and a standard button (`lib/screens/settings/fjelia_pro_sheet.dart`).
- **Weather detail:** sky tiles, a sky hero with a huge temperature and neon figure tiles (`lib/screens/weather/weather_screen.dart`).
- **Plan:** the weather strip, accented section cards and the Pro analyses card (`lib/screens/planner/`).

## Don'ts

- No custom gradient, glowing or pill buttons. Use the theme's buttons.
- No full-screen gradients, rainbow text or more than one sweep gradient per screen.
- No coloured backgrounds behind long text. Long text sits on `panel`.
- No hard drop shadows with an offset. Glows are centred, soft and slightly negative in spread.
- No new hex colours for text. Use `fjInk…`, `muted` or `fjAccent(pair)`.

## Checking a screen

Render it in both modes before shipping. Use the widget-test preview pattern with `FJELIA_UI_PREVIEW_DIR`, or a temporary render test with the system Arial font. Look at it at phone size and with large text.
