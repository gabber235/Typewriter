import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter/l10n/l10n_provider.dart";
import "package:typewriter/models/entry_blueprint.dart";
import "package:typewriter/utils/passing_reference.dart";
import "package:typewriter/widgets/inspector/editors.dart";
import "package:typewriter/widgets/inspector/header.dart";
import "package:typewriter/widgets/inspector/inspector.dart";

class BooleanEditorFilter extends EditorFilter {
  @override
  bool canEdit(DataBlueprint dataBlueprint) =>
      dataBlueprint is PrimitiveBlueprint &&
      dataBlueprint.type == PrimitiveType.boolean;

  @override
  Widget build(String path, DataBlueprint dataBlueprint) => const SizedBox();
}

class BooleanHeaderActionFilter extends HeaderActionFilter {
  @override
  bool shouldShow(
    String path,
    HeaderContext context,
    DataBlueprint dataBlueprint,
  ) =>
      dataBlueprint is PrimitiveBlueprint &&
      dataBlueprint.type == PrimitiveType.boolean;
  @override
  HeaderActionLocation location(
    String path,
    HeaderContext context,
    DataBlueprint dataBlueprint,
  ) =>
      HeaderActionLocation.trailing;
  @override
  Widget build(
    String path,
    HeaderContext context,
    DataBlueprint dataBlueprint,
  ) =>
      BooleanEditor(
        path: path,
        primitiveBlueprint: dataBlueprint as PrimitiveBlueprint,
      );
}

class BooleanEditor extends HookConsumerWidget {
  const BooleanEditor({
    required this.path,
    required this.primitiveBlueprint,
    super.key,
  }) : super();
  final String path;
  final PrimitiveBlueprint primitiveBlueprint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(l10nProvider);
    final value =
        ref.watch(fieldValueProvider(path, primitiveBlueprint.defaultValue()));

    return Row(
      children: [
        Checkbox(
          value: value,
          onChanged: (value) {
            ref
                .read(inspectingEntryDefinitionProvider)
                ?.updateField(ref.passing, path, value ?? false);
          },
        ),
        if (value)
          Text(l10n.trueValue, style: const TextStyle(color: Colors.greenAccent))
        else
          Text(l10n.falseValue, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
