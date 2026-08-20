# Phase 0 Research: Photography Assistant Foundation

## Flutter and Dart baseline

**Decision**: Build on Flutter 3.44.x stable and Dart 3.10+, pinning the exact SDK in project and CI
configuration.

**Rationale**: The first release needs Android and iOS from one codebase, while later desktop/web support
must remain viable. Flutter officially supports the needed platform model and its current documentation is
based on 3.44.7. Dart provides deterministic, testable calculation code independent of widgets.

**Alternatives considered**: Kotlin Multiplatform with separate native UIs increases first-release UI and
test work; React Native adds a second runtime boundary for numerical domain code; two native applications
duplicate calculation, persistence, and acceptance logic.

**References**: [Flutter releases](https://docs.flutter.dev/release),
[platform integration](https://docs.flutter.dev/platform-integration)

## Application architecture

**Decision**: Use feature-oriented slices over presentation, domain, and data boundaries. Keep calculators
as immutable-input pure functions/services. Use repository interfaces between domain/application logic and
local persistence. Use Riverpod for dependency wiring and presentation state, without exposing providers
inside the domain.

**Rationale**: Flutter's architecture guidance recommends separating views/view models from repositories
and services to improve testability. Feature slices keep future calculators independent, while explicit
interfaces allow in-memory tests and later persistence/platform adaptations.

**Alternatives considered**: A global layer-only tree becomes difficult to navigate as calculator count
grows; putting formulas in widgets prevents deterministic unit testing; a service locator hides dependency
graphs; full Clean Architecture ceremony would add abstractions without v1 value.

**References**: [Flutter architecture guide](https://docs.flutter.dev/app-architecture/guide),
[Riverpod package](https://pub.dev/packages/flutter_riverpod)

## Physical quantities and numerical correctness

**Decision**: Normalize lengths to millimetres, exposure duration to seconds, aperture to positive f-number,
sensitivity to positive ISO, and exposure differences to base-2 stops. Use typed value objects with finite,
domain-specific validation. Each calculator returns raw values plus formula ID/version, assumptions,
warnings, and a validity status; formatting and conventional rounding occur only at the presentation edge.

**Rationale**: Keeping exact domain values separate from display rounding prevents cumulative conversion
errors and makes fixtures reproducible. Formula metadata lets saved snapshots remain explainable if a model
changes later.

**Alternatives considered**: Passing primitive doubles permits unit mistakes; rounding inside formulas
breaks equivalence across display units; arbitrary-precision decimal arithmetic is unnecessary for these
optical formulas when tolerances are explicit.

## Depth-of-field model

**Decision**: Use the thin-lens depth-of-field model with focal length, f-number, focus distance, and circle
of confusion. Return hyperfocal distance, near limit, far limit (including infinity), total depth, front and
rear depth, and explicit model limitations. Let users enter circle of confusion directly or derive it from
a saved sensor profile using a documented default criterion.

**Rationale**: The model is transparent, widely reproducible, works offline, and supports both inventory and
manual input. Direct override avoids pretending one circle-of-confusion convention is universally correct.

**Alternatives considered**: Manufacturer-specific depth tables are incomplete and hard to license;
diffraction-aware or pupil-magnification models can be later opt-in calculation variants.

**Reference basis**: Carl Zeiss Camera Lens Division's technical treatment documents circle-of-confusion
criteria and the dependence of perceived depth of field on viewing conditions. Published Zeiss depth-of-
field tables provide independent numeric fixtures. The implementation task MUST record the exact formula,
fixture source, input convention, and tolerance beside every fixture.

**References**: [Zeiss: Depth of Field and Bokeh](https://lenspire.zeiss.com/photo/app/uploads/2018/04/Article-Bokeh-2010-EN.pdf),
[Zeiss depth-of-field tables](https://www.zeiss.com/content/dam/consumer-products/downloads/cinematography/manuals/en/depth-of-field-tables/manual-depth-of-field-tables-zeiss-cinema-zoom-70-200mm.pdf)

## Exposure and ND models

**Decision**: Represent exposure value differences as `log2` stop deltas from aperture, shutter time, and
ISO ratios. Long-exposure calculation applies filter strength in stops (`newTime = baseTime × 2^stops`),
supports stacked filters by summing stops, and offers conventional shutter-time formatting without changing
the raw seconds result.

**Rationale**: Base-2 stop arithmetic directly matches photographic practice, supports partial stops, and
is straightforward to verify with exact fixtures.

**Alternatives considered**: Lookup tables alone cannot handle arbitrary partial stops; optical-density and
filter-factor input remain presentation conversions into the canonical stop value.

**Reference basis**: Nikon's exposure guidance defines a full stop as twice or half the captured light and
identifies shutter speed, aperture, and ISO as the exposure controls. Manufacturer guidance also documents
ND filters in stop values for obtaining longer shutter times. Calculator fixtures MUST cite their source or
show an independent derivation from these relationships and declare a numerical tolerance.

**References**: [Nikon exposure fundamentals](https://www.nikonusa.com/learn-and-explore/c/tips-and-techniques/a-basic-look-at-the-basics-of-exposure),
[Nikon long-exposure and ND guidance](https://www.nikonusa.com/learn-and-explore/c/tips-and-techniques/creating-a-long-exposure-look-without-the-wait-or-nd-filter)

## Local persistence

**Decision**: Use SQLite through Drift with versioned migrations. Store equipment and calculation snapshots
relationally, encode enum-like values as stable text identifiers, use UUID-style locally generated IDs, and
test against an in-memory database.

**Rationale**: Typed queries and explicit schema migrations fit structured equipment data and immutable
snapshots, while Drift supports the planned later platforms. SQLite provides durable transactional local
storage without an account or service.

**Alternatives considered**: Shared preferences are unsuitable for relational records and migration;
untyped JSON files make atomic updates and queries fragile; an object database adds proprietary data-model
coupling without a v1 need.

**References**: [drift_flutter](https://pub.dev/packages/drift_flutter),
[Drift native backend](https://pub.dev/documentation/drift/latest/native/)

## Testing and CI

**Decision**: Apply a pyramid: exhaustive deterministic unit fixtures for formulas and quantities; database
tests for constraints and migrations; widget/semantics tests for every state; limited golden tests for theme
regression; integration tests for inventory-to-calculator journeys; Android and iOS build/smoke jobs. GitHub
CI runs formatting, analysis, unit/widget/data tests and an Android build on Linux for every pull request;
iOS build and simulator smoke tests run on macOS. Release testing includes representative real devices.

**Rationale**: Flutter distinguishes unit, widget, and integration testing and recommends many fast tests
plus enough integration coverage for important use cases. Platform builds catch native configuration drift.

**Alternatives considered**: An integration-heavy suite is slow and brittle; global line coverage alone
does not prove formula branches; snapshot-only UI testing misses semantics and behavior.

**References**: [Flutter testing overview](https://docs.flutter.dev/testing/overview),
[integration testing](https://docs.flutter.dev/testing/integration-tests),
[continuous delivery](https://docs.flutter.dev/deployment/cd)

## Privacy, observability, and failure behavior

**Decision**: Ship v1 without accounts, network clients, advertising, analytics, or crash-report uploads.
Use structured local diagnostic events with sensitive values redacted and an explicit user action to export
a diagnostic report in a future scoped feature. Validation failures are typed domain results, never silent
fallback calculations.

**Rationale**: This meets local-only privacy requirements and keeps offline behavior deterministic. Local
logs remain useful during development without creating an undisclosed data path.

**Alternatives considered**: Default cloud telemetry conflicts with the privacy baseline; swallowing errors
can produce plausible but unsafe photographic guidance.

## Core optics expansion

**Decision**: Field of view uses rectilinear pinhole geometry; diffraction reports the first Airy-minimum
diameter `2.44 × wavelength × f-number`; focus-stack planning uses the existing thin-lens depth-of-field
criterion and emits conservative ordered near-to-far focus positions with user-selected overlap.

**Rationale**: These models are deterministic, explainable, useful offline, and share the already tested
sensor, focal-length, aperture, distance, and circle-of-confusion inputs. Results explicitly describe
distortion, focus breathing, broadband light, close-focus, and distance-scale limitations.

**Alternatives considered**: Lens-specific projection/distortion profiles and wave-optics simulation imply
unsupported precision without calibrated lens data. Image-analysis-driven stacking requires captured image
access and belongs outside this planning calculator.
