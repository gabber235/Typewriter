import "package:flutter/foundation.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

class _EditorSource extends ChangeNotifier implements EditorSource {
  _EditorSource({
    this.current = const EditorValue.ready(UnitValue()),
    this.rootType = const StringType(),
    this.registry,
    this.mutationResult = const EditorMutationResult.applied(
      StringValue("updated"),
    ),
  });

  EditorValue current;

  @override
  final TypeExpression? rootType;

  @override
  final TypeRegistry? registry;

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
  void dispose() {
    disposed = true;
    super.dispose();
  }
}

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
      final registry = TypeRegistry(TypeCatalog([]));
      const mutationResult = EditorMutationResult.applied(StringValue("after"));
      final source = _EditorSource(
        current: const EditorValue.ready(StringValue("before")),
        rootType: const StringType(minimumLength: 1),
        registry: registry,
        mutationResult: mutationResult,
      );
      final controller = EditorController(source: source);
      var notifications = 0;
      controller.addListener(() => notifications++);
      final path = DataPath.root.field("name");

      expect((controller.rootType! as StringType).minimumLength, 1);
      expect(controller.registry, same(registry));
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
