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
    test("cases use value equality", () {
      const diagnostic = TypeDiagnostic(
        code: TypeDiagnosticCode.invalidValue,
        message: "Invalid value",
      );

      expect(const EditorValue.loading(), const EditorValue.loading());
      expect(const EditorValue.conflict(), const EditorValue.conflict());
      expect(
        EditorValue.invalid([diagnostic]),
        EditorValue.invalid([diagnostic]),
      );
      expect(
        const EditorValue.ready(StringValue("ready")),
        const EditorValue.ready(StringValue("ready")),
      );
    });

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

    test("invalid state owns an immutable diagnostic list", () {
      final state =
          EditorValue.invalid([
                const TypeDiagnostic(
                  code: TypeDiagnosticCode.invalidValue,
                  message: "Invalid value",
                ),
              ])
              as InvalidEditorValue;

      expect(state.diagnostics, hasLength(1));
      expect(state.diagnostics.clear, throwsUnsupportedError);

      final copied = state.copyWith(
        diagnostics: const [
          TypeDiagnostic(
            code: TypeDiagnosticCode.invalidValue,
            message: "Replacement diagnostic",
          ),
        ],
      );

      expect(copied.diagnostics.single.message, "Replacement diagnostic");
    });
  });

  group("EditorMutationResult", () {
    test("cases use value equality and support copyWith", () {
      const first = TypeDiagnostic(
        code: TypeDiagnosticCode.invalidValue,
        message: "First diagnostic",
      );
      const second = TypeDiagnostic(
        code: TypeDiagnosticCode.invalidValue,
        message: "Second diagnostic",
      );
      final invalid = EditorMutationResult.invalid([first]);

      expect(
        const EditorMutationResult.applied(StringValue("value")),
        const EditorMutationResult.applied(StringValue("value")),
      );
      expect(
        const EditorMutationResult.conflict(),
        const EditorMutationResult.conflict(),
      );
      expect(invalid, EditorMutationResult.invalid([first]));
      expect(
        (invalid as InvalidEditorMutation)
            .copyWith(diagnostics: const [second])
            .diagnostics,
        const [second],
      );
    });
  });

  group("EditorController", () {
    test("forwards root type and typed values", () {
      final registry = TypeRegistry(TypeCatalog([]));
      final source = _EditorSource(
        current: const EditorValue.ready(StringValue("before")),
        rootType: const StringType(minimumLength: 1),
        registry: registry,
      );
      final controller = EditorController(source: source);

      expect((controller.rootType! as StringType).minimumLength, 1);
      expect(controller.registry, same(registry));
      expect(
        controller.value(DataPath.root.field("name")).valueOrNull,
        const StringValue("before"),
      );
    });

    test("forwards structured paths, typed values, and mutation results", () {
      const result = EditorMutationResult.applied(StringValue("after"));
      final source = _EditorSource(mutationResult: result);
      final controller = EditorController(source: source);
      final path = DataPath.root.field("name");

      final actual = controller.update(path, const StringValue("after"));

      expect(actual, same(result));
      expect(source.updatedPath, path);
      expect(source.updatedValue, const StringValue("after"));
    });

    test("preserves invalid mutation diagnostics", () {
      final result = EditorMutationResult.invalid([
        const TypeDiagnostic(
          code: TypeDiagnosticCode.invalidValue,
          message: "Expected a string",
          path: DataPath.root,
        ),
      ]);
      final controller = EditorController(
        source: _EditorSource(mutationResult: result),
      );

      final actual = controller.update(DataPath.root, const BooleanValue(true));

      expect(actual, same(result));
      expect(
        (actual as InvalidEditorMutation).diagnostics.single.code,
        TypeDiagnosticCode.invalidValue,
      );
    });

    test("forwards source notifications", () {
      final source = _EditorSource();
      final controller = EditorController(source: source);
      var notifications = 0;
      controller.addListener(() => notifications++);

      source.replace(const EditorValue.ready(StringValue("updated")));

      expect(notifications, 1);
      expect(
        controller.value(DataPath.root).valueOrNull,
        const StringValue("updated"),
      );
    });

    test("disposes its source", () {
      final source = _EditorSource();

      EditorController(source: source).dispose();

      expect(source.disposed, isTrue);
    });
  });
}
