import "package:typewriter_panel/typewriter_panel.dart";

/// String transformations used for authored names and display labels.
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

  String? get nullIfEmpty => isEmpty ? null : this;

  /// Appends a dot separated path, omitting the separator when this is empty.
  String join(String other) {
    if (isEmpty) return other;
    return "$this.$other";
  }

  /// Replaces [prefix] only when it occurs at the start of this string.
  String replacePrefix(
    String prefix,
    String replacement, {
    bool caseSensitive = true,
  }) {
    if (caseSensitive && !startsWith(prefix)) return this;
    if (!caseSensitive && !toLowerCase().startsWith(prefix.toLowerCase())) {
      return this;
    }
    return replaceRange(0, prefix.length, replacement);
  }

  /// Replaces [suffix] only when it occurs at the end of this string.
  String replaceSuffix(
    String suffix,
    String replacement, {
    bool caseSensitive = true,
  }) {
    if (caseSensitive && !endsWith(suffix)) return this;
    if (!caseSensitive && !toLowerCase().endsWith(suffix.toLowerCase())) {
      return this;
    }
    return replaceRange(length - suffix.length, length, replacement);
  }
}
