import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// A [PanelDialog] opened over a page that sinks back behind it.
@widgetbook.UseCase(name: "Over a page", type: PanelDialog)
Widget panelDialogUseCase(BuildContext context) {
  return Story(
    const [],
    at: PanelLocation.component(
      DialogBackdrop(
        child: Center(
          child: Builder(
            builder: (context) => Button(
              label: "Review changes",
              onPressed: () => showAdvancedDialog<void>(
                context: context,
                builder: (context) => PanelDialog(
                  title: "Review changes",
                  content: const Text(
                    "Two pages changed since you opened them.",
                  ),
                  actions: [
                    Button(
                      label: "Close",
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// A [PanelDialog] on its own, with a long message and two actions.
@widgetbook.UseCase(name: "Surface", type: PanelDialog)
Widget panelDialogSurfaceUseCase(BuildContext context) {
  return Story(
    const [],
    at: PanelLocation.component(
      PanelDialog(
        title: "Leave this work session?",
        content: const Text(
          "Some local work has not reached a safe state. Leaving now loses "
          "it.",
        ),
        actions: [
          Button(label: "Stay", onPressed: () {}),
          Button(face: ButtonFace.filled, label: "Leave", onPressed: () {}),
        ],
      ),
    ),
  );
}
