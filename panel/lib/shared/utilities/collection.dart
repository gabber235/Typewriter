import "package:typewriter_panel/typewriter_panel.dart";

/// Collection operations used by panel presentation and data assembly.
extension ListX<T> on List<T> {
  /// Picks a random element, or returns `null` when this list is empty.
  T? randomOrNull() {
    if (isEmpty) return null;
    return elementAt(random.nextInt(length));
  }

  /// Picks a random element and throws when this list is empty.
  T randomElement() {
    if (isEmpty) throw Exception("List is empty");
    return elementAt(random.nextInt(length));
  }

  /// Returns [count] distinct elements in random order.
  ///
  /// Invalid counts return an empty list rather than partially sampling.
  List<T> randomSubset(int count) {
    if (count <= 0 || count > length) return [];
    final indices = List.generate(length, (index) => index);
    final result = <T>[];
    for (var i = 0; i < count; i++) {
      final index = indices.removeAt(random.nextInt(indices.length));
      result.add(this[index]);
    }
    return result;
  }

  List<int> get indices => List.generate(length, (index) => index);

  /// Inserts a newly created separator between every adjacent element.
  List<T> joinWith(T Function() separator) {
    final result = <T>[];
    for (var i = 0; i < length; i++) {
      result.add(this[i]);
      if (i < length - 1) result.add(separator());
    }
    return result;
  }

  /// Combines two lists positionally, recursively masking shared values.
  List<dynamic> mask(List<dynamic> other) {
    final result = <dynamic>[];
    for (var i = 0; i < max(length, other.length); i++) {
      if (i < length && i < other.length) {
        result.add(maskObjects(this[i], other[i]));
      } else if (i < length) {
        result.add(this[i]);
      } else {
        result.add(other[i]);
      }
    }
    return result;
  }

  /// Yields elements also present in [other], preserving this list's order.
  Iterable<T> intersection(List<T> other) {
    return where((e) => other.contains(e));
  }
}

/// Immutable updates for nullable list projections.
extension NullableListX<T> on List<T>? {
  /// Replaces the first item with the same key, or appends [updated].
  ///
  /// A `null` list becomes a one item list.
  List<T> upsertByKey<TKey>(TKey Function(T) keySelector, T updated) {
    if (this == null) return [updated];

    final updatedId = keySelector(updated);

    final matchingIndex = this!.indexWhere(
      (value) => keySelector(value) == updatedId,
    );
    if (matchingIndex == -1) return [...this!, updated];

    return [
      ...this!.take(matchingIndex),
      updated,
      ...this!.skip(matchingIndex + 1),
    ];
  }
}

/// Ordering and type filtering operations for iterables.
extension IterableX<T> on Iterable<T> {
  /// Returns the item with the smallest projected value, or `null` when empty.
  T? minByOrNull<S>(S Function(T) orderBy, {int Function(S, S)? compare}) =>
      minBy(this, orderBy, compare: compare);

  /// Returns the item with the largest projected value, or `null` when empty.
  T? maxByOrNull<S>(S Function(T) orderBy, {int Function(S, S)? compare}) =>
      maxBy(this, orderBy, compare: compare);

  /// Yields items whose runtime types are absent from [types].
  Iterable<T> excluding(List<Type> types) {
    return where((element) => !types.contains(element.runtimeType));
  }

  /// Are all of a given type [T]. Returns false if the selection is empty.
  bool allAre<S extends T>() => isNotEmpty && every((t) => t is S);
}

/// Converts an iterable of entries into a map.
extension EntryMapIterable<K, V> on Iterable<MapEntry<K, V>> {
  Map<K, V> toMap() => Map.fromEntries(this);
}
