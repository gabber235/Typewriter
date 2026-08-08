import "package:flutter/foundation.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

class SelectionEditorSource extends ChangeNotifier implements EditorSource {
  SelectionEditorSource(this._ref) {
    _ref.listen(inspectedSelectionProvider, (_, _) => notifyListeners());
  }

  final Ref _ref;

  @override
  ObjectBlueprint? get blueprint => _ref.read(inspectedDataBlueprintProvider);

  @override
  EditorValue value(String path) {
    final inspected = _ref.read(inspectedSelectionProvider);
    if (inspected.isLoading) return const EditorValue.loading();

    final selection = inspected.value;
    if (selection == null || selection.isEmpty) return const EditorValue.none();

    final values = selection
        .map((selectable) => selectable.fieldValue(path))
        .toList();
    if (values.length == 1) return EditorValue.from(values.single);
    if (values.skip(1).any((value) => value != values.first)) {
      return const EditorValue.conflict();
    }
    return EditorValue.from(values.first);
  }

  @override
  void update(String path, dynamic value) {
    final selection = _ref.read(inspectedSelectionProvider).value ?? [];
    for (final selectable in selection) {
      selectable.setFieldValue(path, value);
    }
  }
}
