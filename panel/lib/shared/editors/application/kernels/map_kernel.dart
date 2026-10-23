import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// The panel's map operations. Keys compare with [portableEquals].
final class PanelMapKernel implements skir.MapKernel {
  const PanelMapKernel();

  @override
  bool containsKey(List<skir.MapRow> source, skir.DataValue key) {
    final expected = canonicalAuthoredValue(key);
    return source.any((row) => canonicalAuthoredValue(row.key) == expected);
  }

  @override
  List<skir.MapRow> fromEntries(List<skir.ListItem> source) {
    final rows = <String, skir.MapRow>{};
    for (final item in source) {
      final entry = item.value.asRecordFields();
      final key = entry["key"] ?? _notAnEntry();
      final value = entry["value"] ?? _notAnEntry();
      final canonical = canonicalAuthoredValue(key);
      final previous = rows[canonical];
      // A later equal key replaces the value in the first row's position.
      rows[canonical] = skir.MapRow(
        id: previous?.id ?? item.id,
        key: previous?.key ?? key,
        value: value,
      );
    }
    return rows.values.toList(growable: false);
  }

  @override
  skir.PortableMaybe<skir.DataValue> get(
    skir.Located<List<skir.MapRow>> source,
    skir.DataValue key,
  ) {
    final expected = canonicalAuthoredValue(key);
    final unfilledKeys = <skir.ValueLocation>[];
    var anyUnfilledKey = false;
    for (final row in source.value) {
      if (_containsUnfilled(row.key)) {
        anyUnfilledKey = true;
        unfilledKeys.addAll([?source.mapKey(row.id)]);
        continue;
      }
      if (canonicalAuthoredValue(row.key) != expected) continue;
      return _containsUnfilled(row.value)
          ? skir.PortableMaybeMissing([?source.mapValue(row.id)])
          : skir.PortableMaybeValue(row.value);
    }
    if (anyUnfilledKey) return skir.PortableMaybeMissing(unfilledKeys);
    throw skir.PortableOperationFailure(
      skir.PortableFailures.collectionKeyAbsent,
    );
  }

  @override
  List<skir.MapRow> mapValues(
    List<skir.MapRow> source,
    List<skir.DataValue> body,
  ) => [
    for (final (index, row) in source.indexed)
      skir.MapRow(id: row.id, key: row.key, value: body[index]),
  ];
}

Never _notAnEntry() => throw skir.PortableOperationFailure(
  skir.PortableFailures.illTypedArgument,
  "Expected a map entry.",
);

bool _containsUnfilled(skir.DataValue value) => unfilledPaths(value).isNotEmpty;
