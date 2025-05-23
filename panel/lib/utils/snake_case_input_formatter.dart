import "package:flutter/services.dart";

class SnakeCaseInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final processed = newValue.text
        .replaceAllMapped(
          RegExp("[A-Z]"),
          (match) => match.group(0)!.toLowerCase(),
        )
        .replaceAll(RegExp(r"[\s\-]"), "_")
        .replaceAll(RegExp("[^a-z0-9_]+"), "");
    return TextEditingValue(
      text: processed,
      selection: TextSelection.collapsed(offset: processed.length),
    );
  }
}
