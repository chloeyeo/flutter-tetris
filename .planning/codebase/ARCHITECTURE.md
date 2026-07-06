<!-- refreshed: 2026-07-06 -->
# Architecture

**Analysis Date:** 2026-07-06

## System Overview

```text
┌─────────────────────────────────────────────────────────────┐
│                      App Bootstrap                           │
│                     `lib/main.dart`                           │
│   Initializes AdService, runs MyApp → MaterialApp → GameBoard │
└───────────────────────────┬───────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│              GameBoard (StatefulWidget)  `lib/board.dart`     │
│  Owns ALL game state: board grid, current/next/held piece,   │
│  score, game-over flag, Timer game loop, touch-gesture DAS    │
│  state, skin selection, ad + sound service handles            │
├──────────────────┬──────────────────┬───────────────────────┤
│  Piece  (model)  │  Skins (theming) │  Services (side-fx)    │
│ `lib/piece.dart` │ `lib/skins.dart` │ `ad_service.dart`,      │
│                  │                  │ `sound_service.dart`   │
└────────┬─────────┴────────┬─────────┴──────────┬────────────┘
         │                  │                     │
         ▼                  ▼                     ▼
┌─────────────────────────────────────────────────────────────┐
│                     Presentation Widgets                     │
│  `lib/pixel.dart` (single cell), `lib/piece_preview.dart`     │
│  (hold/next box render), `lib/skin_gallery.dart` (skin picker)│
└─────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────┐
│  Persistence / External Services                              │
│  `shared_preferences` (skin choice, unlocked skins)            │
│  `google_mobile_ads` (banner + rewarded ads)                   │
│  `audioplayers` (WAV assets in `assets/sounds/`)               │
└─────────────────────────────────────────────────────────────┘
```

## Component Responsibilities

| Component | Responsibility | File |
|-----------|----------------|------|
| `MyApp` | Root widget, wires `MaterialApp` to `GameBoard` | `lib/main.dart` |
| `_GameBoardState` | Central game engine: board state, timer-driven gravity, collision/landing/line-clear logic, gesture handling, UI composition | `lib/board.dart` |
| `Piece` | Tetromino model: shape positions, movement, SRS-lite rotation + wall kicks, position validity checks | `lib/piece.dart` |
| `Pixel` | Renders a single grid cell with skin-specific decoration (color, emoji, chalk texture, sparkle icons) | `lib/pixel.dart` |
| `PiecePreview` | Renders a static piece shape (used for HOLD/NEXT boxes) on a 4x4 relative grid | `lib/piece_preview.dart` |
| `TetrisSkin` / `SkinType` | Theming data: per-tetromino colors, emojis, background/grid/text colors, sound asset paths | `lib/skins.dart` |
| `SkinGallery` | Full-screen skin picker UI; triggers unlock flow via rewarded ads | `lib/skin_gallery.dart` |
| `AdService` | Singleton wrapper around `google_mobile_ads`: init, banner ad unit id, rewarded ad loading | `lib/ad_service.dart` |
| `SoundService` | Singleton wrapper around `audioplayers` for landing/clear sound effects | `lib/sound_service.dart` |
| Constants (`rowLength`, `colLength`, `Tetromino`, `Direction`, `tetrominoColors`) | Shared global config/enums used across model and UI | `lib/values.dart` |

## Pattern Overview

**Overall:** Single-screen, single "God Widget" architecture typical of small Flutter game prototypes. There is no dedicated state-management library (no Provider/Bloc/Riverpod) — `_GameBoardState.setState()` is the only state propagation mechanism, and `GameBoard` is effectively both the controller and the view.

**Key Characteristics:**
- **Monolithic state holder:** `_GameBoardState` (`lib/board.dart`) owns board grid, piece state, score, timer, skin, ad, sound, and raw touch-gesture accelerometer-like accumulators all in one class (~770 lines).
- **Flat 1D array board representation:** the 10x20 grid is modeled as `List<List<Tetromino?>>` for storage, but active/ghost piece positions are tracked as flat integer indices (`row * rowLength + col`) requiring manual `floor()`/`%` math scattered through `board.dart` and `piece.dart`.
- **Timer-driven game loop:** gravity/tick logic runs via `Timer.periodic` (`lib/board.dart:196`), not a `Ticker`/`AnimationController`, so frame rate = drop speed (single timer serves both purposes).
- **Singleton services:** `AdService` and `SoundService` use the private-constructor + static-instance singleton pattern for cross-widget access without DI.
- **Data-driven theming:** `TetrisSkin` (`lib/skins.dart`) centralizes all visual/audio theming as static data objects, consumed by `Pixel`, `PiecePreview`, and `GameBoard` — no separate ThemeData/ThemeExtension.

