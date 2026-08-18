final RegExp decimalPattern = RegExp(r"^-?(0|[1-9][0-9]*)(\.[0-9]+)?$");

int compareDecimalStrings(String left, String right) {
  final leftParts = left._decimalParts;
  final rightParts = right._decimalParts;
  final scale = leftParts.$2 > rightParts.$2 ? leftParts.$2 : rightParts.$2;
  final leftCoefficient =
      leftParts.$1 * BigInt.from(10).pow(scale - leftParts.$2);
  final rightCoefficient =
      rightParts.$1 * BigInt.from(10).pow(scale - rightParts.$2);
  return leftCoefficient.compareTo(rightCoefficient);
}

extension DecimalStringProperties on String {
  int get decimalScale {
    final separator = indexOf(".");
    return separator < 0 ? 0 : length - separator - 1;
  }

  (BigInt, int) get _decimalParts {
    final separator = indexOf(".");
    if (separator < 0) return (BigInt.parse(this), 0);
    return (BigInt.parse(replaceFirst(".", "")), length - separator - 1);
  }
}
