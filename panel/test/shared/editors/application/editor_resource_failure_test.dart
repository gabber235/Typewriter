import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

const _key = EditorResourceKey(
  scope: "original organization",
  identity: "resource",
);
final _title = DataPath.root.field("title");

RecordValue _value(String title) => RecordValue({"title": StringValue(title)});

EditorSnapshot _snapshot({String title = "Original", int revision = 1}) =>
    FakeEditorSnapshot(
      EditorDocument(
        rootType: RecordType(
          fields: const {"title": TypeField(name: "title", type: StringType())},
        ),
        typeCatalog: const TypeCatalog([]),
        confirmedValue: _value(title),
        revision: revision,
      ),
      validation: acceptTestEditorMutation,
    );

TransactionalEditorSource _draft(
  LocalWorkSession workspace,
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
  source.update(_title, const StringValue("Draft"));
  return source;
}

void main() {
  test("validation diagnostics survive preparation without a commit", () async {
    final workspace = LocalWorkSession();
    addTearDown(workspace.dispose);
    const diagnostic = TypeDiagnostic(
      code: TypeDiagnosticCode.invalidValue,
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
    source.update(_title, const StringValue("Draft"));

    final result = await source.flush();

    expect(result, isA<MutationInvalid>());
    expect(source.saveState(DataPath.root).diagnostics, [diagnostic]);
  });

  test(
    "unexpected preparation failure reports cause and sanitizes result",
    () async {
      final workspace = LocalWorkSession();
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
          .saveState(DataPath.root)
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
    final workspace = LocalWorkSession();
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
    expect(source.value(_title).valueOrNull, const StringValue("Draft"));
    expect(reports, isEmpty);
  });

  test("confirmed deletion returns typed failure without reporting", () async {
    final workspace = LocalWorkSession();
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
      source.saveState(DataPath.root).phase,
      EditorSavePhase.deletedElsewhere,
    );
    expect(reports, isEmpty);
  });

  test("workspace disposal returns typed failure without reporting", () async {
    final workspace = LocalWorkSession();
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
