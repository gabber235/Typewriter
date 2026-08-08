import "package:flutter/widgets.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "inspection.g.dart";

@riverpod
AsyncValue<List<InspectableSelectable>> inspectedSelection(Ref ref) {
  return ref.watch(selectedProvider).whenData((selection) {
    if (selection.any((selectable) => selectable is! InspectableSelectable)) {
      return [];
    }
    return selection.cast<InspectableSelectable>();
  });
}

@riverpod
bool hasInspectableSelection(Ref ref) {
  return ref.watch(inspectedSelectionProvider).value?.isNotEmpty ?? false;
}

@riverpod
ObjectBlueprint? inspectedDataBlueprint(Ref ref) {
  final selected = ref.watch(inspectedSelectionProvider).value;
  if (selected == null || selected.isEmpty) return null;
  return selected
      .map((selectable) => selectable.objectBlueprint)
      .toList()
      .overlap;
}

@riverpod
Widget? inspectedHeader(Ref ref) {
  final selected = ref.watch(inspectedSelectionProvider).value;
  if (selected == null || selected.length != 1) return null;
  return selected.single.buildInspectorHeader();
}
