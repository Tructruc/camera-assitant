<!--
Sync Impact Report
- Version change: template (unratified) -> 1.0.0
- Added principles:
  - I. Photographic and Astronomical Correctness
  - II. Test-First, Evidence-Based Quality
  - III. Cross-Platform, Offline-First Core
  - IV. Privacy, Safety, and Honest Guidance
  - V. Accessible, Field-Ready Experience
- Added sections:
  - Product and Technical Constraints
  - Development Workflow and Quality Gates
- Removed sections: none
- Follow-up TODOs: none
-->
# Camera Assistant Constitution

## Core Principles

### I. Photographic and Astronomical Correctness
Every calculator MUST define its inputs, units, formula, assumptions, valid domain, rounding rules,
and known limitations. Calculations MUST use internally consistent units and MUST be verified against
published references or independently derived fixtures. Sensor, lens, time, coordinate, elevation,
refraction, and astronomical conventions MUST be explicit wherever they affect results. The app MUST
distinguish estimates from exact values and MUST never present uncertain planning data as guaranteed.
Correctness is the product's primary value and takes precedence over feature count or delivery speed.

### II. Test-First, Evidence-Based Quality
Automated tests MUST be written with or before each behavior and MUST cover normal cases, boundary
conditions, invalid inputs, unit conversions, numerical tolerances, time-zone and date transitions,
and regression cases. Pure calculation logic MUST have deterministic unit tests. User-visible workflows,
persistence, platform integrations, and AR or sensor boundaries MUST have appropriate integration or
end-to-end tests. A change MUST NOT merge while required tests, static analysis, formatting, or build
checks fail. A defect fix MUST include a test that reproduces the defect.

### III. Cross-Platform, Offline-First Core
The supported product experience MUST remain available across the declared target platforms, with
platform capability differences documented and gracefully handled. Calculators, saved equipment, and
planning computations that do not inherently require a network MUST work offline. Domain calculations
MUST be isolated from UI, storage, network, and device services so they remain portable and independently
testable. Platform-specific code MUST be confined behind explicit interfaces and MUST have a usable
fallback when hardware or permissions are unavailable.

### IV. Privacy, Safety, and Honest Guidance
Location, camera orientation, equipment inventory, plans, and usage data MUST remain on-device by
default. Collection, transmission, or sharing of personal data MUST be opt-in, purpose-limited, and
clearly explained. The app MUST request the minimum permissions needed at the moment they are needed.
Sun, Moon, celestial, exposure, and AR guidance MUST show accuracy limitations and relevant safety
warnings, including that users must not look at the Sun through optical equipment without certified
protection. Failure or stale-data states MUST be visible rather than silently replaced with plausible
values.

### V. Accessible, Field-Ready Experience
Every tool MUST be operable without specialist knowledge: inputs require labels and units, defaults must
be safe and explainable, results must include an actionable interpretation, and validation errors must
explain how to recover. Core workflows MUST support screen readers, scalable text, sufficient contrast,
and non-color-only communication. Controls MUST remain usable outdoors, with one hand, and under low-light
conditions. Metric and commonly used photographic units MUST be supported without altering calculation
meaning.

## Product and Technical Constraints

- The product is a cross-platform photography calculator and field-planning assistant.
- Its planned scope includes depth of field, extension-tube macro, reversed-lens macro, dual-lens macro,
  astrophotography shutter limits, exposure comparison, focus stacking, long exposure, panorama planning,
  celestial and Milky Way planning, Sun and Moon planning, alignment from a position and elevation, and a
  reusable camera/lens inventory.
- AR is an enhancement to an equivalent map, compass, timeline, or numeric planning view; lack of AR
  support MUST NOT make the underlying planner unusable.
- Equipment parameters MUST identify their source, allow user correction, and preserve user-entered
  values. Calculators MUST show which inventory values were applied.
- Time, time zone, daylight-saving rules, coordinates, elevation, heading reference, and atmospheric
  assumptions MUST be explicit in planning results.
- Dependencies and bundled datasets MUST have compatible licenses, pinned versions, and an update policy.
- Performance budgets and supported platform versions MUST be defined in each implementation plan and
  verified for workflows affected by that plan.

## Development Workflow and Quality Gates

Work MUST follow the Spec Kit sequence: constitution, specification, clarification when needed, plan,
tasks, analysis, implementation, and convergence. Each specification MUST define independently testable
user scenarios, measurable success criteria, edge cases, assumptions, and explicit exclusions. Plans MUST
document calculation references, data provenance, platform capability differences, privacy impact, and
the testing strategy.

GitHub pull requests are the integration unit. GitHub CI MUST run formatting, static analysis, unit tests,
integration tests, and supported-platform build checks appropriate to the change. Release candidates MUST
also pass end-to-end tests on representative real devices or simulators and a documented manual check for
sensor- or AR-dependent behavior. Test coverage MUST be risk-based: all calculation branches and critical
planning paths require explicit assertions; a global percentage alone is not proof of completeness.

Changes MUST be small enough to review, contain no unexplained complexity, and update relevant
documentation and fixtures. Reviews MUST verify constitutional compliance. Exceptions require a written
rationale, risk assessment, owner, and removal date in the plan or pull request.

## Governance

This constitution is the highest-priority project governance document. Specifications, plans, tasks,
implementation, and reviews MUST comply with it. Amendments require a documented proposal explaining the
motivation, compatibility impact, and any migration work; approval by the project owner; and an update to
this document's Sync Impact Report.

Constitution versions follow semantic versioning: MAJOR for incompatible principle removals or
redefinitions, MINOR for new principles or materially expanded obligations, and PATCH for clarifications
that do not change obligations. Every feature plan and pull request review MUST include a constitution
check. Compliance MUST be reviewed before each release, and unresolved violations block release unless an
explicit, time-bounded exception has been approved under the workflow above.

**Version**: 1.0.0 | **Ratified**: 2026-08-16 | **Last Amended**: 2026-08-16
