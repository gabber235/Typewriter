import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "Parsed whole seconds", type: ValidatedTextField)
Widget validatedTextFieldUseCase(
  BuildContext context,
) => ValidatedTextFieldStory(
  enabled: context.knobs.boolean(label: "Enabled", initialValue: true),
  readOnly: context.knobs.boolean(label: "Read only", initialValue: false),
  clearable: context.knobs.boolean(label: "Allow clearing", initialValue: true),
  mixed: context.knobs.boolean(label: "Mixed selection", initialValue: false),
  width: context.knobs.double.slider(
    label: "Field width",
    initialValue: 360,
    min: 220,
    max: 600,
  ),
);

/// Edits a respawn delay through text while retaining the last valid value
/// during invalid drafts.
class ValidatedTextFieldStory extends HookWidget {
  const ValidatedTextFieldStory({
    this.enabled = true,
    this.readOnly = false,
    this.clearable = true,
    this.mixed = false,
    this.width = 360,
    super.key,
  });

  final bool enabled;
  final bool readOnly;
  final bool clearable;
  final bool mixed;
  final double width;

  @override
  Widget build(BuildContext context) {
    final bound = useState<int?>(mixed ? null : 30);
    final edited = useState(false);
    final showsMixed = mixed && !edited.value;
    return FakeApp(
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: [
            const Text("Respawn delay (seconds)"),
            ValidatedTextField<int>(
              value: showsMixed ? null : bound.value,
              mixed: showsMixed,
              name: "respawn delay",
              icon: Ic.round_timer,
              keyboardType: TextInputType.number,
              enabled: enabled,
              readOnly: readOnly,
              serialize: _seconds,
              validator: (value) =>
                  value > 3600 ? "Use at most 3600 seconds" : null,
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
            Text(switch ((showsMixed, bound.value)) {
              (true, _) => "Bound value: mixed",
              (_, null) => "Bound value: empty",
              (_, final value?) => "Bound value: $value",
            }),
          ],
        ),
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
