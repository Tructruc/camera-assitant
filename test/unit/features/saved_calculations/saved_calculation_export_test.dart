import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/core/domain/calculation_snapshot.dart';
import 'package:photography_assistant/core/domain/validation/validation.dart';
import 'package:photography_assistant/features/saved_calculations/presentation/saved_calculation_export.dart';

/// The pure export formatter behind "Copy field brief" and "Copy exact JSON".
///
/// These tests hold the two claims the copy actions make: the brief restates the
/// recorded plan in human words with the units the canonical keys actually
/// declare, and the JSON copy is the stored record byte-for-byte round-trippable.
void main() {
  group('tool labels', () {
    const labels = <String, String>{
      'depth_of_field': 'Depth of field',
      'exposure_comparison': 'Exposure comparison',
      'long_exposure_nd': 'Long exposure / ND',
      'field_of_view': 'Field of view',
      'diffraction': 'Diffraction guidance',
      'focus_stacking': 'Focus stack planner',
      'flash_exposure': 'Flash exposure',
      'timelapse': 'Timelapse planner',
      'macro': 'Macro planner',
      'panorama': 'Panorama planner',
      'astronomy': 'Night-sky planner',
      'sun_moon_alignment': 'Sun & Moon alignment',
    };

    test('names every shipped tool', () {
      for (final entry in labels.entries) {
        expect(
          savedCalculationToolLabel(entry.key),
          entry.value,
          reason: entry.key,
        );
      }
    });

    test('an unrecognised id is named by itself, never relabelled', () {
      expect(savedCalculationToolLabel('future_tool'), 'future_tool');
      expect(savedCalculationToolLabel(''), '');
    });
  });

  group('recorded values', () {
    // The canonical input keys each shipped calculator actually writes, with the
    // line the brief must print for them. The units come from the key names; no
    // physics is recomputed.
    const cases = <String, (Map<String, Object?>, List<String>)>{
      'depth_of_field': (
        <String, Object?>{
          'focalLengthMm': 50.0,
          'aperture': 2.8,
          'focusDistanceMm': 5000.0,
          'circleOfConfusionMm': 0.03,
        },
        <String>[
          'Focal length: 50 mm',
          'Aperture: f/2.8',
          'Focus distance: 5000 mm',
          'Circle of confusion: 0.03 mm',
        ],
      ),
      'long_exposure_nd': (
        <String, Object?>{
          'baseTimeSeconds': 0.5,
          'filterStops': 6.0,
          'targetTimeSeconds': null,
        },
        <String>[
          'Base exposure: 0.5 s',
          'Filter strength: 6 stops',
          'Target exposure: not recorded',
        ],
      ),
      'exposure_comparison': (
        <String, Object?>{
          'baseline': <String, Object?>{
            'aperture': 8.0,
            'timeSeconds': 0.008,
            'iso': 100.0,
          },
          'candidate': <String, Object?>{
            'aperture': 2.8,
            'timeSeconds': 0.001,
            'iso': 100.0,
          },
        },
        <String>[
          'Baseline · Aperture: f/8',
          'Baseline · Time: 0.008 s',
          'Baseline · ISO: 100',
          'Candidate · Aperture: f/2.8',
          'Candidate · Time: 0.001 s',
          'Candidate · ISO: 100',
        ],
      ),
      'flash_exposure': (
        <String, Object?>{
          'guideNumberIso100Metres': 40.0,
          'iso': 400.0,
          'powerFraction': 0.25,
          'subjectDistanceMetres': 5.0,
        },
        <String>[
          'Guide number (ISO 100): 40 m',
          'ISO: 400',
          'Flash power (fraction): 0.25',
          'Subject distance: 5 m',
        ],
      ),
      'field_of_view': (
        <String, Object?>{
          'sensorWidthMm': 36.0,
          'sensorHeightMm': 24.0,
          'focalLengthMm': 50.0,
          'distanceMm': 10000.0,
        },
        <String>[
          'Sensor width: 36 mm',
          'Sensor height: 24 mm',
          'Focal length: 50 mm',
          'Subject distance: 10000 mm',
        ],
      ),
      'diffraction': (
        <String, Object?>{
          'aperture': 8.0,
          'wavelengthNm': 550.0,
          'pixelPitchMicrometres': 4.0,
        },
        <String>['Aperture: f/8', 'Wavelength: 550 nm', 'Pixel pitch: 4 µm'],
      ),
      'focus_stacking': (
        <String, Object?>{
          'focalLengthMm': 100.0,
          'aperture': 8.0,
          'nearDistanceMm': 500.0,
          'farDistanceMm': 1000.0,
          'circleOfConfusionMm': 0.03,
          'overlapPercent': 20.0,
        },
        <String>[
          'Focal length: 100 mm',
          'Aperture: f/8',
          'Near distance: 500 mm',
          'Far distance: 1000 mm',
          'Circle of confusion: 0.03 mm',
          'Overlap: 20%',
        ],
      ),
      'timelapse': (
        <String, Object?>{
          'intervalSeconds': 10.0,
          'captureDurationSeconds': 3600.0,
          'playbackFps': 30.0,
          'megabytesPerFrame': 25.0,
          'startExposureSeconds': 1.0,
          'endExposureSeconds': 4.0,
        },
        <String>[
          'Interval: 10 s',
          'Capture duration: 3600 s',
          'Playback frame rate: 30 fps',
          'Estimated size per frame: 25 MB',
          'Starting exposure: 1 s',
          'Ending exposure: 4 s',
        ],
      ),
      'macro': (
        <String, Object?>{
          'configuration': 'extensionTube',
          'focalLengthMm': 100.0,
          'extensionLengthMm': 20.0,
          'nativeMagnification': 0.6,
          'nominalAperture': 8.0,
          'sensorWidthMm': 36.0,
        },
        <String>[
          'Configuration: extensionTube',
          'Focal length: 100 mm',
          'Extension length: 20 mm',
          'Native magnification: 0.6×',
          'Nominal aperture: f/8',
          'Sensor width: 36 mm',
        ],
      ),
      'panorama': (
        <String, Object?>{
          'sensorWidthMm': 36.0,
          'sensorHeightMm': 24.0,
          'focalLengthMm': 50.0,
          'orientation': 'landscape',
          'horizontalBoundsDegrees': 90.0,
          'verticalBoundsDegrees': 45.0,
          'horizontalOverlapPercent': 30.0,
          'verticalOverlapPercent': 30.0,
        },
        <String>[
          'Sensor width: 36 mm',
          'Sensor height: 24 mm',
          'Focal length: 50 mm',
          'Orientation: landscape',
          'Horizontal bounds: 90°',
          'Vertical bounds: 45°',
          'Horizontal overlap: 30%',
          'Vertical overlap: 30%',
        ],
      ),
      'astronomy': (
        <String, Object?>{
          'latitudeDegrees': 48.8,
          'longitudeDegrees': 2.3,
          'observerElevationMetres': 35.0,
          'instantUtc': '2026-08-21T20:00:00.000Z',
          'target': 'jupiter',
          'rightAscensionDegrees': 10.0,
          'declinationDegrees': 12.0,
          'focalLengthMm': 200.0,
          'cropFactor': 1.6,
          'aperture': 4.0,
          'pixelPitchMicrometres': 4.3,
          'desiredTrailDegrees': 0.0,
          'selectedRule': 'npf',
          'sharpnessTolerance': 'balanced',
          'magneticDeclinationDegrees': 1.0,
        },
        <String>[
          'Latitude: 48.8°',
          'Longitude: 2.3°',
          'Observer elevation: 35 m',
          'Planned instant (UTC): 2026-08-21T20:00:00.000Z',
          'Target: jupiter',
          'Right ascension: 10°',
          'Declination: 12°',
          'Focal length: 200 mm',
          'Crop factor: 1.6',
          'Aperture: f/4',
          'Pixel pitch: 4.3 µm',
          'Desired star trail: 0°',
          'Shutter rule: npf',
          'Sharpness tolerance: balanced',
          'Magnetic declination: 1°',
        ],
      ),
      'sun_moon_alignment': (
        <String, Object?>{
          'body': 'sun',
          'observerLatitudeDegrees': 51.4779,
          'observerLongitudeDegrees': 0.0,
          'observerElevationMetres': 20.0,
          'targetElevationMetres': 820.0,
          'targetDistanceMetres': 1000.0,
          'desiredBearingDegrees': 180.0,
          'angularToleranceDegrees': 3.0,
          'magneticDeclinationDegrees': 0.0,
          'startLocalDate': '2026-03-28',
          'endLocalDate': '2026-03-28',
          'startUtc': '2026-03-28T00:00:00.000Z',
          'endUtc': '2026-03-29T00:00:00.000Z',
        },
        <String>[
          'Body: sun',
          'Observer latitude: 51.4779°',
          'Observer longitude: 0°',
          'Observer elevation: 20 m',
          'Target elevation: 820 m',
          'Target distance: 1000 m',
          'Desired bearing: 180°',
          'Angular tolerance: 3°',
          'Magnetic declination: 0°',
          'Search start date: 2026-03-28',
          'Search end date: 2026-03-28',
          'Search window start (UTC): 2026-03-28T00:00:00.000Z',
          'Search window end (UTC): 2026-03-29T00:00:00.000Z',
        ],
      ),
    };

    test('labels every shipped tool with honest units', () {
      for (final entry in cases.entries) {
        expect(
          savedCalculationRecordedValues(entry.value.$1),
          entry.value.$2,
          reason: entry.key,
        );
      }
    });

    test('an unknown key is copied verbatim, with no unit invented', () {
      final lines = savedCalculationRecordedValues(<String, Object?>{
        'experimentalGain': 12,
        'mysteryFlag': true,
        'opaqueList': <Object?>[1, 2],
        // A nested map is walked leaf by leaf, so an unknown group still names
        // its own keys rather than printing an opaque blob.
        'opaqueMap': <String, Object?>{'a': 1},
        'emptyValue': null,
      });
      expect(lines, <String>[
        'experimentalGain: 12',
        'mysteryFlag: yes',
        'opaqueList: [1,2]',
        'opaqueMap · a: 1',
        'emptyValue: not recorded',
      ]);
    });

    test('skip omits top-level keys only', () {
      final lines = savedCalculationRecordedValues(
        <String, Object?>{
          'latitudeDegrees': 48.8,
          'instantUtc': '2026-08-21T20:00:00.000Z',
          'focalLengthMm': 50.0,
          'baseline': <String, Object?>{'iso': 100.0},
        },
        skip: const <String>{'latitudeDegrees', 'instantUtc'},
      );
      expect(lines, <String>['Focal length: 50 mm', 'Baseline · ISO: 100']);
    });

    test('value text is honest for the shapes a payload can hold', () {
      expect(savedCalculationValueText(null), 'not recorded');
      expect(savedCalculationValueText(50.0), '50');
      expect(savedCalculationValueText(-0.0), '0');
      expect(savedCalculationValueText(0.03), '0.03');
      expect(
        savedCalculationValueText(12.033333333333333),
        '12.033333333333333',
      );
      expect(savedCalculationValueText(true), 'yes');
      expect(savedCalculationValueText(false), 'no');
      expect(savedCalculationValueText('extensionTube'), 'extensionTube');
      expect(savedCalculationValueText(double.infinity), 'Infinity');
    });

    test('the returned lines cannot be mutated into the record', () {
      final lines = savedCalculationRecordedValues(<String, Object?>{
        'focalLengthMm': 50.0,
      });
      expect(() => lines.add('extra'), throwsUnsupportedError);
    });
  });

  group('field brief', () {
    test('prints the saved plan in human words', () {
      final text = buildSavedCalculationBrief(
        SavedCalculationBriefInput(
          title: 'Field depth',
          toolLabel: 'Depth of field',
          savedDate: '2026-08-20',
          primaryLabel: 'Near limit',
          primaryValue: '4.50 m',
          primaryCaption: 'Sharp from 3.20 m to 8.00 m.',
          notes: 'Use at sunset',
          recordedInputs: const <String>['Focal length: 50 mm'],
          warnings: const <String>['Close focus reduces the accuracy.'],
          assumptions: const <String>['optics: thinLensApproximation'],
          equipment: const <String>['Zoom 24-70mm (lens) · bundled'],
        ),
      );
      expect(text, '''
Field brief — Field depth
Depth of field · saved 2026-08-20
Near limit: 4.50 m
Sharp from 3.20 m to 8.00 m.

Notes
Use at sunset

Recorded inputs
- Focal length: 50 mm

Warnings
- Close focus reduces the accuracy.

Assumptions
- optics: thinLensApproximation

Equipment
- Zoom 24-70mm (lens) · bundled
''');
    });

    test('prints the observation block with its own zone and site', () {
      final text = buildSavedCalculationBrief(
        const SavedCalculationBriefInput(
          title: 'Jupiter night-sky plan',
          toolLabel: 'Night-sky planner',
          savedDate: '2026-08-20',
          primaryLabel: 'Target altitude',
          primaryValue: '30° above the horizon',
          observation: SavedCalculationObservationBrief(
            site: '48.8, 2.3 · elevation 35 m · manual entry',
            time: '2026-08-21 22:00 UTC+02:00',
            zone: 'UTC+02:00',
            reference: 'true north',
          ),
        ),
      );
      expect(text, contains('Observation\n'));
      expect(text, contains('Site: 48.8, 2.3 · elevation 35 m · manual entry'));
      expect(text, contains('Time: 2026-08-21 22:00 UTC+02:00'));
      expect(text, contains('Zone: UTC+02:00'));
      expect(text, contains('Reference: true north'));
    });

    test('a record with no optional field prints no empty section', () {
      final text = buildSavedCalculationBrief(
        const SavedCalculationBriefInput(
          title: 'Minimal',
          toolLabel: 'field_of_view',
          savedDate: '2026-08-20',
          primaryLabel: 'Saved result',
          primaryValue: 'field_of_view',
        ),
      );
      expect(text, '''
Field brief — Minimal
field_of_view · saved 2026-08-20
Saved result: field_of_view
''');
      expect(text, isNot(contains('Notes')));
      expect(text, isNot(contains('Warnings')));
      expect(text, isNot(contains('Assumptions')));
      expect(text, isNot(contains('Equipment')));
      expect(text, isNot(contains('Observation')));
      expect(text, isNot(contains('not recorded')));
    });

    test('a blank note is not printed as a section', () {
      final text = buildSavedCalculationBrief(
        const SavedCalculationBriefInput(
          title: 'Blank note',
          toolLabel: 'Macro planner',
          savedDate: '2026-08-20',
          primaryLabel: 'Subject width across frame',
          primaryValue: '120 mm',
          notes: '   ',
        ),
      );
      expect(text, isNot(contains('Notes')));
    });
  });

  group('exact JSON', () {
    CalculationSnapshot snapshot() => CalculationSnapshot(
      id: 'snapshot-1',
      calculatorId: 'depth_of_field',
      formulaVersion: 3,
      createdAt: DateTime.utc(2026, 8, 20),
      title: 'Field depth',
      notes: 'Use at sunset',
      canonicalInputs: const <String, Object?>{'focalLengthMm': 50.0},
      canonicalOutputs: const <String, Object?>{
        'nearLimitMm': 4500.0,
        'fieldChecklist': <Object?>[
          <String, Object?>{
            'task': 'Focus on a bright star',
            'complete': false,
          },
        ],
      },
      displayContext: const <String, Object?>{'distanceUnit': 'metric'},
      assumptions: const <CalculationAssumption>[
        CalculationAssumption(key: 'optics', value: 'thinLensApproximation'),
      ],
      warnings: const <CalculationWarning>[
        CalculationWarning(code: 'close_focus', messageKey: 'dof.close'),
      ],
      equipment: <AppliedEquipmentSnapshot>[
        AppliedEquipmentSnapshot(
          id: 'lens-1',
          type: SnapshotEquipmentType.lens,
          name: 'Macro 100mm',
          source: 'bundled',
          values: const <String, Object?>{'focalLengthMm': 100.0},
        ),
      ],
    );

    test('keeps every canonical value, id and version', () {
      final record = snapshot();
      final text = buildSavedCalculationExactJson(record);
      expect(text, contains('"id": "snapshot-1"'));
      expect(text, contains('"calculatorId": "depth_of_field"'));
      expect(text, contains('"formulaVersion": 3'));
      expect(text, contains('"payloadVersion": 1'));
      expect(text, contains('"createdAt": "2026-08-20T00:00:00.000Z"'));
      expect(text, contains('"notes": "Use at sunset"'));
      expect(text, contains('"focalLengthMm": 50'));
      expect(text, contains('"nearLimitMm": 4500'));
      expect(text, contains('"Macro 100mm"'));
      expect(text, contains('"thinLensApproximation"'));
      expect(text, contains('"close_focus"'));
      // The checklist as stored: a tick made while reading is session state and
      // can never appear here.
      expect(text, contains('"complete": false'));
    });

    test('round-trips back through the snapshot codec', () {
      final record = snapshot();
      final text = buildSavedCalculationExactJson(record);
      final decoded = jsonDecode(text) as Map<String, Object?>;
      final restored = CalculationSnapshot.fromJson(decoded);
      expect(restored.toJson(), record.toJson());
      expect(
        buildSavedCalculationExactJson(restored),
        text,
        reason: 'a second export must be byte-identical',
      );
    });

    test('formatting leaves the record untouched', () {
      final record = snapshot();
      final before = jsonEncode(record.toJson());
      final inputs = record.canonicalInputs;
      final outputs = record.canonicalOutputs;

      savedCalculationRecordedValues(record.canonicalInputs);
      buildSavedCalculationBrief(
        SavedCalculationBriefInput(
          title: record.title,
          toolLabel: savedCalculationToolLabel(record.calculatorId),
          savedDate: '2026-08-20',
          primaryLabel: 'Near limit',
          primaryValue: '4.50 m',
          notes: record.notes,
          recordedInputs: savedCalculationRecordedValues(
            record.canonicalInputs,
          ),
          equipment: const <String>['Macro 100mm (lens) · bundled'],
        ),
      );
      buildSavedCalculationExactJson(record);

      expect(jsonEncode(record.toJson()), before);
      expect(identical(record.canonicalInputs, inputs), isTrue);
      expect(identical(record.canonicalOutputs, outputs), isTrue);
      expect(
        () => record.canonicalInputs['injected'] = 1,
        throwsUnsupportedError,
      );
      expect(
        () => record.canonicalOutputs['injected'] = 1,
        throwsUnsupportedError,
      );
    });
  });
}
