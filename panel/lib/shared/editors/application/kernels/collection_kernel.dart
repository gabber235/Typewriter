import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// The panel's operations on any collection's items. Item identities follow
/// the operation's declared item ids; equality is [portableEquals].
final class PanelCollectionKernel implements skir.CollectionKernel {
  const PanelCollectionKernel();

  @override
  bool contains(List<skir.ListItem> source, skir.DataValue value) {
    final key = canonicalAuthoredValue(value);
    return source.any((item) => canonicalAuthoredValue(item.value) == key);
  }

  @override
  List<skir.ListItem> filter(
    List<skir.ListItem> source,
    List<bool> predicate,
  ) => [
    for (final (index, item) in source.indexed)
      if (predicate[index]) item,
  ];

  @override
  skir.DataValue fold(
    List<skir.ListItem> source,
    skir.DataValue initial,
    skir.PortableStep step,
  ) => source.fold(initial, step);

  @override
  List<skir.MapRow> groupBy(
    List<skir.ListItem> source,
    List<skir.DataValue> key,
  ) {
    final groups = <String, (skir.DataValue, List<skir.ListItem>)>{};
    for (final (index, item) in source.indexed) {
      groups
          .putIfAbsent(
            canonicalAuthoredValue(key[index]),
            () => (key[index], <skir.ListItem>[]),
          )
          .$2
          .add(item);
    }
    return [
      for (final (key, members) in groups.values)
        skir.MapRow(
          id: members.first.id,
          key: key,
          value: skir.itemsList(members),
        ),
    ];
  }

  @override
  List<skir.ListItem> map(
    List<skir.ListItem> source,
    List<skir.DataValue> body,
  ) => [
    for (final (index, item) in source.indexed)
      skir.ListItem(id: item.id, value: body[index]),
  ];

  @override
  int size(List<skir.ListItem> source) => source.length;

  @override
  List<skir.ListItem> sortBy(
    List<skir.ListItem> source,
    List<skir.DataValue> key,
    skir.SortDirection direction,
  ) {
    final order = List.generate(source.length, (index) => index)
      ..sort((left, right) {
        final comparison = portableCompare(key[left], key[right]);
        final directed = direction == skir.SortDirection.descending
            ? -comparison
            : comparison;
        // Equal keys keep their source order in both directions.
        return directed != 0 ? directed : left.compareTo(right);
      });
    return [for (final index in order) source[index]];
  }

  @override
  List<skir.ListItem> sortWith(
    List<skir.ListItem> source,
    skir.PortableComparator comparator,
    skir.PortableMeter meter,
  ) {
    // This exact insertion sort is part of the contract: both hosts call the
    // comparator the same number of times and charge the same items.
    final sorted = <skir.ListItem>[];
    for (final item in source) {
      var index = sorted.length;
      while (index > 0) {
        meter.items(2);
        if (comparator(sorted[index - 1], item) <= 0) break;
        index--;
      }
      sorted.insert(index, item);
    }
    return sorted;
  }

  @override
  List<skir.ListItem> toList(List<skir.ListItem> source) => source;

  @override
  List<skir.ListItem> toSet(List<skir.ListItem> source) =>
      distinctItems(source);
}

/// The first occurrence of every distinct value, with its identity.
List<skir.ListItem> distinctItems(Iterable<skir.ListItem> source) {
  final seen = <String>{};
  return [
    for (final item in source)
      if (seen.add(canonicalAuthoredValue(item.value))) item,
  ];
}
