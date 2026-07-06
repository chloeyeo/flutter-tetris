# Codebase Concerns

**Analysis Date:** 2026-07-06

## Tech Debt

**Monolithic game state/widget class:**
- Issue: `_GameBoardState` in `lib/board.dart` (769 lines) owns game logic (collision, line clearing, piece spawning), gesture/touch DAS math, ad lifecycle, sound triggering, skin persistence, and the entire UI tree in one `State` class. There is no separation between game engine and presentation layer.
- Files: `lib/board.dart`
- Impact: Any change to game rules risks breaking UI rendering or gesture handling and vice versa. Impossible to unit test game logic (`checkCollision`, `clearLines`, `checkLanding`, `rotatePiece`) without spinning up a full widget tree via `flutter_test`.
- Fix approach: Extract a plain-Dart `GameEngine`/`GameController` class (board state, collision, scoring, line clearing, piece bag) with no Flutter/widget dependencies, tested independently. Keep `_GameBoardState` as a thin view that reads from and dispatches to the controller.

**Inline magic numbers for touch/gesture tuning:**
- Issue: DAS (delayed auto-shift) constants are hardcoded inline: `_moveThreshold = 20.0`, initial `_horizontalMoveDelay = 100`, acceleration formula `max(35, 100 - (_consecutiveHorizontalMoves * 20))`, vertical soft-drop threshold `60.0`, and hard-drop flick velocity `500` in `onVerticalDragEnd`.
- Files: `lib/board.dart:67-72`, `lib/board.dart:606-662`
- Impact: Tuning touch feel requires editing deep inside gesture callback bodies; no single place to adjust game feel; values are duplicated/recomputed rather than named constants.
- Fix approach: Extract these into a `TouchConfig`/`DasConfig` class or `values.dart` constants with descriptive names (e.g., `dasInitialDelayMs`, `dasMinDelayMs`, `hardDropFlickVelocity`).

**Mutable "constant" board dimensions:**
- Issue: `rowLength` and `colLength` are declared as mutable top-level `int` variables (not `const`/`final`) in `lib/values.dart:3-4`.
- Files: `lib/values.dart`
- Impact: Any code path (including test code or a future feature) can reassign `rowLength`/`colLength` at runtime, silently corrupting board math (`checkCollision`, `clearLines`, ghost-piece calculation, and all `position % rowLength` arithmetic in `lib/piece.dart` and `lib/board.dart`) with no compiler protection.
- Fix approach: Change to `const int rowLength = 10;` / `const int colLength = 20;`.

**Repeated game-board reconstruction logic:**
- Issue: The `List.generate(colLength, (i) => List.generate(rowLength, (j) => null))` board-initialization expression is duplicated between the field initializer and `resetGame()`.
- Files: `lib/board.dart:33-39`, `lib/board.dart:258-264`
- Impact: Low risk, but any change to board shape/init (e.g., adding garbage rows) must be updated in two places or they'll drift.
- Fix approach: Extract a `_createEmptyBoard()` helper method.

## Known Bugs

**iOS ad initialization will crash the app:**
- Symptoms: On iOS, `AdService().init()` in `lib/main.dart:11` calls `MobileAds.instance.initialize()`, and `_loadBannerAd()` in `lib/board.dart:106` reads `_adService.bannerAdUnitId`. The getter in `lib/ad_service.dart:19-25` and `:27-33` explicitly does `if (Platform.isAndroid) { ... } else { throw UnsupportedError('Unsupported platform'); }` for both banner and rewarded ad unit IDs.
- Files: `lib/ad_service.dart:19-33`, `lib/main.dart:11`, `lib/board.dart:106-122`
- Trigger: Running the app on iOS (simulator or device) — the rewarded/banner ad path throws an uncaught `UnsupportedError` the first time a skin unlock or banner load is attempted (banner load happens automatically 5 seconds after launch via the `Future.delayed` in `initState`).
- Workaround: None currently implemented; iOS is effectively unsupported despite the project including a full `ios/` platform folder (Xcode project, `Runner.xcworkspace`, `RunnerTests`).

**Missing iOS AdMob App ID:**
- Symptoms: `ios/Runner/Info.plist` has no `GADApplicationIdentifier` key. The Google Mobile Ads iOS SDK requires this key to be present or it will assert/crash on `MobileAds.instance.initialize()`.
- Files: `ios/Runner/Info.plist`
- Trigger: Any iOS launch, since `AdService().init()` runs unconditionally in `lib/main.dart` before `runApp`.
- Workaround: None. Combined with the `UnsupportedError` above, iOS builds are non-functional for ads and likely crash at startup or on first ad load.

