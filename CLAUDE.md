# Free The Key — CLAUDE.md

Onboarding notes for any Claude Code session working in this repo.

## Game concept

**Free The Key** is a Rush Hour / Unblock Me–style sliding-block puzzle. The
board is a 6×6 grid. Blocks slide only along their axis (horizontal blocks move
left/right, vertical blocks move up/down) and cannot rotate or overlap. One
special **key block** (golden, length 2) sits on the exit row (row index 2, the
`kExitRow` constant). The player drags the other blocks out of the way to open a
lane, then slides the key off the right edge.

- **Win condition:** the key block slides past the right edge (`col + length >
  kGridSize`). There is **no lose condition** — it's a pure puzzle.
- **Scoring:** `moves` counts single-cell slides of *non-key* blocks. 3 stars if
  `moves <= par`, 2 stars within `par + 3`, else 1 star.
- **Genre / tone:** casual minimalist puzzle, dark neon theme. All ages.

## Tech / architecture decisions

- **State management: `ChangeNotifier` + `setState`** (the game was built this
  way before the spec was applied). `GameEngine` is a `ChangeNotifier`;
  `LevelRepository` is a `ChangeNotifier` singleton. We deliberately did **not**
  migrate to Riverpod to avoid a risky rewrite of working code — if a migration
  is ever wanted, the notifiers are the seams to replace.
- **Persistence: `shared_preferences` only.** Progress is simple key/value
  (unlock index, per-level stars, endless best, settings flags), so no
  Hive/sqflite schema was needed. Generated levels are cached as JSON in prefs.
- **App ID prefix:** `com.xufagroup.*` (Android `com.xufagroup.free_the_key`,
  iOS `com.xufagroup.freeTheKey`).

## Folder structure / where things live

```
lib/
  main.dart                    App entry; MaterialApp -> SplashScreen
  core/ (n/a)                  constants live under data/
  data/
    constants.dart             kGridSize (6), kExitRow (2)
    levels_data.dart           kCuratedLevels — 20 hand-authored levels
    level_repository.dart      Source of truth: curated + generated (80 total),
                               caching, and endless-level generation
    progress_service.dart      Unlock state + per-level stars (shared_preferences)
    app_prefs.dart             How-to-play-seen flag + endless best
    sound_service.dart         Procedurally-generated SFX + ambient music,
                               independent persisted toggles
  models/
    block.dart                 Runtime block (mutable position + color)
    level.dart                 BlockConfig + Level (+ JSON serialization)
  logic/
    solver.dart                RushHourSolver — Dijkstra solvability + par
    level_generator.dart       Seeded, solver-verified board generator
    game_engine.dart           Live game state, move rules, star rating, hints
  screens/
    splash_screen.dart         2s white splash, precache + warm repository
    how_to_play_screen.dart    First-launch tutorial (+ replay from Settings)
    home_screen.dart           Play / Levels / Endless + Settings
    level_select_screen.dart   Grid grouped by difficulty, reactive to progress
    game_screen.dart           Gameplay (campaign + endless), hint, banner slot
    settings_screen.dart       Sound/music toggles, replay tutorial, reset
  widgets/
    game_board.dart            Gesture handling + board CustomPaint host
    board_painter.dart         Renders board, blocks, exit arrow, hint glow
    banner_ad_placeholder.dart Reserved adaptive-banner region (placeholder)
  theme/
    app_colors.dart            Palette
assets/images/logo.png         Studio logo (splash + launcher icon source)
```

## Levels: data format & solvability

- A `Level` is `{number, difficulty, par, blocks}`; each `BlockConfig` is
  `{row, col, length, isHorizontal, isKey}`. Positions are grid cells.
- The campaign is **80 levels**: levels **1–3** are the gentle curated tutorial
  (`kCuratedLevels.take(3)` in `levels_data.dart`); levels **4–80** are
  procedurally generated. Those generated levels are **pre-built at dev time**
  by `tool/generate_levels.dart` and shipped as the bundled asset
  `assets/data/campaign_levels.json`, so first launch is instant.
- **The difficulty curve is driven by solver *step* count, not par.** `par`
  counts single-cell slides, so it inflates when a block merely has to travel
  further — which is not what makes a board hard. `LevelGenerator.campaignParams`
  returns a `minSteps`/`maxSteps` band (the number of *decisions* on the optimal
  path): 5→8 decisions over L4–L20, 8→10 over L21–L40, 10→13 over L41–L80, with
  6→13 blocks. `par` is still what the star rating is scored against; it just no
  longer steers generation. Gating on par alone previously shipped a level 5 that
  was solvable in three moves.
