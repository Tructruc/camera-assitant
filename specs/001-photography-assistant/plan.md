# Implementation Plan: Photography Assistant Foundation

**Branch**: `v2` | **Date**: 2026-08-16 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/001-photography-assistant/spec.md`

## Summary

Deliver a small, offline Android/iOS application containing camera and lens inventory, depth-of-field
and hyperfocal calculation, exposure comparison, and long-exposure/ND calculation. Use Flutter with a
pure Dart domain layer, feature-oriented presentation, and typed local SQLite persistence. Establish the
architecture, calculation contracts, accessibility behavior, reference fixtures, GitHub CI, and test
pyramid that later macro, panorama, astronomical, and AR features can extend without rewriting the core.

## Technical Context

**Language/Version**: Dart 3.10+ with Flutter 3.44.x stable

**Primary Dependencies**: Flutter SDK and Material; Riverpod 3.x for explicit dependency/state wiring;
Drift 2.x with drift_flutter for typed SQLite access and migrations; intl for unit-aware formatting;
go_router only if navigation outgrows the initial shell

**Storage**: On-device SQLite for equipment, preferences, and immutable calculation snapshots; no remote
storage or account in v1

**Testing**: Dart unit tests, Flutter widget and semantics tests, Drift in-memory database tests, golden
tests for a small stable visual set, Flutter integration_test for primary journeys, and Android/iOS
real-device or simulator smoke tests

**Target Platform**: First release: Android and iOS phones/tablets supported by Flutter 3.44 stable;
portable domain/data contracts prepared for later web and desktop targets

**Project Type**: Cross-platform mobile application with a reusable pure Dart domain core

**Performance Goals**: Calculator result update under 100 ms p95 after valid input; inventory screen ready
under 500 ms p95 for 1,000 items; cold launch to interactive under 2 seconds on representative mid-range
devices; scrolling sustains 60 frames per second

**Constraints**: Offline-first; no account or telemetry; all physical quantities normalized to SI inside
the domain; deterministic calculations; accessibility at 200% text scale; no platform API in domain code;
no AR, maps, location, or network dependency in v1

**Scale/Scope**: Four first-release capabilities, approximately 8-12 primary screens/sheets, up to 1,000
equipment records and 10,000 saved snapshots per installation, English UI initially with all strings and
units structured for later localization

## Constitution Check

*GATE: Passed before Phase 0 and re-checked after Phase 1.*

| Principle or constraint | Design evidence | Status |
|-------------------------|-----------------|--------|
| Photographic correctness | Pure calculators, explicit quantity types, formula/version metadata, cited reference fixtures, and tolerance-based tests | PASS |
| Test-first quality | Unit/widget/database/integration/device layers and CI gates are defined in research and quickstart | PASS |
| Cross-platform, offline-first core | Pure Dart domain; repository boundaries; local SQLite; no v1 network dependency | PASS |
| Privacy, safety, honest guidance | No account/telemetry; local-only data; assumptions and limitations are contract fields | PASS |
| Accessible field experience | Semantics, 200% text scale, contrast, large targets, low-light theme, and recovery errors are acceptance contracts | PASS |
| Equipment provenance | User-entered source and per-calculation applied values are persisted and displayed | PASS |
| GitHub CI | Format, analysis, tests, coverage checks, and Android/iOS build validation are required | PASS |

Post-design re-check: contracts preserve formula identity, units, provenance, validation, accessibility,
and immutable snapshot semantics. No constitutional exception or complexity waiver is required.

## Project Structure

### Documentation (this feature)

```text
specs/001-photography-assistant/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── feature-contracts.md
└── tasks.md
```

### Source Code (repository root)

```text
lib/
├── app/
│   ├── app.dart
│   ├── navigation.dart
│   └── theme/
├── core/
│   ├── domain/
│   │   ├── quantities/
│   │   ├── validation/
│   │   └── calculation_result.dart
│   ├── data/
│   │   ├── database/
│   │   └── repositories/
│   └── presentation/
├── features/
│   ├── equipment/
│   │   ├── domain/
│   │   ├── data/
│   │   └── presentation/
│   ├── depth_of_field/
│   │   ├── domain/
│   │   └── presentation/
│   ├── exposure_comparison/
│   │   ├── domain/
│   │   └── presentation/
│   └── long_exposure/
│       ├── domain/
│       └── presentation/
└── main.dart

test/
├── fixtures/
├── unit/
├── widget/
├── data/
└── golden/

integration_test/
├── equipment_flow_test.dart
└── calculator_flows_test.dart

android/
ios/
.github/workflows/
```

**Structure Decision**: One Flutter application with feature-oriented vertical slices. Calculation code
is pure Dart under each feature's domain directory; shared physical quantities and validation remain in
`core/domain`. Persistence implementations remain behind repository interfaces. This keeps v1 simple while
allowing later tools to reuse stable contracts without depending on Flutter widgets or SQLite.

## Complexity Tracking

No constitution violations require justification.
