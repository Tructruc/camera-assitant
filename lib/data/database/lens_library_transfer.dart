import 'dart:convert';

import 'package:camera_assistant/domain/models/lens.dart';

class LensLibraryTransfer {
  LensLibraryTransfer._();

  static const String backupType = 'camera_assistant_lens_library';
  static const int currentVersion = 1;

  static String encode(List<Lens> lenses, {DateTime? exportedAt}) {
    final payload = <String, Object?>{
      'type': backupType,
      'version': currentVersion,
      'exported_at': (exportedAt ?? DateTime.now()).toUtc().toIso8601String(),
      'lens_count': lenses.length,
      'lenses': lenses
          .map((lens) => lens.toMap()
            ..remove('id')
            ..remove('default_focal_mm'))
          .toList(growable: false),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  static List<Lens> decode(String raw) {
    final decoded = jsonDecode(raw);
    final lensItems = switch (decoded) {
      List<dynamic>() => decoded,
      Map<dynamic, dynamic>() => _decodePayload(decoded),
      _ => throw const FormatException(
          'Lens backup must be a JSON object or a JSON array.',
        ),
    };

    return lensItems.map(_decodeLens).toList(growable: false);
  }

  static List<dynamic> _decodePayload(Map<dynamic, dynamic> payload) {
    final type = payload['type'];
    if (type != null && type != backupType) {
      throw const FormatException(
          'This JSON is not a Camera Assistant lens backup.');
    }

    final version = payload['version'];
    if (version is num && version.toInt() > currentVersion) {
      throw const FormatException(
        'This lens backup was created by a newer app version.',
      );
    }

    final lenses = payload['lenses'];
    if (lenses is! List<dynamic>) {
      throw const FormatException('Lens backup is missing the "lenses" list.');
    }
    return lenses;
  }

  static Lens _decodeLens(dynamic item) {
    if (item is! Map) {
      throw const FormatException('Each lens entry must be a JSON object.');
    }

    final map = Map<String, Object?>.from(item.cast<String, Object?>());
    map.remove('id');
    map.putIfAbsent(
      'default_focal_mm',
      () => map['min_focal_mm'] ?? map['max_focal_mm'],
    );
    return Lens.fromMap(map);
  }
}
