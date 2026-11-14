# HAVEN DHAKA 2026

An original, lightweight 2D sandboarding adventure built with Godot 4.7.2, GDScript, and native Godot scenes. It combines original vector character/environment artwork, layered biome scenery, procedural endless terrain, and generated audio.

## Run on desktop

1. Install Godot 4.7.2 from [godotengine.org](https://godotengine.org/download/windows/).
2. Open Godot and import this folder by selecting `project.godot`.
3. Open the project and press **F5** to play from the main menu.

## Controls

- **Space**: jump; keep holding while airborne to glide.
- **Down**: slide on the ground; start a frontflip in the air.
- **Up**: start a backflip in the air.
- **Left / Right**: steer while airborne.
- **Repeat Up or tap ADD FLIP while airborne**: chain up to three rotations in a trick.
- **Rideable banks**: riding engages automatically on steep generated walls; press **Space** to launch away.
- **E**: activate Echo Vision to reveal hidden crystals and secret paths. Echo uses a regenerating energy bar.
- **Shift**: deploy or stow the wingsuit after unlocking it at **600 m** in one run or **10 lifetime crystals**. Hold **Space** for lift; **Up** pitches up and **Down** dives while deployed.
- **Esc**: pause or resume.
- **Touch/mouse**: on-screen Jump, Slide/Dive, Trick, Wingsuit, Echo, and pause buttons. Hold Jump for flight lift; tap Trick again midair to add a rotation.

The board carries momentum along the ground tangent: downhill gravity accelerates, uphill terrain bleeds speed, and sliding reduces friction. Jump release cuts upward momentum; holding Jump on descent engages a terminal-speed-limited glide. Landings rate both impact into the contacted surface and board alignment. Generated steep banks support physical wall rides with jump-off exits and ride scoring.

The run includes distance, crystals, trick/landing bonuses, wall rides, and combos. Eight environments cycle with blended transitions: Golden Desert, Ancient Ruins, Mountain Valleys, Desert City, Sunset Canyon, Twilight Desert, Moonlit Desert, and Starry Night Mountains. Reaching a new biome persists its world unlock. Layered sky, landmark, and parallax art keeps each biome visually distinct while preserving lightweight Web rendering. Best score/distance, lifetime distance/crystals/tricks, wingsuit unlock, worlds, achievements, and audio settings are stored locally in `user://echo_save.cfg` (versioned with migration and fallback).

The main menu includes a functional tutorial, lifetime journey/achievement panel, settings, and credits. The character sheet now includes a separate animated wingsuit row. The unlocked-world count is shown in journey statistics; there is not yet a manual world-select screen or multiple playable characters.

## Regression test

With Godot 4.7.2 installed, run this from the project directory:

```powershell
godot --headless --path . --script res://tests/smoke_test.gd
```

The test exercises save validation/migration, tutorial/stats/settings/credits, all seven environment names, ground following/momentum, jump/glide/slide, wingsuit deployment/lift/dive/stow, keyboard flips and chained touch double flips, landing awards/combos, generated wall-ride contact and jump exit, Echo reveal/expiry, crystal collection/unlock progression, pause, collision, game over, distance saving, and retry. It is a headless test; it does not verify visual appearance, native audio playback, performance, or browser behavior.

## Web export and GitHub Pages

A ready-to-play HTML5 build is included:

- `export/web/` — the complete browser build (HTML, JS, PCK, WASM).
- `export/haven-dhaka-2026-web.zip` — the same build packaged for sharing. Unzip, serve the folder, and play.
- `serve_web.sh` — convenience server script.

The build uses the single-threaded Web template, so it does **not** require COOP/COEP cross-origin-isolation headers. It still must be served over HTTP; opening `export/web/index.html` with `file://` will not work.

```bash
./serve_web.sh          # http://127.0.0.1:8060/
./serve_web.sh 9000     # custom port
```

Equivalent manual command:

```bash
python3 -m http.server 8060 --bind 127.0.0.1 --directory export/web
```

Then open `http://127.0.0.1:8060/` in a browser. The menu appears after the engine loads; click **RIDE** to start. The first run shows the tutorial.

Verified output (present in `export/web/`):

- `index.html`
- `index.js`
- `index.pck`
- `index.wasm`
- `index.audio.worklet.js`
- `index.audio.position.worklet.js`
- `index.icon.png`
- `index.apple-touch-icon.png`

The exported build was loaded in headless Chromium (Playwright, SwiftShader WebGL) and confirmed to render the menu, start a run from **RIDE**, dismiss the tutorial, accept jump input, and advance to 753 m / 8,930 points in the Ancient Ruins biome with no gameplay console errors. Evidence captures:

- `screenshots/web_menu.png`
- `screenshots/web_gameplay.png`

For GitHub Pages, publish the **contents** of `export/web/` as the site root. Keep the folder structure intact — the build is a file bundle, not a single self-contained `.html` file.

To recreate the export after changing the project:

```bash
~/Downloads/Godot_v4.7.2-stable_linux.x86_64 --headless --path . \
  --export-release "HAVEN DHAKA 2026" export/web/index.html
```

The matching Godot 4.7.2 Web export templates must be installed in `~/.local/share/godot/export_templates/4.7.2.stable/`. The preset intentionally keeps `variant/thread_support` and `variant/extensions_support` disabled and the PWA service worker off.

