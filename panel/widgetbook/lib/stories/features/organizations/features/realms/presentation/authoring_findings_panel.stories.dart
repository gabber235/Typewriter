import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "Current and outdated", type: AuthoringFindingsPanel)
Widget authoringFindingsPanelUseCase(BuildContext context) => FakeApp(
  child: Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: AuthoringFindingsPanel(
        findings: [
          _finding(
            id: "missing title",
            message: "The page title is required before publishing",
            severity: skir.DiagnosticSeverity.error,
            status: skir.FindingStatus.current,
          ),
          _finding(
            id: "previous target",
            message: "The previous target did not accept this element type",
            severity: skir.DiagnosticSeverity.warning,
            status: skir.FindingStatus.outdated,
          ),
          _finding(
            id: "available hint",
            message: "Choose a page from the current book",
            severity: skir.DiagnosticSeverity.information,
            status: skir.FindingStatus.current,
          ),
        ],
      ),
    ),
  ),
);

AuthoredFindingView _finding({
  required String id,
  required String message,
  required skir.DiagnosticSeverity severity,
  required skir.FindingStatus status,
}) {
  final location = skir.ValueLocation(
    resource: skir.ResourceId(value: "page:welcome"),
    path: skir.ValuePath(
      segments: [skir.PathSegment.createField(name: "title")],
    ),
  );
  final value = skir.Diagnostic(
    id: skir.DiagnosticId(value: id),
    origin: skir.RuleOrigin.defaultInstance,
    code: "story.$id",
    message: message,
    severity: severity,
    primary: location,
    related: const [],
  );
  return AuthoredFindingView(
    source: skir.FindingSet(
      ticket: skir.CheckTicket(
        instance: skir.CheckInstanceId(
          rule: skir.RuleId(
            origin: skir.RuleOrigin.defaultInstance,
            localIndex: 0,
          ),
          location: location,
        ),
        incarnation: "widgetbook",
        execution: skir.CheckExecutionId(value: "check:story"),
        catalog: skir.CatalogGeneration(value: "catalog:7"),
      ),
      expectations: const [],
      outcome: skir.CheckOutcome.finished,
      findings: [value],
      status: status,
    ),
    diagnostic: value,
  );
}
