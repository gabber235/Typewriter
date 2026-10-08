import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("findings retain current and outdated status at exact resources", () {
    final first = skir.ResourceId(value: "resource:first");
    final second = skir.ResourceId(value: "resource:second");
    final primary = _location(first, "title");
    final related = _location(second, "name");
    final current = _set(
      location: primary,
      status: skir.FindingStatus.current,
      findings: [
        _diagnostic(
          id: "current",
          message: "Title is required",
          primary: primary,
          related: [related],
        ),
      ],
    );
    final outdated = _set(
      location: primary,
      status: skir.FindingStatus.outdated,
      outcome: skir.CheckOutcome.wrapFailed([
        _diagnostic(
          id: "outdated",
          message: "Previous check failed",
          primary: null,
        ),
      ]),
    );

    final firstFindings = [current, outdated].atResource(first);
    final secondFindings = [current, outdated].atResource(second);

    expect(firstFindings.map((finding) => finding.diagnostic.message), [
      "Title is required",
      "Previous check failed",
    ]);
    expect(firstFindings.last.isOutdated, isTrue);
    expect(secondFindings.map((finding) => finding.diagnostic.message), [
      "Title is required",
    ]);
  });
}

skir.FindingSet _set({
  required skir.ValueLocation location,
  required skir.FindingStatus status,
  Iterable<skir.Diagnostic> findings = const [],
  skir.CheckOutcome outcome = skir.CheckOutcome.finished,
}) => skir.FindingSet(
  ticket: skir.CheckTicket(
    instance: skir.CheckInstanceId(
      rule: skir.RuleId(origin: skir.RuleOrigin.defaultInstance, localIndex: 0),
      location: location,
    ),
    incarnation: "test",
    execution: skir.CheckExecutionId(value: "check:1"),
    catalog: skir.CatalogGeneration(value: "catalog:1"),
  ),
  expectations: const [],
  outcome: outcome,
  findings: findings,
  status: status,
);

skir.Diagnostic _diagnostic({
  required String id,
  required String message,
  required skir.ValueLocation? primary,
  Iterable<skir.ValueLocation> related = const [],
}) => skir.Diagnostic(
  id: skir.DiagnosticId(value: id),
  origin: skir.RuleOrigin.defaultInstance,
  code: id,
  message: message,
  severity: skir.DiagnosticSeverity.error,
  primary: primary,
  related: related,
);

skir.ValueLocation _location(skir.ResourceId resource, String field) =>
    skir.ValueLocation(
      resource: resource,
      path: skir.ValuePath(
        segments: [skir.PathSegment.createField(name: field)],
      ),
    );
