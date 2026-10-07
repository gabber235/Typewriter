import "package:flutter/material.dart";
import "package:typewriter_panel/features/organizations/features/realms/application/authored_findings.dart";
import "package:typewriter_panel/features/organizations/features/realms/presentation/authoring_findings_panel.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/checking.dart"
    as checking;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/diagnostic.dart"
    as diagnostic;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/type_catalog.dart"
    as types;
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
            severity: diagnostic.DiagnosticSeverity.error,
            status: checking.FindingStatus.current,
          ),
          _finding(
            id: "previous target",
            message: "The previous target did not accept this element type",
            severity: diagnostic.DiagnosticSeverity.warning,
            status: checking.FindingStatus.outdated,
          ),
          _finding(
            id: "available hint",
            message: "Choose a page from the current book",
            severity: diagnostic.DiagnosticSeverity.information,
            status: checking.FindingStatus.current,
          ),
        ],
      ),
    ),
  ),
);

AuthoredFindingView _finding({
  required String id,
  required String message,
  required diagnostic.DiagnosticSeverity severity,
  required checking.FindingStatus status,
}) {
  final location = types.ValueLocation(
    resource: types.ResourceId(value: "page:welcome"),
    path: types.ValuePath(
      segments: [types.PathSegment.createField(name: "title")],
    ),
  );
  final value = diagnostic.Diagnostic(
    id: types.DiagnosticId(value: id),
    origin: types.RuleOrigin.defaultInstance,
    code: "story.$id",
    message: message,
    severity: severity,
    primary: location,
    related: const [],
  );
  return AuthoredFindingView(
    source: checking.FindingSet(
      ticket: checking.CheckTicket(
        instance: checking.CheckInstanceId(
          rule: types.RuleId(
            origin: types.RuleOrigin.defaultInstance,
            localIndex: 0,
          ),
          location: location,
        ),
        incarnation: "widgetbook",
        execution: types.CheckExecutionId(value: "check:story"),
        catalog: types.CatalogGeneration(value: "catalog:7"),
      ),
      expectations: const [],
      outcome: checking.CheckOutcome.finished,
      findings: [value],
      status: status,
    ),
    diagnostic: value,
  );
}
