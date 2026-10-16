# Photography Assistant: field workbench redesign

## Product direction

The app should feel like adjusting a camera and preparing a shot, not completing a scientific form. Optimize for setting up a shot quickly in the field while retaining precise control and honest physical limitations. All existing calculators, warnings, offline capabilities, equipment provenance and persisted snapshots remain available.

## Architecture

- **Plan**: a concise field-planning launchpad. Direct access to Sun & Moon alignment, night-sky planning and offline locations; capture-workflow shortcuts. Distinguish saved coordinates from live positioning; never imply a schematic is a downloaded map.
- **Tools**: searchable, task-grouped collection of every existing calculator. Common tools get direct access. Search includes photographic synonyms. Favorites remain persisted using the existing preferences repository.
- **Kit**: equipment inventory with visible add/edit actions, kind filters, helpful specifications and deliberate destructive actions.
- **Saved**: searchable/filterable calculation and observation plans, with clear summaries and access to existing notes, exact values, assumptions and deletion.
- **Settings**: app-bar action, not a primary destination. Preserve all existing preferences.
- Preserve navigation state when switching primary destinations. Use a navigation rail when width permits and bottom navigation on phones.

## Interaction system

- Retain canonical raw units and domain calculation APIs. Practical display units are an input adapter, not a data migration.
- Numeric controls support exact editable entry, labeled decrement/increment actions and sensible bounds. Canonical camera quantities use explicit standard presets; do not infer physical semantics from label strings.
- Sliders are useful for bounded continuous adjustments and intervals, not coordinates or arbitrary scientific values. Do not silently clamp a valid precise value to a slider's range.
- Every slider/preset/stepper writes through the same controller used for exact entry. Handle empty, negative, nonfinite and invalid values safely.
- Live results for cheap calculations, recalculated after input changes. Results must never falsely represent stale inputs. Keep explicit Search/Plan actions for heavy astronomy/alignment tasks.
- Put essential shot inputs before advanced model assumptions. Keep operation modes visible as accessible chips/segments rather than dropdowns when the option count is small.
- Use metres/minutes/seconds where people think in those units. Include units and explain any conversion. Keep precise editing available.
- Show the primary answer with clear units, then a compact secondary summary. Keep warnings visible and exact values/derivations progressively disclosed.
- Equipment should help fill values, not block manual use. No empty optional picker should consume a prominent row when the kit is empty.

## Visual behavior

A calm, restrained instrument-like Material 3 language: strong numeric hierarchy, readable neutral surfaces, a consistent accent, and minimal decorative cards. Preserve light, dark and low-light themes and bundled offline fonts. Consistent spacing, headers, action labels and controls across features. No network assets, analytics or new backend dependencies.

## Acceptance criteria

1. Every existing feature remains discoverable and functional; snapshots and equipment retain their canonical schema.
2. Frequent calculator values are adjustable without opening the keyboard; precise numeric input remains possible.
3. Switching primary destinations preserves local screen state.
4. Heavy searches remain explicit and do not start repeatedly while dragging a slider.
5. Narrow phones, landscape, 200% text and bold text remain usable without clipping or inaccessible controls.
6. Widget semantics, keyboard operation, validation and touch targets remain meaningful.
7. Analysis, unit/widget/integration checks and an available target build are run and reported truthfully; render actual screens where the environment permits.

## Implementation ownership

- Foundation: app shell/navigation/catalog/theme and shared calculator components.
- Focus: depth of field, optics trio, macro presentations.
- Capture: exposure comparison, long exposure, flash, timelapse, panorama presentations.
- Field planning: alignment, astronomy, locations and live/schematic planning presentations.
- Library: equipment, saved calculations, settings presentations.

No domain calculator, generated database, migration or repository rewrite is required. Tests may change when an intentional interaction changes; physics/hostile-input assertions must not be weakened to mask a regression.

## Review refinements

- Presets use a compact horizontally scrollable rail instead of wrapping every choice into several rows. Steppers rebuild from their own controller, independent of parent screen rebuilds.
- Aperture steppers walk standard f-stops rather than adding arbitrary numeric increments. Exact custom entry remains available.
- Display synchronization is guarded: equipment/reset updates and cursor/composition changes cannot round-trip rounded text into canonical values. Canonical serialization retains full double precision; scientific notation is never trimmed as though its exponent were a decimal fraction.
- Live tools have a persistent compact answer while inputs scroll; heavy planners instead keep their explicit search action reachable. These are layout siblings, not overlays on controls.
- Incomplete edits do not replace the form's widget hierarchy: field identity, keyboard focus and scroll state survive result withdrawal and restoration. Expanded model/details sections survive scrolling away and back.
- Empty location pickers and repeated coordinate bounds copy are omitted; elevation remains visible in the site summary and editable in Site details. The macro mode's extension length is a primary parameter, not a hidden assumption.
- Saved cameras sit beside saved lenses on the relevant tools; raw sensor and model assumptions remain advanced.
- Calculator equipment reads are independent of the retained Kit category filter and exclude archived items. Inventory filtering and counts retain their own semantics.
- Checklist progress wording does not promise persistence for temporary session edits. Unreadable saved records retain their preservation notice and have an explicitly confirmed deletion path.

## Division of work

Sol defines the product direction, interaction architecture, ownership boundaries, acceptance criteria and review decisions, owns final integration/visual review, and made small canonical-precision, focus-retention and macro-hierarchy review fixes. Flash performed repository/history investigation, baseline verification, all major UI implementation, regression-test creation/migration, focused fixes and command-based validation. Verification outcomes are recorded separately after execution, not inferred from source review.
