import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// A [MotionLabel] changing word: Publish types ing, Published keeps the
/// shared letters. Pick a word to watch it type; Busy ripples it.
@widgetbook.UseCase(name: "Changing word", type: MotionLabel)
Widget motionLabelUseCase(BuildContext context) {
  final word = context.knobs.object.segmented(
    label: "Word",
    options: const ["Publish", "Publishing", "Published"],
    initialOption: "Publish",
  );
  final busy = context.knobs.boolean(label: "Busy");
  return Story(
    const [],
    at: PanelLocation.component(MotionLabel(word, rippling: busy)),
  );
}

/// A [TypedParagraph], the field message that types in: it wraps like its
/// whole text from the first letter, so nothing below it moves. Pick
/// another message to watch it type.
@widgetbook.UseCase(name: "Field message", type: TypedParagraph)
Widget typedParagraphUseCase(BuildContext context) {
  final message = context.knobs.object.segmented(
    label: "Message",
    options: const [
      "A line needs a speaker.",
      "Use at least three characters.",
      "This objective counts kills of a mob that no longer exists in "
          "this realm. Pick another mob or remove the objective.",
    ],
    initialOption: "A line needs a speaker.",
  );
  return Story(
    const [],
    at: PanelLocation.component(
      SizedBox(
        width: 260,
        child: TypedParagraph(
          message,
          style: context.text.sentenceSmall.copyWith(
            color: context.colors.dangerText,
          ),
        ),
      ),
    ),
  );
}

/// The busy sign of an icon button with no busy word: a [RippleGlyph]
/// rising and settling like one letter while Rippling. Under reduced motion
/// it stays level.
@widgetbook.UseCase(name: "Busy icon", type: RippleGlyph)
Widget rippleGlyphUseCase(BuildContext context) {
  final rippling = context.knobs.boolean(label: "Rippling", initialValue: true);
  return Story(
    context.knobs.motion(),
    at: PanelLocation.component(
      RippleGlyph(rippling: rippling, child: const Icon(Icons.refresh)),
    ),
  );
}