- `campaignParams` is the **single source of truth** for the curve — both
  `tool/generate_levels.dart` and `LevelRepository._generateMainSetJson` call it,
  so they can't drift. **If you change it, re-run `dart run
  tool/generate_levels.dart` and bump `_cacheKey`** (currently
  `generated_levels_v4`). `test/campaign_curve_test.dart` re-solves every shipped
  level and fails if any falls outside its band, so a stale asset is caught by
  `flutter test`.
- `LevelRepository` loads that asset; if it's missing/corrupt it falls back to
  generating in a background isolate (`compute`) and caching to
  `shared_preferences` under `_cacheKey`.
- The full curated array (20 levels) still lives in `levels_data.dart`; only the
  first 3 are used in-app, but the rest remain as reference / solver test data.
- **Solvability check (`lib/logic/solver.dart`):** `RushHourSolver.solve()` runs
  a Dijkstra search over board states. Cost model matches the game exactly —
  moving a non-key block one cell costs 1, key moves are free — so the returned
  `minMoves` is an achievable `par`. A state is winning when every exit-row cell
  to the right of the key is empty. Used both to validate curated levels (see
  `test/solver_test.dart`) and to reject/regenerate unsolvable generated boards.
- **Generation (`lib/logic/level_generator.dart`):** places the key, forces at
  least one vertical blocker across the exit row (so boards are never
  pre-solved), fills random non-overlapping blocks (never a horizontal block on
  the exit row), then keeps only boards whose optimal path length falls in
  `[minSteps, maxSteps]` and whose par falls in `[minPar, maxPar]`. The step
  band needs *both* ends: block density alone pushes step count well past any
  floor, which is what made the old curve spiky. Seeded, so a given seed always
  yields the same board.
- **Endless mode:** `LevelRepository.endlessLevel(index)` generates on demand,
  step-banded like the campaign and opening around mid-campaign difficulty (7
  decisions). Progress persists via `AppPrefs.getEndlessBest()`, which is also
  what the home screen uses to **resume** endless where the player left off —
  it is not just a stat.
- **Daily Challenge (retention loop):** `LevelRepository.dailyLevel(date)`
  generates one deterministic mid-tier puzzle per calendar day (seeded by the
  date, so it can't be re-rolled). `lib/data/daily_service.dart` tracks the
  streak — consecutive days completed, reset once a day is missed — plus the
  longest streak, all in `shared_preferences`. The home screen shows a daily
  card with the live 🔥 streak; `GameScreen(mode: GameMode.daily)` plays it.
- **Game modes:** `GameScreen` takes a `GameMode` (`campaign` / `endless` /
  `daily`); `index` is the level or endless index (unused for daily).

## Known placeholders (need real integration later)

- **Banner ad** — `lib/widgets/banner_ad_placeholder.dart` reserves the layout
  space only. To make it real: add `google_mobile_ads`, compute an anchored
  adaptive size, and render an `AdWidget`. Test unit IDs are in that file's doc
  comment. Ads are disabled on Web (`kIsWeb`) per spec; use Google test IDs in
  debug.
- **Hint button** — top-right of `game_screen.dart`. It shows a *stubbed*
  rewarded-ad dialog; on "Watch" it calls `GameEngine.computeHint()` (a real
  solver-backed hint that highlights the next optimal move). Replace the dialog's
  "Watch" branch with a real rewarded ad and reward callback.
- **App-store assets** — launcher icons are configured via
  `flutter_launcher_icons` (`dart run flutter_launcher_icons`) from
  `assets/images/logo.png`. A 1024×500 Play Store feature graphic still needs to
  be produced by hand.

## Commands

```bash
flutter pub get                 # fetch deps
flutter run                     # run on a device/emulator
flutter run -d chrome           # web build (ads auto-disabled)
flutter analyze                 # static analysis
flutter test                    # unit + widget tests (incl. solver_test.dart)
dart run tool/generate_levels.dart   # rebuild the bundled campaign level set
dart run flutter_launcher_icons # regenerate platform app icons from the logo
flutter build apk --release     # Android release
flutter build ios --release     # iOS release
```
