/// Persistence support shared by calculator result views.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../domain/calculation_snapshot.dart';

Future<void> saveCalculationSnapshot(
  BuildContext context,
  WidgetRef ref,
  CalculationSnapshot snapshot,
) async {
  try {
    await ref.read(snapshotRepositoryProvider).save(snapshot);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Result saved on this device.')),
    );
  } on Object {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Result could not be saved. Try again.')),
    );
  }
}
