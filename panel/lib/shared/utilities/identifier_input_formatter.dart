import "package:typewriter_panel/typewriter_panel.dart";

const identifierMinimumLength = 3;
const identifierPattern = r"^[a-z0-9]+(_[a-z0-9]+)*$";

/// Normalizes user entered identifiers before resource validation.
final identifierInputFormatters = <TextInputFormatter>[
  TextInputFormatter.withFunction(
    (oldValue, newValue) => newValue.copyWith(
      text: newValue.text.toLowerCase().replaceAll(RegExp(r"[\s-]+"), "_"),
    ),
  ),
  FilteringTextInputFormatter.allow(RegExp("[a-z0-9_]")),
];

/// Validates identifiers accepted by panel authored resources.
extension StringIdentifierValidation on String {
  /// Requires at least three lowercase letters or digits separated by single
  /// underscores. Leading, trailing, and repeated underscores are rejected.
  bool get isValidIdentifier =>
      length >= identifierMinimumLength &&
      RegExp(identifierPattern).hasMatch(this);
}
