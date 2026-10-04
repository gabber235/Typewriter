import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/features/organizations/features/realms/application/authored_findings.dart";
import "package:typewriter_panel/features/organizations/features/realms/presentation/authoring_findings_panel.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/checking.dart"
    as checking;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/diagnostic.dart"
    as diagnostic;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/type_catalog.dart"
    as types;

import "../../../../../support/test_utils.dart";

void main() {
  testWidgets("renders current and outdated findings without hiding either", (
    tester,
  ) async {
    final current = _view("Current error", checking.FindingStatus.current);
    final outdated = _view(
      "Previous warning",
      checking.FindingStatus.outdated,
      severity: diagnostic.DiagnosticSeverity.warning,
    );

    await tester.pumpTestApp(
      child: Scaffold(
        body: AuthoringFindingsPanel(findings: [current, outdated]),
      ),
    );

    expect(find.text("Current error"), findsOneWidget);
    expect(find.text("Previous warning"), findsOneWidget);
    expect(find.text("From a previous authored state"), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_outlined), findsOneWidget);
  });
}

AuthoredFindingView _view(
  String message,
  checking.FindingStatus status, {
  diagnostic.DiagnosticSeverity severity = diagnostic.DiagnosticSeverity.error,
}) {
  final resource = types.ResourceId(value: "resource:page");
  final location = types.ValueLocation(
    resource: resource,
    path: types.ValuePath(segments: const []),
  );
  final finding = diagnostic.Diagnostic(
    id: types.DiagnosticId(value: message),
    origin: types.RuleOrigin.defaultInstance,
    code: "test",
    message: message,
    severity: severity,
    primary: location,
    related: const [],
  );
  final source = checking.FindingSet(
    ticket: checking.CheckTicket(
      instance: checking.CheckInstanceId(
        rule: types.RuleId(
          origin: types.RuleOrigin.defaultInstance,
          localIndex: 0,
        ),
        location: location,
      ),
      incarnation: "test",
      execution: types.CheckExecutionId(value: "check:1"),
      snapshot: types.SnapshotId(value: "realm:1"),
      catalog: types.CatalogGeneration(value: "catalog:1"),
    ),
    observations: const [],
    outcome: checking.CheckOutcome.finished,
    findings: [finding],
    status: status,
  );
  return AuthoredFindingView(source: source, diagnostic: finding);
}
