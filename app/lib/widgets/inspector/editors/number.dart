import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter/models/entry_blueprint.dart";
import "package:typewriter/models/writers.dart";
import "package:typewriter/utils/icons.dart";
import "package:typewriter/widgets/components/app/writers.dart";
import "package:typewriter/widgets/inspector/editors.dart";
import "package:typewriter/widgets/inspector/validated_inspector_text_field.dart";

class NumberEditorFilter extends EditorFilter {
  @override
  bool canEdit(DataBlueprint dataBlueprint) =>
      dataBlueprint is PrimitiveBlueprint &&
      (dataBlueprint.type == PrimitiveType.integer ||
          dataBlueprint.type == PrimitiveType.double);

  @override
  Widget build(String path, DataBlueprint dataBlueprint) => NumberEditor(
        path: path,
        primitiveBlueprint: dataBlueprint as PrimitiveBlueprint,
      );
}

class NumberEditor extends HookConsumerWidget {
  const NumberEditor({
    required this.path,
    required this.primitiveBlueprint,
    super.key,
  }) : super();
  final String path;
  final PrimitiveBlueprint primitiveBlueprint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isNegativeAllowed =
        primitiveBlueprint.get("negative") as bool? ?? true;
    final min = primitiveBlueprint.get("min") as num?;
    final max = primitiveBlueprint.get("max") as num?;

    return WritersIndicator(
      provider: fieldWritersProvider(path),
      shift: (_) => const Offset(15, 0),
      child: ValidatedInspectorTextField(
        path: path,
        defaultValue: primitiveBlueprint.defaultValue(),
        serialize: (value) => primitiveBlueprint.type == PrimitiveType.integer
            ? int.tryParse(value) ?? 0
            : double.tryParse(value) ?? 0,
        deserialize: (value) => value.toString(),
        icon: TWIcons.hashtag,
        keyboardType: TextInputType.number,
        inputFormatters: [
          if (!isNegativeAllowed) ...[
            if (primitiveBlueprint.type == PrimitiveType.integer)
              FilteringTextInputFormatter.digitsOnly,
            if (primitiveBlueprint.type == PrimitiveType.double)
              FilteringTextInputFormatter.allow(RegExp(r"^\d+\.?\d*")),
          ] else ...[
            if (primitiveBlueprint.type == PrimitiveType.integer)
              FilteringTextInputFormatter.allow(RegExp(r"^-?\d*")),
            if (primitiveBlueprint.type == PrimitiveType.double)
              FilteringTextInputFormatter.allow(RegExp(r"^-?\d*\.?\d*")),
          ],
        ],
        validator: (value) {
          if (min != null && value < min) return "Value must be at least $min";
          if (max != null && value > max) return "Value must be at most $max";
          return null;
        },
      ),
    );
  }
}
