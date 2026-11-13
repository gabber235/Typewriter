import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/shared/editors/diagnostics.dart";
import "package:widgetbook_workspace/support/story.dart";

/// The messages under a field. New problems type in once the value rests;
/// Fix clears them and the field says Fixed before the messages close, and
/// Report brings them back.
@widgetbook.UseCase(name: "Type in and Fixed", type: PortableDiagnosticMessages)
Widget portableDiagnosticMessagesUseCase(BuildContext context) {
  final problems = context.knobs.object.dropdown(
    label: "Problems",
    options: const ["One", "Mixed severities", "Long"],
    initialOption: "One",
  );
  final width = context.knobs.width(const {"Inspector": 360, "Narrow": 200});
  return Story(
    context.knobs.traits("Motion", {
      "Full": const [],
      "Reduced": const [reducedMotion],
    }),
    at: PanelLocation.component(
      PortableDiagnosticMessagesStory(
        width: width,
        diagnostics: switch (problems) {
          "Mixed severities" => [
            storyDiagnostic("Use at least three characters"),
            storyDiagnostic(
              "Titles over 40 characters are cut off in the quest book",
              severity: skir.DiagnosticSeverity.warning,
            ),
            storyDiagnostic(
              "Players see this title when they accept the quest",
              severity: skir.DiagnosticSeverity.information,
            ),
          ],
          "Long" => [
            storyDiagnostic(
              "The objective names an entity that was removed from the "
              "realm. Choose another entity or remove this objective before "
              "you publish the quest, or players cannot finish it.",
            ),
          ],
          _ => [storyDiagnostic("Use at least three characters")],
        },
      ),
    ),
  );
}

/// [diagnostics] under a title field, with buttons that clear and report
/// them again.
class PortableDiagnosticMessagesStory extends HookWidget {
  const PortableDiagnosticMessagesStory({
    required this.diagnostics,
    required this.width,
    super.key,
  });

  final List<PortablePresentationDiagnostic> diagnostics;
  final double width;

  @override
  Widget build(BuildContext context) {
    final reported = useState(true);
    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Row(
            spacing: 8,
            children: [
              Button(
                label: "Fix",
                onPressed: reported.value ? () => reported.value = false : null,
              ),
              Button(
                label: "Report",
                onPressed: reported.value ? null : () => reported.value = true,
              ),
            ],
          ),
          const EditorTextField(text: "Go", semanticLabel: "Title"),
          PortableDiagnosticMessages(
            diagnostics: reported.value ? diagnostics : const [],
          ),
        ],
      ),
    );
  }
}

/// The marker a collapsed header shows for the problems inside it: its
/// icon takes the worst severity and its tooltip counts them.
@widgetbook.UseCase(name: "Severities", type: PortableDiagnosticHeaderMarker)
Widget portableDiagnosticHeaderMarkerUseCase(BuildContext context) {
  final severity = context.knobs.severity();
  final many = context.knobs.boolean(label: "Several problems");
  return Story(
    const [],
    at: PanelLocation.component(
      Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          const Text("Objectives"),
          PortableDiagnosticHeaderMarker(
            summary: PortableDiagnosticSummary(
              direct: [storyDiagnostic("Add an objective", severity: severity)],
              descendants: many
                  ? [
                      storyDiagnostic(
                        "Choose an entity",
                        severity: skir.DiagnosticSeverity.information,
                        field: "entity",
                      ),
                      storyDiagnostic(
                        "Set an amount",
                        severity: skir.DiagnosticSeverity.information,
                        field: "amount",
                      ),
                    ]
                  : const [],
            ),
          ),
        ],
      ),
    ),
  );
}

/// The feedback around a whole presentation. An inspector or workspace
/// lists its general problems above the content; a search result card keeps
/// them behind a corner icon that also shows problems no field claimed.
@widgetbook.UseCase(name: "Roles", type: PortablePresentationChrome)
Widget portablePresentationChromeUseCase(BuildContext context) {
  final role = context.knobs.role();
  final problems = context.knobs.object.segmented(
    label: "Problems",
    options: const ["None", "General", "Unplaced"],
    initialOption: "General",
  );
  final severity = context.knobs.severity();
  final diagnostic = storyDiagnostic(
    "The quest has no reward",
    severity: severity,
    field: problems == "Unplaced" ? "reward" : null,
  );
  return Story(
    const [],
    at: PanelLocation.component(
      StoryDiagnosticScope(
        child: PortableDiagnosticSource(
          diagnostics: problems == "None" ? const [] : [diagnostic],
          diagnosticFallback: problems == "Unplaced"
              ? PortableDiagnosticFallback.resource
              : PortableDiagnosticFallback.presentation,
          observations: const [],
          child: SizedBox(
            width: role == skir.PresentationRole.resourceSearchResult
                ? 280
                : 420,
            child: PortablePresentationChrome(
              role: role,
              child: Builder(
                builder: (context) {
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: context.colors.borderSubtle),
                      borderRadius: context.shapes.mediumBorderRadius,
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(context.spacing.space3),
                      child: const Text("Find the lantern"),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
