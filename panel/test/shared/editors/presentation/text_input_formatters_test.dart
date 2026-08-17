import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("applies formatter operations in declaration order", () {
    final result = identifierInputFormats.toTextInputFormatters().applyTo(
      const TextEditingValue(
        text: "My Book!",
        selection: TextSelection.collapsed(offset: 8),
      ),
    );

    expect(result.text, "my_book");
    expect(result.selection, const TextSelection.collapsed(offset: 7));
  });

  test("supports uppercase, allow, and deny operations", () {
    const formats = [
      TextInputFormat.uppercase(),
      TextInputFormat.allow("[A-Z0-9]"),
      TextInputFormat.deny("[X]"),
    ];

    final result = formats.toTextInputFormatters().applyTo(
      const TextEditingValue(text: "a-x 1"),
    );

    expect(result.text, "A1");
  });

  test("uses literal replacement strings", () {
    const formats = [
      TextInputFormat.replace(pattern: "[a-z]+", replacement: r"$1"),
    ];

    final result = formats.toTextInputFormatters().applyTo(
      const TextEditingValue(text: "value"),
    );

    expect(result.text, r"$1");
  });

  test("leaves active composing text unchanged", () {
    const formats = [TextInputFormat.lowercase()];
    const value = TextEditingValue(
      text: "ÄBC",
      selection: TextSelection.collapsed(offset: 3),
      composing: TextRange(start: 0, end: 3),
    );

    expect(formats.toTextInputFormatters().applyTo(value), value);
  });

  test("keeps incomplete identifiers editable", () {
    final result = identifierInputFormats.toTextInputFormatters().applyTo(
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
