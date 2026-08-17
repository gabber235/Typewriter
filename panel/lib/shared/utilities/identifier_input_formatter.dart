const identifierMinimumLength = 3;
const identifierPattern = r"^[a-z0-9]+(_[a-z0-9]+)*$";

extension StringIdentifierValidation on String {
  bool get isValidIdentifier =>
      length >= identifierMinimumLength &&
      RegExp(identifierPattern).hasMatch(this);
}
