import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "Text and picker editing", type: ColorPickerField)
Widget colorPickerFieldUseCase(BuildContext context) => ColorPickerFieldStory(
  includeAlpha: context.knobs.boolean(
    label: "Include alpha",
    initialValue: true,
  ),
  editingFormat: context.knobs.object.dropdown(
    label: "Editing format",
    options: ColorFieldFormat.values,
    initialOption: ColorFieldFormat.hex,
    labelBuilder: (format) => format.name.toUpperCase(),
  ),
  showSwatch: context.knobs.boolean(label: "Show swatch", initialValue: true),
  showFormatSelector: context.knobs.boolean(
    label: "Show format selector",
    initialValue: true,
  ),
  mixed: context.knobs.boolean(label: "Mixed selection", initialValue: false),
  enabled: context.knobs.boolean(label: "Enabled", initialValue: true),
  readOnly: context.knobs.boolean(label: "Read only", initialValue: false),
  width: context.knobs.double.slider(
    label: "Field width",
    initialValue: 420,
    min: 260,
    max: 640,
  ),
);

/// Binds a Tag color so text drafts, picker drags and swatches report the
/// value they would write.
class ColorPickerFieldStory extends HookWidget {
  const ColorPickerFieldStory({
    this.includeAlpha = true,
    this.editingFormat = ColorFieldFormat.hex,
    this.showSwatch = true,
    this.showFormatSelector = true,
    this.mixed = false,
    this.enabled = true,
    this.readOnly = false,
    this.width = 420,
    super.key,
  });

  final bool includeAlpha;
  final ColorFieldFormat editingFormat;
  final bool showSwatch;
  final bool showFormatSelector;
  final bool mixed;
  final bool enabled;
  final bool readOnly;
  final double width;

  static const _offeredSwatches = [0xFFE74C3C, 0xFF3498DB, 0xFF2ECC71];

  @override
  Widget build(BuildContext context) {
    final bound = useState<Color?>(const Color(0xCC7C4DFF));
    final edited = useState(false);
    final showsMixed = mixed && !edited.value;
    void changed(Color next) {
      edited.value = true;
      bound.value = next;
    }

    void cleared() {
      edited.value = true;
      bound.value = null;
    }

    return FakeApp(
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: [
            const Text("Tag color"),
            if (showsMixed)
              ColorPickerField.mixed(
                includeAlpha: includeAlpha,
                editingFormat: editingFormat,
                showSwatch: showSwatch,
                showFormatSelector: showFormatSelector,
                offeredSwatches: _offeredSwatches,
                enabled: enabled,
                readOnly: readOnly,
                onChanged: changed,
                onCleared: cleared,
              )
            else
              ColorPickerField(
                color: bound.value,
                includeAlpha: includeAlpha,
                editingFormat: editingFormat,
                showSwatch: showSwatch,
                showFormatSelector: showFormatSelector,
                offeredSwatches: _offeredSwatches,
                enabled: enabled,
                readOnly: readOnly,
                onChanged: changed,
                onCleared: cleared,
              ),
            Text(switch ((showsMixed, bound.value)) {
              (true, _) => "Bound color: mixed",
              (_, null) => "Bound color: empty",
              (_, final color?) =>
                "Bound color: #${color.argbValue.toRadixString(16).toUpperCase().padLeft(8, "0")}",
            }),
          ],
        ),
      ),
    );
  }
}