**Potential crash on corrupted/unexpected SharedPreferences skin value:**
- Symptoms: `_loadSettings()` reads `unlocked_skins` as a `List<String>` and maps each entry via `SkinType.values.firstWhere((s) => s.name == e)` with no `orElse`.
- Files: `lib/board.dart:97-98`
- Trigger: If persisted skin names ever fall out of sync with the `SkinType` enum (e.g., a skin is renamed/removed in a future update, or storage is corrupted/tampered), `firstWhere` throws `StateError: No element` during `initState`, crashing the app on launch with no recovery path.
- Workaround: None currently; app would need reinstall/data clear to recover.

**Test suite does not test the application:**
- Symptoms: `test/widget_test.dart` is the unmodified Flutter "counter app" boilerplate. It calls `tester.pumpWidget(const MyApp())` (which now boots the real Tetris `GameBoard`), then asserts `find.text('0')` exists and taps `find.byIcon(Icons.add)` — neither of which exist in the Tetris UI.
- Files: `test/widget_test.dart`
- Trigger: Running `flutter test`.
- Workaround: None; the test will fail (or at best pass vacuously if pump/timeout behavior swallows the missing-widget failure) and provides zero real coverage. This is the only test file in the entire repository.

## Security Considerations

**Test AdMob IDs hardcoded in source, no environment separation:**
- Risk: `lib/ad_service.dart:21` (banner) and `:29` (rewarded) hardcode Google's publicly documented *sample/test* ad unit IDs (`ca-app-pub-3940256099942544/...`), and `android/app/src/main/AndroidManifest.xml:38` hardcodes Google's sample test App ID (`ca-app-pub-3940256099942544~3347511713`).
- Files: `lib/ad_service.dart`, `android/app/src/main/AndroidManifest.xml`
- Current mitigation: None — there is no build-flavor/environment split between debug and release ad unit IDs.
- Recommendations: Before any production release, real AdMob App ID and ad unit IDs must replace the test IDs (AdMob policy prohibits shipping test ads to real users, and test IDs generate no revenue). Introduce environment-based configuration (e.g., `--dart-define` flags or flavor-specific files) so debug builds automatically use test IDs and release builds use production IDs, preventing accidental test-ID shipping or real-ID use during development.

**No secrets present, but no secrets management pattern established:**
- Risk: The project currently has no `.env` files or credential files (verified: none found in repo). If real AdMob keys, analytics keys, or a backend API key are added later, there is no established pattern (e.g., `--dart-define`, `flutter_dotenv`, platform-specific secrets files) for keeping them out of source control.
- Files: N/A (absence of pattern)
- Current mitigation: `.gitignore` does not currently list any env/secret file patterns.
- Recommendations: Establish a secrets-handling convention now (e.g., dart-define-based config passed at build time) before adding any real API keys, so the pattern is in place rather than retrofitted.

## Performance Bottlenecks

**Full-board rebuild driven by `Timer.periodic` + `setState` every tick:**
- Problem: `gameLoop()` in `lib/board.dart:192-220` runs `clearLines()`, `checkLanding()`, `checkCollision()`, and a piece move all inside a single `setState` on every timer tick (as fast as 800ms at slow start, presumably faster as difficulty could increase). This triggers a full rebuild of the `GridView.builder` (200 cells: `rowLength * colLength` = 10*20) each tick, plus recomputation of `getGhostPosition()` once per `build()` in the `LayoutBuilder`.
- Files: `lib/board.dart:192-220`, `lib/board.dart:663-667`
- Cause: No `RepaintBoundary` isolation per cell, no memoization of unchanged cells, and ghost-position simulation (`getGhostPosition()` at `lib/board.dart:389-414`) re-walks the board from the current piece position down to the floor on every single `build()` call (including ones triggered by unrelated state changes like ad-loaded or gesture updates).
- Improvement path: Wrap individual `Pixel` cells in `RepaintBoundary` if profiling shows jank; only recompute ghost position when `currentPiece.position` or `gameBoard` actually changes (cache and invalidate) rather than unconditionally each build.

