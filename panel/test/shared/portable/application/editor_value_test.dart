import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  group("EditorValue", () {
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
