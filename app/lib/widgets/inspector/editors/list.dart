import "package:flutter/material.dart" hide FilledButton;
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter/l10n/l10n_provider.dart";
import "package:typewriter/models/entry_blueprint.dart";
import "package:typewriter/utils/extensions.dart";
import "package:typewriter/utils/icons.dart";
import "package:typewriter/utils/passing_reference.dart";
import "package:typewriter/widgets/components/general/iconify.dart";
import "package:typewriter/widgets/components/general/outline_button.dart";
import "package:typewriter/widgets/inspector/editors.dart";
import "package:typewriter/widgets/inspector/editors/field.dart";
import "package:typewriter/widgets/inspector/header.dart";
import "package:typewriter/widgets/inspector/inspector.dart";

part "list.g.dart";

class ListEditorFilter extends EditorFilter {
  @override
  bool canEdit(DataBlueprint dataBlueprint) => dataBlueprint is ListBlueprint;

  @override
  Widget build(String path, DataBlueprint dataBlueprint) =>
      ListEditor(path: path, listBlueprint: dataBlueprint as ListBlueprint);

  @override
  (HeaderActions, Iterable<(String, HeaderContext, DataBlueprint)>)
      headerActions(
    Ref<Object?> ref,
    String path,
    DataBlueprint dataBlueprint,
    HeaderContext context,
  ) {
    final listBlueprint = dataBlueprint as ListBlueprint;
    final length = _listValueLength(ref, path);

    final actions = super.headerActions(ref, path, dataBlueprint, context);
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
  return (ref.watch(fieldValueProvider(path)) as List<dynamic>? ?? []).length;
}

class ListEditor extends HookConsumerWidget {
  const ListEditor({
    required this.path,
    required this.listBlueprint,
    super.key,
  }) : super();
  final String path;
  final ListBlueprint listBlueprint;

  void _addNew(PassingRef ref) {
    ref.read(inspectingEntryDefinitionProvider)?.updateField(
      ref,
      path,
      [..._get(ref), listBlueprint.type.defaultValue()],
    );
  }

  List<dynamic> _get(PassingRef ref) {
    return ref.read(fieldValueProvider(path)) as List<dynamic>? ?? [];
  }

  void _reorderList(List<dynamic> value, int oldIndex, int newIndex) {
    final item = value.removeAt(oldIndex);
    value.insert(newIndex, item);
  }

  void _reorder(
    PassingRef ref,
    int oldIndex,
    int newIndex,
  ) {
    final newValue = [..._get(ref)];
    _reorderList(newValue, oldIndex, newIndex);

    ref.read(inspectingEntryDefinitionProvider)?.updateField(
          ref,
          path,
          newValue,
        );
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
      child: length > 0
          ? ReorderableList(
              itemCount: length,
              onReorder: (oldIndex, newIndex) {
                _reorder(ref.passing, oldIndex, newIndex);
                _reorderList(globalKeys, oldIndex, newIndex);
              },
              shrinkWrap: true,
              // The Inspector is already scrollable, so we don't want this to be nested.
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) => _ListItem(
                key: globalKeys[index],
                index: index,
                path: path,
                listBlueprint: listBlueprint,
              ),
            )
          : NoElements(
              path: path,
              onAdd: () => _addNew(ref.passing),
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
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(l10nProvider);
    final name =
        ref.watch(pathDisplayNameProvider(path)).nullIfEmpty ?? l10n.fields;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          spacing: 8,
          children: [
            Text(
              l10n.noElementsFound(name),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            OutlineButton.icon(
              onPressed: onAdd,
              icon: const Iconify(TWIcons.plus),
              label: Text(l10n.addNew(name.singular)),
              color: Theme.of(context).colorScheme.primary,
            ),
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
    super.key,
  }) : super();

  final int index;
  final String path;
  final ListBlueprint listBlueprint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataBlueprint = listBlueprint.type;
    final childPath = path.join("$index");
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: FieldHeader(
        path: childPath,
        canExpand: true,
        child: FieldEditor(
          path: childPath,
          dataBlueprint: dataBlueprint,
        ),
      ),
    );
  }
}
