import "package:flutter/services.dart";
import "package:typewriter_panel/typewriter_panel.dart";

extension TextInputFormatCompilation on Iterable<TextInputFormat> {
  List<TextInputFormatter> toTextInputFormatters() => [
    for (final format in this) format.toTextInputFormatter(),
  ];
}

extension TextInputFormatCompilationSingle on TextInputFormat {
  TextInputFormatter toTextInputFormatter() => switch (this) {
    LowercaseTextInputFormat() => _TransformingTextInputFormatter(
      (value) => value.toLowerCase(),
    ),
    UppercaseTextInputFormat() => _TransformingTextInputFormatter(
      (value) => value.toUpperCase(),
    ),
    ReplaceTextInputFormat(:final pattern, :final replacement) =>
      _TransformingTextInputFormatter(
        (value) => value.replaceAll(RegExp(pattern), replacement),
      ),
    AllowTextInputFormat(:final pattern) => FilteringTextInputFormatter.allow(
      RegExp(pattern),
    ),
    DenyTextInputFormat(:final pattern) => FilteringTextInputFormatter.deny(
      RegExp(pattern),
    ),
  };
}

final class _TransformingTextInputFormatter extends TextInputFormatter {
  const _TransformingTextInputFormatter(this.transform);

  final String Function(String value) transform;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (!newValue.composing.isCollapsed) return newValue;
    final transformed = transform(newValue.text);
    if (transformed == newValue.text) return newValue;
    return TextEditingValue(
      text: transformed,
      selection: TextSelection(
        baseOffset: _transformedOffset(newValue, newValue.selection.baseOffset),
        extentOffset: _transformedOffset(
          newValue,
          newValue.selection.extentOffset,
        ),
        affinity: newValue.selection.affinity,
        isDirectional: newValue.selection.isDirectional,
      ),
    );
  }

  int _transformedOffset(TextEditingValue value, int offset) {
    if (offset < 0) return offset;
    return transform(value.text.substring(0, offset)).length;
  }
}
