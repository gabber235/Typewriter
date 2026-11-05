import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// A respawn delay in whole seconds: valid or out of range on load, mixed across a selection, read only or disabled.
@widgetbook.UseCase(name: "Parsed whole seconds", type: ValidatedTextField)
Widget validatedTextFieldUseCase(BuildContext context) {
  final initial = context.knobs.object.segmented(
    label: "Value",
    options: const [30, 7200],
    labelBuilder: (seconds) => seconds > 3600 ? "Out of range" : "Valid",
    initialOption: 30,
  );
  return Story(
    const [],
    at: PanelLocation.component(
      ValidatedTextFieldStory(
        initial: initial,
        enabled: context.knobs.boolean(label: "Enabled", initialValue: true),
        readOnly: context.knobs.boolean(label: "Read only"),
        clearable: context.knobs.boolean(
          label: "Allow clearing",
          initialValue: true,
        ),
        mixed: context.knobs.boolean(label: "Mixed selection"),
      ),
    ),
  );
}

/// Edits a respawn delay through text while retaining the last valid value
/// during invalid drafts; it starts at [initial] seconds.
class ValidatedTextFieldStory extends HookWidget {
  const ValidatedTextFieldStory({
    this.enabled = true,
    this.readOnly = false,
    this.clearable = true,
    this.mixed = false,
    this.initial = 30,
    super.key,
  });

  final bool enabled;
  final bool readOnly;
  final bool clearable;
  final bool mixed;
  final int initial;

  @override
  Widget build(BuildContext context) {
    final bound = useState<int?>(mixed ? null : initial);
    final edited = useState(false);
    final showsMixed = mixed && !edited.value;
    return SizedBox(
      width: 360,
      child: ValidatedTextField<int>(
        value: showsMixed ? null : bound.value,
        mixed: showsMixed,
        name: "respawn delay",
        icon: Ic.round_timer,
        keyboardType: TextInputType.number,
        enabled: enabled,
        readOnly: readOnly,
        serialize: _seconds,
        validator: (value) => value > 3600 ? "Use at most 3600 seconds" : null,
        onChanged: (value) {
          edited.value = true;
          bound.value = value;
        },
        onCleared: clearable
            ? () {
                edited.value = true;
                bound.value = null;
              }
            : null,
      ),
    );
  }
}

int _seconds(String text) {
  final value = int.tryParse(text.trim());
  if (value == null || value < 0) {
    throw const FormatException("Enter whole seconds");
  }
  return value;
}
