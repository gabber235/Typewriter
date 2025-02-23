import "package:collection/collection.dart";
import "package:flutter/material.dart" hide FilledButton;
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter/models/entry_blueprint.dart";
import "package:typewriter/utils/extensions.dart";
import "package:typewriter/utils/icons.dart";
import "package:typewriter/utils/passing_reference.dart";
import "package:typewriter/utils/popups.dart";
import "package:typewriter/widgets/components/general/iconify.dart";
import "package:typewriter/widgets/inspector/editors.dart";
import "package:typewriter/widgets/inspector/editors/entry_selector.dart";
import "package:typewriter/widgets/inspector/editors/enum.dart";
import "package:typewriter/widgets/inspector/editors/field.dart";
import "package:typewriter/widgets/inspector/editors/list.dart";
import "package:typewriter/widgets/inspector/editors/string.dart";
import "package:typewriter/widgets/inspector/header.dart";
import "package:typewriter/widgets/inspector/inspector.dart";

class MapEditorFilter extends EditorFilter {
  @override
  bool canEdit(DataBlueprint dataBlueprint) => dataBlueprint is MapBlueprint;

  @override
  Widget build(String path, DataBlueprint dataBlueprint) =>
      MapEditor(path: path, mapBlueprint: dataBlueprint as MapBlueprint);

  @override
  (HeaderActions, Iterable<(String, HeaderContext, DataBlueprint)>)
      headerActions(
    Ref<Object?> ref,
    String path,
    DataBlueprint dataBlueprint,
    HeaderContext context,
  ) {
    final mapBlueprint = dataBlueprint as MapBlueprint;
    final rawValue =
        ref.watch(fieldValueProvider(path, mapBlueprint.defaultValue()));

    final value = <String, dynamic>{
      ...rawValue.map((key, value) => MapEntry(key.toString(), value)),
    };

    final actions = super.headerActions(ref, path, dataBlueprint, context);
    final childContext = context.copyWith(parentBlueprint: dataBlueprint);
    final children = value.entries.map(
      (entry) => (path.join(entry.key), childContext, mapBlueprint.value),
    );

    return (actions.$1, actions.$2.followedBy(children));
  }
}

class MapEditor extends HookConsumerWidget {
  const MapEditor({
    required this.path,
    required this.mapBlueprint,
    super.key,
  }) : super();
  final String path;
  final MapBlueprint mapBlueprint;

