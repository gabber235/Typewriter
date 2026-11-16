import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// The layers [AppRequiredWidgets] puts around every page, at work on two
/// panes: Tab moves the one focus ring, Ctrl with an arrow moves between
/// the panes, which lift as they gain focus, and Join shows a toast.
@widgetbook.UseCase(name: "Panes, focus and toasts", type: AppRequiredWidgets)
Widget appRequiredWidgetsUseCase(BuildContext context) {
  return const Story([], at: PanelLocation.component(_TwoPanes()));
}

class _TwoPanes extends StatelessWidget {
  const _TwoPanes();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 560,
      height: 240,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Pane(
              id: "story-left",
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: context.spacing.space2,
                  children: [
                    Button(label: "Publish", autofocus: true, onPressed: () {}),
                    Button(label: "Rename", onPressed: () {}),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Pane(
              id: "story-right",
              child: Center(
                child: Button(
                  label: "Join",
                  face: ButtonFace.filled,
                  onPressed: () => context.reportSuccess("Join request sent"),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
