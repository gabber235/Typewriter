import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/ic.dart";
import "package:typewriter_panel/logic/selectable/data_blueprint.dart";
import "package:typewriter_panel/logic/selectable/selection.dart";
import "package:typewriter_panel/widgets/app/components/inspector/editors.dart";
import "package:typewriter_panel/widgets/app/components/inspector/editors/field_editor.dart";
import "package:typewriter_panel/widgets/generic/components/validated_text_field.dart";

class ValidatedEditorTextField<T> extends HookConsumerWidget {
  const ValidatedEditorTextField({
    required this.path,
    required this.dataBlueprint,
    required this.editorMode,
    required this.defaultValue,
    required this.deserialize,
    required this.serialize,
    this.formatted,
    this.validator,
    this.icon = Ic.round_text_fields,
    this.keyboardType = TextInputType.text,
    this.inputFormatters = const [],
    this.keepValidVisibleWhileFocused = false,
    super.key,
  });
  final String path;
  final DataBlueprint dataBlueprint;
  final EditorMode editorMode;

  final T defaultValue;
  final String Function(T) deserialize;
  final T Function(String) serialize;
  final String Function(T)? formatted;
  final String? Function(T)? validator;
  final String icon;
  final TextInputType keyboardType;
  final List<TextInputFormatter> inputFormatters;
  final bool keepValidVisibleWhileFocused;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focus = useFocusNode();

    final name = ref.watch(pathDisplayNameProvider(path));

    return FieldValueEditor(
      path: path,
      dataBlueprint: dataBlueprint,
      editorMode: editorMode,
      builder: (value) {
        return ValidatedTextField<T>(
          value: value ?? defaultValue,
          deserialize: deserialize,
          serialize: serialize,
          formatted: formatted,
          validator: validator,
          focusNode: focus,
          name: name,
          icon: icon,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          keepValidVisibleWhileFocused: keepValidVisibleWhileFocused,
          onChanged: (value) =>
              ref.read(selectedProvider.notifier).updateFieldValue(path, value),
        );
      },
    );
  }
}
