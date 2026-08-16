# Feature Specification: Cross-Platform Photography Assistant

**Feature Branch**: `v2`

**Created**: 2026-08-16

**Status**: Draft

**Input**: User description: "Create a fully tested, cross-platform photography calculator and
planning assistant with reusable camera/lens inventory, photographic and macro calculators,
astrophotography tools, panorama planning, and location-aware Sun, Moon, and celestial AR planners."

## Clarifications

### Session 2026-08-16

- Q: Which platforms must the first public release support? → A: Android and iOS first; desktop and
  web follow.
- Q: Which capabilities must be included in the first public release? → A: Equipment inventory, depth
  of field, exposure comparison, and long-exposure/ND calculations only.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Calculate a Photograph (Priority: P1)

A photographer selects a calculation tool, enters or selects the required camera, lens, scene, and
exposure values, and receives a result with units, assumptions, limits, and a practical interpretation.
The initial calculation catalog includes depth of field and hyperfocal distance, exposure comparison,
long exposure and neutral-density filters, focus stacking, field of view, diffraction guidance, flash
exposure, and timelapse planning.

**Why this priority**: Accurate, fast, offline calculations provide the core value without requiring
location, sensors, or specialized hardware.

**Independent Test**: Use published reference cases for every calculator, including boundaries and unit
conversions, and confirm that users can obtain and understand matching results while offline.

**Acceptance Scenarios**:

1. **Given** valid manual inputs, **When** the user calculates a result, **Then** the app shows the result,
   units, applied formula assumptions, input summary, and limitations.
2. **Given** an input outside the tool's valid domain, **When** the user requests a result, **Then** the app
   identifies the invalid value and explains how to correct it without fabricating a result.
3. **Given** a result in one supported unit system, **When** the user changes units, **Then** displayed
   values convert without changing the underlying physical result.

---

### User Story 2 - Reuse Camera and Lens Equipment (Priority: P1)

A photographer creates an on-device inventory of camera bodies, lenses, teleconverters, extension tubes,
filters, and relevant custom equipment, then selects those items in any compatible tool instead of
re-entering their properties.

**Why this priority**: Shared, trustworthy inputs reduce errors and make every calculator faster to use.

**Independent Test**: Create, edit, duplicate, select, and delete equipment offline, then verify that a
compatible calculator uses the selected parameters and displays their origin.

**Acceptance Scenarios**:

1. **Given** saved equipment, **When** the user opens a compatible calculator, **Then** the equipment can be
   selected and its relevant values are populated visibly.
2. **Given** incomplete or unusual equipment, **When** the user saves it, **Then** required values are
   validated while supported custom values and notes are preserved.
3. **Given** a saved item used by a plan, **When** the item is edited or deleted, **Then** the app warns about
   affected plans and avoids silently changing previously saved results.

---

### User Story 3 - Plan Macro Magnification (Priority: P2)

A macro photographer compares extension tubes, a reversed lens, or two coupled lenses and obtains
magnification, effective aperture, field of view, working-distance assumptions, and exposure guidance.

**Why this priority**: Macro configurations are difficult to estimate in the field and naturally benefit
from the shared equipment inventory.

**Independent Test**: Evaluate extension-tube, reversed-lens, and dual-lens reference configurations with
manual and saved equipment values and compare outputs within each model's stated tolerance.

**Acceptance Scenarios**:

1. **Given** a lens and extension length, **When** the user calculates, **Then** estimated magnification and
   exposure effects are shown with the assumptions behind the estimate.
2. **Given** reversed or coupled lenses, **When** the user selects the configuration, **Then** the app asks
   only for parameters relevant to that model and does not imply unsupported precision.

---

### User Story 4 - Plan Night-Sky Photography (Priority: P2)

A photographer chooses a location, date, time, direction, camera, lens, and celestial target to see its
position and visibility, plan Milky Way or star-trail composition, and estimate a maximum shutter time
for acceptably sharp stars.

**Why this priority**: It combines calculation and planning into a high-value field workflow while still
remaining useful without AR.

