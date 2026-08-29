# Data Model: Photography Assistant Foundation

## Shared value objects

All quantities are immutable and finite. Domain values retain full precision; display preferences never
alter stored/calculated values.

| Value object | Canonical representation | Validation |
|--------------|--------------------------|------------|
| Length | millimetres (`double`) | finite; positive unless zero is explicitly meaningful |
| Focus distance | millimetres or infinity | positive finite value or explicit infinity |
| Aperture | f-number (`double`) | finite and greater than zero |
| Exposure time | seconds (`double`) | finite and greater than zero |
| Sensitivity | ISO (`double`) | finite and greater than zero |
| Stop difference | base-2 stops (`double`) | finite; may be positive, zero, or negative |
| Filter strength | stops (`double`) | finite and non-negative |
| Circle of confusion | millimetres (`double`) | finite and greater than zero |

## Camera Body

Represents a user-owned or custom camera.

- `id`: stable locally generated identifier
- `name`: required user-visible name, unique after case/whitespace normalization among active cameras
- `sensorWidthMm`, `sensorHeightMm`: positive dimensions
- `defaultCircleOfConfusionMm`: optional positive override/derived value
- `sourceType`: `user`, `bundled`, or `user_override`
- `sourceNote`: optional provenance text
- `createdAt`, `updatedAt`: UTC timestamps
- `archivedAt`: optional UTC timestamp; referenced records are archived rather than hard-deleted

## Lens

Represents a prime or zoom lens.

- `id`, `name`, provenance and lifecycle fields as for Camera Body
- `minimumFocalLengthMm`, `maximumFocalLengthMm`: positive; maximum is not less than minimum
- `minimumAperture`: optional positive widest f-number at minimum focal length
- `maximumFocalLengthMinimumAperture`: optional positive widest f-number at maximum focal length
- `minimumFocusDistanceMm`: optional positive value
- `notes`: optional user text

Camera bodies and lenses are independent many-to-many choices; no mount compatibility enforcement is
required in v1. A calculation snapshot embeds applied values rather than depending on mutable equipment.

## Filter

Represents a neutral-density filter.

- `id`, `name`, provenance and lifecycle fields
- `strengthStops`: non-negative canonical strength
- `opticalDensity`: optional display/source value; must agree with stops within declared tolerance if present
- `filterFactor`: optional display/source value; must agree with stops within declared tolerance if present
- `notes`: optional user text

Multiple selected filters are ordered for display but their canonical strengths sum for calculation.

## Optical Accessory

Represents a reusable extension tube or teleconverter.

- `id`, `name`, provenance, notes, and lifecycle fields match other equipment.
- `kind`: stable `extension_tube` or `teleconverter` identifier.
- `value`: positive extension length in millimetres for a tube, or a factor of at least 1× for a converter.
- Schema version 2 adds the accessory table and expands immutable snapshot references without changing
  existing camera, lens, filter, preference, or calculation payloads.

## Macro Result

An immutable configuration-specific estimate containing magnification, effective aperture, subject width
across the sensor, and exposure compensation. Its snapshot stores only inputs relevant to the selected
extension-tube, reversed-lens, or coupled-lens model plus exact applied equipment values.

## Panorama Plan

An immutable angular capture plan containing orientation, per-frame horizontal/vertical field of view,
minimum column and row counts, movement increments, resulting coverage, and an ordered list of frame
positions. Each position records a one-based capture index plus zero-based row/column and centered yaw and
pitch angles. Saved plans embed applied camera sensor dimensions and lens focal length.

## Astronomy Plan

An immutable UTC/location plan for a bundled fixed ICRS/J2000 target. It records altitude, true-north
azimuth, above-horizon state, circumpolar/rising visibility cycle, next geometric rise/transit/set events,
500-rule and NPF shutter estimates, and star-trail duration. Its snapshot embeds the target coordinates,
observer coordinates, formula version, optical inputs, applied equipment, assumptions, and event instants.
It also embeds the saved/manual location source, reported accuracy and capture timestamp, local and UTC
planning times, timezone confidence, elevation, horizon/refraction policy, catalog version/provenance/
freshness, supported epoch, and the result's explicit planning-accuracy boundary.

