import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/heroicons_solid.dart";
import "package:typewriter_panel/logic/selectable/data_blueprint.dart";
import "package:typewriter_panel/logic/selectable/selection.dart";
import "package:typewriter_panel/utils/string.dart";
import "package:typewriter_panel/widgets/app/components/inspector/editors.dart";
import "package:typewriter_panel/widgets/app/components/inspector/editors/field_editor.dart";
import "package:typewriter_panel/widgets/generic/components/formatted_text_field.dart";

class StringEditor extends Editor {
  @override
  bool canEdit(DataBlueprint dataBlueprint) =>
      dataBlueprint.matches(DataBlueprint.string());

  @override
  Widget build(
    String path,
    DataBlueprint dataBlueprint,
    EditorMode editorMode,
  ) {
    return StringEditorWidget(
      path: path,
      primitiveBlueprint: dataBlueprint as PrimitiveBlueprint,
      editorMode: editorMode,
    );
  }
}

class StringEditorWidget extends HookConsumerWidget {
  const StringEditorWidget({
    required this.path,
    required this.primitiveBlueprint,
    required this.editorMode,
    this.forceValue,
    this.icon = HeroiconsSolid.pencil,
    this.hint = "",
    this.onChanged,
    super.key,
  });
  final String path;
  final PrimitiveBlueprint primitiveBlueprint;
  final EditorMode editorMode;

  final String? forceValue;

  final String icon;
  final String hint;
  final Function(String)? onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusNode = useFocusNode();
    final controller = useTextEditingController();

    final multiline = primitiveBlueprint.hasModifier<MultilineModifier>();
    final snakeCase = primitiveBlueprint.hasModifier<SnakeCaseModifier>();
    final canEdit = editorMode.canEdit;

    return FieldValueEditor(
      path: path,
      dataBlueprint: primitiveBlueprint,
      editorMode: editorMode,
      forceValue: forceValue,
      builder: (value) {
        return FormattedTextField(
          controller: controller,
          focusNode: focusNode,
          icon: icon,
          hintText: hint.isNotEmpty
              ? hint
              : "Enter a ${primitiveBlueprint.type.name}",
          text: value,
          singleLine: !multiline,
          inputFormatters: [
            if (snakeCase) snakeCaseFormatter(),
          ],
          onChanged: (value) =>
              ref.read(selectedProvider.notifier).updateFieldValue(path, value),
          readOnly: !canEdit,
        );
      },
    );
  }
}
