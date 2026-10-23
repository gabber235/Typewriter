import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// The panel's list operations.
final class PanelListKernel implements skir.ListKernel {
  const PanelListKernel();

  @override
  skir.PortableMaybe<skir.DataValue> at(
    skir.Located<List<skir.ListItem>> source,
    int index,
  ) {
    if (index < 0 || index >= source.value.length) {
      throw skir.PortableOperationFailure(
        skir.PortableFailures.collectionKeyAbsent,
        "The index $index is outside the list of ${source.value.length} items.",
      );
    }
    final item = source.value[index];
    if (item.value == skir.DataValue.unfilled) {
      return skir.PortableMaybeMissing([?source.item(item.id)]);
    }
    return skir.PortableMaybeValue(item.value);
  }

  @override
  List<skir.ListItem> concat(
    List<skir.ListItem> first,
    List<skir.ListItem> second,
    List<List<skir.ListItem>> rest,
  ) => [
    for (final (position, items) in [first, second, ...rest].indexed)
      for (final item in items)
        skir.ListItem(
          id: skir.nestedItemId(skir.ItemId(value: "$position"), item.id),
          value: item.value,
        ),
  ];

  @override
  List<skir.ListItem> flatten(List<skir.ListItem> source) => [
    for (final outer in source)
      for (final inner in outer.value.asItems())
        skir.ListItem(
          id: skir.nestedItemId(outer.id, inner.id),
          value: inner.value,
        ),
  ];

  @override
  int indexOf(List<skir.ListItem> source, skir.DataValue value) {
    final key = canonicalAuthoredValue(value);
    return source.indexWhere(
      (item) => canonicalAuthoredValue(item.value) == key,
    );
  }

  @override
  int lastIndexOf(List<skir.ListItem> source, skir.DataValue value) {
    final key = canonicalAuthoredValue(value);
    return source.lastIndexWhere(
      (item) => canonicalAuthoredValue(item.value) == key,
    );
  }

  @override
  List<skir.ListItem> of(List<skir.DataValue> values) =>
      skir.positionalItems(values);

  @override
  List<int> range(int start, int end, int step, skir.PortableMeter meter) {
    if (step == 0) {
      throw skir.PortableOperationFailure(
        skir.PortableFailures.invalidRangeStep,
      );
    }
    final count = step > 0
        ? (end > start ? (end - start + step - 1) ~/ step : 0)
        : (start > end ? (start - end - step - 1) ~/ -step : 0);
    meter.items(count);
    return [for (var index = 0; index < count; index++) start + index * step];
  }

  @override
  List<skir.ListItem> reverse(List<skir.ListItem> source) =>
      source.reversed.toList(growable: false);

  @override
  List<skir.ListItem> scan(
    List<skir.ListItem> source,
    skir.DataValue initial,
    skir.PortableStep step,
  ) {
    final accumulators = [initial];
    for (final item in source) {
      accumulators.add(step(accumulators.last, item));
    }
    return skir.positionalItems(accumulators);
  }

  @override
  List<skir.ListItem> slice(List<skir.ListItem> source, int start, int end) {
    if (start < 0 || end < start || end > source.length) {
      throw skir.PortableOperationFailure(
        skir.PortableFailures.sliceRange,
        "The range $start to $end is outside the list of ${source.length} "
        "items.",
      );
    }
    return source.sublist(start, end);
  }

  @override
  List<skir.ListItem> zip(
    List<skir.ListItem> first,
    List<skir.ListItem> second,
  ) => [
    for (var index = 0; index < first.length && index < second.length; index++)
      skir.ListItem(
        id: first[index].id,
        value: skir.entryValue(first[index].value, second[index].value),
      ),
  ];
}
