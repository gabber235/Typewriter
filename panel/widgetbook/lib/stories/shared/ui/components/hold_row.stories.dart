import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/stories/features/members/membership_story.dart";
import "package:widgetbook_workspace/support/story.dart";

/// Hold Delete or D on a member row, or Remove on a selection.
@widgetbook.UseCase(name: "Member rows", type: HoldRow)
Widget holdRowStory(BuildContext context) {
  return membershipStory(
    context,
    page: const MemberListRoute(),
    varied: MembershipList.members,
    traits: context.knobs.traits("Line layout", {
      for (final layout in HoldLineLayout.values)
        layout.name: [holdLine(layout)],
    }),
  );
}

/// The outcome line of a hold as a [HoldLine]: the verb types itself, then
/// the rest arrives on a bounce. Replay shows it again; a long line ends in
/// an ellipsis at narrow width.
@widgetbook.UseCase(name: "Outcome line", type: HoldLine)
Widget holdLineUseCase(BuildContext context) {
  final long = context.knobs.boolean(label: "Long line");
  final width = context.knobs.width(const {"Wide": 420, "Narrow": 220});
  return Story(
    context.knobs.motion(),
    at: PanelLocation.component(
      HookBuilder(
        builder: (context) {
          final run = useState(0);
          return SizedBox(
            width: width,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 16,
              children: [
                Button(label: "Replay", onPressed: () => run.value++),
                HoldLine(
                  key: ValueKey(run.value),
                  verb: "Removes",
                  text: long
                      ? "Removes Grace from Acme and every realm she edits"
                      : "Removes Grace",
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}

/// A row with its outcome line placed by [HoldLineSlot] in each layout the
/// hold story compares; the row keeps its size in every layout.
@widgetbook.UseCase(name: "Layouts", type: HoldLineSlot)
Widget holdLineSlotUseCase(BuildContext context) {
  final layout = context.knobs.object.segmented(
    label: "Layout",
    options: HoldLineLayout.values,
    initialOption: HoldLineLayout.over,
    labelBuilder: (layout) => layout.name,
  );
  return Story(
    const [],
    at: PanelLocation.component(
      HoldLineLayoutScope(
        layout: layout,
        child: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              HoldLineSlot(
                line: HoldLine(verb: "Removes", text: "Removes Grace"),
                child: const PanelRow(
                  title: Text("Grace"),
                  subtitle: Text("Editor"),
                ),
              ),
              const PanelRow(title: Text("Linus"), subtitle: Text("Viewer")),
            ],
          ),
        ),
      ),
    ),
  );
}