## Alignment Result

An immutable Sun/Moon composition search containing observer coordinates/elevation, target elevation and
distance, desired true bearing, derived target altitude, UTC range, angular tolerance, sampling resolution,
and up to 20 ordered candidates selected by a memory-bounded one-year scan. Each candidate records UTC
instant, true azimuth, altitude, angular error, and horizon state. The immutable snapshot additionally
stores the inclusive local civil dates, timezone rule confidence, source/accuracy context, elevations,
horizon/refraction policy, model freshness, and declared accuracy. Numeric, locally grouped timeline,
compass, map, and AR-capability views consume this same result.

## Saved Location

A mutable reusable local record with stable ID, normalized unique name, latitude, longitude, optional
elevation, IANA-style time-zone identifier, manual/device source, optional device accuracy, and UTC
creation/update timestamps. Schema version 3 adds `saved_locations`; calculation and observation-plan
snapshots embed coordinates and context so later location edits cannot rewrite a saved plan. Schema version
5 adds planner-default preferences while preserving all earlier choices.

## User Preferences

Singleton local settings record.

- `lengthDisplay`: metric millimetres/metres or feet/inches where applicable
- `shutterDisplay`: exact seconds or nearest conventional value
- `fractionStep`: whole, half, or third stops
- `themeMode`: system, light, dark, or field-red/low-light
- `textScalePolicy`: system value without application-imposed reduction
- `favoriteToolIds`: ordered stable identifiers
- `northReference`: true or magnetic north presentation preference
- `defaultStarSharpness`: strict, balanced, or relaxed night-sky recommendation
- `defaultAlignmentToleranceDegrees`: positive default tolerance up to 180°

## Calculation Input and Result

Transient immutable domain structures. Each calculator defines typed input and output fields according to
`contracts/feature-contracts.md`.

Every result also contains:

- `calculatorId` and `formulaVersion`
- `status`: valid, invalid, or valid-with-warning
- `assumptions`: ordered human-readable keys with values
- `warnings`: typed warning codes plus presentation-ready explanation keys
- `rawOutputs`: canonical quantities

## Calculation Snapshot

Immutable saved record that can reproduce and explain a calculation.

- `id`, `calculatorId`, `formulaVersion`, `createdAt`
- `title` and optional `notes`
- `inputPayload`: versioned canonical input values
- `outputPayload`: versioned canonical raw output values
- `displayContext`: units and conventional rounding selected when saved
- `assumptions` and `warnings`
- `equipmentRefs`: optional IDs for navigation
- `equipmentSnapshot`: names, provenance, and exact values applied at calculation time

Snapshots are never updated when equipment changes. A user may delete a snapshot explicitly. Schema or
formula migrations preserve the original payload/version; viewing code adapts old versions without
silently recalculating them.

## Optics Planning Results

- **Field of View Result**: horizontal, vertical, and diagonal angle plus scene width/height at the entered
  distance, tied to sensor dimensions, focal length, and rectilinear-projection assumptions.
- **Diffraction Result**: Airy disk diameter/radius and diameter in sensor pixels, tied to aperture,
  wavelength, pixel pitch, and the circular-aperture/first-minimum criterion.
- **Focus Stack Result**: immutable ordered focus distances and frame count, tied to near/far bounds,
  overlap, focal length, aperture, circle of confusion, and thin-lens assumptions.

## State transitions

### Equipment

`draft input -> validated -> active -> edited active` or `active -> archived -> restored`.
Invalid drafts are not persisted. Hard deletion is allowed only when no snapshot/reference needs the item;
otherwise archival preserves explainability.

### Calculator

`empty -> incomplete -> invalid` or `ready -> calculated -> saved snapshot`.
Any input change invalidates the displayed result and triggers a fresh deterministic calculation only when
all required inputs are valid.

## Persistence constraints

- Database foreign keys and uniqueness constraints are enabled.
- Writes that affect multiple records are transactional.
- Every migration has forward-migration and representative legacy-fixture tests.
- Corrupt or unsupported payload versions produce a visible recovery state and preserve original bytes;
  they are never replaced with defaults.
