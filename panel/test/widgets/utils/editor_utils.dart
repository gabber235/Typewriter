import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:hooks_riverpod/misc.dart";
import "package:typewriter_panel/logic/selectable/data_blueprint.dart";
import "package:typewriter_panel/logic/selectable/dynamic_data.dart";
import "package:typewriter_panel/logic/selectable/selectable.dart";
import "package:typewriter_panel/logic/selectable/selection.dart";
import "package:typewriter_panel/utils/map.dart";
import "package:typewriter_panel/widgets/app/components/action_shortcuts.dart";
import "package:typewriter_panel/widgets/app/components/inspector/editors.dart";
import "package:typewriter_panel/widgets/app/components/inspector/editors/object_editor.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../test_utils.dart";

extension EditorTesterExtension on WidgetTester {
  Future<void> pumpEditor({
    List<Override> overrides = const [],
    String selectedId = "editor",
    String path = "test",
    DataBlueprint? dataBlueprint,
    Widget? child,
    EditorMode editorMode = EditorMode.interactiveInspector,
    bool defaultExpanded = true,
    bool settle = true,
    bool actionRow = false,
    Map<String, dynamic> initialData = const {},
  }) async {
    assert(
      child != null || dataBlueprint != null,
      "Either child or dataBlueprint must be provided",
    );

    final objectBlueprint = dataBlueprint is ObjectBlueprint && path.isEmpty
        ? dataBlueprint
        : dataBlueprint != null
            ? ObjectBlueprint(
                fields: {
                  path: dataBlueprint,
                },
              )
            : null;

    await pumpTestApp(
      overrides: [
        ...overrides,
        if (objectBlueprint != null)
          selectionProvider.overrideWithValue([
            TestSelectableIdentifier(
              id: selectedId,
              dataBlueprint: objectBlueprint,
            ),
          ]),
      ],
      settle: settle,
      child: Consumer(
        child: child ??
            SingleChildScrollView(
              child: ObjectEditorWidget(
                path: "",
                objectBlueprint: objectBlueprint!,
                editorMode: editorMode,
                defaultExpanded: defaultExpanded,
              ),
            ),
        builder: (context, ref, child) {
          ref.watch(selectedProvider);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: child,
                ),
              ),
              if (actionRow) ActionRow(),
            ],
          );
        },
      ),
    );

    final Map<dynamic, dynamic> baseData =
        objectBlueprint?.defaultValue() ?? {};
    final data = stringMap(baseData.mask(initialData));
    container()
        .read(testSelectableDataProvider.notifier)
        .set(selectedId, DynamicData(data));

    if (settle) {
      await pumpAndSettle();
    }
  }

  void selectSelectables(List<SelectableIdentifier> identifiers) {
    container().read(selectionProvider.notifier).selectAll(identifiers);
  }

  dynamic fieldValue({
    String selectedId = "editor",
    String path = "test",
  }) {
    return container().read(testDataProvider(selectedId))?.get(path);
  }

  void setTestSelectableData({
    required Map<String, dynamic> data,
    String selectedId = "editor",
  }) {
    container()
        .read(testSelectableDataProvider.notifier)
        .set(selectedId, DynamicData(data));
  }
}
