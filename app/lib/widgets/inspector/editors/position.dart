import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter/l10n/l10n_provider.dart";
import "package:typewriter/models/entry_blueprint.dart";
import "package:typewriter/models/writers.dart";
import "package:typewriter/utils/extensions.dart";
import "package:typewriter/utils/icons.dart";
import "package:typewriter/utils/passing_reference.dart";
import "package:typewriter/widgets/components/app/cord_property.dart";
import "package:typewriter/widgets/components/app/writers.dart";
import "package:typewriter/widgets/components/general/formatted_text_field.dart";
import "package:typewriter/widgets/inspector/current_editing_field.dart";
import "package:typewriter/widgets/inspector/editors.dart";
import "package:typewriter/widgets/inspector/inspector.dart";

class PositionEditorFilter extends EditorFilter {
  @override
  bool canEdit(DataBlueprint dataBlueprint) =>
      dataBlueprint is CustomBlueprint && dataBlueprint.editor == "position";

  @override
  Widget build(String path, DataBlueprint dataBlueprint) => PositionEditor(
        path: path,
        customBlueprint: dataBlueprint as CustomBlueprint,
      );
}

class PositionEditor extends HookConsumerWidget {
  const PositionEditor({
    required this.path,
    required this.customBlueprint,
    super.key,
  });
  final String path;

  final CustomBlueprint customBlueprint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(l10nProvider);
    final withRotation = customBlueprint.hasModifier("with_rotation");

    return Column(
      children: [
        _WorldEditor(path: path.join("world")),
        const SizedBox(height: 8),
        Row(
          children: [
            CordPropertyEditor(
              path: path.join("x"),
              label: "X",
              color: Colors.red,
            ),
            const SizedBox(width: 8),
            CordPropertyEditor(
              path: path.join("y"),
              label: "Y",
              color: Colors.green,
            ),
            const SizedBox(width: 8),
            CordPropertyEditor(
              path: path.join("z"),
              label: "Z",
              color: Colors.blue,
            ),
          ],
        ),
        if (withRotation) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              CordPropertyEditor(
                path: path.join("yaw"),
                label: l10n.yawFieldLabel,
                color: Colors.deepPurpleAccent,
              ),
              const SizedBox(width: 8),
              CordPropertyEditor(
                path: path.join("pitch"),
                label: l10n.pitchFieldLabel,
                color: Colors.amberAccent,
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _WorldEditor extends HookConsumerWidget {
  const _WorldEditor({
    required this.path,
  });

  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(l10nProvider);
    final focus = useFocusNode();
    final value = ref.watch(fieldValueProvider(path, ""));

    useFocusedBasedCurrentEditingField(focus, ref.passing, path);

    return WritersIndicator(
      provider: fieldWritersProvider(path),
      shift: (_) => const Offset(15, 0),
      child: FormattedTextField(
        focus: focus,
        text: value,
        icon: TWIcons.earth,
        hintText: l10n.worldFieldHint,
        onChanged: (value) {
          ref
              .read(inspectingEntryDefinitionProvider)
              ?.updateField(ref.passing, path, value);
        },
      ),
    );
  }
}
