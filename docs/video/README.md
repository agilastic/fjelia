# Fjelia website video edits

Edited from the supplied iPhone screen recordings. Original source files are unchanged.

Each clip is provided as VP9 WebM plus H.264 MP4 fallback, 600 × 1030, 24 fps, no audio. MP4 files use fast-start playback. Motion is baked at 0.75× original speed. The website starts previews only when visible and pauses them off-screen.

| Clip | Original recording | Source cuts (seconds) | Export duration | Size |
| --- | --- | --- | --- | --- |
| daily-health.mp4 | ScreenRecording_10-23-2026 16-03-27_1.MP4 | 1.3–8.0 | 9.4s | 518 KiB |
| sleep.mp4 | ScreenRecording_10-23-2026 16-04-22_1.MP4 | 2.1–10.6, 13.1–18.0 | 17.9s | 484 KiB |
| training-load.mp4 | ScreenRecording_10-23-2026 16-05-05_1.MP4 | 2.7–13.0, 29.8–32.2 | 18.9s | 607 KiB |

The iOS recording indicator, status bar, app toolbar and bottom tabs were cropped from the main views. The training graph uses a lower crop that preserves the full chart width and a two-second reading hold. Sleep and training edits join selected sections with a 0.45-second dissolve; each clip returns to its opening frame with a 0.6-second dissolve for looping.

The six original screenshot cards remain available under “Explore six more app screens”; their scroll animation no longer pauses just because the pointer rests over a card.

Autoplay follows visibility even when the OS Reduce Motion setting is enabled, as explicitly requested. A gallery-wide pause/resume control remains available. Off-screen or background-tab videos are paused. Local preview serving must support HTTP byte ranges; GitHub Pages supports these for deployed assets.
