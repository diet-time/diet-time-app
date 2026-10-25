# Diet Time

Initial Flutter foundation for the Diet Time healthy meal subscription app.

## Included

- Native emerald launch screens for Android and iOS
- Animated, reduced-motion-aware Flutter splash and authentication routing
- Responsive English/Arabic login with immediate RTL switching
- Riverpod state management, `go_router`, and secure storage boundary
- Material 3 brand tokens and reusable form/button components
- Placeholder home route and mock unauthenticated service

## Required brand assets

The supplied brand-sheet logo is currently extracted to:

`assets/logo/diet_time_logo.png`

Replace it with the original client-approved SVG export when available. Add
licensed Bw Surco DEMO and Almarai files under `assets/fonts/`, register the font
weights in `pubspec.yaml`, and update the family constants in
`lib/app/theme/app_typography.dart`. Manrope is the temporary English family.

## Google Maps setup

Enable **Maps SDK for Android** and **Maps SDK for iOS** in Google Cloud. For
Android, copy the example secret file and replace its placeholder value:

- `android/local.properties.example` → `android/local.properties`
The Android destination file is ignored by Git. The current iOS key is embedded
in `ios/Runner/AppDelegate.swift`, so restrict it in Google Cloud to the iOS
bundle ID `com.diettime.dietTime`. Restrict the Android key to application ID
`com.diettime.diet_time` plus its signing SHA-1.

On macOS, install the native iOS dependencies and open the workspace:

```sh
cd ios
pod install
open Runner.xcworkspace
```

## TestFlight

The `iOS TestFlight` GitHub Actions workflow builds a signed IPA and uploads it
to App Store Connect on pushes to `main` or from **Actions → iOS TestFlight →
Run workflow**. It expects the app record and the `com.diettime.dietTime` App
Store bundle ID to already exist in Apple Developer and App Store Connect.

Configure these GitHub Actions variables:

- `APPSTORE_ISSUER_ID`
- `APPSTORE_API_KEY_ID`
- `APPSTORE_TEAM_ID`

Configure these GitHub Actions secrets:

- `APPSTORE_API_PRIVATE_KEY` — the contents of the App Store Connect `AuthKey_*.p8`
- `APPSTORE_CERTIFICATES_FILE_BASE64` — a base64-encoded Apple Distribution `.p12`
- `APPSTORE_CERTIFICATES_PASSWORD` — the `.p12` password

The workflow downloads the App Store provisioning profile named
`AppStore com.diettime.dietTime`; create that profile with the same bundle ID
and an Apple Distribution certificate. Never commit signing certificates,
private keys, provisioning profiles, or local API key files.

## Run

```sh
flutter pub get
flutter run
```

Use `flutter gen-l10n` after editing the ARB files.

## Connecting authentication

Implement `AuthenticationService` with the backend client, persist the returned
token through `SecureStorageService`, and override
`authenticationServiceProvider` with the real implementation. Keep token and
session decisions outside presentation widgets.