**Independent Test**: For known locations and timestamps, compare rise/set, altitude, azimuth, Milky Way
orientation, target visibility, and shutter guidance with authoritative fixtures, then repeat with network
and sensor access disabled.

**Acceptance Scenarios**:

1. **Given** a location and time, **When** the user selects a supported celestial target, **Then** its
   altitude, azimuth, visibility state, and relevant event times are displayed with time-zone context.
2. **Given** camera and lens parameters, **When** the user requests shutter guidance, **Then** the app shows
   the result for each supported rule, the chosen tolerance, and that the value is an estimate.
3. **Given** AR is unavailable or denied, **When** the user opens the sky planner, **Then** an equivalent map,
   compass, timeline, and numeric view remains usable.

---

### User Story 5 - Plan Sun and Moon Alignment (Priority: P2)

A photographer selects a shooting position, target position or desired bearing, elevation information,
and date range to find when the Sun or Moon aligns with the intended composition, then inspects the event
on a map, timeline, or AR overlay.

**Why this priority**: Alignment search turns astronomical data into a concrete shooting opportunity and
is a distinctive assistant capability.

**Independent Test**: Search known solar and lunar alignment cases across elevation, horizon, time-zone,
and daylight-saving boundaries and verify that results agree with authoritative fixtures within the
declared angular and temporal tolerances.

**Acceptance Scenarios**:

1. **Given** valid observer and target geometry, **When** the user searches a date range, **Then** candidate
   alignments are ordered by closeness and include time, azimuth, altitude, angular error, and assumptions.
2. **Given** terrain or elevation data is missing, **When** the user plans an alignment, **Then** the app
   states the fallback assumption and allows manual elevation entry.
3. **Given** the Sun is selected, **When** any optical or AR view is shown, **Then** the app displays an
   appropriate solar-viewing safety warning.

---

### User Story 6 - Plan Panoramas and Stacks (Priority: P3)

A photographer selects camera, lens, orientation, overlap, scene bounds, and focus range to determine
panorama frame counts, capture positions, final field of view, and focus-stack steps.

**Why this priority**: Structured capture plans prevent gaps and missed focus while extending the same
geometry and equipment model used by core calculators.

**Independent Test**: Generate horizontal, vertical, multi-row, and focus-stack plans from reference
inputs and verify coverage, overlap, ordering, and boundary handling.

**Acceptance Scenarios**:

1. **Given** panorama bounds and overlap, **When** the user creates a plan, **Then** the app shows the minimum
   frame grid, orientation, movement increments, coverage, and overlap.
2. **Given** near and far focus limits, **When** the user creates a focus-stack plan, **Then** the app lists
   ordered focus distances with the chosen overlap or sharpness criterion.

---

### User Story 7 - Save and Use a Field Plan (Priority: P3)

A photographer saves a calculation or location-based plan, adds notes, revisits it offline, and follows a
concise field checklist without losing the original assumptions.

**Why this priority**: Planning is only useful if results remain available and understandable at the
shooting location.

**Independent Test**: Save each supported result type, disable connectivity, change current preferences or
equipment, and verify that the saved snapshot and checklist remain complete and unchanged.

**Acceptance Scenarios**:

1. **Given** a completed calculation or plan, **When** the user saves it, **Then** all inputs, outputs,
   assumptions, equipment references, location/time context, and notes are retained as a snapshot.
2. **Given** no connectivity, **When** the user opens a saved plan, **Then** all previously stored planning
   details remain available and stale or unavailable dynamic data is identified.

### Edge Cases

- Zero, negative, non-finite, physically impossible, extreme, or mutually inconsistent inputs.
- Very near focus distances, focus at infinity, crop and nonstandard sensor sizes, adapted lenses, and
  missing entrance-pupil or focal-plane data.
- Polar day/night, celestial objects that never rise or set, dates around leap days, daylight-saving
  changes, time-zone boundary changes, and locations near the poles or antimeridian.
- Magnetic versus true north, low-quality compass calibration, device motion, obstructed sensors, and
  denied camera, orientation, or location permissions.