**Gesture handler performs `DateTime.now()` and per-pixel-delta math on every `onPanUpdate` callback:**
- Problem: `onPanUpdate` in `lib/board.dart:606-656` calls `DateTime.now()`, `difference().inMilliseconds`, multiple accumulator comparisons, and conditionally triggers `setState` + `HapticFeedback.selectionClick()` on every raw pointer-move event (which can fire at high frequency, e.g., 60-120Hz on modern touchscreens).
- Files: `lib/board.dart:606-656`
- Cause: No throttling/debouncing of the raw pointer stream before accumulator logic runs.
- Improvement path: Acceptable at current complexity given the accumulator pattern already gates actual `setState` calls behind thresholds, but if jank is observed on lower-end devices, consider using `Ticker`-based sampling instead of per-event `DateTime.now()` calls.

## Fragile Areas

**Piece rotation wall-kick table (`lib/piece.dart:248-270`):**
- Files: `lib/piece.dart`
- Why fragile: The wall-kick offsets (`[1, -1, rowLength, -rowLength, 2, -2]`) are a simplified custom approximation of SRS (Super Rotation System), not the official kick tables. A code comment even flags uncertainty: `"Down (actually push up if we check negative rowLength, but wait)"` (`lib/piece.dart:257`). Because `position` is a flat `List<int>` index into a single-dimensional board array, any kick offset that crosses a row boundary incorrectly (e.g., near left/right walls) can wrap a piece to the opposite side of the board without being caught, since wraparound is only explicitly checked in `piecePositionIsValid` via the `firstColOccupied && lastColOccupied` heuristic — which itself can misfire for legitimately-valid positions that touch both edges only coincidentally in future board sizes.
- Safe modification: Any change to `rowLength`/`colLength` or to the kick offsets must be manually re-verified against all 7 piece types x 4 rotation states x near-wall positions; there is no automated test coverage for rotation correctness.
- Test coverage: None. Zero unit tests exist for `Piece.rotatePiece`, `checkCollision`, `clearLines`, or any board logic.

**Flat 1D index arithmetic for a 2D board throughout `piece.dart` and `board.dart`:**
- Files: `lib/piece.dart` (all `position[i] +/- rowLength` and `+/- 1` arithmetic), `lib/board.dart:279-306` (`checkCollision`), `lib/board.dart:389-414` (`getGhostPosition`)
- Why fragile: Row/column are derived from a flat index via `(position / rowLength).floor()` and `position % rowLength` repeated independently in at least 4 places (`checkCollision`, `checkLanding`, `getGhostPosition`, `Piece.positionIsValid`) rather than a single shared utility function. Negative modulo handling (`if (col < 0) col += rowLength;`) is manually repeated at each call site — a comment in `README.md` even calls out this exact class of bug ("Collision Detection Math... required a deep understanding of how Dart handles arithmetic versus traditional C-style languages") as a past source of difficulty.
- Safe modification: Any new code that reads piece/board positions must remember to replicate this exact row/col/negative-modulo pattern; a missed negative-modulo correction anywhere will silently misplace pieces near column 0.
- Test coverage: None.

**`SharedPreferences`-based skin persistence with no schema versioning:**
- Files: `lib/board.dart:90-100`, `lib/board.dart:134-149`
- Why fragile: Skin unlock state is stored as a raw `List<String>` of enum names (`unlocked_skins`) with no version tag. Renaming or removing a `SkinType` enum value in the future (see "Known Bugs" above) will throw at load time for existing installs with no migration path.
- Safe modification: Any enum rename/removal in `lib/skins.dart` `SkinType` requires a data migration; currently none exists.
- Test coverage: None.

## Scaling Limits

**Board dimensions and difficulty curve are effectively static:**
- Current capacity: Fixed 10x20 board (`rowLength`/`colLength` in `lib/values.dart`); game loop starts at a flat 800ms tick (`lib/board.dart:184`, `:168`) with no visible difficulty-scaling logic tied to score/level in the reviewed code path (frame rate is only ever set to the same 800ms constant in `startGame()` and after returning from the skin gallery).
- Limit: There is no level-based speed-up system implemented yet, meaning long-term engagement/difficulty progression (a core Tetris expectation) is currently absent from the gameplay loop as read.
- Scaling path: Introduce a level counter derived from `currentScore` (or lines cleared) that reduces the `Timer.periodic` duration, likely requiring `gameLoop()` to be re-invoked with a shorter `Duration` as thresholds are crossed.

