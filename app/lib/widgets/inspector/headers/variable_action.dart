import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter/models/entry.dart";
import "package:typewriter/models/entry_blueprint.dart";
import "package:typewriter/utils/icons.dart";
import "package:typewriter/utils/passing_reference.dart";
import "package:typewriter/widgets/components/app/entry_search.dart";
import "package:typewriter/widgets/components/app/header_button.dart";
import "package:typewriter/widgets/components/app/search_bar.dart";
import "package:typewriter/widgets/inspector/editors.dart";
import "package:typewriter/widgets/inspector/editors/generic.dart";
import "package:typewriter/widgets/inspector/editors/variable.dart";
import "package:typewriter/widgets/inspector/header.dart";
import "package:typewriter/widgets/inspector/inspector.dart";

class VariableHeaderActionFilter extends HeaderActionFilter {
  @override
  bool shouldShow(
    String path,
    HeaderContext context,
    DataBlueprint dataBlueprint,
  ) {
    if (dataBlueprint is! CustomBlueprint) return false;
    return dataBlueprint.editor == "var";
  }

  @override
  HeaderActionLocation location(
    String path,
    HeaderContext context,
    DataBlueprint dataBlueprint,
  ) =>
      HeaderActionLocation.actions;

  @override
  Widget build(
    String path,
    HeaderContext context,
    DataBlueprint dataBlueprint,
  ) {
    return VariableHeaderAction(
      path: path,
      customBlueprint: dataBlueprint as CustomBlueprint,
    );
  }
}

class VariableHeaderAction extends HookConsumerWidget {
  const VariableHeaderAction({
    required this.path,
    required this.customBlueprint,
    super.key,
  });

  final String path;
  final CustomBlueprint customBlueprint;

  Future<void> _createVariable(PassingRef ref, BuildContext context) async {
    var blueprint = customBlueprint.shape;

    // If the blueprint is a generic blueprint, we want to use the actual blueprint instead.
    if (blueprint is CustomBlueprint && blueprint.editor == "generic") {
      final generic = Generic.maybeOf(context);
      if (generic != null) {
        blueprint = generic.dataBlueprint;
      } else {
        final b = ref.read(inspectingEntryProvider)?.genericBlueprint;
        if (b != null) {
          blueprint = b;
        } else {
          throw Exception(
            "Could not find generic blueprint, this should not happen! For path: $path",
          );
        }
      }
    }

    ref.read(searchProvider.notifier).asBuilder()
      ..fetchNewEntry(
        genericBlueprint: blueprint,
        onAdded: (entry) => _update(ref, entry, blueprint),
      )
      ..fetchEntry(onSelect: (entry) => _update(ref, entry, blueprint))
      ..genericEntry(blueprint)
      ..tag("variable", canRemove: false)
      ..open();
  }

  bool _update(PassingRef ref, Entry? entry, DataBlueprint blueprint) {
    if (entry == null) return false;
    final targetBlueprint = ref.read(entryBlueprintProvider(entry.blueprintId));
    if (targetBlueprint == null) return false;

    final data = {
      "_kind": "backed",
      "ref": entry.id,
      "data": targetBlueprint.variableDataBlueprint?.defaultValue() ?? {},
    };
    ref.read(inspectingEntryDefinitionProvider)?.updateField(ref, path, data);

    // Refresh the variable generic blueprint.
    if (entry.genericBlueprint != null) {
      ref.read(entryDefinitionProvider(entry.id))?.updateField(
            ref,
            "_genericBlueprint",
            blueprint.toJson(),
          );
    }

    return true;
  }

  Future<void> _removeVariable(PassingRef ref) async {
    await ref
        .read(inspectingEntryDefinitionProvider)
        ?.updateField(ref, path, customBlueprint.defaultValue());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(fieldValueProvider(path));
    final data = variableData(value);
    if (data == null) {
      return HeaderButton(
        tooltip: "Replace with Variable",
        icon: TWIcons.variable,
        color: Colors.green,
        onTap: () => _createVariable(ref.passing, context),
      );
    }

    return HeaderButton(
      tooltip: "Remove Variable",
      icon: TWIcons.x,
      color: Colors.red,
      onTap: () => _removeVariable(ref.passing),
    );
  }
}
