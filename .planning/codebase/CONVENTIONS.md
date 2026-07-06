# Coding Conventions

**Analysis Date:** 2026-07-06

## Naming Patterns

**Files:**
- `snake_case.dart` throughout — `ad_service.dart`, `piece_preview.dart`, `skin_gallery.dart`, `sound_service.dart`
- File name matches primary class/widget it exports, converted to snake_case: `board.dart` → `GameBoard`, `piece.dart` → `Piece`, `pixel.dart` → `Pixel`
- One primary public class per file; private companion classes (e.g. `_GameBoardState`, `ChalkTexturePainter`) can share the file of the class they support

**Functions/Methods:**
- `lowerCamelCase` for all methods — `initializePiece()`, `movePiece()`, `checkCollision()`, `clearLines()`, `generateNextPiece()`
- Private helper methods prefixed with underscore — `_loadSettings()`, `_initAds()`, `_loadBannerAd()`, `_openSkinGallery()`, `_showUnlockDialog()`, `_buildSkinPreview()`, `_getShapeCoords()`
- Boolean-returning methods read as predicates — `isGameOver()`, `positionIsValid()`, `piecePositionIsValid()`
- `build()` reserved for Flutter widget build method override

**Variables:**
- `lowerCamelCase` for local variables and fields — `currentPiece`, `currentScore`, `gameBoard`, `pieceBag`
- Private state fields prefixed with underscore in `State` classes — `_bannerAd`, `_isBannerLoaded`, `_horizontalAccumulator`, `_consecutiveHorizontalMoves`
- Booleans use `is`/`can` prefixes — `canHold`, `gameOver` (exception — no `is` prefix but still boolean), `_isBannerLoaded`, `_isInitialized`
- Constants and module-level globals are lowerCamelCase, not SCREAMING_CASE — `rowLength`, `colLength` in `lib/values.dart:3-4`

**Types (classes/enums):**
- `UpperCamelCase` for classes and enums — `Piece`, `GameBoard`, `TetrisSkin`, `SkinType`, `Tetromino`, `Direction`
- Enum values are lowerCamelCase or short abbreviations matching domain terms — `Tetromino.L`, `Tetromino.J`, `SkinType.classic`, `SkinType.y2k`, `Direction.left`

## Code Style

**Formatting:**
- No custom `.prettierrc`/formatter config present — relies on default `dart format` conventions (2-space indent, trailing commas in multi-line widget trees)
- Widget trees use trailing commas consistently to trigger `dart format`'s one-arg-per-line style (see `lib/board.dart:489-767`)

**Linting:**
- `analysis_options.yaml:10` includes `package:flutter_lints/flutter.yaml` (flutter_lints ^6.0.0) with no rules overridden — all custom rule lines are commented out (`analysis_options.yaml:24-25`)
- No `avoid_print` override, no `prefer_single_quotes` override — project uses default Flutter lint recommendations only
- Both single quotes and double quotes appear in source (e.g. `lib/board.dart:152` uses double quotes, `lib/main.dart:1` uses single quotes for imports) — no enforced quote style beyond default

## Import Organization

**Order observed (not enforced by lint, but consistently followed):**
1. `dart:` core imports first — `dart:async`, `dart:math`, `dart:ui`, `dart:io` (`lib/board.dart:1-2`, `lib/piece.dart:1`, `lib/ad_service.dart:1`)
2. `package:flutter/...` imports next — `package:flutter/material.dart`, `package:flutter/gestures.dart`, `package:flutter/services.dart` (`lib/board.dart:4-6`)
3. Third-party `package:` imports — `package:google_mobile_ads/google_mobile_ads.dart`, `package:shared_preferences/shared_preferences.dart`, `package:audioplayers/audioplayers.dart`
4. Local project imports last, using the `package:tetris/...` form for cross-file imports in `board.dart` (`lib/board.dart:7-16`) but relative imports (`'values.dart'`, `'skins.dart'`) in leaf files like `piece.dart`, `pixel.dart`, `skins.dart`, `piece_preview.dart`

**Path Aliases:**
- None. No `barrel` files (no `lib/tetris.dart` export-all file). Every file imports exactly what it needs directly.

## Error Handling

