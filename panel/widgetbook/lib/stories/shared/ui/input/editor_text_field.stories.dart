import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// An [EditorTextField] for a page name: editable or read only, with or
/// without an error and icon, one line or several, wide or narrow.
@widgetbook.UseCase(name: "Default", type: EditorTextField)
Widget editorTextFieldUseCase(BuildContext context) {
  final readOnly = context.knobs.boolean(label: "Read only");
  final error = context.knobs.boolean(label: "Error");
  final icon = context.knobs.boolean(label: "Icon");
  final multiline = context.knobs.boolean(label: "Multiline");
  final narrow = context.knobs.boolean(label: "Narrow");
  return Story(
    const [],
    at: PanelLocation.component(
      SizedBox(
        width: narrow ? 200 : 420,
        child: EditorTextField(
          text: multiline
              ? "The village elder greets the player.\n"
                    "She asks them to find the lost lantern before dusk."
              : "Arrival",
          readOnly: readOnly,
          minLines: multiline ? 3 : null,
          maxLines: multiline ? 6 : 1,
          decoration: InputDecoration(
            hintText: "Page name",
            errorText: error ? "A page with this name already exists" : null,
            prefixIcon: icon ? const Icon(Icons.description_outlined) : null,
          ),
        ),
      ),
    ),
  );
}
