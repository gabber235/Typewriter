import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../../support/test_utils.dart";

final class TestEditorSource extends ChangeNotifier implements EditorSource {
  TestEditorSource({
    required this.rootType,
    required DataValue value,
    this.registry,
    this.rootPresentation,
  }) : _value = value;

  final TypeExpression rootType;

  final TypeRegistry? registry;
  final PresentationNode? rootPresentation;

  DataValue _value;
  late EditorDocument _document = EditorDocument(
    rootType: rootType,
    typeCatalog: const TypeCatalog([]),
    confirmedValue: _value,
    revision: 0,
    rootPresentation: rootPresentation,
  );

  DataValue get rootValue => _value;

  int beginCount = 0;
  int commitCount = 0;
  int cancelCount = 0;
  DataPath? lastUpdatedPath;

  @override
  EditorDocument get document => _document;

  @override
  EditorValue value(DataPath path) => _value.readEditorValue(path);

  @override
  EditorMutationResult update(DataPath path, DataValue value) {
    lastUpdatedPath = path;
    final validation = rootType.validateEditorMutation(
      path,
      value,
      registry: registry,
    );
    if (validation is! AppliedEditorMutation) return validation;
    final replaced = path.replace(_value, value);
    if (replaced case TypeFailure(:final diagnostics)) {
      return EditorMutationResult.invalid(diagnostics);
    }
    _value = replaced.valueOrNull!;
    notifyListeners();
    return validation;
  }

  @override
  void refreshDocument(EditorDocument document) {
    _document = document;
    _value = document.confirmedValue;
    notifyListeners();
  }

  @override
  EditorInteractionSession beginInteraction(DataPath path) {
    beginCount++;
    return _TestInteraction(this, path, path.read(_value).valueOrNull);
  }

  @override
  EditorSaveState saveState(DataPath path) => const EditorSaveState.idle();

  @override
  Future<TypedMutationResult> flush({Set<DataPath>? paths}) async =>
      TypedMutationResult.success(revision: 0, value: _value);

  @override
  Future<EditorActionResult> executeAction(
    EditorAction action,
    ExpressionContext context,
    Map<BindingId, BindingReference> aliases,
  ) async => switch (action) {
    LocalEditorAction() => LocalEditorActionResult(
      action.canonicalizedWith(aliases).execute(context, registry: registry),
    ),
    RealmEditorAction() => RealmEditorActionResult(
      RealmCommandResult.unavailable([
        const TypeDiagnostic(
          code: TypeDiagnosticCode.invalidValue,
          message: "Realm actions are unavailable in tests",
        ),
      ]),
    ),
  };

  @override
  void acceptRemote({required int revision, required DataValue value}) {}

  @override
  void acceptRemoteDeletion() {}

  @override
  void useRemote(DataPath path) {}

  @override
  Future<TypedMutationResult> keepLocal(DataPath path) => flush(paths: {path});
}

final class _TestInteraction implements EditorInteractionSession {
  _TestInteraction(this.source, this.path, this.origin);

  final TestEditorSource source;
  @override
  final DataPath path;
  final DataValue? origin;
  @override
  bool active = true;

  @override
  Future<TypedMutationResult> commit() async {
    if (active) source.commitCount++;
    active = false;
    return source.flush(paths: {path});
  }

  @override
  void cancel() {
    if (!active) return;
    source.cancelCount++;
    active = false;
    if (origin != null) source.update(path, origin!);
  }
}

extension TypedEditorTesterExtension on WidgetTester {
  Future<TestEditorSource> pumpTypedEditor({
    required TypeExpression type,
    required DataValue value,
    DataPath path = DataPath.root,
    bool readOnly = false,
    TypeRegistry? registry,
    PresentationNode? presentation,
  }) async {
    final source = TestEditorSource(
      rootType: type,
      value: value,
      registry: registry,
      rootPresentation: presentation,
    );
    await pumpTestApp(
      child: EditorRoot(
        create: (_) => source,
        child: Material(
          child: SizedBox(
            width: 500,
            child: TypedEditor(
              path: path,
              registry: registry,
              readOnly: readOnly,
            ),
          ),
        ),
      ),
    );
    return source;
  }
}
