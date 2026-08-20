# Photography Assistant

An offline-first Flutter application for dependable photographic planning on Android and iOS.

The first release includes reusable camera, lens, and ND-filter inventory; depth-of-field and
hyperfocal calculations; exposure comparison; long-exposure/ND timing; and immutable saved results.
Calculations preserve canonical values and expose their assumptions, warnings, and formula version.

## Development

The supported baseline is Flutter 3.44.x stable with Dart 3.10 or newer.

```sh
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

See [the feature quickstart](specs/001-photography-assistant/quickstart.md) for full validation.

## Privacy

The first release has no account, telemetry, advertising, or network-backed features. Equipment,
preferences, and saved calculations remain on the device.

## Backup and recovery

Photography Assistant stores its data in the app's private SQLite database. Android and iOS normally
include that private data in their platform-managed application backup when device backup is enabled.
The app does not upload a separate cloud copy and cannot restore data from another account or service.

Before uninstalling, clearing application storage, changing signing keys, or installing a build whose
application identifier differs, make a platform backup if the equipment and saved calculations matter.
Uninstalling or clearing storage can permanently remove the local database. Installing a newer build
with the same application identifier and signing identity upgrades the database in place.

If a saved calculation was written by a newer payload version or its JSON is damaged, the Saved screen
shows a recovery record instead of deleting or silently rewriting it. Keep the application data intact
and upgrade to a compatible version. Developers diagnosing a database should work on a copy: SQLite
databases can have `-wal` and `-shm` companion files, which must be copied together while the app is not
running to obtain a consistent backup.

Schema compatibility is guarded by frozen fixtures in `test/fixtures/database/`. Every schema-version
change must retain the previous fixtures, add a new fixture, and prove that equipment, preferences,
snapshot payloads, and their reference links survive migration before release.
