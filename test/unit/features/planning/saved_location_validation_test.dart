import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/features/planning/presentation/saved_locations_screen.dart';

/// The dialog's field rules are pure, so each branch is asserted directly
/// instead of only through the widget (FR-002).
void main() {
  Map<String, String> validate({
    String name = 'Dark site',
    String latitude = '45',
    String longitude = '5',
    String elevation = '',
    String timeZoneId = 'Europe/London',
  }) => validateLocationDraft(
    name: name,
    latitude: latitude,
    longitude: longitude,
    elevation: elevation,
    timeZoneId: timeZoneId,
  );

  test('a complete draft is valid', () {
    expect(validate(), isEmpty);
    expect(validate(elevation: '1200'), isEmpty);
    expect(validate(latitude: '-90', longitude: '180'), isEmpty);
  });

  test('a blank name is rejected', () {
    expect(validate(name: '   '), contains('name'));
  });

  test('coordinates must be numeric and inside Earth bounds', () {
    expect(validate(latitude: 'north'), contains('latitude'));
    expect(validate(latitude: '90.1'), contains('latitude'));
    expect(validate(latitude: '-90.1'), contains('latitude'));
    expect(validate(longitude: 'east'), contains('longitude'));
    expect(validate(longitude: '180.1'), contains('longitude'));
    expect(validate(longitude: '-180.1'), contains('longitude'));
  });

  test('elevation is optional but must parse when present', () {
    expect(validate(elevation: '   '), isEmpty);
    expect(validate(elevation: 'sea level'), contains('elevation'));
  });

  test('the time zone must be named', () {
    expect(validate(timeZoneId: '  '), contains('timeZoneId'));
    // An ID the bundled database does not know is still accepted; the planner
    // reports its confidence honestly rather than blocking the save.
    expect(validate(timeZoneId: 'Mars/Olympus'), isEmpty);
  });
}