## Layers

**Model / Domain Layer:**
- Purpose: Represent tetromino shapes, positions, movement, rotation math, and collision-position validity independent of rendering.
- Location: `lib/piece.dart`, `lib/values.dart`
- Contains: `Piece` class, `Tetromino`/`Direction` enums, `tetrominoColors` map, board dimension constants.
- Depends on: nothing else in the app (pure Dart + `dart:ui` for `Color`).
- Used by: `lib/board.dart` (all collision/landing/rotation calls delegate into `Piece`).

**Game Controller / State Layer:**
- Purpose: Owns board grid, drives the game loop, orchestrates collision detection, line clearing, scoring, hold/next piece queue (7-bag), and gesture-to-move translation.
- Location: `lib/board.dart` (`_GameBoardState`)
- Contains: `Timer`-based loop, `checkCollision`, `checkLanding`, `clearLines`, `rotatePiece`, `holdPiece`, `getGhostPosition`, gesture callbacks (`onPanStart`/`onPanUpdate`/`onVerticalDragEnd`).
- Depends on: `Piece` (model), `TetrisSkin` (theming), `AdService`, `SoundService`, `shared_preferences`.
- Used by: nothing (top of the widget-owned stack; it is the screen).

**Presentation / Widget Layer:**
- Purpose: Pure rendering of grid cells, piece previews, and the skin picker screen.
- Location: `lib/pixel.dart`, `lib/piece_preview.dart`, `lib/skin_gallery.dart`
- Contains: `StatelessWidget`/`StatefulWidget` subclasses with no game logic — only decoration and callbacks passed in from `board.dart`.
- Depends on: `TetrisSkin`/`SkinType` (`skins.dart`), `Tetromino` (`values.dart`).
- Used by: `_GameBoardState.build()` (`Pixel`, `PiecePreview`) and `_openSkinGallery()` (`SkinGallery`).

**Theming / Config Layer:**
- Purpose: Static data describing visual/audio "skins" and shared numeric/enum constants.
- Location: `lib/skins.dart`, `lib/values.dart`
- Contains: `TetrisSkin` static instances (classic, y2k, sparkle, candy, chalkboard), `SkinType` enum, board size constants.
- Depends on: `flutter/material.dart` (Color), nothing app-specific.
- Used by: every rendering file plus `_GameBoardState`.

**External Services Layer:**
- Purpose: Wrap third-party SDKs (ads, audio) and persistence behind small singleton APIs.
- Location: `lib/ad_service.dart`, `lib/sound_service.dart`
- Contains: `AdService` (google_mobile_ads wrapper), `SoundService` (audioplayers wrapper).
- Depends on: `google_mobile_ads`, `audioplayers` packages.
- Used by: `_GameBoardState` (both), `SkinGallery` (rewarded ad unlock flow indirectly via callback passed from `board.dart`).

## Data Flow

### Primary Game Loop (gravity tick)

1. `Timer.periodic(frameRate, ...)` fires every N ms, set initially to 800ms (`lib/board.dart:196`, `startGame()` at `lib/board.dart:181`).
2. Inside the callback, `setState()` wraps: `clearLines()` (`lib/board.dart:454`) → `checkLanding()` (`lib/board.dart:308`) → game-over check → `checkCollision(Direction.down)` (`lib/board.dart:277`) → `currentPiece.movePiece(Direction.down)` (`lib/piece.dart:41`).
3. `checkLanding()` writes the landed piece's flat positions into `gameBoard[row][col]`, plays a land sound via `SoundService`, and calls `createNewPiece()` (`lib/board.dart:349`), which pulls from `nextPiece` / regenerates the 7-bag (`generateNextPiece()`, `lib/board.dart:364`).
4. `build()` re-renders the `GridView.builder` (`lib/board.dart:687`), computing per-cell color by checking membership in `currentPiece.position`, precomputed `ghostPosition` (via `getGhostPosition()`, `lib/board.dart:389`), then `gameBoard[row][col]`.

### Touch Gesture → Piece Movement

