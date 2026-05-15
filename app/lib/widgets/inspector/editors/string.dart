import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter/l10n/l10n_provider.dart";
import "package:typewriter/models/entry_blueprint.dart";
import "package:typewriter/models/writers.dart";
import "package:typewriter/utils/extensions.dart";
import "package:typewriter/utils/icons.dart";
import "package:typewriter/utils/passing_reference.dart";
import "package:typewriter/widgets/components/app/writers.dart";
import "package:typewriter/widgets/components/general/formatted_text_field.dart";
import "package:typewriter/widgets/inspector/current_editing_field.dart";
import "package:typewriter/widgets/inspector/editors.dart";
import "package:typewriter/widgets/inspector/inspector.dart";

class StringEditorFilter extends EditorFilter {
  @override
  bool canEdit(DataBlueprint dataBlueprint) =>
      dataBlueprint is PrimitiveBlueprint &&
      dataBlueprint.type == PrimitiveType.string;

  @override
  Widget build(String path, DataBlueprint dataBlueprint) => StringEditor(
        path: path,
        primitiveBlueprint: dataBlueprint as PrimitiveBlueprint,
      );
}

class StringEditor extends HookConsumerWidget {
  const StringEditor({
    required this.path,
    required this.primitiveBlueprint,
    this.forcedValue,
    this.icon = TWIcons.pencil,
    this.hint = "",
    this.onChanged,
    super.key,
  }) : super();

  final String path;
  final PrimitiveBlueprint primitiveBlueprint;
  final String? forcedValue;

  final String icon;
  final String hint;
  final Function(String)? onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(l10nProvider);
    final focus = useFocusNode();
    useFocusedBasedCurrentEditingField(focus, ref.passing, path);
    final value =
        ref.watch(fieldValueProvider(path, primitiveBlueprint.defaultValue()));

    final singleLine = !primitiveBlueprint.hasModifier("multiline");

    return WritersIndicator(
      provider: fieldWritersProvider(path, exact: true),
      shift: (_) => const Offset(15, 0),
      child: FormattedTextField(
        focus: focus,
        icon: icon,
        hintText:
            hint.isNotEmpty ? hint : l10n.enterAValue(primitiveBlueprint.type.name),
        text: forcedValue ?? value,
        singleLine: singleLine,
        keyboardType: singleLine ? TextInputType.text : TextInputType.multiline,
        inputFormatters: [
          if (primitiveBlueprint.hasModifier("snake_case"))
            snakeCaseFormatter(),
        ],
        onChanged: onChanged ??
            (value) => ref
                .read(inspectingEntryDefinitionProvider)
                ?.updateField(ref.passing, path, value),
      ),
    );
  }
}
