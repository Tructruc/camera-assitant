# Camera Assistant (Flutter)

## Warning : This project is almost entirely made with AI, and is not intended for production use. It may contain errors, inaccuracies, or incomplete features. Use at your own risk and verify results independently.

Initial Flutter app scaffold for photography tools.

## Implemented Tools

1. Exposure calculator
- Solves one variable (`shutter`, `aperture`, or `ISO`) from equivalent exposure.

2. DOF calculator
- Hyperfocal distance, near/far limits, and total depth of field.

3. Macro tools
- Extension tube estimator for focus range, macro ratio, effective aperture, and light loss.
- Reverse lens estimator for magnification, effective aperture, light loss, and focus distance.

4. Sun planner
- Sunrise/sunset and civil/nautical/astronomical twilight.
- Blue/golden hour windows from sun altitude thresholds.

5. Long exposure + motion path
- ND stop/factor based long exposure conversion.
- Physical path length from speed and exposure.
- Sensor streak estimate in mm and px.

## Core Formulas

- Equivalent exposure constant: `K = (N^2 / t) * (100 / ISO)`
- EV100: `log2(N^2 / t)`
- Hyperfocal: `H = f^2 / (N * c) + f`
- Near limit: `Dn = (H * s) / (H + (s - f))`
- Far limit: `Df = (H * s) / (H - (s - f))`
- Extension tube magnification gain: `m_add = extension / f`
- Effective macro aperture: `N_eff = N * (1 + m)`
- Thin-lens sensor distance: `s = f * (2 + m + 1/m)`
- ND conversion: `t2 = t1 * 2^stops` or `t2 = t1 * factor`
- Physical light path: `distance = speed * exposure`
- Sensor streak approximation: `streak_mm = f_mm * distance_m / subjectDistance_m`

## Run

Prerequisite: Flutter SDK installed and available in `PATH`.

```bash
flutter pub get
flutter run
```

If this folder has never been initialized with platform directories, run:

```bash
flutter create .
flutter pub get
flutter run
```
