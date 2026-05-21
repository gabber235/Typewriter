import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter/l10n/extension_l10n_provider.dart";
import "package:typewriter/l10n/locale_provider.dart";
import "package:typewriter/models/entry_blueprint.dart";
import "package:typewriter/utils/extensions.dart";
import "package:typewriter/utils/localized_entry_metadata.dart";
import "package:typewriter/widgets/inspector/editors/algebraic.dart";
import "package:typewriter/widgets/inspector/editors/boolean.dart";
import "package:typewriter/widgets/inspector/editors/closed_range.dart";
import "package:typewriter/widgets/inspector/editors/color.dart";
import "package:typewriter/widgets/inspector/editors/coordinate.dart";
import "package:typewriter/widgets/inspector/editors/cron.dart";
import "package:typewriter/widgets/inspector/editors/duration.dart";
import "package:typewriter/widgets/inspector/editors/entry_interaction_context_key.dart";
import "package:typewriter/widgets/inspector/editors/entry_selector.dart";
import "package:typewriter/widgets/inspector/editors/enum.dart";
import "package:typewriter/widgets/inspector/editors/generic.dart";
import "package:typewriter/widgets/inspector/editors/global_context_key.dart";
import "package:typewriter/widgets/inspector/editors/item.dart";
import "package:typewriter/widgets/inspector/editors/list.dart";
import "package:typewriter/widgets/inspector/editors/map.dart";
import "package:typewriter/widgets/inspector/editors/material.dart";
import "package:typewriter/widgets/inspector/editors/number.dart";
import "package:typewriter/widgets/inspector/editors/object.dart";
import "package:typewriter/widgets/inspector/editors/optional.dart";
import "package:typewriter/widgets/inspector/editors/page_selector.dart";
import "package:typewriter/widgets/inspector/editors/position.dart";
import "package:typewriter/widgets/inspector/editors/potion_effect.dart";
import "package:typewriter/widgets/inspector/editors/skin.dart";
import "package:typewriter/widgets/inspector/editors/sound_id.dart";
import "package:typewriter/widgets/inspector/editors/sound_source.dart";
import "package:typewriter/widgets/inspector/editors/string.dart";
import "package:typewriter/widgets/inspector/editors/variable.dart";
import "package:typewriter/widgets/inspector/editors/vector.dart";
import "package:typewriter/widgets/inspector/editors/world.dart";
import "package:typewriter/widgets/inspector/header.dart";
import "package:typewriter/widgets/inspector/inspector.dart";

part "editors.g.dart";

@riverpod
dynamic fieldValue(Ref ref, String path, [dynamic defaultValue]) {
  final entry = ref.watch(inspectingEntryProvider);
  return entry?.get(path, defaultValue) ?? defaultValue;
}

@riverpod
List<EditorFilter> editorFilters(Ref ref) => [
      // Modifier Editors
      EntrySelectorEditorFilter(),
      PageSelectorEditorFilter(),

      // Custom Editors
      AlgebraicEditorFilter(),
      MaterialEditorFilter(),
      OptionalEditorFilter(),
      PositionEditorFilter(),
      CoordinateEditorFilter(),
      VectorEditorFilter(),
      DurationEditorFilter(),
      CronEditorFilter(),
      ClosedRangeFilter(),
      PotionEffectEditorFilter(),
      ItemEditorFilter(),
      SerializedItemEditorFilter(),
      SoundIdEditorFilter(),
      SoundSourceEditorFilter(),
      SkinEditorFilter(),
      ColorEditorFilter(),
      VariableEditorFilter(),
      GenericEditorFilter(),
      GlobalContextKeyEditorFilter(),
      WorldEditorFilter(),
      EntryInteractionContextKeyEditorFilter(),

      // Default filters
      StringEditorFilter(),
      NumberEditorFilter(),
      BooleanEditorFilter(),
      EnumEditorFilter(),
      ListEditorFilter(),
      MapEditorFilter(),
      ObjectEditorFilter(),
    ];

abstract class EditorFilter {
  bool canEdit(DataBlueprint dataBlueprint);

  Widget build(String path, DataBlueprint dataBlueprint);

  (HeaderActions, Iterable<(String, HeaderContext, DataBlueprint)>)
      headerActions(
    Ref ref,
    String path,
    DataBlueprint dataBlueprint,
    HeaderContext context,
  ) {
    final actions = ref
        .watch(headerActionFiltersProvider)
        .where((filter) {
          return filter.shouldShow(path, context, dataBlueprint);
        })
        .groupListsBy((filter) => filter.location(path, context, dataBlueprint))
        .map(
          (key, value) => MapEntry(
            key,
            value
                .map((filter) => filter.build(path, context, dataBlueprint))
                .toList(),
          ),
        );

    return (
      HeaderActions(
        leading: actions[HeaderActionLocation.leading] ?? [],
        trailing: actions[HeaderActionLocation.trailing] ?? [],
        actions: actions[HeaderActionLocation.actions] ?? [],
      ),
      [],
    );
  }
}

@riverpod
String pathDisplayName(Ref ref, String path) {
  final parts = path.split(".");
  final name = parts.removeLast();

  if (name == "") return "";
  if (int.tryParse(name) != null) {
    final index = int.parse(name) + 1;
    final parent = parts.removeLast();
    if (parent == "") return "#$index";
    return "${parent.formatted} #$index";
  }

  final definition = ref.watch(inspectingEntryDefinitionProvider);
  final blueprint = definition?.blueprint;
  final field = blueprint?.getField(path);
  if (blueprint != null && field != null) {
    final labelKey = LocalizedEntryMetadata.getLabelKey(field) ??
        LocalizedEntryMetadata.defaultFieldLabelKey(blueprint, path);
    return ref.watch(extensionL10nResolverProvider).resolve(
          blueprint.extension,
          ref.watch(localeControllerProvider),
          labelKey,
          fallback: name.formatted,
        );
  }

  return name.formatted;
}
