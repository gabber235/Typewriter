import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

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
}
