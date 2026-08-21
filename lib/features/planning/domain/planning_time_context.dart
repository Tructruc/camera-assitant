import 'package:intl/intl.dart';

final class PlanningTimeContext {
  const PlanningTimeContext._({required this.timeZoneId, this.offset});

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
    if (match == null) return PlanningTimeContext._(timeZoneId: normalized);
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

  final String timeZoneId;
  final Duration? offset;

  bool get canConvertOffline => offset != null;
  String get confidenceLabel => canConvertOffline
      ? 'Exact fixed offset; daylight-saving changes are not applied'
      : 'Time-zone offset unavailable offline; UTC retained';

  String format(DateTime instantUtc) {
    final utc = instantUtc.toUtc();
    final local = offset == null ? utc : utc.add(offset!);
    final suffix = offset == null ? 'UTC' : timeZoneId;
    return '${DateFormat('yyyy-MM-dd HH:mm').format(local)} $suffix';
  }
}
