import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

const _key = EditorResourceKey(
  scope: "original organization",
  identity: "resource",
);
final _title = editorRootPath.field("title");

void main() {
  test("validation diagnostics survive preparation without a commit", () async {
    final workspace = testWorkSession();
    const diagnostic = EditorDiagnostic(
      code: EditorDiagnosticCode.invalidValue,
      message: "The resource is invalid",
    );
    final snapshot = FakeEditorSnapshot(
      savedTitleSnapshot().document,
      validation: acceptTestEditorMutation,
      draftValidation: (_) => const [diagnostic],
    );
    final resource = ScriptedValuePersistence(
      key: _key,
      current: snapshot,
      commit: (_) async => throw StateError("Unexpected send"),
    );
    final source = ValueEditingRegistration(
      targetId: _key.identity,
      label: "Resource",
      persistence: resource,
      snapshot: snapshot,
      commitPolicy: EditorCommitPolicy.applyResource,
    ).acquire(workspace);
    holdValueLease(workspace, _key);
    source.update(_title, skir.DataValue.wrapStringValue("Draft"));

    final result = await source.flush();

    expect(result, isA<MutationInvalid>());
    expect(source.saveState(editorRootPath).diagnostics, [diagnostic]);
  });

  test(
    "unexpected preparation failure reports cause and sanitizes result",
    () async {
      final workspace = testWorkSession();
      final cause = StateError("private preparation detail");
      final reports = <FlutterErrorDetails>[];
      final previousErrorHandler = FlutterError.onError;
      FlutterError.onError = reports.add;
      addTearDown(() => FlutterError.onError = previousErrorHandler);
      final resource = ScriptedValuePersistence(
        key: _key,
        current: savedTitleSnapshot(),
        load: () async => throw cause,
        commit: (_) async => throw StateError("Unexpected send"),
      );
      final source = titleDraft(workspace, resource);

      final result = await source.flush();
      final message = source
          .saveState(editorRootPath)
          .diagnostics
          .single
          .message;

      expect(result, isA<MutationUnavailable>());
      expect(message, contains("StateError"));
      expect(message, isNot(contains("private preparation detail")));
      expect(reports, hasLength(1));
      expect(reports.single.exception, same(cause));
      expect(reports.single.stack, isNotNull);
    },
  );
}
