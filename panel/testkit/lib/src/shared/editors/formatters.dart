import "package:typewriter_panel/typewriter_panel.dart";

/// Running an edit through a chain of input formatters.
extension FormatterChain on Iterable<TextInputFormatter> {
  /// The value each formatter in order leaves of [value], as a field applies
  /// them to one edit that replaces its whole text.
  TextEditingValue applyTo(TextEditingValue value) {
    var current = value;
    for (final formatter in this) {
      current = formatter.formatEditUpdate(current, current);
    }
    return current;
  }
}
