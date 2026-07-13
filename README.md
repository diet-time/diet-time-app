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
