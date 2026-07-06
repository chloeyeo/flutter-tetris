# Technology Stack

**Analysis Date:** 2026-07-06

## Languages

**Primary:**
- Dart `^3.11.5` (SDK constraint in `pubspec.yaml`) - All application logic in `lib/*.dart` (10 files, ~1,704 lines)

**Secondary:**
- Kotlin - Android native glue code and Gradle build scripts (`android/app/build.gradle.kts`, `android/build.gradle.kts`)
- Swift/Objective-C - iOS/macOS native runner scaffolding (`ios/Runner/`, `macos/Runner/`) — present but not actively developed against (see Platform Requirements)
- C++ - Windows/Linux desktop runner scaffolding (`windows/runner/`, `linux/runner/`) — default Flutter template, unmodified

## Runtime

**Environment:**
- Flutter SDK `>=3.38.4` (from `pubspec.lock` sdks section), channel `stable` (`.metadata`)
- Dart SDK `>=3.11.5 <4.0.0`

**Package Manager:**
- `pub` (Dart/Flutter's built-in package manager)
- Lockfile: present (`pubspec.lock`, fully pinned with sha256 hashes)

## Frameworks

**Core:**
- Flutter (`sdk: flutter`) - Cross-platform UI framework; this is a single-page game app (`MaterialApp` → `GameBoard`)
- Material Design (`uses-material-design: true` in `pubspec.yaml`) - Only Material Icons font is pulled in; UI is custom-painted pixel/grid based, not Material widgets

**Testing:**
- `flutter_test` (SDK-bundled, version `0.0.0` placeholder) - Only default widget test present: `test/widget_test.dart`

**Build/Dev:**
- `flutter_launcher_icons: ^0.14.4` (pinned `0.14.4`) - Generates Android adaptive launcher icons from `assets/tetris_icon.png` (configured under `flutter_launcher_icons:` key in `pubspec.yaml`, iOS icon generation explicitly disabled with `ios: false`)
- `flutter_lints: ^6.0.0` (pinned `6.0.0`) - Base lint ruleset, included via `analysis_options.yaml` (`package:flutter_lints/flutter.yaml`); no custom rule overrides defined

## Key Dependencies

**Critical:**
- `google_mobile_ads: ^8.0.0` (pinned `8.0.0`) - AdMob monetization (banner + rewarded ads); Android-only in this codebase (see `lib/ad_service.dart`)
- `shared_preferences: ^2.5.2` (pinned `2.5.5`) - Local persistence for unlocked skins list and selected skin index (`lib/board.dart`)
- `audioplayers: ^6.1.0` (pinned `6.7.1`) - Plays local WAV sound effects for piece landing/line clear (`lib/sound_service.dart`, assets in `assets/sounds/`)
- `cupertino_icons: ^1.0.8` (pinned `1.0.9`) - iOS-style icon font, standard Flutter template dependency

**Infrastructure:**
- Transitive plugin federations pulled in by the above: `google_mobile_ads` brings `webview_flutter` (`4.13.1`) and platform interface packages; `shared_preferences` brings per-platform implementations (`shared_preferences_android`, `_foundation`, `_linux`, `_web`, `_windows`); `audioplayers` brings per-platform implementations (`audioplayers_android`, `_darwin`, `_linux`, `_web`, `_windows`)
- No HTTP client, state-management library (no Provider/Riverpod/Bloc), routing library, or serialization/codegen package is used — this is a deliberately dependency-light project

## Configuration

**Environment:**
- No `.env` files present in the repository
- No secrets management or environment-variable loading library in use
- Android release signing reads from `android/key.properties` (file exists locally, is **not excluded** by `.gitignore` — see INTEGRATIONS.md/CONCERNS for risk) via `android/app/build.gradle.kts`
- AdMob unit IDs and App ID are hardcoded as Google's public **test IDs** directly in source/manifest (not environment-driven) — see INTEGRATIONS.md

**Build:**
- `pubspec.yaml` - Package manifest, asset declarations (`assets/sounds/`), and `flutter_launcher_icons` config
- `analysis_options.yaml` - Dart analyzer/linter config (uses default `flutter_lints` ruleset, no custom rules enabled/disabled)
- `android/app/build.gradle.kts` + `android/build.gradle.kts` - Kotlin DSL Gradle build; Java/Kotlin target `VERSION_17`; `applicationId`/`namespace` = `app.chloeyeo.tetris`
- `android/app/src/main/AndroidManifest.xml` - Declares AdMob Application ID meta-data, disables Impeller (`io.flutter.embedding.android.EnableImpeller` = `false`, falls back to Skia renderer per README's documented workaround)
- `.metadata` - Flutter tooling migration tracking; marks `lib/main.dart` and `ios/Runner.xcodeproj/project.pbxproj` as user-modified ("unmanaged_files")

## Platform Requirements

**Development:**
- Flutter stable channel, Flutter SDK ≥3.38.4, Dart ≥3.11.5
- Android: `compileSdk`/`minSdk`/`targetSdk` inherited from Flutter tooling defaults (`flutter.compileSdkVersion` etc. in Gradle — no explicit override)
- README documents a known emulator issue: experimental "16k Page Size" environments cause crashes; developer resolved this by using an API 34 system image
- JDK 17 required for Android builds (`sourceCompatibility`/`targetCompatibility` = `VERSION_17`)

**Production:**
- Primary target: **Android** (only platform with functioning AdMob integration, launcher icon config, and active README/tech-debt documentation)
- Scaffolding exists for iOS, macOS, Windows, Linux, and Web (`ios/`, `macos/`, `windows/`, `linux/`, `web/` directories all present with default Flutter templates) but these are not the documented/active deployment target — iOS Info.plist has no AdMob configuration (`GADApplicationIdentifier` absent), and `ad_service.dart` explicitly throws `UnsupportedError` for any non-Android platform
- Rendering: Skia (Impeller explicitly disabled for Android stability per `AndroidManifest.xml` and README)

---

*Stack analysis: 2026-07-06*
