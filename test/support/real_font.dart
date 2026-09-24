/// Helpers for the tests that have to measure with the font the app ships
/// rather than `flutter_test`'s stand-in.
///
/// The stand-in font's glyphs are about one em wide: wider than Roboto, so a
/// gate that uses it errs on the pessimistic side, but it also breaks lines
/// where Roboto would not. Layout gates that make a *claim about width* -
/// "this message fits", "this row is not clipped" - have to load the real
/// metrics, or they measure a font no photographer will ever see.
library;

import 'dart:io';

import 'package:flutter/services.dart';

/// `flutter test` runs on the dart inside the SDK cache, so the fonts sit
/// `bin/cache/artifacts/material_fonts` under some ancestor of the executable.
/// The ancestor is searched for rather than counted, so a different SDK layout
/// cannot silently point a gate at an empty directory.
Directory materialFontsDirectory() {
  var directory = File(Platform.resolvedExecutable).parent;
  for (var depth = 0; depth < 8; depth++) {
    final candidate = Directory(
      '${directory.path}/bin/cache/artifacts/material_fonts',
    );
    if (candidate.existsSync()) return candidate;
    final parent = directory.parent;
    if (parent.path == directory.path) break;
    directory = parent;
  }
  return Directory('bin/cache/artifacts/material_fonts');
}

/// The Roboto faces the SDK ships, in the weights the app's text theme asks
/// for. Faces the SDK does not ship are dropped rather than fatal.
List<String> robotoFontPaths() {
  final directory = materialFontsDirectory();
  return <String>[
        'Roboto-Regular.ttf',
        'Roboto-Medium.ttf',
        'Roboto-Bold.ttf',
        'Roboto-Italic.ttf',
      ]
      .where((name) => File('${directory.path}/$name').existsSync())
      .map((name) => '${directory.path}/$name')
      .toList();
}

/// Registers Roboto with the test engine. Returns false when the SDK ships no
/// fonts here, so the caller can skip instead of failing for an environment
/// reason.
///
/// [family] defaults to the name the app's text theme asks for. A file that
/// needs real metrics for one gate can pass its own name instead, so its other
/// tests keep measuring whatever they measured before.
Future<bool> loadRoboto({String family = 'Roboto'}) async {
  final paths = robotoFontPaths();
  if (paths.isEmpty) return false;

  final loader = FontLoader(family);
  for (final path in paths) {
    loader.addFont(
      Future<ByteData>.value(
        ByteData.sublistView(Uint8List.fromList(File(path).readAsBytesSync())),
      ),
    );
  }
  await loader.load();
  return true;
}
