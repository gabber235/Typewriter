import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../support/editor_fixture.dart";

const _key = EditorResourceKey(
  scope: "original organization",
  identity: "resource",
);
final _title = editorRootPath.field("title");

EditorSnapshot _snapshot({String title = "Original", int revision = 1}) =>
    FakeEditorSnapshot(
      recordEditorDocument(
        {"title": skir.DataValue.wrapStringValue(title)},
        {"title": skir.TypeTemplate.wrapScalar(skir.ScalarKind.text)},
        revision,
      ),
      validation: acceptTestEditorMutation,
    );

TransactionalEditorSource _draft(
  ScopedWorkSession workspace,
  EditableResource resource,
) {
  final source = workspace.editor(
    ResourceEditorTarget(
      targetId: resource.key.identity,
      label: "Resource",
      resource: resource,
      snapshot: _snapshot(),
      commitPolicy: EditorCommitPolicy.applyResource,
    ),
  ) as TransactionalEditorSource;
  workspace.retain(resource.key);
  source.update(_title, skir.DataValue.wrapStringValue("Draft"));
  return source;
}

void main() {
  test("validation diagnostics survive preparation without a commit", () async {
    final workspace = ScopedWorkSession();
    addTearDown(workspace.dispose);
    const diagnostic = EditorDiagnostic(
      code: EditorDiagnosticCode.invalidValue,
      message: "The resource is invalid",
    );
    final snapshot = FakeEditorSnapshot(
      _snapshot().document,
      validation: acceptTestEditorMutation,
      draftValidation: (_) => const [diagnostic],
    );
    final resource = FakeEditableResource(
      key: _key,
      current: snapshot,
      commit: (_) async => throw StateError("Unexpected send"),
    );
    final source = workspace.editor(
      ResourceEditorTarget(
        targetId: _key.identity,
        label: "Resource",
        resource: resource,
        snapshot: snapshot,
        commitPolicy: EditorCommitPolicy.applyResource,
      ),
    ) as TransactionalEditorSource;
    workspace.retain(_key);
    source.update(_title, skir.DataValue.wrapStringValue("Draft"));

    final result = await source.flush();

    expect(result, isA<MutationInvalid>());
    expect(source.saveState(editorRootPath).diagnostics, [diagnostic]);
  });

  test(
    "unexpected preparation failure reports cause and sanitizes result",
    () async {
      final workspace = ScopedWorkSession();
      addTearDown(workspace.dispose);
      final cause = StateError("private preparation detail");
      final reports = <FlutterErrorDetails>[];
      final previousErrorHandler = FlutterError.onError;
      FlutterError.onError = reports.add;
      addTearDown(() => FlutterError.onError = previousErrorHandler);
      final resource = FakeEditableResource(
        key: _key,
        current: _snapshot(),
        load: () async => throw cause,
        commit: (_) async => throw StateError("Unexpected send"),
      );
      final source = _draft(workspace, resource);

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

  test("refresh conflict returns typed failure without reporting", () async {
    final workspace = ScopedWorkSession();
    addTearDown(workspace.dispose);
    final reports = <FlutterErrorDetails>[];
    final previousErrorHandler = FlutterError.onError;
    FlutterError.onError = reports.add;
    addTearDown(() => FlutterError.onError = previousErrorHandler);
    final resource = FakeEditableResource(
      key: _key,
      current: _snapshot(title: "Remote", revision: 2),
      commit: (_) async => throw StateError("Unexpected send"),
    );
    final source = _draft(workspace, resource);

    expect(await source.flush(), isA<MutationUnavailable>());
    expect(
      source.value(_title).valueOrNull,
      skir.DataValue.wrapStringValue("Draft"),
    );
    expect(reports, isEmpty);
  });

  test("confirmed deletion returns typed failure without reporting", () async {
    final workspace = ScopedWorkSession();
    addTearDown(workspace.dispose);
    final reports = <FlutterErrorDetails>[];
    final previousErrorHandler = FlutterError.onError;
    FlutterError.onError = reports.add;
    addTearDown(() => FlutterError.onError = previousErrorHandler);
    final resource = FakeEditableResource(
      key: _key,
      current: null,
      commit: (_) async => throw StateError("Unexpected send"),
    );
    final source = _draft(workspace, resource);

    expect(await source.flush(), isA<MutationUnavailable>());
    expect(
      source.saveState(editorRootPath).phase,
      EditorSavePhase.deletedElsewhere,
    );
    expect(reports, isEmpty);
  });

  test("workspace disposal returns typed failure without reporting", () async {
    final workspace = ScopedWorkSession();
    final reports = <FlutterErrorDetails>[];
    final previousErrorHandler = FlutterError.onError;
    FlutterError.onError = reports.add;
    addTearDown(() => FlutterError.onError = previousErrorHandler);
    final ready = Completer<EditorSnapshot?>();
    final started = Completer<void>();
    final resource = FakeEditableResource(
      key: _key,
      current: _snapshot(),
      load: () {
        started.complete();
        return ready.future;
      },
      commit: (_) async => throw StateError("Unexpected send"),
    );
    final source = _draft(workspace, resource);
    final saving = source.flush();

    await started.future;
    workspace.dispose();
    ready.complete(_snapshot());

    expect(await saving, isA<MutationUnavailable>());
    expect(reports, isEmpty);
  });
}