- Below-horizon targets, negative elevations, large observer/target elevation differences, atmospheric
  refraction near the horizon, terrain occlusion, and missing elevation data.
- Unsupported AR hardware, inaccurate alignment, landscape/portrait rotation, and interrupted sessions.
- Inventory edits that would invalidate a calculation, duplicate equipment names, and user-supplied
  values that conflict with reference data.
- Rounding at conventional shutter, aperture, ISO, focal-length, and filter-stop increments.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The product MUST provide a browsable, searchable, and favoritable catalog of calculators and
  planners grouped by photographic purpose.
- **FR-002**: Every calculator MUST accept manual inputs, label units, validate its domain, show applied
  assumptions, and explain its result and limitations.
- **FR-003**: The product MUST provide depth-of-field and hyperfocal, exposure comparison, long-exposure and
  neutral-density, focus-stacking, field-of-view, diffraction, flash-exposure, and timelapse tools.
- **FR-004**: The product MUST provide extension-tube, reversed-lens, and dual-lens macro tools that expose
  magnification and related optical or exposure effects supported by each model.
- **FR-005**: The product MUST provide astrophotography shutter guidance with selectable supported rules,
  camera/lens inputs, tolerance explanation, and star-trail planning.
- **FR-006**: The product MUST provide panorama planning for horizontal, vertical, and multi-row capture,
  including overlap, orientation, frame count, movement increments, and resulting coverage.
- **FR-007**: Users MUST be able to maintain an offline inventory of camera bodies, lenses, converters,
  extension tubes, and filters, including custom equipment and user-overridden parameters.
- **FR-008**: Compatible tools MUST accept inventory selections, visibly identify all applied equipment
  values and sources, and permit per-calculation overrides without silently modifying inventory.
- **FR-009**: The product MUST provide location- and time-based positions, paths, rise/set/transit events,
  and visibility for the Sun, Moon, Milky Way, planets, and a maintained catalog of notable deep-sky
  targets suitable for photographic planning.
- **FR-010**: Users MUST be able to search a date range for Sun or Moon alignment with a specified bearing,
  target position, angular tolerance, observer elevation, and target elevation.
- **FR-011**: Celestial and alignment planners MUST provide map, compass, timeline, and numeric views; where
  supported and permitted, an AR view MUST overlay the same plan on the live camera view.
- **FR-012**: AR and compass views MUST display calibration and accuracy state and MUST not conceal planning
  functions when hardware or permissions are unavailable.
- **FR-013**: Planning results MUST identify location, local time, time zone, north reference, elevation,
  refraction or horizon assumptions, source freshness, and expected accuracy where relevant.
- **FR-014**: Users MUST be able to save plans and calculation snapshots with inputs, outputs, equipment,
  assumptions, time/location context, notes, and a field checklist.
- **FR-015**: Calculators, inventory, saved snapshots, and locally computable astronomical planning MUST
  remain usable without an active network connection.
- **FR-016**: Location, orientation, inventory, plans, and usage data MUST remain on the user's device by
  default, with explicit consent required before any transmission or sharing.
- **FR-017**: The product MUST request location, camera, and sensor permissions only when a user starts a
  function that requires them and MUST explain the available fallback when access is denied.
- **FR-018**: Sun-related views MUST display solar observation safety guidance before users rely on optical
  alignment, and all estimates MUST be clearly distinguished from guarantees.
- **FR-019**: Core workflows MUST support screen readers, scalable text, sufficient contrast, large touch
  targets, non-color-only meaning, and a low-light viewing mode.
- **FR-020**: The product MUST support metric units and conventional photographic notation, preserve
  physical equivalence during conversion, and remember user preferences locally.
- **FR-021**: The product MUST identify stale, missing, unsupported, or low-confidence information rather
  than silently substituting plausible values.
- **FR-022**: Every released calculation path MUST be verifiable against documented reference fixtures,
  and every user workflow MUST have repeatable acceptance coverage on each applicable platform class.
- **FR-023**: The first public release MUST support Android and iOS. Later desktop and web releases MUST
  preserve compatible calculation results and saved-data meaning, with AR remaining capability-gated.
