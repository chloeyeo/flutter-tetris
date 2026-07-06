# External Integrations

**Analysis Date:** 2026-07-06

## APIs & External Services

**Advertising/Monetization:**
- Google AdMob (Google Mobile Ads SDK) - Banner ads and rewarded video ads
  - SDK/Client: `google_mobile_ads: ^8.0.0` (pinned `8.0.0`)
  - Implementation: `lib/ad_service.dart` (singleton `AdService`), consumed by `lib/board.dart` (`BannerAd` at line ~107, `_adService.loadRewardedAd(...)` at line ~142)
  - Initialization: `AdService().init()` called in `lib/main.dart` before `runApp()`, so `MobileAds.instance.initialize()` completes during splash/startup
  - Auth/IDs: **Hardcoded Google test ad unit IDs** (not real production IDs):
    - Banner: `ca-app-pub-3940256099942544/6300978111`
    - Rewarded: `ca-app-pub-3940256099942544/5224354917`
    - App ID (Android manifest, `android/app/src/main/AndroidManifest.xml`): `ca-app-pub-3940256099942544~3347511713`
  - **Platform scope:** Android only — `AdService.bannerAdUnitId`/`rewardedAdUnitId` getters throw `UnsupportedError` on any platform where `Platform.isAndroid` is false (`lib/ad_service.dart:20-33`). No AdMob App ID is configured in `ios/Runner/Info.plist`.
  - Status: This is Google's publicly documented **sample/test configuration** used during development; must be swapped for real AdMob App ID + ad unit IDs before production/store release.

## Data Storage

**Databases:**
- None. No SQL/NoSQL database, ORM, or remote data store is used.

**Local Persistence:**
- `shared_preferences: ^2.5.2` (pinned `2.5.5`) - Key-value storage on-device
  - Client: `SharedPreferences.getInstance()` (`lib/board.dart:91,138,148`)
  - Keys used:
    - `unlocked_skins` (`List<String>`) - Which board skins the player has unlocked (`lib/board.dart:97,149`)
    - `current_skin` (`int`) - Index of the currently selected skin enum value (`lib/board.dart:139`)
  - No cloud sync, no backup/restore logic beyond the OS-level backup of local app storage

**File Storage:**
- Local filesystem only — bundled asset files under `assets/sounds/` (`candy_clear.wav`, `candy_land.wav`, `chalk_land.wav`, `eraser_swipe.wav`) and `assets/tetris_icon.png`. No remote file storage or user-generated file uploads.

**Caching:**
- None (no explicit cache layer; Flutter's default image/asset caching applies but is not customized)

## Authentication & Identity

**Auth Provider:**
- None. This is a fully offline, single-player game with no user accounts, login, or identity provider of any kind.

## Monitoring & Observability

**Error Tracking:**
- None. No Sentry/Crashlytics/Firebase Crashlytics or similar crash-reporting SDK integrated.

**Logs:**
- `debugPrint()` only, used defensively in `lib/sound_service.dart:20` to log (not throw) when an audio asset fails to load, so gameplay isn't interrupted by missing/corrupt sound files.

## CI/CD & Deployment

**Hosting:**
- Not applicable — this is a Flutter mobile app package, not a hosted service. No web deployment target is actively used (a default `web/` Flutter scaffold exists but is unconfigured/unused per README and STACK.md findings).

**CI Pipeline:**
- None detected. No `.github/workflows/`, `.gitlab-ci.yml`, `bitrise.yml`, `codemagic.yaml`, or similar CI config files found in the repository.

**App Store / Play Store:**
- No fastlane, App Store Connect API keys, or Play Console service-account JSON present in the repo.
- Android release signing is configured via `android/app/build.gradle.kts`, which reads `keyAlias`/`keyPassword`/`storeFile`/`storePassword` from `android/key.properties` if that file exists.
  - **Note:** `android/key.properties` exists on disk in this working copy but is **not listed** in `.gitignore` (the `.gitignore` only excludes `/android/app/debug`, `/android/app/profile`, `/android/app/release`, not the properties file itself). Contents were not read (forbidden — may contain keystore passwords). Flag for signing-credential hygiene review.

## Environment Configuration

**Required env vars:**
- None. No `.env` file, no `--dart-define` usage, no environment-variable reads detected anywhere in `lib/`.

**Secrets location:**
- `android/key.properties` (Android release keystore credentials — existence noted only, contents not read per security policy)
- AdMob IDs are inlined directly in source (`lib/ad_service.dart`) and in `android/app/src/main/AndroidManifest.xml` rather than injected via build config or environment — currently these are Google's public test IDs, so no live secret is actually at risk today, but the pattern means production IDs would also be hardcoded/committed if swapped in directly.

## Webhooks & Callbacks

**Incoming:**
- None. No server component, no deep-link handling beyond Flutter's default Android `PROCESS_TEXT` intent query declaration (`android/app/src/main/AndroidManifest.xml`).

**Outgoing:**
- None beyond the Google Mobile Ads SDK's own internal network calls (ad request/fill/impression reporting), which are handled entirely inside the `google_mobile_ads` plugin and not directly invoked by application code beyond `AdRequest()`/`RewardedAd.load()` calls in `lib/ad_service.dart`.

---

*Integration audit: 2026-07-06*
