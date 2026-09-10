# Android validation — 2026-09-07

## Environment

- Fedora Linux host; Android Emulator 36.4.9 with KVM and host graphics.
- Isolated `camera_test` Pixel 2 AVD, x86_64 Android 16 / API 36, created from the installed
  `android-36.1/google_apis_playstore/x86_64` image. Resolution: 1080 × 1920, density 420.
- Headless startup flags: `-no-window -no-audio -no-snapshot -gpu host -feature -Vulkan -cores 2`.
  SwiftShader crashed during startup; the host graphics configuration boots and runs the app.
- Wi-Fi and mobile data disabled; both Android settings report `0` throughout the final test run.

## Verified automated checks

| Check | Result |
|---|---|
| `flutter analyze --fatal-infos` | No issues |
| `flutter test --reporter expanded` | 195 passed |
| `flutter test integration_test -d emulator-5554 --reporter expanded` | 4 passed |
| `flutter build appbundle --debug` | Built Android app bundle |
| `flutter build apk --debug` | Built and installed normal APK |
| Formatting of `lib`, `test`, `integration_test` | Applied and checked |
| `git diff --check` | Passed |

The emulator journeys recorded in this run cover:

1. Camera creation, provider-tree rebuild, referenced-equipment archive, restore, and preservation of
   the referencing saved plan. Uses an in-memory database.
2. Flash and timelapse calculations and saving their results. Uses an in-memory database.
3. Saved camera/lens selection, depth of field, exposure comparison, a 10-stop ND calculation, immutable
   snapshots after equipment/preference changes, and corrupt-result recovery. Uses an in-memory database.
4. Milky Way orientation presentation and saved convention, closing and reopening a real SQLite file,
   identical snapshot content, and reopening that plan through the Saved screen. Uses an
   isolated temporary file on the emulator; the test removes its own file afterward.

`integration_test/calculator_flows_test.dart` also defines
`editing an input blocks saving until the result is recalculated`, which calculates a depth-of-field
result, edits the focal length, verifies the result and the save action disappear, recalculates, and saves
exactly one snapshot. Added on 2026-09-10 and executed successfully on a host build of the same
integration target (`flutter test integration_test/calculator_flows_test.dart`, 3/3 journeys passed,
Linux debug bundle); Android device execution still belongs to the T058/T061 quickstart pass.

`integration_test/optics_flows_test.dart` was added on the same date and covers field of view,
diffraction guidance, the focus stack planner, the macro planner, and the panorama planner offline in one
journey. It passes on the host engine (1/1) and likewise awaits the next device pass.

`integration_test/preferences_flow_test.dart` covers quickstart scenarios 4, 22, and 23 end to end: a
display and shutter preference change alters presentation, an already saved plan keeps its own display
context and canonical values, and the same calculation then renders imperial units. It passes on the host
engine (1/1). With these, the suite defines six Android journeys rather than four.

The local suite additionally covers the independent orientation references and singularities, 200%
text scaling, camera notes, permanent deletion guards, input-summary semantics, golden layout, and a
frozen v5-to-v6 migration retaining equipment, preferences, locations, payloads and reference links.

## Normal-app visual and cold-restart check

Installed the normal debug APK and opened Night-sky planner through the catalog. With the default
Greenwich location at 2026-09-07 09:00 UTC, the result displays 160.7° relative to the horizon and
explicitly shows that the core is below the horizon. The input summary and result rows are legible
without clipping in the inspected view. See [the result screenshot](android-milky-way.png).

Saved this plan, issued `am force-stop`, launched a fresh app process and reopened the plan from
Saved. The original timestamp and full-precision `milkyWayOrientationDegrees: 160.69204155901502`
remain available. See [the reopened plan](android-saved-plan.png). This checks one real process
restart in addition to the automated database-close/reopen scenario.

## Remaining release evidence

This is partial Android quickstart evidence, not a completed device acceptance or usability sign-off.
T058 and T061 remain open until every quickstart scenario has been exercised and recorded, including
permission transitions, real sensor/camera behavior, screen-reader operation and representative-device
performance. The integration tests do not simulate Android killing the app process; the normal-app
check above covers one force-stop/relaunch case. iOS validation (T059) and representative-photographer
usability work (T062) remain open.
