# Local-only privacy audit

Audit date: 10 September 2026.

Scope: first-release `v2` source, native manifests, and the resolved dependency graph in the T127/T128
working tree, based on commit `878e6ea`.

Method: static inspection of `pubspec.yaml`, `pubspec.lock`, `lib/`, `android/`, `ios/`, and the
resolved plugin manifests under the local pub cache. See "Verification status" for what this record does
and does not prove.

## Network, account, and telemetry findings

- No network, account, analytics, advertising, crash-reporting, or telemetry package is declared. The
  runtime dependencies are UI, state, formatting, local SQLite, camera, location, and sensor packages:
  `flutter`, `flutter_riverpod`, `intl`, `drift`, `drift_flutter`, `camera`, `geolocator`,
  `sensors_plus`, `flutter_compass`, `timezone`, `uuid`, and `cupertino_icons`.
- `lib/` contains no network client and no endpoint literal. Both scans return nothing:

  ```sh
  grep -rnE "dart:io|package:http/|HttpClient|RawSocket|Socket\(|WebSocket" lib/
  grep -rnE "package:dio|firebase_|google_analytics|sentry|crashlytics" lib/
  grep -rnE "'https?://|\"https?://" lib/
  ```

- The application manifest does not request `android.permission.INTERNET`. Only the debug and profile
  source sets request it, in `android/app/src/debug/AndroidManifest.xml` and
  `android/app/src/profile/AndroidManifest.xml`, because the Flutter tooling needs it. Those source sets
  are not inputs to a release merge.
- `ios/Runner/Info.plist` contains no App Transport Security exception, and the project has no
  `.entitlements` file, so it declares no network, tracking, advertising, or account capability.
- Equipment, preferences, saved locations, and calculation snapshots are written only to the local
  SQLite database opened by `driftDatabase(name: 'photography_assistant')` in
  `lib/core/data/database/database_factory.dart`. `drift_flutter` resolves that path through
  `path_provider`, which is the app-private documents directory. There is no export, share, or sync path
  anywhere in `lib/`.

## Android permissions in the merged release manifest

Only `camera_android_camerax` 0.7.2 contributes permissions beyond the ones this app declares itself.
The remaining resolved Android plugins declare no `uses-permission` entry: `geolocator_android` 5.0.3,
`sensors_plus` 7.1.0, `flutter_compass` 0.8.1, `package_info_plus` 10.2.1, `path_provider_android` 2.3.1
(a Dart-only plugin class over `jni`), `flutter_plugin_android_lifecycle` 2.0.35, `jni` 1.0.3,
`jni_flutter` 1.0.2, and `sqlite3` 3.5.1. `integration_test` is a dev dependency, so it is absent from
release builds.

- `android.permission.CAMERA` — declared by the app manifest and by `camera_android_camerax` 0.7.2.
  Triggered only when the user opens the optional live AR view: `availableCameras()` and then
  `CameraController.initialize()` in `lib/features/planning/presentation/live_ar_view.dart`. Nothing
  requests the camera at startup, and the numeric, timeline, compass, and map views remain usable when it
  is denied.
- `android.permission.ACCESS_FINE_LOCATION` — declared by the app manifest. Triggered only when the user
  starts the current-position action in `saved_locations_screen.dart`, which calls
  `DevicePlanningService.requestCurrentLocation()`; that method checks `Geolocator.checkPermission()` and
  calls `Geolocator.requestPermission()` only when the result is `denied`. Denial returns manual-entry
  guidance rather than blocking the flow.
- `android.permission.RECORD_AUDIO` — merged by `camera_android_camerax` 0.7.2, but unused: the live AR
  view creates its controller with `enableAudio: false` and starts no capture. The app manifest removes
  the merged entry with `tools:node="remove"`.
- `android.permission.WRITE_EXTERNAL_STORAGE`, limited by the plugin to `maxSdkVersion` 28 — merged by
  `camera_android_camerax` 0.7.2, but unused: every write goes to app-private storage. The app manifest
  removes the merged entry with `tools:node="remove"`.
- `android.hardware.camera` with `required="false"` and `android.hardware.sensor.compass` with
  `required="false"` — app-declared install-time capability declarations only; the app installs and runs
  without either, falling back to numeric planning.