1. `GestureDetector.onPanStart` resets horizontal/vertical accumulators and DAS delay state (`lib/board.dart:599-605`).
2. `onPanUpdate` accumulates `details.delta.dx/dy` into `_horizontalAccumulator`/`_verticalAccumulator` with axis-lock logic (dominant axis wins) (`lib/board.dart:606-656`).
3. Once `_horizontalAccumulator` crosses `_moveThreshold` (20px) and enough time has passed (adaptive DAS delay, starts at 100ms, accelerates to a 35ms floor), `moveLeft()`/`moveRight()` is invoked and haptic feedback fires.
4. Vertical accumulation past 60px triggers a single soft-drop step (`currentPiece.movePiece(Direction.down)`, gated by `checkCollision`).
5. `onVerticalDragEnd` checks `details.primaryVelocity > 500` to trigger `hardDrop()` (`lib/board.dart:438`), which loops `movePiece(Direction.down)` until collision, then force-lands.
6. A plain `onTap` on the board triggers `rotatePiece()` (`lib/board.dart:448`), delegating to `Piece.rotatePiece(gameBoard)`.

**State Management:**
- All state lives in `_GameBoardState` instance fields; every mutation is wrapped in `setState()` to trigger a rebuild of the whole board `GridView`.
- No external state container; persistence for skin choice/unlocks uses `SharedPreferences` directly inside `_GameBoardState` (`_loadSettings()`, `lib/board.dart:90`) and inside the `onSkinSelected`/`onUnlockSkin` callbacks passed to `SkinGallery`.

## Key Abstractions

**Piece (Tetromino instance):**
- Purpose: Represents a live tetromino's type, flat-index board positions, and rotation state.
- Examples: `lib/piece.dart` (`Piece` class), instantiated in `lib/board.dart` for `currentPiece`, `nextPiece`, `heldPiece`.
- Pattern: Mutable model object with methods (`initializePiece`, `movePiece`, `rotatePiece`) that mutate its own `position`/`rotationState` fields; rotation math is hardcoded per-`Tetromino`-type/per-rotation-index switch statements (no generalized SRS kick table).

**Flat board index math:**
- Purpose: Both the piece's `position` list and ghost-position simulation use `index = row * rowLength + col`.
- Examples: `checkCollision` (`lib/board.dart:277`), `checkLanding` (`lib/board.dart:308`), `getGhostPosition` (`lib/board.dart:389`), `Piece.positionIsValid` (`lib/piece.dart:274`).
- Pattern: Every consumer independently re-derives `row`/`col` via `(position / rowLength).floor()` and `position % rowLength` (with a manual negative-modulo correction `if (col < 0) col += rowLength`) — this logic is duplicated in at least 4 places rather than centralized in one helper.

**TetrisSkin (theming data object):**
- Purpose: Bundles all visual (colors, emojis) and audio (sound asset paths) properties for one "look" of the game.
- Examples: `lib/skins.dart` — `TetrisSkin.classic`, `.y2k`, `.sparkle`, `.candy`, `.chalkboard` static instances; `TetrisSkin.getSkin(SkinType)` factory lookup.
- Pattern: Immutable data class with named constructor; consumed by widgets purely as a read-only prop (`Pixel(color:, skinType:, emoji:)`, `PiecePreview(skin:)`).

**Singleton services:**
- Purpose: Provide a single shared instance of stateful third-party wrappers without a DI framework.
- Examples: `AdService()` (`lib/ad_service.dart:6-8`), `SoundService()` (`lib/sound_service.dart:5-7`) — both use `factory` constructor returning a cached `static final _instance`.
- Pattern: Classic private-constructor singleton; instantiated fresh in each consumer (`final AdService _adService = AdService();` in `_GameBoardState`) but always resolves to the same object.

## Entry Points

**`main()`:**
- Location: `lib/main.dart:5`
- Triggers: OS/Flutter engine app launch.
- Responsibilities: Ensures Flutter binding init, awaits `AdService().init()` (blocking splash before first frame), then `runApp(const MyApp())`.

**`MyApp.build()`:**
- Location: `lib/main.dart:21`
- Triggers: Called once by the Flutter framework after `runApp`.
- Responsibilities: Wraps a single `MaterialApp` with `home: GameBoard()` — no routes/navigator config beyond the default (skin gallery uses `Navigator.push` ad-hoc, `lib/board.dart:128`).

**`_GameBoardState.initState()`:**
- Location: `lib/board.dart:75`
- Triggers: Flutter framework when `GameBoard` widget is first inserted into the tree.
- Responsibilities: Loads persisted skin/unlock settings, schedules a delayed (5s) banner-ad load, and calls `startGame()` to begin the timer loop.

## Architectural Constraints

