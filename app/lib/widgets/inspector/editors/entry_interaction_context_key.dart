import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter/models/entry.dart";
import "package:typewriter/models/entry_blueprint.dart";
import "package:typewriter/models/page.dart";
import "package:typewriter/utils/extensions.dart";
import "package:typewriter/utils/passing_reference.dart";
import "package:typewriter/widgets/components/app/entry_node.dart";
import "package:typewriter/widgets/components/app/entry_search.dart";
import "package:typewriter/widgets/components/app/search_bar.dart";
import "package:typewriter/widgets/components/general/dropdown.dart";
import "package:typewriter/widgets/inspector/editors.dart";
import "package:typewriter/widgets/inspector/editors/entry_selector.dart";
import "package:typewriter/widgets/inspector/editors/generic.dart";
import "package:typewriter/widgets/inspector/inspector.dart";

class EntryInteractionContextKeyEditorFilter extends EditorFilter {
  @override
  bool canEdit(DataBlueprint dataBlueprint) =>
      dataBlueprint is CustomBlueprint &&
      dataBlueprint.editor == "entryInteractionContextKey";
  @override
  Widget build(String path, DataBlueprint dataBlueprint) {
    return EntryInteractionContextKeyEditor(
      path: path,
      customBlueprint: dataBlueprint as CustomBlueprint,
    );
  }
}

bool _blueprintHasContextKey(
  EntryBlueprint blueprint,
  DataBlueprint? dataBlueprint,
) {
  if (dataBlueprint == null) return blueprint.contextKeys.isNotEmpty;
  return blueprint.contextKeys
      .any((key) => key.blueprint.matches(dataBlueprint));
}

class ContextKeyFilter extends HiddenSearchFilter {
  const ContextKeyFilter(this.blueprint, {this.canRemove = true});

  final DataBlueprint? blueprint;
  @override
  final bool canRemove;

  @override
  bool filter(SearchElement action) {
    final blueprint = switch (action) {
      final EntrySearchElement entry => entry.blueprint,
      final AddEntrySearchElement entry => entry.blueprint,
      _ => null,
    };

    if (blueprint == null) return true;
    return _blueprintHasContextKey(blueprint, this.blueprint);
  }
}

extension on SearchBuilder {
  void fetchContextKey(DataBlueprint? blueprint) {
    filter(ContextKeyFilter(blueprint));
  }
}

class EntryInteractionContextKeyEditor extends HookConsumerWidget {
  const EntryInteractionContextKeyEditor({
    required this.path,
    required this.customBlueprint,
    super.key,
  });

  final String path;
  final CustomBlueprint customBlueprint;

  bool _updateEntry(
    PassingRef ref,
    Entry? entry,
    DataBlueprint? dataBlueprint,
  ) {
    if (entry == null) return false;
    final blueprint = ref.read(entryBlueprintProvider(entry.blueprintId));
    if (blueprint == null) return false;

    final firstValidKey = blueprint.contextKeys.firstWhereOrNull(
      (key) => dataBlueprint == null || key.blueprint.matches(dataBlueprint),
    );

    if (firstValidKey == null) return false;

    ref.read(inspectingEntryDefinitionProvider)?.updateField(ref, path, {
      "ref": entry.id,
      "key": firstValidKey.name,
      "keyClass": firstValidKey.klassName,
    });
    return true;
  }

  void _select(PassingRef ref, DataBlueprint? blueprint) {
    final selectedEntryId = ref.read(inspectingEntryIdProvider);

    ref.read(searchProvider.notifier).asBuilder()
      ..excludeEntry(selectedEntryId ?? "", canRemove: false)
      ..nonGenericAddEntry()
      ..fetchContextKey(blueprint)
      ..fetchEntry(onSelect: (entry) => _updateEntry(ref, entry, blueprint))
      ..fetchNewEntry(onAdded: (entry) => _updateEntry(ref, entry, blueprint))
      ..open();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final generic = Generic.maybeOf(context);
    final ignoresBlueprint =
        customBlueprint.hasModifier("ignore_context_key_blueprint");
    if (generic == null && !ignoresBlueprint) {
      return const GenericNotFoundWidget();
    }
    final targetBlueprint = ignoresBlueprint ? generic?.dataBlueprint : null;

    final entryId = ref.watch(fieldValueProvider(path.join("ref"), ""));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DragTarget<EntryDrag>(
          onWillAcceptWithDetails: (details) {
            if (details.data.entryId == entryId) return false;
            final entry = ref.read(globalEntryProvider(details.data.entryId));
            if (entry == null) return false;
            final blueprint =
                ref.read(entryBlueprintProvider(entry.blueprintId));
            if (blueprint == null) return false;

            return _blueprintHasContextKey(blueprint, targetBlueprint);
          },
          onAcceptWithDetails: (details) {
            final entry = ref.read(globalEntryProvider(details.data.entryId));
            _updateEntry(ref.passing, entry, targetBlueprint);
          },
          builder: (context, candidateData, rejectedData) {
            if (rejectedData.isNotEmpty) {
              return EntrySelectorRejectWidget();
            }
            final isAccepting = candidateData.isNotEmpty;

            return EntrySelectorEditorDisplay(
              entryId: candidateData.firstOrNull?.entryId ?? entryId,
              display: "Entry",
              isAccepting: isAccepting,
              selectEntry: () {
                _select(ref.passing, targetBlueprint);
              },
              onRemove: () {
                ref.read(inspectingEntryDefinitionProvider)?.updateField(
                      ref.passing,
                      path,
                      customBlueprint.defaultValue(),
                    );
              },
            );
          },
        ),
        if (ref.watch(entryExistsProvider(entryId))) ...[
          const SizedBox(height: 8),
          _ContextKeyDropdown(
            entryId: entryId,
            path: path,
            targetBlueprint: targetBlueprint,
          ),
        ],
      ],
    );
  }
}

class _ContextKeyDropdown extends HookConsumerWidget {
  const _ContextKeyDropdown({
    required this.entryId,
    required this.path,
    required this.targetBlueprint,
  });

  final String entryId;
  final String path;
  final DataBlueprint? targetBlueprint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entry = ref.read(globalEntryProvider(entryId));
    if (entry == null) return const SizedBox.shrink();
    final blueprint = ref.read(entryBlueprintProvider(entry.blueprintId));
    if (blueprint == null) return const SizedBox.shrink();

    final contextKeys = blueprint.contextKeys
        .where(
          (key) =>
              targetBlueprint == null ||
              key.blueprint.matches(targetBlueprint!),
        )
        .toList();

    if (contextKeys.isEmpty) return const SizedBox.shrink();

    final contextKeyName = ref.watch(fieldValueProvider(path.join("key"), ""));

    final selectedKey =
        contextKeys.firstWhereOrNull((key) => key.name == contextKeyName);

    return Dropdown<ContextKey>(
      value: selectedKey ?? contextKeys.first,
      values: contextKeys,
      onChanged: (value) {
        ref.read(inspectingEntryDefinitionProvider)?.updateField(
          ref.passing,
          path,
          {
            "ref": entryId,
            "key": value.name,
            "keyClass": value.klassName,
          },
        );
      },
      builder: (context, value) => Text(value.name.formatted),
    );
  }
}
