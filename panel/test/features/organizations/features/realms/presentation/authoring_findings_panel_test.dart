import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../../../support/test_utils.dart";

void main() {
  testWidgets("renders current and outdated findings without hiding either", (
    tester,
  ) async {
    final current = _view("Current error", skir.FindingStatus.current);
    final outdated = _view(
      "Previous warning",
      skir.FindingStatus.outdated,
      severity: skir.DiagnosticSeverity.warning,
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
  skir.FindingStatus status, {
  skir.DiagnosticSeverity severity = skir.DiagnosticSeverity.error,
}) {
  final resource = skir.ResourceId(value: "resource:page");
  final location = skir.ValueLocation(
    resource: resource,
    path: skir.ValuePath(segments: const []),
  );
  final finding = skir.Diagnostic(
    id: skir.DiagnosticId(value: message),
    origin: skir.RuleOrigin.defaultInstance,
    code: "test",
    message: message,
    severity: severity,
    primary: location,
    related: const [],
  );
  final source = skir.FindingSet(
    ticket: skir.CheckTicket(
      instance: skir.CheckInstanceId(
        rule: skir.RuleId(
          origin: skir.RuleOrigin.defaultInstance,
          localIndex: 0,
        ),
        location: location,
      ),
      incarnation: "test",
      execution: skir.CheckExecutionId(value: "check:1"),
      catalog: skir.CatalogGeneration(value: "catalog:1"),
    ),
    expectations: const [],
    outcome: skir.CheckOutcome.finished,
    findings: [finding],
    status: status,
  );
  return AuthoredFindingView(source: source, diagnostic: finding);
}
