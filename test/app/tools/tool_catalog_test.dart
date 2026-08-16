import 'package:camera_assistant/app/tools/tool_catalog.dart';
import 'package:camera_assistant/domain/models/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('default home tool order only references catalog tools', () {
    expect(
      ToolCatalog.toolIds,
      containsAll(AppSettings.defaultHomeToolOrder),
    );
  });

  test('catalog tool ids are unique', () {
    final ids = ToolCatalog.tools.map((tool) => tool.id).toList();

    expect(ids.toSet(), hasLength(ids.length));
  });
}