- **Threading:** Single-threaded Dart/Flutter event loop. No isolates. Gravity ticking and ad/sound calls all happen on the UI thread inside `setState`.
- **Global state:** `rowLength`/`colLength` in `lib/values.dart` are top-level mutable `int` variables (not `const`/`final`), globally accessible and mutable from anywhere that imports `values.dart`. `AdService`/`SoundService` are process-wide singletons.
- **Circular imports:** None observed — dependency direction is strictly `values.dart` → `piece.dart`/`skins.dart` → `pixel.dart`/`piece_preview.dart`/`skin_gallery.dart` → `board.dart` → `main.dart`.
- **No separation between game logic and widget tree:** `_GameBoardState` mixes pure game-logic methods (`checkCollision`, `clearLines`) with Flutter widget code (`build()`, gesture callbacks) in a single 769-line file, making game logic hard to unit test in isolation from widgets.
- **No automated test coverage of game logic:** the only test (`test/widget_test.dart`) is the unmodified Flutter counter-app template test and does not test the actual Tetris app — it references a nonexistent counter UI and will fail if run.

## Anti-Patterns

### God Widget / God State

**What happens:** `_GameBoardState` (`lib/board.dart`) owns board state, piece state, scoring, persistence loading, ad lifecycle, sound triggering, gesture-driven physics (DAS acceleration), and the entire widget build method in one 769-line class.
**Why it's wrong:** Any change to one concern (e.g., tuning touch sensitivity) risks breaking unrelated concerns (e.g., line-clear scoring) because everything shares the same mutable instance state and the same `setState` calls. It also makes the game logic impossible to unit-test without instantiating a full widget tree.
**Do this instead:** Extract a plain-Dart `GameEngine`/`GameState` class (no Flutter imports) holding the grid, piece, score, and game-loop methods (`checkCollision`, `checkLanding`, `clearLines`, `rotatePiece`, `holdPiece`), and have `_GameBoardState` hold an instance of it, delegating and calling `setState(() {})` only to trigger repaint. This is not yet done anywhere in the codebase.

### Duplicated flat-index math

**What happens:** The `row = (position / rowLength).floor(); col = position % rowLength; if (col < 0) col += rowLength;` pattern is repeated verbatim in `checkCollision` (`lib/board.dart:280-283`), `checkLanding` (`lib/board.dart:313-315`), `getGhostPosition` (`lib/board.dart:399-401`), and `Piece.positionIsValid` (`lib/piece.dart:275-276`, without the negative-mod guard).
**Why it's wrong:** Any future change to board dimensions or indexing scheme (e.g., switching to `Offset`/`Point` based positions) requires hunting down and updating 4+ independent copies; the negative-modulo guard is inconsistently applied (missing in `Piece.positionIsValid`), which is a latent bug source for negative position values.
**Do this instead:** Add a single `int rowOf(int index)` / `int colOf(int index)` pair of top-level functions (e.g., in `lib/values.dart`) and use them everywhere position math is needed.

## Error Handling

**Strategy:** Minimal / defensive-by-omission. Most side-effect calls (ads, sound) fail silently rather than surfacing errors to game state.

**Patterns:**
- `SoundService.playSound()` wraps playback in `try/catch`, swallowing exceptions and only `debugPrint`-ing them (`lib/sound_service.dart:14-21`) so a missing/corrupt audio asset never crashes gameplay.
- `AdService` ad-loading uses SDK-provided failure callbacks (`onAdFailedToLoad`) that simply `ad.dispose()` or show a `SnackBar` rather than throwing (`lib/board.dart:117-119`, `lib/board.dart:155-160`).
- `AdService.bannerAdUnitId`/`rewardedAdUnitId` explicitly `throw UnsupportedError('Unsupported platform')` for any non-Android platform (`lib/ad_service.dart:19-33`) — this is a hard crash path with no iOS/desktop fallback despite the project having `ios/`, `macos/`, `windows/`, `linux/`, `web/` platform folders present from `flutter create`.

## Cross-Cutting Concerns

**Logging:** `debugPrint` only, used solely in `SoundService` for swallowed audio errors (`lib/sound_service.dart:20`). No structured logging, no analytics/crash-reporting SDK integrated.

**Validation:** Game-state validity (collision/bounds/occupied-cell checks) is validated via `Piece.positionIsValid`/`piecePositionIsValid` (`lib/piece.dart:274-309`) and `_GameBoardState.checkCollision` (`lib/board.dart:277`); no input validation exists elsewhere (no forms/user text input in the app).

**Authentication:** None — the app has no user accounts, network auth, or backend; the only "identity" concern is anonymous per-device `SharedPreferences` storage of skin choice/unlocks.

---

*Architecture analysis: 2026-07-06*
