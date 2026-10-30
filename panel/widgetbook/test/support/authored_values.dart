import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Authored collections read the way a story test compares them: as the
/// text of their items and entries.
extension AuthoredCollectionText on skir.DataValue {
  /// The text of each item of an authored list; fails on another value.
  List<String> get itemTexts => [
    for (final item in authoredItems ?? (throw StateError("$this is no list")))
      item.value.authoredString ?? "${item.value}",
  ];

  /// Each entry of an authored map, key to value, as text; fails on another
  /// value.
  Map<String, String> get entryTexts => switch (authoredPayload) {
    skir.DataValue_mapValueWrapper(:final value) => {
      for (final row in value.rows) "${row.key}": "${row.value}",
    },
    final other => throw StateError("$other is no map"),
  };
}
