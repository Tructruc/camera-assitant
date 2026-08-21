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
}
