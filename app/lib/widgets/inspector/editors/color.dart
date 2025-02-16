import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_colorpicker/flutter_colorpicker.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter/hooks/select_on_focus.dart";
import "package:typewriter/models/entry_blueprint.dart";
import "package:typewriter/utils/icons.dart";
import "package:typewriter/utils/passing_reference.dart";
import "package:typewriter/widgets/components/general/formatted_text_field.dart";
import "package:typewriter/widgets/inspector/editors.dart";
import "package:typewriter/widgets/inspector/header.dart";
import "package:typewriter/widgets/inspector/inspector.dart";

class ColorEditor extends HookConsumerWidget {
  const ColorEditor({
    required this.path,
    required this.customBlueprint,
    super.key,
  });

  final String path;
  final CustomBlueprint customBlueprint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startColor =
        ref.watch(fieldValueProvider(path, customBlueprint.defaultValue()));

    final pickerColor = startColor is int ? Color(startColor) : Colors.black;
    final hexController =
        useTextEditingController(text: pickerColor.toHexString());

    final focus = useFocusNode();
    useSelectOnFocus(focus, hexController);

    final withAlpha = customBlueprint.hasModifier("with_alpha");

    return FieldHeader(
      path: path,
      canExpand: true,
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                ColorPicker(
                  pickerColor: pickerColor,
                  colorPickerWidth: constraints.maxWidth,
                  portraitOnly: true,
                  labelTypes: const [],
                  pickerAreaBorderRadius: BorderRadius.circular(4),
                  enableAlpha: withAlpha,
                  hexInputController: hexController,
                  onColorChanged: (color) {
                    ref
                        .read(inspectingEntryDefinitionProvider)
                        // ignore: deprecated_member_use
                        ?.updateField(ref.passing, path, color.value);
                  },
                ),
                FormattedTextField(
                  focus: focus,
                  controller: hexController,
                  icon: TWIcons.hashtag,
                  hintText: "Hex Code",
                  inputFormatters: [
                    UpperCaseTextFormatter(),
                    FilteringTextInputFormatter.allow(RegExp(kValidHexPattern)),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class ColorEditorFilter extends EditorFilter {
  @override
  Widget build(String path, DataBlueprint dataBlueprint) => ColorEditor(
        path: path,
        customBlueprint: dataBlueprint as CustomBlueprint,
      );

  @override
  bool canEdit(DataBlueprint dataBlueprint) =>
      dataBlueprint is CustomBlueprint && dataBlueprint.editor == "color";
}