- **FR-024**: The first public release MUST include only the shared equipment inventory, depth-of-field
  and hyperfocal calculation, exposure comparison, and long-exposure/neutral-density calculation. Other
  specified tools MUST be delivered incrementally after this foundation meets its release criteria.

### Key Entities

- **Equipment Item**: A camera, lens, converter, tube, or filter with identity, relevant physical
  parameters, value provenance, user overrides, and notes.
- **Calculation Definition**: A named photographic model with inputs, units, valid domain, assumptions,
  outputs, explanation, limitations, and reference fixtures.
- **Calculation Snapshot**: An immutable record of inputs, selected equipment values, outputs, units,
  assumptions, and creation context.
- **Location**: Coordinates, elevation, time-zone context, source, accuracy, and optional label.
- **Celestial Target**: A Sun, Moon, Milky Way, planet, or catalog object with identity and planning data.
- **Observation Plan**: A target, location, time or range, direction, equipment, predicted events,
  uncertainty, notes, and field checklist.
- **Alignment Candidate**: A predicted time and geometry with azimuth, altitude, angular error, visibility,
  elevation assumptions, and confidence information.
- **User Preferences**: Units, north reference, low-light presentation, default tolerances, favorites, and
  permission choices.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of released calculator reference fixtures match their documented expected values within
  the declared tolerance, including boundary and unit-conversion cases.
- **SC-002**: At least 90% of representative photographers can obtain and correctly interpret a core
  calculator result on their first attempt in under 60 seconds.
- **SC-003**: At least 90% of representative photographers can create equipment and reuse it in a compatible
  tool in under two minutes without re-entering shared parameters.
- **SC-004**: For authoritative astronomical fixtures, displayed event times and sky positions remain
  within the accuracy tolerance declared by the product for 100% of supported locations and date ranges.
- **SC-005**: Users can access every calculator, their equipment inventory, and all previously saved plans
  after a cold start with network access disabled.
- **SC-006**: Every AR-assisted workflow has a functionally equivalent non-AR planning path and can be
  completed when camera, orientation, or precise-location permission is denied.
- **SC-007**: All critical user journeys pass automated acceptance checks on every supported platform class,
  with no unresolved critical or high-severity accessibility defects at release.
- **SC-008**: A saved plan preserves 100% of the inputs, outputs, assumptions, equipment values, and
  time/location context needed to reproduce or explain its result.
- **SC-009**: Common calculator results appear within one second of the final input on representative
  supported devices; a one-year alignment search completes within five seconds.
- **SC-010**: No location, orientation, equipment, plan, or usage data leaves the device during default and
  offline use, as verified by release privacy testing.
- **SC-011**: All first-release acceptance scenarios pass on both Android and iOS; subsequent platform
  releases produce equivalent results for the same calculation fixtures.
- **SC-012**: The first public release ships no calculator or planner outside the scope of FR-024 unless
  its full reference, accessibility, offline, privacy, and cross-platform acceptance criteria also pass.

## Assumptions

- Android and iOS phones and tablets are the first public-release platforms. Desktop and web follow with
  calculators, inventory, maps, and planning views, while sensor- and camera-dependent AR remains
  capability-gated.
- No account is required for the baseline product. Optional synchronization, community content, or sharing
  services require separate future specifications.
- Equipment can be entered manually from launch. Any bundled equipment catalog must expose data provenance
  and allow correction; acquiring or licensing a comprehensive catalog is outside this baseline feature.
- Weather, cloud, smoke, aurora, light-pollution, and satellite-transit forecasts are valuable future
  planning modules but are excluded until their external data sources, cost, licensing, privacy, and
  offline behavior receive separate specifications.
- Camera remote control, image capture, editing, raw processing, and automatic image analysis are outside
  the baseline scope.
- Astronomical output is planning guidance, not navigation or observatory-grade measurement.
- The project will ship incrementally in priority order; the complete catalog is the product target, not a
  requirement that every tool appear in the first public release.
- The deliberately small first release validates the shared domain, inventory, persistence, accessibility,
  and mobile delivery foundations before additional calculator or planner scope is accepted.
