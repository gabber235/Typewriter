import "package:dart_casing/dart_casing.dart";
import "package:flutter/services.dart";

extension StringX on String {
  String titleCase() {
    if (isEmpty) return this;
    return Casing.titleCase(this);
  }

  String snakeCase() {
    if (isEmpty) return this;
    return Casing.snakeCase(this);
  }

  String get formatted {
    if (isEmpty) return this;
    return split(".").map(Casing.titleCase).join(" | ").titleCase();
  }

  int? get asInt => int.tryParse(this);

  /// If the string is empty, returns null
  /// Otherwise returns the string
  String? get nullIfEmpty => isEmpty ? null : this;

  /// Joins a path with another path.
  String join(String other) {
    if (isEmpty) return other;
    return "$this.$other";
  }

  /// Returns a singular form of the string.
  /// Basic implementation that removes 's' from the end if present.
  String get singular {
    if (isEmpty) return this;
    if (endsWith("s") && length > 1) {
      return substring(0, length - 1);
    }
    return this;
  }
}

TextInputFormatter snakeCaseFormatter() => TextInputFormatter.withFunction(
      (oldValue, newValue) => newValue.copyWith(
        text: newValue.text
            .toLowerCase()
            .replaceAll(" ", "_")
            .replaceAll("-", "_"),
      ),
    );
