import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

@widgetbook.UseCase(name: "Issue states", type: ResourceIssueBadge)
Widget resourceIssueBadgeStory(BuildContext context) {
  final state = context.knobs.object.dropdown(
    label: "Issues",
    options: const ["One error", "Warnings", "Many", "Checking", "Unavailable"],
  );
  return Story(
    const [],
    at: PanelLocation.component(
      ResourceIssueBadge(
        issues: switch (state) {
          "One error" => [_issue(skir.DiagnosticSeverity.error)],
          "Warnings" => [
            for (var index = 0; index < 2; index++)
              _issue(skir.DiagnosticSeverity.warning),
          ],
          "Many" => [
            for (var index = 0; index < 12; index++)
              _issue(
                index.isEven
                    ? skir.DiagnosticSeverity.error
                    : skir.DiagnosticSeverity.warning,
              ),
          ],
          _ => const [],
        },
        checking: state == "Checking",
        unavailable: state == "Unavailable",
      ),
    ),
  );
}

ResourceIssue _issue(skir.DiagnosticSeverity severity) => ResourceIssue(
  current: true,
  diagnostic: PortablePresentationDiagnostic(
    code: "unfinished_value",
    message: "A required value is unfinished.",
    severity: severity,
    targets: [
      PortableDiagnosticTarget.value(
        skir.ValueLocation(
          resource: skir.ResourceId(value: "page:harbor"),
          path: skir.ValuePath(
            segments: [skir.PathSegment.createField(name: "name")],
          ),
        ),
      ),
    ],
  ),
);
