import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/fa6_solid.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "package:typewriter_panel/logic/selectable/data_blueprint.dart";
import "package:typewriter_panel/logic/selectable/selection.dart";
import "package:typewriter_panel/utils/string.dart";
import "package:typewriter_panel/widgets/app/components/inspector/editors.dart";
import "package:typewriter_panel/widgets/app/components/inspector/editors/field_editor.dart";
import "package:typewriter_panel/widgets/app/components/inspector/header.dart";
import "package:typewriter_panel/widgets/generic/components/icones.dart";

part "list_editor.g.dart";

class ListEditor extends Editor {
  @override
  bool canEdit(DataBlueprint dataBlueprint) => dataBlueprint is ListBlueprint;

  @override
  Widget build(String path, DataBlueprint dataBlueprint, EditorMode mode) =>
      ListEditorWidget(
        path: path,
        listBlueprint: dataBlueprint as ListBlueprint,
        editorMode: mode,
      );

  @override
  (HeaderActions, Iterable<(String, HeaderContext, DataBlueprint)>)
      headerActions(
    Ref ref,
    String path,
    DataBlueprint dataBlueprint,
    HeaderContext context,
    EditorMode mode,
  ) {
    final listBlueprint = dataBlueprint as ListBlueprint;
    final length = ref.watch(_listValueLengthProvider(path));

    final actions =
        super.headerActions(ref, path, dataBlueprint, context, mode);
    final childContext = context.copyWith(parentBlueprint: dataBlueprint);
    final children = List.generate(
      length,
      (index) => (path.join("$index"), childContext, listBlueprint.type),
    );

    return (actions.$1, actions.$2.followedBy(children));
  }
}

@riverpod
int _listValueLength(Ref ref, String path) {
  return (ref.watch(fieldValueProvider(path)).value([]) as List<dynamic>? ?? [])
      .length;
}

class ListEditorWidget extends HookConsumerWidget {
  const ListEditorWidget({
    required this.path,
    required this.listBlueprint,
    required this.editorMode,
    super.key,
  });

  final String path;
  final ListBlueprint listBlueprint;
  final EditorMode editorMode;

  void _addNew(WidgetRef ref) {
    final currentValue = _get(ref);
    final newValue = [...currentValue, listBlueprint.type.defaultValue()];
    ref.read(selectedProvider.notifier).updateFieldValue(path, newValue);
  }

  List<dynamic> _get(WidgetRef ref) {
    return ref.read(fieldValueProvider(path)).value([]);
  }

  void _reorderList(List<dynamic> value, int oldIndex, int newIndex) {
    final item = value.removeAt(oldIndex);
    if (newIndex > oldIndex) {
      value.insert(newIndex - 1, item);
    } else {
      value.insert(newIndex, item);
    }
  }

  void _reorder(WidgetRef ref, int oldIndex, int newIndex) {
    final newValue = [..._get(ref)];
    _reorderList(newValue, oldIndex, newIndex);
    ref.read(selectedProvider.notifier).updateFieldValue(path, newValue);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final length = ref.watch(_listValueLengthProvider(path));
    final globalKeys = useMemoized(
      () => List.generate(
        length,
        (index) => GlobalKey(debugLabel: "item-$index"),
      ),
      [length],
    );

    return FieldHeader(
      path: path,
      canExpand: true,
      editorMode: editorMode,
      child: length > 0
          ? ReorderableListView(
              onReorder: (oldIndex, newIndex) {
                _reorder(ref, oldIndex, newIndex);
                _reorderList(globalKeys, oldIndex, newIndex);
              },
              shrinkWrap: true,
              // The Inspector is already scrollable, so we don't want this to be nested.
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              children: List.generate(
                length,
                (index) => _ListItem(
                  key: globalKeys[index],
                  index: index,
                  path: path,
                  listBlueprint: listBlueprint,
                  editorMode: editorMode,
                ),
              ),
            )
          : NoElements(
              path: path,
              onAdd: editorMode.canEdit ? () => _addNew(ref) : null,
            ),
    );
  }
}

class NoElements extends HookConsumerWidget {
  const NoElements({
    required this.path,
    required this.onAdd,
    super.key,
  });

  final String path;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name =
        ref.watch(pathDisplayNameProvider(path)).nullIfEmpty ?? "Fields";
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          spacing: 8,
          children: [
            Text(
              "No $name found",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (onAdd != null)
              ElevatedButton.icon(
                onPressed: onAdd,
                icon: const Icones(Fa6Solid.plus),
                label: Text("Add ${name.singular}"),
              )
            else
              const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}

class _ListItem extends HookConsumerWidget {
  const _ListItem({
    required this.index,
    required this.path,
    required this.listBlueprint,
    required this.editorMode,
    super.key,
  });

  final int index;
  final String path;
  final ListBlueprint listBlueprint;
  final EditorMode editorMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataBlueprint = listBlueprint.type;
    final childPath = path.join("$index");
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: FieldHeader(
        path: childPath,
        canExpand: true,
        editorMode: editorMode,
        child: FieldEditor(
          path: childPath,
          dataBlueprint: dataBlueprint,
          editorMode: editorMode,
        ),
      ),
    );
  }
}
