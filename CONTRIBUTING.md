# Contributing

## Local verification

Use the Flutter version declared in `pubspec.yaml`, then run the same checks as CI:

```sh
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos
flutter test
```

Changes to persistence must also retain every frozen fixture under `test/fixtures/database/`. Add a
fixture for each new schema version and verify that older equipment, preferences, calculations, and
reference links remain readable.

## Branch and pull-request workflow

The active development branch is `v2`. As verified on 21 August 2026, GitHub branch protection is not
enabled for `v2`; repository administrators can therefore push directly. Contributors should still use
a topic branch and pull request for review:

1. Branch from the current `v2` head.
2. Keep commits scoped and do not commit signing files, local databases, or generated build output.
3. Open a pull request targeting `v2` and wait for both required workflows to pass.
4. Review changes to formulas, schema versions, signing, permissions, and release workflows explicitly.
5. Merge without rewriting published release commits unless repository maintainers agree otherwise.

For enforced protection, configure `v2` to require a pull request and the `quality`, `android`, `ios`,
`android-integration`, and `ios-integration` status checks, require the branch to be up to date, dismiss
stale approvals, and prevent force pushes and deletions. Do not enable those rules until the repository
owner decides whether direct pushes should remain part of the current development workflow.

## CI and release artifacts

`CI` runs formatting, strict analysis, and the complete device-independent test suite on pushes to `v2`
or `main` and on every pull request. `Mobile builds` validates Android and iOS on every push and pull
request. Android and iOS simulators additionally run the complete offline equipment, calculator,
restart, snapshot-mutation, and recovery journeys. Pull requests use unsigned/debug validation
artifacts and cannot publish a release.

Pushes to `v2` publish the rolling `continuous-v2` prerelease after both platforms build successfully.
The same build runs nightly at 02:17 UTC, explicitly checking out `v2`, and refreshes that prerelease.
Mobile runs are queued rather than cancelled when another commit arrives, so every pushed commit retains
its platform evidence. Only the publish job receives contents-write permission; build and integration
jobs remain read-only.
The Android APK uses the persistent repository signing key so it can update an earlier installed build.
The Android App Bundle is retained as a workflow artifact. The iOS ZIP is an unsigned simulator build;
physical iPhone installation requires a separately configured Apple signing identity and provisioning
profile.
