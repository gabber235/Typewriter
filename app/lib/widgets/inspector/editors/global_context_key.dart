import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter/l10n/l10n_provider.dart";
import "package:typewriter/models/entry_blueprint.dart";
import "package:typewriter/models/extension.dart";
import "package:typewriter/utils/extensions.dart";
import "package:typewriter/utils/passing_reference.dart";
import "package:typewriter/widgets/components/general/admonition.dart";
import "package:typewriter/widgets/components/general/dropdown.dart";
import "package:typewriter/widgets/inspector/editors.dart";
import "package:typewriter/widgets/inspector/inspector.dart";

class GlobalContextKeyEditorFilter extends EditorFilter {
  @override
  bool canEdit(DataBlueprint dataBlueprint) =>
      dataBlueprint is CustomBlueprint &&
      dataBlueprint.editor == "globalContextKey";

  @override
  Widget build(String path, DataBlueprint dataBlueprint) =>
      GlobalContextKeyEditor(
        path: path,
        globalContextKeyBlueprint: dataBlueprint as CustomBlueprint,
      );
}

class GlobalContextKeyEditor extends HookConsumerWidget {
  const GlobalContextKeyEditor({
    required this.path,
    required this.globalContextKeyBlueprint,
    super.key,
  });

  final String path;
  final CustomBlueprint globalContextKeyBlueprint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(l10nProvider);
    final selectedKlassName = ref.watch(fieldValueProvider(path, ""));
    final keys = ref.watch(globalContextKeysProvider);

    if (keys.isEmpty) {
      return Admonition.warning(
        child: Text(l10n.globalContextKeyEditor_noGlobalKeys),
      );
    }

    final selectedKey = keys.firstWhereOrNull(
      (key) => key.klassName == selectedKlassName,
    );
    return Dropdown<GlobalContextKey>(
      value: selectedKey ?? keys.first,
      values: keys,
      builder: (context, value) => Text(
        value.name.formatted,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      onChanged: (value) {
        return ref.read(inspectingEntryDefinitionProvider)?.updateField(
              ref.passing,
              path,
              value.klassName,
            );
      },
    );
  }
}
