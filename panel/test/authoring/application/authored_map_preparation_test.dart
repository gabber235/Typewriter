import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  test(
    "map record branches are prepared and findings keep their branch",
    () async {
      final fixture = await MapEntriesFixture().open();
      var evaluations = 0;
      final host = fixture.host((request) async {
        evaluations++;
        return fixture.prepared(request, "$evaluations", finding: true);
      });
      final result = await host.addMapRow(
        fixture.reference,
        context: fixture.context,
      );
      expect(result, isA<PortablePresentationWriteApplied>());
      expect(evaluations, 2);
      final rows = fixture.rows;
      expect(rows, hasLength(1));
      expect(
        rows.single.key.authoredField("name"),
        skir.DataValue.wrapStringValue("1"),
      );
      expect(
        rows.single.value.authoredField("name"),
        skir.DataValue.wrapStringValue("2"),
      );
      final findings = fixture.workspace.document.initializationFindings;
      expect(findings, hasLength(2));
      expect(
        findings.map((finding) => finding.location.path.segments.toList()[2]),
        [skir.PathSegment.mapKey, skir.PathSegment.mapValue],
      );
      expect(
        findings.every(
          (finding) =>
              finding.location.resource == fixture.resource &&
              finding.evidence.appliesTo(fixture.workspace.document),
        ),
        isTrue,
      );
      fixture.workspace
          .edit(
            label: "Edit map value",
            policy: EditorCommitPolicy.applyResource,
            apply: (operation) => operation.set(
              skir.ValueLocation(
                resource: fixture.resource,
                path: skir.ValuePath(
                  segments: [
                    skir.PathSegment.createField(name: "entries"),
                    skir.PathSegment.createItem(id: rows.single.id),
                    skir.PathSegment.mapValue,
                    skir.PathSegment.createField(name: "name"),
                  ],
                ),
              ),
              skir.DataValue.wrapStringValue("changed"),
            ),
          )
          .requireAccepted();
      expect(
        findings.first.evidence.appliesTo(fixture.workspace.document),
        isTrue,
      );
      expect(
        findings.last.evidence.appliesTo(fixture.workspace.document),
        isFalse,
      );
    },
  );

  test("second map preparation failure leaves no row or findings", () async {
    final fixture = await MapEntriesFixture().open();
    var evaluations = 0;
    final host = fixture.host((request) async {
      if (++evaluations == 2) throw StateError("value preparation unavailable");
      return fixture.prepared(request, "key", finding: true);
    });
    final result = await host.addMapRow(
      fixture.reference,
      context: fixture.context,
    );
    expect(result, isA<PortablePresentationWriteRejected>());
    expect(evaluations, 2);
    expect(fixture.rows, isEmpty);
    expect(fixture.workspace.document.initializationFindings, isEmpty);
    expect(fixture.workspace.hasPendingWork, isFalse);
  });

  test(
    "closing the map presentation during preparation discards the row",
    () async {
      final fixture = await MapEntriesFixture().open();
      final pending = Completer<skir.PreparedValue>();
      skir.ValuePreparationRequest? observed;
      final host = fixture.host((request) {
        observed = request;
        return pending.future;
      });
      final result = host.addMapRow(
        fixture.reference,
        context: fixture.context,
      );
      expect(observed, isNotNull);
      host.dispose();
      pending.complete(fixture.prepared(observed!, "key"));
      expect(await result, isA<PortablePresentationWriteRejected>());
      expect(fixture.rows, isEmpty);
      expect(fixture.workspace.hasPendingWork, isFalse);
    },
  );
}
