# CheckAndSee

A new Flutter project.

## Getting Started

FlutterFlow projects are built to run on the Flutter _stable_ release.

## Secure OpenAI Setup (Prod)

Use OpenAI only from Firebase Cloud Functions. Do not pass `OPENAI_API_KEY` to Flutter web builds or runs.

1. Set function secret (server-side only):

```bash
cd firebase/functions
firebase functions:secrets:set OPENAI_API_KEY
firebase deploy --only functions:analyzeProductScan
```

2. Verify secret is available:

```bash
firebase functions:secrets:access OPENAI_API_KEY
```

3. Run web app without client OpenAI key:

```bash
flutter run -d chrome --dart-define=SCAN_USE_CLOUD_ON_WEB=true
```

4. Production build without client OpenAI key:

```bash
flutter build web --release --dart-define=SCAN_USE_CLOUD_ON_WEB=true
```

## Smoke Test Checklist (Pre-User Testing)

Run 5-10 real scans in a production-like environment and verify:

1. Each scan creates exactly one history entry.
2. Product name is extracted and displayed correctly.
3. Analysis fields are populated (score, warnings, benefits, recommendation).
4. No user-facing failures in scan flow.

Check Cloud Function logs for upstream failures:

```bash
firebase functions:log --only analyzeProductScan --limit 200
```

If logs show frequent upstream 4xx/5xx or quota errors, resolve billing/quota before rollout.

## Store Deployment

### Preflight

1. Bump app version in `pubspec.yaml` (example: `1.0.1+2`).
2. Ensure Firebase project and OpenAI secret are configured for production.
3. Confirm Android release keystore exists in `android/key.properties`.
4. Confirm iOS signing, certificates, and App Store Connect app are configured.

### Google Play Store

Build Android App Bundle (`.aab`):

```bash
flutter build appbundle --release
```

Output file:

```text
build/app/outputs/bundle/release/app-release.aab
```

Upload to Play Console:

1. Create or open app in Play Console.
2. Go to `Testing` (Internal or Closed) for first rollout.
3. Create release and upload `app-release.aab`.
4. Complete Data safety, Content rating, and App access forms.
5. Roll out to testers.

### Apple App Store (iStore)

iOS builds require macOS with Xcode.

On a Mac:

```bash
flutter build ipa --release
```

Then in Xcode Organizer:

1. Open `ios/Runner.xcworkspace`.
2. Archive app.
3. Distribute to App Store Connect.
4. Submit to TestFlight (recommended before App Review).

### Recommended First Rollout

1. Play Internal testing (5-20 testers).
2. TestFlight internal testing.
3. Validate crash-free scans, auth, history writes, and analysis responses.

## Deploy Without Owning a Mac

You cannot build/upload iOS App Store binaries directly from Windows, but you can do it with hosted macOS CI.

This repo includes `codemagic.yaml` with:

1. `ios-app-store` workflow: builds signed IPA on Codemagic macOS and uploads to TestFlight.
2. `android-play-internal` workflow: builds AAB and uploads to Play internal track.

### Required Codemagic Secret Groups

Create group `app_store_credentials`:

1. `APP_STORE_CONNECT_PRIVATE_KEY`
2. `APP_STORE_CONNECT_KEY_IDENTIFIER`
3. `APP_STORE_CONNECT_ISSUER_ID`

Create group `google_play_credentials`:

1. `GOOGLE_PLAY_SERVICE_ACCOUNT_CREDENTIALS` (JSON content)

Create group `banuba_credentials`:

1. `BANUBA_CLIENT_TOKEN` (required)
2. `BANUBA_AR_CLOUD_TOKEN` (optional)

Compatibility alias (optional):

1. `BANUBA_TOKEN` (used only if `BANUBA_CLIENT_TOKEN` is not set)

### iOS Signing Setup in Codemagic

1. Connect Apple Developer account in Codemagic.
2. Enable automatic code signing for bundle id `com.okuhleit.checkandseeai`.
3. Trigger workflow `ios-app-store`.

### Android Publishing Setup in Codemagic

1. Provide Play service account JSON in `GOOGLE_PLAY_SERVICE_ACCOUNT_CREDENTIALS`.
2. Ensure app exists in Play Console.
3. Trigger workflow `android-play-internal`.

## Banuba AR Setup (This Project)

This repo does not use Banuba's sample `page_arcloud.dart` structure directly.
Equivalent setup points are:

1. `lib/main.dart` (startup validation / debug note)
2. `lib/beauty/banuba_config.dart` (token config)
3. `lib/page_arcloud.dart` (optional token status page)

Preferred token setup (do not hardcode secrets):

```bash
flutter pub get
flutter run \
	--dart-define=BANUBA_CLIENT_TOKEN=<your_client_token>
```

Optional (if you also have AR Cloud token):

```bash
flutter run \
	--dart-define=BANUBA_CLIENT_TOKEN=<your_client_token> \
	--dart-define=BANUBA_AR_CLOUD_TOKEN=<your_ar_cloud_token>
```

If tokens are missing, the app now shows a clear snackbar when opening
`Try On with AR`.

### Codemagic Variables for Banuba

In Codemagic UI:

1. Go to `Teams -> Environment variables`.
2. Create (or edit) group `banuba_credentials`.
3. Add `BANUBA_CLIENT_TOKEN` as a secure variable with your client token value.
4. Add optional `BANUBA_AR_CLOUD_TOKEN` if you use AR Cloud features.
5. Attach `banuba_credentials` to both workflows (`ios-app-store`, `android-play-internal`).

The workflows now fail early if no Banuba token is available, and build with:

```bash
--dart-define=BANUBA_CLIENT_TOKEN=${BANUBA_CLIENT_TOKEN:-$BANUBA_TOKEN}
```
