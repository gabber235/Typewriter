import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

extension AuthoredResourceLabel on skir.AuthoringRecord {
  /// The authored `name` text, falling back to `title`.
  ///
  /// Blank values are skipped. Null means neither field holds a label, so the
  /// caller chooses its own fallback.
  String? get authoredLabel => [
    authoredField("name")?.authoredString,
    authoredField("title")?.authoredString,
  ].nonNulls.where((value) => value.trim().isNotEmpty).firstOrNull;
}
