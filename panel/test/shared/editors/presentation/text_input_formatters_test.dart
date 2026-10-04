import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("normalizes identifiers before filtering characters", () {
    final result = identifierInputFormatters.applyTo(
      const TextEditingValue(
        text: "My Book!",
        selection: TextSelection.collapsed(offset: 8),
      ),
    );

    expect(result.text, "my_book");
    expect(result.selection, const TextSelection.collapsed(offset: 7));
  });

  test("keeps incomplete identifiers editable", () {
    final result = identifierInputFormatters.applyTo(
      const TextEditingValue(text: "a_"),
    );

    expect(result.text, "a_");
    expect(result.text.isValidIdentifier, isFalse);
  });
}

extension on Iterable<TextInputFormatter> {
  TextEditingValue applyTo(TextEditingValue value) {
    var current = value;
    for (final formatter in this) {
      current = formatter.formatEditUpdate(current, current);
    }
    return current;
  }
}
