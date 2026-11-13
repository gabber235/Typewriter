import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/shared/editors/diagnostics.dart";
import "package:widgetbook_workspace/support/story.dart";

/// A header anchor over the fields of a quest. Open, each problem shows
/// on its field and the header marks what lies below it; collapsed, the
/// fields are gone and the header takes their problems.
@widgetbook.UseCase(name: "Header over fields", type: PortableDiagnosticAnchor)
Widget portableDiagnosticAnchorUseCase(BuildContext context) {
  final problems = context.knobs.object.segmented(
    label: "Problems",
    options: const ["None", "One", "Several"],
    initialOption: "One",
  );
  final collapsed = context.knobs.boolean(label: "Collapsed");
  final width = context.knobs.width(const {"Inspector": 420, "Narrow": 240});
  final diagnostics = [
    if (problems != "None")
      storyDiagnostic("Use at least three characters", field: "title"),
    if (problems == "Several") ...[
      storyDiagnostic(
        "Rewards over 1000 coins unbalance the economy",
        severity: skir.DiagnosticSeverity.warning,
        field: "reward",
      ),
      storyDiagnostic(
        "Players see this title when they accept the quest",
        severity: skir.DiagnosticSeverity.information,
        field: "title",
      ),
    ],
  ];
  return Story(
    const [],
    at: PanelLocation.component(
      StoryDiagnosticScope(
        child: PortableDiagnosticSource(
          diagnostics: diagnostics,
          observations: const [],
          child: SizedBox(
            width: width,
            child: PortableDiagnosticAnchor(
              node: PortableDiagnosticNode(
                kind: PortableDiagnosticNodeKind.header,
                observations: [
                  PortableDiagnosticObservation(
                    target: storyQuestTarget,
                    value: null,
                  ),
                ],
              ),
              builder: (context, summary, _) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 16,
                  children: [
                    Row(
                      spacing: 8,
                      children: [
                        const Expanded(child: Text("Find the lantern")),
                        if (!summary.isEmpty)
                          PortableDiagnosticHeaderMarker(summary: summary),
                      ],
                    ),
                    if (!collapsed) ...[
                      const StoryDiagnosedField(
                        field: "title",
                        label: "Title",
                        text: "Go",
                      ),
                      const StoryDiagnosedField(
                        field: "reward",
                        label: "Reward",
                        text: "5000 coins",
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
}
