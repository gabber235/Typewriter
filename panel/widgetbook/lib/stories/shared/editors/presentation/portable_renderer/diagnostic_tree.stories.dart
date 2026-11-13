import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/shared/editors/diagnostics.dart";
import "package:widgetbook_workspace/support/story.dart";

/// Where a source's problems land: on the field they name, or, when no
/// field claims them, above the form as general feedback. A problem on a
/// field the form does not show stays with the resource unless it falls
/// back to the presentation.
@widgetbook.UseCase(name: "Routing", type: PortableDiagnosticSource)
Widget portableDiagnosticSourceUseCase(BuildContext context) {
  final target = context.knobs.object.dropdown(
    label: "Problem on",
    options: const [
      "Nothing",
      "Title",
      "Reward",
      "Both fields",
      "General",
      "Hidden field, resource",
      "Hidden field, presentation",
    ],
    initialOption: "Title",
  );
  final severity = skir.DiagnosticSeverity.error;
  final readOnly = context.knobs.boolean(label: "Read only");
  final width = context.knobs.width(const {"Inspector": 420, "Narrow": 240});
  final diagnostics = switch (target) {
    "Nothing" => const <PortablePresentationDiagnostic>[],
    "Title" => [
      storyDiagnostic(
        "Use at least three characters",
        severity: severity,
        field: "title",
      ),
    ],
    "Reward" => [
      storyDiagnostic("Pick a reward", severity: severity, field: "reward"),
    ],
    "Both fields" => [
      storyDiagnostic(
        "Use at least three characters",
        severity: severity,
        field: "title",
      ),
      storyDiagnostic("Pick a reward", severity: severity, field: "reward"),
    ],
    "General" => [
      storyDiagnostic("The quest is never started", severity: severity),
    ],
    _ => [
      storyDiagnostic(
        "The quest giver was removed",
        severity: severity,
        field: "giver",
      ),
    ],
  };
  return Story(
    const [],
    at: PanelLocation.component(
      StoryDiagnosticScope(
        child: PortableDiagnosticSource(
          diagnostics: diagnostics,
          diagnosticFallback: target == "Hidden field, resource"
              ? PortableDiagnosticFallback.resource
              : PortableDiagnosticFallback.presentation,
          observations: const [],
          child: SizedBox(
            width: width,
            child: PortablePresentationChrome(
              role: skir.PresentationRole.inspector,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 16,
                children: [
                  StoryDiagnosedField(
                    field: "title",
                    label: "Title",
                    text: "Go",
                    readOnly: readOnly,
                  ),
                  StoryDiagnosedField(
                    field: "reward",
                    label: "Reward",
                    text: "",
                    readOnly: readOnly,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
