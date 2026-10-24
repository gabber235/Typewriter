import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "Current issue count", type: ResourceIssueBadge)
Widget resourceIssueBadgeStory(BuildContext context) => FakeApp(
  child: Center(
    child: ResourceIssueBadge(
      issues: context.knobs.boolean(label: "Has issue", initialValue: true)
          ? [_issue]
          : [],
    ),
  ),
);

final _issue = ResourceIssue(
  current: true,
  diagnostic: PortablePresentationDiagnostic(
    code: "unfinished_value",
    message: "A required value is unfinished.",
    severity: skir.DiagnosticSeverity.error,
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
