import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

final class PlanningTimeContext {
  const PlanningTimeContext._({
    required this.timeZoneId,
    this.offset,
    this.location,
  });

  factory PlanningTimeContext.parse(String timeZoneId) {
    final normalized = timeZoneId.trim();
    if (normalized == 'UTC' || normalized == 'Etc/UTC' || normalized == 'Z') {
      return PlanningTimeContext._(
        timeZoneId: normalized.isEmpty ? 'UTC' : normalized,
        offset: Duration.zero,
      );
    }
    final match = RegExp(
      r'^UTC([+-])(\d{1,2})(?::?(\d{2}))?$',
      caseSensitive: false,
    ).firstMatch(normalized);
    if (match == null) {
      if (!_initialized) {
        tz_data.initializeTimeZones();
        _initialized = true;
      }
      try {
        return PlanningTimeContext._(
          timeZoneId: normalized,
          location: tz.getLocation(normalized),
        );
      } on Object {
        return PlanningTimeContext._(timeZoneId: normalized);
      }
    }
    final hours = int.parse(match.group(2)!);
    final minutes = int.parse(match.group(3) ?? '0');
    if (hours > 14 || minutes > 59) {
      return PlanningTimeContext._(timeZoneId: normalized);
    }
    final total = Duration(hours: hours, minutes: minutes);
    return PlanningTimeContext._(
      timeZoneId: normalized,
      offset: match.group(1) == '-' ? -total : total,
    );
  }

  static var _initialized = false;

  final String timeZoneId;
  final Duration? offset;
  final tz.Location? location;

  bool get canConvertOffline => offset != null || location != null;
  String get confidenceLabel => location != null
      ? 'Bundled IANA timezone rules; daylight-saving transitions applied offline'
      : offset != null
      ? 'Exact fixed offset; daylight-saving changes are not applied'
      : 'Time-zone identifier unsupported; UTC retained';

  String format(DateTime instantUtc) {
    final utc = instantUtc.toUtc();
    final local = location != null
        ? tz.TZDateTime.from(utc, location!)
        : offset == null
        ? utc
        : utc.add(offset!);
    final suffix = canConvertOffline ? timeZoneId : 'UTC';
    return '${DateFormat('yyyy-MM-dd HH:mm').format(local)} $suffix';
  }

  /// Returns wall-clock fields suitable for local date and time controls.
  ///
  /// The returned [DateTime] deliberately carries no timezone meaning; callers
  /// should pass the selected fields back through [toUtc].
  DateTime localCivilTime(DateTime instantUtc) {
    final utc = instantUtc.toUtc();
    final local = location != null
        ? tz.TZDateTime.from(utc, location!)
        : offset == null
        ? utc
        : utc.add(offset!);
    return DateTime(
      local.year,
      local.month,
      local.day,
      local.hour,
      local.minute,
      local.second,
    );
  }

  /// Interprets [localCivilTime] as wall-clock fields in this context.
  DateTime toUtc(DateTime localCivilTime) {
    if (location != null) {
      return tz.TZDateTime(
        location!,
        localCivilTime.year,
        localCivilTime.month,
        localCivilTime.day,
        localCivilTime.hour,
        localCivilTime.minute,
        localCivilTime.second,
      ).toUtc();
    }
    final fieldsAsUtc = DateTime.utc(
      localCivilTime.year,
      localCivilTime.month,
      localCivilTime.day,
      localCivilTime.hour,
      localCivilTime.minute,
      localCivilTime.second,
    );
    return offset == null ? fieldsAsUtc : fieldsAsUtc.subtract(offset!);
  }
}
