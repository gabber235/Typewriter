import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// The [ModalHeader] of selector popups and mobile sheets, with a short or
/// long title, with or without its close action.
@widgetbook.UseCase(name: "Default", type: ModalHeader)
Widget modalHeaderUseCase(BuildContext context) {
  final long = context.knobs.boolean(label: "Long title");
  final closable = context.knobs.boolean(
    label: "Close action",
    initialValue: true,
  );
  return Story(
    const [],
    at: PanelLocation.component(
      SizedBox(
        width: 360,
        child: ModalHeader(
          title: long
              ? "Choose the organization whose Realms you want to open"
              : "Organizations",
          onClose: closable ? () {} : null,
        ),
      ),
    ),
  );
}