**Patterns:**
- Defensive `try/catch` used only where an external/IO operation can fail unpredictably — `lib/sound_service.dart:14-20` wraps `_player.play()` in try/catch and swallows the exception, logging via `debugPrint` so a missing audio asset never crashes the game
- Ad-related failures use callback-based error handling rather than exceptions — `onAdFailedToLoad` callbacks in `lib/ad_service.dart:46-48` and `lib/board.dart:117-119`, `155-160` degrade gracefully (banner ad simply doesn't show; snackbar informs user)
- Platform-unsupported paths throw explicit exceptions rather than silently failing — `lib/ad_service.dart:23`, `lib/ad_service.dart:31` (`throw UnsupportedError('Unsupported platform')`)
- Game logic (collision detection, rotation, line clearing) uses boolean return values and early returns instead of exceptions — see `checkCollision()`, `piecePositionIsValid()`, wall-kick fallback loop in `lib/piece.dart:248-270`
- No centralized error boundary or logging service; error handling is local to the operation that can fail

## Logging

**Framework:** `debugPrint` (Flutter foundation), used sparingly

**Patterns:**
- Only one logging call in the entire codebase: `lib/sound_service.dart:20`, used purely for a caught-exception diagnostic message, never for general flow tracing
- No `print()` calls anywhere in `lib/` (confirmed via search) — `debugPrint` is the only sanctioned output mechanism, consistent with the default (non-overridden) `avoid_print` lint rule

## Comments

**When to Comment:**
- Short one-line comments precede non-obvious logic blocks, especially game-mechanic sections — e.g. `// collision detection (check for collision in a future position)` (`lib/board.dart:275`), `// BETTER WALL KICK (SRS-lite)` (`lib/piece.dart:253`)
- Inline comments explain "why", not "what", especially around tuning constants — `// Starts slow (140ms) for precision` (`lib/board.dart:71`), `// Finger must move 20 pixels to shift a block` (`lib/board.dart:69`)
- Bracketed tags mark recent/notable changes inline: `// [NEW]`, `// [BRAKE LOGIC]` — `lib/board.dart:597`, `lib/board.dart:642`, `lib/pixel.dart:9`, `lib/skins.dart:21-22`
- Section-header comments in ALL CAPS mark major logic blocks inside large methods — `// AXIS LOCK:`, `// ADAPTIVE DAS MOVEMENT:` (`lib/board.dart:611`, `lib/board.dart:622`)
- Block comments (`/* ... */`) used sparingly for file-level context — `lib/board.dart:18-21` explains the game board data structure

**JSDoc/TSDoc:**
- No Dartdoc (`///`) comments used anywhere in the codebase. All comments use `//` line comments. There is no API documentation generation in use.

## Function Design

**Size:** Widget `build()` methods are large and monolithic (the `build()` method in `lib/board.dart:488-768` spans ~280 lines encompassing header UI, gesture handling, and the grid). Non-UI logic methods (collision, movement, scoring) stay small and single-purpose (5-40 lines).

**Parameters:** Named parameters with `required` used consistently for widget constructors — `const Pixel({super.key, required this.color, this.skinType = SkinType.classic, this.emoji})` (`lib/pixel.dart:11-16`). Plain positional/typed parameters used for internal logic methods, e.g. `bool piecePositionIsValid(List<int> piecePosition, List<List<Tetromino?>> gameBoard)` (`lib/piece.dart:292`).

**Return Values:** Boolean predicates return early on the first failing condition rather than accumulating state (`lib/piece.dart:274-289`, `lib/board.dart:277-306`). Methods that mutate object state directly (e.g. `movePiece`, `rotatePiece`) return `void` and mutate fields in place rather than returning new instances.

## Module Design

**Exports:** No `export` statements; every consumer imports the specific file it needs directly. Each file typically exports one primary class plus tightly related private helper classes/painters.

**Barrel Files:** Not used. There is no single "import everything" entry file — `lib/main.dart` only imports `ad_service.dart` and `board.dart`, and each domain file (`piece.dart`, `skins.dart`, `pixel.dart`) imports only its direct dependencies.

## State Management

**Pattern:** No external state management library (no `provider`, `riverpod`, `bloc`). All state lives in `StatefulWidget`/`State` classes using `setState()` directly — the entire game state (`gameBoard`, `currentPiece`, `currentScore`, etc.) is held as fields on `_GameBoardState` in `lib/board.dart:30-72` and mutated inside `setState(() { ... })` blocks (e.g. `lib/board.dart:200-217`, `lib/board.dart:375-387`).

**Persistence:** `shared_preferences` used directly (no repository/DAO abstraction) for simple key-value persistence of skin selection and unlocks — `lib/board.dart:90-100`, `lib/board.dart:138-139`, `lib/board.dart:148-149`.

**Singletons:** Service classes (`AdService`, `SoundService`) use the private-constructor + static-instance factory singleton pattern:
```dart
class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();
  ...
}
```
See `lib/ad_service.dart:5-8` and `lib/sound_service.dart:5-7`. Follow this exact pattern for any new global service.

---

*Convention analysis: 2026-07-06*
