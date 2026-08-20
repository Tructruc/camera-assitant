# Local-only privacy audit

Audit date: 21 August 2026  
Scope: first-release `v2` source and dependency graph through commit preceding this document.

## Findings

- Runtime dependencies are UI, state, formatting, and local SQLite packages: Flutter, Riverpod, `intl`,
  Drift, and Drift's SQLite support. No HTTP client, analytics, advertising, crash-reporting, account,
  cloud database, location, or telemetry SDK is declared in `pubspec.yaml`.
- `lib/` contains no URL, socket, HTTP-client, analytics, or telemetry implementation. User equipment,
  preferences, and calculation snapshots flow only through the local Drift database.
- The Android release manifest at `android/app/src/main/AndroidManifest.xml` does not request
  `android.permission.INTERNET`. Flutter's debug and profile manifests do request it for development
  tooling; those manifests are not merged into the signed release APK.
- The iOS application has no networking, location, tracking, advertising, or account entitlement or
  usage-description entry. Standard XML namespace URLs in Xcode project files are identifiers, not
  runtime endpoints.
- `test/privacy/no_network_test.dart` installs an `HttpOverrides` guard that throws as soon as production
  code attempts to create a Dart network client, then launches the application and completes a depth-of-
  field journey. The test passes without a request.

## Reproduction

```sh
rg -n "INTERNET|NSAppTransport|http://|https://|dart:io|package:http|dio|firebase|telemetry|analytics" \
  android ios lib pubspec.yaml
flutter test test/privacy/no_network_test.dart
flutter build apk --release
```

For an Android artifact, additionally inspect the merged release manifest with Android build tools and
confirm `android.permission.INTERNET` is absent. On physical Android and iOS validation devices, capture
traffic with a trusted system-level proxy while exercising every quickstart scenario; expected
application traffic is zero.

## Boundary and limitations

The automated guard covers Dart `HttpClient` creation during the representative journey. Static manifest
and dependency inspection covers the current native surface. It cannot observe operating-system backup,
store services, Flutter development tooling, or future native plugins. Debug/profile builds may contact
Flutter tooling because their Android manifests deliberately include Internet permission. Repeat this
audit whenever dependencies, platform permissions, native code, or product scope changes.
