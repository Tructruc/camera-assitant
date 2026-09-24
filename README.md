# Photography Assistant

An offline-first Flutter application for dependable photographic planning on Android and iOS.

> [!WARNING]
> This project and its current implementation were produced entirely by AI. It has not received a
> complete independent human code, security, accessibility, or photographic-accuracy review. Treat all
> calculations as estimates, verify important results with trusted references and your own equipment,
> and do not rely on the app for safety-critical decisions. The software is provided without warranty;
> inspect the source and release provenance before installing or using it.

Delivered scope: reusable camera, lens, ND-filter, optical-accessory, and converter inventory;
depth-of-field and hyperfocal; exposure comparison; long-exposure/ND timing; diffraction guidance; field
of view; focus-stack planning; flash exposure; timelapse planning; macro (extension-tube, reversed-lens,
and coupled-lens) planning; panorama planning; and an offline celestial planner for the Sun, Moon, planets,
the Milky Way core, and a bundled deep-sky catalog, with rise/transit/set events and sharp-star shutter
guidance. Sun and Moon alignment searches add dated composition candidates, and the planning views offer
numeric, timeline, compass, offline-map, and capability-gated live-AR presentations. Calculations preserve
canonical values and expose their assumptions, warnings, formula version, applied equipment, and
limitations; saved results and plans are immutable.

## Development

The supported baseline is Flutter 3.47.x stable with its bundled Dart 3.13. CI verifies that baseline;
`pubspec.yaml` keeps a lower floor (`>=3.41.0`) so an older stable can still resolve, but only 3.47.x is
tested.

```sh
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

If the Flutter SDK checkout is read-only, run the same arguments through the wrapper instead:
`./.tooling/flutterw --no-version-check <args>` (see [CONTRIBUTING.md](CONTRIBUTING.md)).

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