  void _addNew(PassingRef ref, Map<String, dynamic> value) {
    final key = switch (mapBlueprint.key) {
      EnumBlueprint(values: final values) =>
        values.firstWhereOrNull((e) => !value.containsKey(e)),
      CustomBlueprint(editor: "ref") => "",
      _ => mapBlueprint.key.defaultValue(),
    };

    if (key == null) return;
    final val = mapBlueprint.value.defaultValue();
    ref.read(inspectingEntryDefinitionProvider)?.updateField(
      ref,
      path,
      {
        ...value.map(MapEntry.new),
        key: val,
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = stringMap(
      ref.watch(fieldValueProvider(path, mapBlueprint.defaultValue())),
    );

    // Create global keys for the different fields.
    // This is to keep the state of the fields when they are when a field is added or removed.
    final globalKeys = useMemoized(
      () => List.generate(
        value.length,
        (index) => GlobalKey(debugLabel: "item-$index"),
      ),
      [value.length],
    );

    return FieldHeader(
      path: path,
      canExpand: true,
      child: value.isNotEmpty
          ? Column(
              children: value.entries
                  .mapIndexed(
                    (index, entry) => _MapEntry(
                      key: globalKeys[index],
                      index: index,
                      map: value,
                      entry: entry,
                      path: path,
                      mapBlueprint: mapBlueprint,
                    ),
                  )
                  .toList(),
            )
          : NoElements(
              path: path,
              onAdd: () => _addNew(ref.passing, value),
            ),
    );
  }
}

class _MapEntry extends HookConsumerWidget {
  const _MapEntry({
    required this.index,
    required this.map,
    required this.entry,
    required this.path,
    required this.mapBlueprint,
    super.key,
  });

  final int index;
  final Map<String, dynamic> map;
  final MapEntry<String, dynamic> entry;
  final String path;
  final MapBlueprint mapBlueprint;

  void _changeKeyField(PassingRef ref, String key) {
    ref.read(inspectingEntryDefinitionProvider)?.updateField(
      ref,
      path,
      {
        ...map.map(MapEntry.new)..removeWhere((key, value) => key == entry.key),
        key: entry.value,
      },
    );
  }

  bool _alreadyContainsKey(String key) =>
      map.containsKey(key) && key != entry.key;

  Future<void> _changeKey(
    BuildContext context,
    PassingRef ref,
    String key,
  ) async {
    if (_alreadyContainsKey(key)) {
      final confirm = await showConfirmationDialogue(
        context: context,
        title: "Override key?",
        content:
            "The key '$key' already exists.\nThis will delete all the data from the existing key.",
        confirmIcon: TWIcons.warning,
        onConfirm: () => _changeKeyField(ref, key),
      );
      if (!confirm) return;
    }
    _changeKeyField(ref, key);
  }

  void _delete(PassingRef ref, Map<String, dynamic> value, String key) {
    final newValue = {
      ...value.map(MapEntry.new)..removeWhere((key, value) => key == entry.key),
    };

    ref.read(inspectingEntryDefinitionProvider)?.updateField(
          ref,
          path,
          newValue,
        );
  }

  Widget _keyEditor(BuildContext context, WidgetRef ref, String name) {
    if (mapBlueprint.key is PrimitiveBlueprint &&
        (mapBlueprint.key as PrimitiveBlueprint).type == PrimitiveType.string) {
      return Flexible(
        child: _StringKey(
          path: path,
          field: mapBlueprint.key as PrimitiveBlueprint,
          value: entry.key,
          onChanged: (value) => _changeKey(context, ref.passing, value),
        ),
      );
    }
    if (mapBlueprint.key is EnumBlueprint) {
      return Flexible(
        child: _EnumKey(
          path: path,
          enumBlueprint: mapBlueprint.key as EnumBlueprint,
          value: entry.key,
          onChanged: (value) => _changeKey(context, ref.passing, value),
        ),
      );
    }

    if (mapBlueprint.key.hasModifier("entry")) {
      return Flexible(
        child: _EntryKey(
          path: path,
          dataBlueprint: mapBlueprint.key,
          value: entry.key,
          onChanged: (value) => _changeKey(context, ref.passing, value),
        ),
      );
    }

    return Text(name);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(pathDisplayNameProvider(path.join(entry.key)));
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          Row(
            children: [
              const Iconify(TWIcons.barsStaggered, size: 12),
              const SizedBox(width: 8),
              _keyEditor(context, ref, name),
              IconButton(
                icon: const Iconify(TWIcons.trash, size: 12),
                color: Theme.of(context).colorScheme.error,
                onPressed: () => _delete(ref.passing, map, entry.key),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: FieldEditor(
              key: ValueKey("map-$index"),
              path: "$path.${entry.key}",
              dataBlueprint: mapBlueprint.value,
            ),
          ),
        ],
      ),
    );
  }
}

class _StringKey extends HookConsumerWidget {
  const _StringKey({
    required this.path,
    required this.field,
    required this.value,
    required this.onChanged,
  }) : super();
  final String path;
  final PrimitiveBlueprint field;
  final String value;
  final Function(String) onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StringEditor(
      path: path,
      primitiveBlueprint: field,
      forcedValue: value,
      icon: TWIcons.key,
      hint: "Enter a key",
      onChanged: onChanged,
    );
  }
}

class _EnumKey extends HookConsumerWidget {
  const _EnumKey({
    required this.path,
    required this.enumBlueprint,
    required this.value,
    required this.onChanged,
  });
  final String path;
  final EnumBlueprint enumBlueprint;
  final String value;
  final Function(String) onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return EnumEditor(
      path: path,
      enumBlueprint: enumBlueprint,
      forcedValue: value,
      icon: TWIcons.key,
      onChanged: onChanged,
    );
  }
}

class _EntryKey extends HookConsumerWidget {
  const _EntryKey({
    required this.path,
    required this.dataBlueprint,
    required this.value,
    required this.onChanged,
  });
  final String path;
  final DataBlueprint dataBlueprint;
  final String value;
  final Function(String) onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return EntrySelectorEditor(
      path: path,
      dataBlueprint: dataBlueprint,
      forcedValue: value,
      onChanged: onChanged,
    );
  }
}
