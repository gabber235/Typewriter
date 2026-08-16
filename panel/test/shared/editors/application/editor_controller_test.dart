import "package:flutter/foundation.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

class _EditorSource extends ChangeNotifier implements EditorSource {
  _EditorSource({
    this.current = const EditorValue.ready(UnitValue()),
    TypeExpression rootType = const StringType(),
    TypeCatalog typeCatalog = const TypeCatalog([]),
    this.mutationResult = const EditorMutationResult.applied(
      StringValue("updated"),
    ),
  }) : document = EditorDocument(
         rootType: rootType,
         typeCatalog: typeCatalog,
         confirmedValue: current.valueOrNull ?? const UnitValue(),
         revision: 1,
       );

  EditorValue current;

  @override
  EditorDocument document;

  EditorMutationResult mutationResult;
  DataPath? updatedPath;
  DataValue? updatedValue;
  bool disposed = false;

  @override
  EditorValue value(DataPath path) => current;

  @override
  EditorMutationResult update(DataPath path, DataValue value) {
    updatedPath = path;
    updatedValue = value;
    return mutationResult;
  }

  void replace(EditorValue value) {
    current = value;
    notifyListeners();
  }

  @override
  void refreshDocument(EditorDocument document) {
    this.document = document;
    notifyListeners();
  }

  @override
  EditorInteractionSession beginInteraction(DataPath path) =>
      _EditorInteraction(this, path);

  @override
  EditorSaveState saveState(DataPath path) => const EditorSaveState.idle();

  @override
  Future<TypedMutationResult> flush({Set<DataPath>? paths}) async =>
      TypedMutationResult.success(
        revision: document.revision,
        value: document.confirmedValue,
      );

  @override
  Future<TypedMutationResult> executeAction(
    EditorAction action,
    ExpressionContext context,
    Map<BindingId, BindingReference> aliases,
  ) async => _unavailable();

  @override
  void acceptRemote({required int revision, required DataValue value}) {
    document = document.copyWith(confirmedValue: value, revision: revision);
  }

  @override
  void acceptRemoteDeletion() {}

  @override
  void useRemote(DataPath path) {}

  @override
  Future<TypedMutationResult> keepLocal(DataPath path) async => _unavailable();

  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }
}

final class _EditorInteraction implements EditorInteractionSession {
  _EditorInteraction(this.source, this.path);

  final _EditorSource source;

  @override
  final DataPath path;

  @override
  bool active = true;

  @override
  void cancel() => active = false;

  @override
  Future<TypedMutationResult> commit() async {
    active = false;
    return source.flush(paths: {path});
  }
}

TypedMutationResult _unavailable() => TypedMutationResult.unavailable([
  const TypeDiagnostic(
    code: TypeDiagnosticCode.invalidValue,
    message: "The test source does not persist changes",
  ),
]);

void main() {
  group("EditorValue", () {
    test("ready exposes its typed value", () {
      const state = EditorValue.ready(StringValue("ready"));

      expect(state.valueOrNull, const StringValue("ready"));
    });

    test("nonready states do not manufacture fallback values", () {
      final invalid = EditorValue.invalid([
        const TypeDiagnostic(
          code: TypeDiagnosticCode.invalidValue,
          message: "Invalid value",
        ),
      ]);

      expect(const EditorValue.loading().valueOrNull, isNull);
      expect(const EditorValue.conflict().valueOrNull, isNull);
      expect(invalid.valueOrNull, isNull);
    });
  });

  group("EditorController", () {
    test("forwards behavior and owns the source lifecycle", () {
      const mutationResult = EditorMutationResult.applied(StringValue("after"));
      final source = _EditorSource(
        current: const EditorValue.ready(StringValue("before")),
        rootType: const StringType(minimumLength: 1),
        mutationResult: mutationResult,
      );
      final controller = EditorController(source: source);
      var notifications = 0;
      controller.addListener(() => notifications++);
      final path = DataPath.root.field("name");

      expect((controller.rootType! as StringType).minimumLength, 1);
      expect(controller.registry, isNotNull);
      expect(controller.document, same(source.document));
      expect(controller.value(path).valueOrNull, const StringValue("before"));

      final actual = controller.update(path, const StringValue("after"));
      source.replace(const EditorValue.ready(StringValue("updated")));
      controller.dispose();

      expect(actual, same(mutationResult));
      expect(source.updatedPath, path);
      expect(source.updatedValue, const StringValue("after"));
      expect(notifications, 1);
      expect(source.disposed, isTrue);
    });
  });
}