`geolocator_android` 5.0.3 also merges a `GeolocatorLocationService` element with
`foregroundServiceType="location"`. The app never starts it: it uses one-shot
`Geolocator.getCurrentPosition()` and not `getPositionStream()`, so no foreground location service runs
and no notification is posted.

Open observation, not changed by this audit: `camera_android_camerax` 0.7.2 declares
`<uses-feature android:name="android.hardware.camera.any" />` without `required="false"`, so the merged
manifest marks that feature required and would filter camera-less Android devices, even though every
camera-dependent path in this app is capability-gated.

## iOS usage descriptions

`ios/Runner/Info.plist` declares exactly three usage strings, each tied to an optional, user-started
feature:

- `NSCameraUsageDescription` — for `camera_avfoundation` 0.10.2. The optional live AR view overlays a
  saved sky plan on the camera preview; no photo, video, or audio capture is started.
- `NSLocationWhenInUseUsageDescription` — for `geolocator_apple` 2.3.14, and also required by
  `flutter_compass` 0.8.1, which reads `CLLocationManager` heading. It covers the current-position action
  that fills observer coordinates on request. No always-on or background location entry exists.
- `NSMotionUsageDescription` — for `sensors_plus` 7.1.0. Device pitch aligns target altitude while the
  live AR view is open.

No microphone, photo-library, contacts, tracking, advertising, or account usage description exists, which
matches the app: it never records audio and never writes to shared media.

## Storage and minimization

- The only persistent store is the app-private SQLite database described above. No file is written to
  shared or external storage on either platform.
- Snapshots keep the inputs, outputs, assumptions, and applied equipment values a user chose to save, so
  the result can be reproduced offline. They are never transmitted.
- Clearing app data or uninstalling removes every record; the app has no backup, sync, or restore path of
  its own.

## Reproduction

```sh
grep -rnE "dart:io|package:http/|HttpClient|RawSocket|Socket\(|WebSocket" lib/
grep -rnE "package:dio|firebase_|google_analytics|sentry|crashlytics" lib/
grep -rnE "'https?://|\"https?://" lib/
grep -rn "uses-permission" android/app/src/main/AndroidManifest.xml
grep -rn "UsageDescription" ios/Runner/Info.plist
flutter test test/privacy/no_network_test.dart
```

The privacy widget test installs an `HttpOverrides` guard that throws as soon as production code creates
a Dart network client, then launches the application and completes a depth-of-field journey. It covers
that one calculator journey only; inventory, saved-plan reopening, and the planners are not yet inside
the guard.

## Verification status

Statically verified for this record:

- Declared dependencies and locked versions, and the absence of any network, account, or telemetry
  package.
- The absence of network identifiers and URL literals in `lib/`.
- Permission and feature declarations in every repository manifest, and the permission declarations of
  every resolved native plugin named above.
- The three iOS usage descriptions and the absence of an entitlements file.

Not verified here, and therefore still required before release:

- The merged release manifest. Confirming that `tools:node="remove"` drops `RECORD_AUDIO` and
  `WRITE_EXTERNAL_STORAGE` needs a Gradle manifest merge, which this environment cannot run because its
  Gradle and Flutter caches sit outside the writable sandbox. The `mobile-builds` workflow is the place
  to check: it runs `flutter build apk --release` and `flutter build appbundle --release` and uploads
  both artifacts, so the merged manifest inside those artifacts must be inspected there, or on a
  workstation, before release. The workflow does not currently assert the absence of the two
  permissions.
- Runtime behavior on a device: permission prompts, denial and `deniedForever` paths, camera and sensor
  behavior, and operating-system backup or store services.
- Traffic capture. No proxy or packet capture was run, so "zero traffic" is a static conclusion from the
  source, manifests, and dependency graph, not a measurement.
- The merged iOS plugin surface. It is inferred from plugin sources and `Info.plist`; no iOS build or
  simulator run happened for this record.

## Boundary and limitations

This audit describes the current source and dependency graph. It cannot observe operating-system backup,
store services, Flutter development tooling, or future native plugins. Debug and profile builds may
contact Flutter tooling because their Android manifests deliberately include Internet permission; release
builds do not include those source sets. Repeat this audit whenever dependencies, platform permissions,
native code, or product scope changes, and re-date this record.