## Dependencies at Risk

**`google_mobile_ads: ^8.0.0`:**
- Risk: Google Mobile Ads SDK undergoes frequent breaking changes across major versions and periodically deprecates/changes initialization requirements (e.g., adding mandatory `Info.plist`/manifest keys). Combined with the current iOS misconfiguration (missing `GADApplicationIdentifier`), any SDK upgrade is likely to surface further platform-specific setup gaps.
- Impact: Ad monetization (banner + rewarded unlock flow) is the primary monetization path and is currently Android-only and test-ID-only.
- Migration plan: Complete iOS setup (App ID in `Info.plist`, App Tracking Transparency consent handling for iOS 14.5+) before attempting any SDK version bump or iOS release.

**`audioplayers: ^6.1.0`:**
- Risk: Lower risk; used narrowly through a single `SoundService` wrapper (`lib/sound_service.dart`) with try/catch around playback, so failures are already contained.
- Impact: Sound is cosmetic (landing/clear cues for 2 of 5 skins only); failures are silently swallowed via `debugPrint`, so a broken audio path would not surface to QA/analytics.
- Migration plan: No urgent action; consider surfacing audio failures to a lightweight analytics/logging channel instead of only `debugPrint` if sound becomes a core feature.

## Missing Critical Features

**No pause/resume control exposed to the player:**
- Problem: The game is only paused programmatically when navigating to the Skin Gallery (`timer?.cancel()` in `_openSkinGallery()`, `lib/board.dart:126`) and resumed on return. There is no explicit pause button, so backgrounding the app (e.g., switching apps, receiving a call) does not appear to pause `Timer.periodic`, though Flutter typically suspends timers when the app is backgrounded — this relies on OS/engine behavior rather than an explicit `AppLifecycleState` listener.
- Blocks: Players cannot intentionally pause a game in progress; no `WidgetsBindingObserver` is registered in `_GameBoardState` to explicitly handle `AppLifecycleState.paused`/`resumed`, meaning behavior on backgrounding relies entirely on implicit engine/timer suspension rather than explicit handling.

**No persistent high score:**
- Problem: `currentScore` is only held in memory (`lib/board.dart:45`) and reset to 0 on `resetGame()` (`lib/board.dart:266`). `shared_preferences` is already a dependency (used for skins) but is not used to persist a best/high score across sessions.
- Blocks: Players have no way to track progress or compete against a personal best across app restarts.

## Test Coverage Gaps

**Zero coverage of core game logic:**
- What's not tested: `checkCollision`, `checkLanding`, `clearLines`, `isGameOver`, `getGhostPosition`, `holdPiece`, `hardDrop` in `lib/board.dart`; `rotatePiece`, `movePiece`, `piecePositionIsValid`, `positionIsValid` in `lib/piece.dart`; the 7-bag randomizer in `generateNextPiece()`.
- Files: `lib/board.dart`, `lib/piece.dart`
- Risk: Any refactor (e.g., extracting a game-engine class per the Tech Debt recommendation above) has no safety net; regressions in collision detection, line clearing, or rotation would only be caught by manual play-testing.
- Priority: High — this is the entire gameplay engine of the app.

**Zero coverage of skin persistence and ad-unlock flow:**
- What's not tested: `_loadSettings()`, skin selection/persistence round-trip, `unlockedSkins` mutation after a simulated rewarded-ad callback in `lib/board.dart` and `lib/skin_gallery.dart`.
- Files: `lib/board.dart:90-172`, `lib/skin_gallery.dart:109-140`
- Risk: The known `firstWhere`-without-`orElse` crash bug (see Known Bugs) would have been caught by a basic persistence round-trip test.
- Priority: Medium — affects monetization/retention feature, not core gameplay.

**No widget/integration test replacing the stale boilerplate:**
- What's not tested: Basic smoke test that `GameBoard` renders, a piece spawns, and score starts at 0 (the *actual* intended behavior the current stale test seems to have been adapted from, given it checks for text '0').
- Files: `test/widget_test.dart`
- Risk: The single existing test file gives false confidence that some test coverage exists (`flutter test` may show 0 passing/1 failing, but a quick glance at directory listing suggests a test suite is present when it is not meaningful).
- Priority: High — replace immediately with even a minimal real smoke test asserting `GameBoard` renders and initial `SCORE` text shows `0`.

---

*Concerns audit: 2026-07-06*
