# Feature Contracts: Photography Assistant Foundation

These contracts define observable behavior between presentation, domain calculators, and repositories.
They are not network APIs.

## Common calculator contract

Each calculator exposes a stable identifier, formula version, input schema, validation operation, and pure
calculation operation.

```text
validate(input) -> valid input | ordered field errors
calculate(valid input) -> calculation result
```

Guarantees:

- Identical canonical inputs and formula version produce identical raw outputs.
- Validation never throws for user-entered values; it returns field-specific recovery guidance.
- Calculation never reads UI state, storage, clock, locale, network, or platform services.
- Results contain canonical raw quantities, assumptions, warnings, and formula identity.
- Display conversion and rounding do not mutate inputs or raw results.

## Depth-of-field contract

Input:

- focal length, aperture, focus distance, circle of confusion
- optional camera/lens snapshot metadata

Output:

- hyperfocal distance
- near focus limit
- far focus limit as finite distance or explicit infinity
- total depth of field as finite distance or infinity
- front and rear depth around the focus plane where defined
- thin-lens/model warning and any close-focus limitation

Acceptance invariants:

- Near limit is positive and no farther than focus distance.
- Far limit is at least focus distance or infinity.
- At or beyond the hyperfocal condition, far limit is infinity within the declared numerical tolerance.
- Unit conversion does not change the physical result.

## Exposure comparison contract

Input consists of baseline and candidate exposure triples: aperture, exposure time, and ISO.

Output:

- signed total stop difference
- signed aperture, time, and ISO contributions
- relative exposure multiplier
- plain-language direction: brighter, equivalent, or darker

Acceptance invariants:

- Swapping baseline and candidate negates the stop difference and reciprocates the multiplier.
- Equal triples return exactly zero stops and multiplier one.
- Component contributions sum to total difference within floating-point tolerance.

## Long-exposure/ND contract

Input:

- unfiltered base exposure time
- zero or more filters expressed canonically in stops
- optional target exposure time for inverse calculation

Output:

- total filter strength
- calculated exposure time
- conventional formatted shutter guidance
- optional required filter strength for the target time
- bulb/timer guidance flag when the result exceeds conventional camera shutter ranges

Acceptance invariants:

- Zero stops preserves base exposure.
- Adding one stop doubles exposure time; adding ten stops multiplies it by 1,024.
- Stacked filter order does not change the raw result.
- Optical density and filter factor inputs convert to the same canonical stops within tolerance.

## Core optics contracts

- Field of view accepts positive sensor width/height, focal length, and subject distance and returns
  rectilinear horizontal/vertical/diagonal angles and scene coverage.
- Diffraction accepts positive f-number, wavelength, and pixel pitch and returns first-minimum Airy disk
  measurements, warning when its diameter spans at least two pixels.
- Focus stacking accepts positive optical values, a far bound greater than the near bound, and overlap in
  `[0, 100)`, returning a strictly increasing, bounded capture list that starts at the near distance and
  reaches the far distance.
- Each result declares formula version, assumptions, limitations, and remains savable offline.

## Flash exposure contract

Positive ISO-100 guide number, ISO, power fraction `(0, 1]`, and distance produce adjusted guide number,
recommended aperture, power reduction in stops, and equivalent full-power range. Results identify direct
flash and nominal-rating assumptions and never imply that bounce, modifiers, ambient light, or TTL metering
are modeled.

## Timelapse contract

Positive interval, capture duration, playback rate, estimated frame size, and exposure-ramp endpoints
produce inclusive frame count, playback length, storage estimate, signed ramp stops, and maximum duty
cycle. A longest exposure equal to or exceeding the interval produces a visible feasibility warning.

## Macro contract

The selected configuration controls the input schema: extension-tube mode accepts focal length, extension,
native magnification, aperture, and sensor width; reversed-lens mode accepts reversed focal length,
flange/extension distance, aperture, and sensor width; coupled-lens mode accepts both focal lengths,
aperture, and sensor width. Each returns magnification, effective aperture, subject width, exposure
compensation, formula version, and an unavoidable configuration-estimate warning. Saved equipment values
and provenance are embedded and remain immutable after inventory edits.

## Panorama contract

