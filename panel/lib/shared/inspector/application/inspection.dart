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
TypeExpression? inspectedRootType(Ref ref) {
  final selected = ref.watch(inspectedSelectionProvider).value;
  if (selected == null || selected.isEmpty) return null;
  if (selected.length == 1) return NamedType(selected.single.rootType);
  final representations = <TypeExpression>[];
  for (final selectable in selected) {
    final resolved = selectable.typeRegistry.resolveExact(selectable.rootType);
    final representation = resolved.valueOrNull?.representation;
    if (representation == null) return null;
    representations.add(representation);
  }
  return representations.commonEditableProjection().valueOrNull;
}

@riverpod
Widget? inspectedHeader(Ref ref) {
  final selected = ref.watch(inspectedSelectionProvider).value;
  if (selected == null || selected.length != 1) return null;
  return selected.single.buildInspectorHeader();
}
