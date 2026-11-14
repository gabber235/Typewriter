import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Edits of a list, set or map value made in place of the value, keeping its
/// named wrapper and its kind. Each is null when this value is not that kind
/// of collection or the item it names is gone.
extension PortableCollectionEdits on skir.DataValue {
  /// This list or set with [item] placed after the item [after], or first
  /// when [after] is null.
  skir.DataValue? withItemAfter(skir.ItemId? after, skir.ListItem item) =>
      _withItems((items) {
        final index = after == null
            ? 0
            : items.indexWhere((candidate) => candidate.id == after) + 1;
        if (after != null && index == 0) return null;
        return [...items.take(index), item, ...items.skip(index)];
      });

  /// This list or set with [item] added at its end.
  skir.DataValue? withItemAppended(skir.ListItem item) =>
      _withItems((items) => [...items, item]);

  /// This list or set without the item [item].
  skir.DataValue? withoutItem(skir.ItemId item) => _withItems(
    (items) => items.any((candidate) => candidate.id == item)
        ? [
            for (final candidate in items)
              if (candidate.id != item) candidate,
          ]
        : null,
  );

  /// This list or set with the item [item] moved after the item [after], or
  /// first when [after] is null.
  skir.DataValue? withItemMoved(skir.ItemId item, skir.ItemId? after) {
    final moved = authoredItems?.where((candidate) => candidate.id == item);
    if (moved == null || moved.isEmpty) return null;
    return withoutItem(item)?.withItemAfter(after, moved.first);
  }

  /// This map with its rows replaced by what [update] makes of them, or null
  /// when [update] returns null.
  skir.DataValue? withRows(
    List<skir.MapRow>? Function(List<skir.MapRow> rows) update,
  ) {
    final payload = authoredPayload;
    if (payload is! skir.DataValue_mapValueWrapper) return null;
    final rows = update(payload.value.rows.toList());
    return rows == null
        ? null
        : withAuthoredPayload(skir.DataValue.createMapValue(rows: rows));
  }

  skir.DataValue? _withItems(
    List<skir.ListItem>? Function(List<skir.ListItem> items) update,
  ) {
    final items = authoredItems?.toList();
    if (items == null) return null;
    final next = update(items);
    if (next == null) return null;
    return withAuthoredPayload(switch (authoredPayload) {
      skir.DataValue_setValueWrapper() => skir.DataValue.createSetValue(
        items: next,
      ),
      _ => skir.DataValue.createListValue(items: next),
    });
  }
}
