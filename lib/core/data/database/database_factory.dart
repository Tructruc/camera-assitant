/// Platform database initialization kept behind a small factory boundary.
library;

import 'package:drift_flutter/drift_flutter.dart';

import 'app_database.dart';

AppDatabase openAppDatabase() {
  return AppDatabase(driftDatabase(name: 'photography_assistant'));
}
