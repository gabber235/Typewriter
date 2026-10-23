import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  group("EditorValue", () {
    test("diagnostic details use structural equality and hashing", () {
      const first = EditorDiagnostic(
        code: EditorDiagnosticCode.invalidValue,
        message: "Invalid value",
        details: {"field": "name"},
      );
      const second = EditorDiagnostic(
        code: EditorDiagnosticCode.invalidValue,
        message: "Invalid value",
        details: {"field": "name"},
      );

      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });

    test("ready exposes its typed value", () {
      final state = EditorValue.ready(skir.DataValue.wrapStringValue("ready"));

      expect(state.valueOrNull, skir.DataValue.wrapStringValue("ready"));
    });

    test("nonready states do not manufacture fallback values", () {
      final invalid = EditorValue.invalid([
        const EditorDiagnostic(
          code: EditorDiagnosticCode.invalidValue,
          message: "Invalid value",
        ),
      ]);

      expect(const EditorValue.loading().valueOrNull, isNull);
      expect(const EditorValue.mixed().valueOrNull, isNull);
      expect(invalid.valueOrNull, isNull);
    });
  });
}
