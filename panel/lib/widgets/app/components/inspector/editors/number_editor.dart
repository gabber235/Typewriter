import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:iconify_flutter_plus/icons/heroicons_solid.dart";
import "package:iconify_flutter_plus/icons/mingcute.dart";
import "package:typewriter_panel/logic/selectable/data_blueprint.dart";
import "package:typewriter_panel/widgets/app/components/inspector/editors.dart";
import "package:typewriter_panel/widgets/app/components/inspector/editors/validated_editor_text_field.dart";

class NumberEditor extends Editor {
  @override
  bool canEdit(DataBlueprint dataBlueprint) =>
      dataBlueprint is PrimitiveBlueprint &&
      (dataBlueprint.type == PrimitiveType.integer ||
          dataBlueprint.type == PrimitiveType.double);

  @override
  Widget build(
    String path,
    DataBlueprint dataBlueprint,
    EditorMode editorMode,
  ) {
    return NumberEditorWidget(
      path: path,
      primitiveBlueprint: dataBlueprint as PrimitiveBlueprint,
      editorMode: editorMode,
    );
  }
}

class NumberEditorWidget extends StatelessWidget {
  const NumberEditorWidget({
    required this.path,
    required this.primitiveBlueprint,
    required this.editorMode,
    super.key,
  });

  final String path;
  final PrimitiveBlueprint primitiveBlueprint;
  final EditorMode editorMode;

  @override
  Widget build(BuildContext context) {
    final isNegativeAllowed =
        primitiveBlueprint.hasModifier<NegativeModifier>();
    final minModifiers = primitiveBlueprint.getModifiers<MinModifier>();
    final maxModifiers = primitiveBlueprint.getModifiers<MaxModifier>();

    final min = minModifiers.map((modifier) => modifier.value).maxOrNull;
    final max = maxModifiers.map((modifier) => modifier.value).minOrNull;

    final isInteger = primitiveBlueprint.type == PrimitiveType.integer;

    return ValidatedEditorTextField<num>(
      path: path,
      dataBlueprint: primitiveBlueprint,
      editorMode: editorMode,
      defaultValue: primitiveBlueprint.defaultValue(),
      serialize: (value) =>
          isInteger ? int.tryParse(value) ?? 0 : double.tryParse(value) ?? 0.0,
      deserialize: (value) => value.toString(),
      icon: HeroiconsSolid.hashtag,
      keyboardType: TextInputType.number,
      inputFormatters: [
        if (!isNegativeAllowed) ...[
          if (isInteger)
            FilteringTextInputFormatter.digitsOnly
          else
            FilteringTextInputFormatter.allow(RegExp(r"^\d+\.?\d*")),
        ] else ...[
          if (isInteger)
            FilteringTextInputFormatter.allow(RegExp(r"^-?\d*"))
          else
            FilteringTextInputFormatter.allow(RegExp(r"^-?\d*\.?\d*")),
        ],
      ],
      validator: (value) {
        if (min != null && value < min) return "Value must be at least $min";
        if (max != null && value > max) return "Value must be at most $max";
        return null;
      },
    );
  }
}