Positive sensor dimensions and focal length, landscape or portrait orientation, horizontal bounds in
`(0, 360]`, vertical bounds in `(0, 180]`, and per-axis overlaps in `[0, 100)` produce the minimum covering
column/row grid. Output includes frame field of view, yaw/pitch increments, resulting coverage, total frame
count, and centered positions in serpentine capture order. Coverage never falls below requested bounds,
portrait orientation swaps sensor axes, and a bound within one frame returns one centered position.
Snapshots retain every position and applied camera/lens provenance.

## Fixed-target astronomy contract

Latitude in `[-90, 90]`, east-positive longitude in `[-180, 180]`, a UTC instant, bundled ICRS/J2000
target, positive optics, and desired trail arc in `(0, 360]` produce airless altitude, true-north azimuth,
horizon visibility, visibility cycle, and next geometric events. Circumpolar and never-rising targets omit
rise/set rather than inventing times. The same result includes 500-rule and NPF shutter estimates and the
sidereal duration for a requested trail arc. Calculations remain offline, disclose exclusions and UTC
context, and snapshots preserve target coordinates, event times, and equipment provenance.

## Sun/Moon alignment contract

A supported body, valid observer coordinates, finite manual observer/target elevations, positive target
distance, true bearing, angular tolerance, and UTC range no longer than 366 elapsed days produce a derived
target altitude and the best 20 ordered local-minimum candidates. The presentation accepts an inclusive
local civil-date range of at most 366 calendar dates and converts its boundaries through bundled IANA
daylight-saving rules before calling the pure UTC domain. The search streams ten-minute samples without
retaining the full range in memory. Every candidate includes local/UTC time, azimuth, altitude, angular
error, and horizon state. Location source/accuracy, local dates, timezone rule confidence, elevations,
terrain/refraction exclusions, true-north reference, source freshness, and expected accuracy remain
visible and are saved. Sun views always display optical safety guidance.

Planning view capability states are `available`, `permissionRequired`, `denied`, or `unsupported`. Live AR
requires camera, orientation, and AR support simultaneously. Any missing capability leaves numeric,
timeline, compass-fallback, and offline schematic-map views usable without fabricating sensor readings.

## Saved-location and live-planning contract

Users can create, edit, list, and delete uniquely named coordinates offline or explicitly request one
device reading. Device-derived records retain reported accuracy and source. Location permission is never
requested until “Use current location” is activated; denial or disabled services return a manual-entry
recovery path. Astronomy and alignment screens apply saved coordinates without mutating the record.

Opening live AR is the only action that initializes a camera preview. Camera denial/no hardware produces
the same non-AR recovery path. The overlay consumes the saved candidate azimuth/altitude and live compass
heading, visibly distinguishes magnetic heading from true-north target bearing, displays calibration and
accuracy limitations, and preserves the solar safety banner. Saved observation plans include a field
checklist inside their immutable canonical payload.

## Equipment repository contract

Operations: watch/list active items by type, fetch by ID, create, update, archive, restore, and determine
reference impact.

Guarantees:

- IDs are stable and names are normalized for uniqueness within type.
- Invalid records are rejected with field-specific errors.
- Create/update/archive operations are atomic.
- A snapshot retains embedded applied equipment values after equipment edit/archive.
- Repository implementations are replaceable with deterministic in-memory versions for tests.

## Snapshot repository contract

Operations: list newest-first, fetch, save immutable snapshot, rename/add notes without changing calculation
payload, and delete.

Guarantees:

- Saving captures formula version, canonical inputs/outputs, display context, assumptions, warnings, and
  applied equipment values in one transaction.
- Opening a supported snapshot never silently recalculates it.
- Unsupported/corrupt payload versions return an explicit recovery result and preserve stored data.

## Presentation contract

Every calculator screen provides labeled inputs with units, inline validation, assumptions/help, result
interpretation, save action, and an explicit reset. Equipment-derived inputs identify the source and allow a
one-off override. Loading, empty, invalid, ready, result, storage-error, and recovery states are testable.

At 200% system text scale, content remains reachable without overlap or clipping. All controls and results
have meaningful semantic labels, focus order, and non-color-only state. Low-light mode never reduces text
contrast below the project accessibility threshold.
