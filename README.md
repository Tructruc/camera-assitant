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
