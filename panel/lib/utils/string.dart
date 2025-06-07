import "package:dart_casing/dart_casing.dart";

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
}
