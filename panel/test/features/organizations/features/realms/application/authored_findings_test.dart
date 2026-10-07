import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/features/organizations/features/realms/application/authored_findings.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/checking.dart"
    as checking;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/diagnostic.dart"
    as diagnostic;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/type_catalog.dart"
    as types;

void main() {
  test("findings retain current and outdated status at exact resources", () {
    final first = types.ResourceId(value: "resource:first");
    final second = types.ResourceId(value: "resource:second");
    final primary = _location(first, "title");
    final related = _location(second, "name");
    final current = _set(
      location: primary,
      status: checking.FindingStatus.current,
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
      status: checking.FindingStatus.outdated,
      outcome: checking.CheckOutcome.wrapFailed([
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

checking.FindingSet _set({
  required types.ValueLocation location,
  required checking.FindingStatus status,
  Iterable<diagnostic.Diagnostic> findings = const [],
  checking.CheckOutcome outcome = checking.CheckOutcome.finished,
}) => checking.FindingSet(
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
    catalog: types.CatalogGeneration(value: "catalog:1"),
  ),
  expectations: const [],
  outcome: outcome,
  findings: findings,
  status: status,
);

diagnostic.Diagnostic _diagnostic({
  required String id,
  required String message,
  required types.ValueLocation? primary,
  Iterable<types.ValueLocation> related = const [],
}) => diagnostic.Diagnostic(
  id: types.DiagnosticId(value: id),
  origin: types.RuleOrigin.defaultInstance,
  code: id,
  message: message,
  severity: diagnostic.DiagnosticSeverity.error,
  primary: primary,
  related: related,
);

types.ValueLocation _location(types.ResourceId resource, String field) =>
    types.ValueLocation(
      resource: resource,
      path: types.ValuePath(
        segments: [types.PathSegment.createField(name: field)],
      ),
    );
