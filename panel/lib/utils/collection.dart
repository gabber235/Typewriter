import "dart:math";

import "package:collection/collection.dart";
import "package:typewriter_panel/main.dart";
import "package:typewriter_panel/utils/map.dart";

extension ListX<T> on List<T> {
  T? randomOrNull() {
    if (isEmpty) return null;
    return elementAt(random.nextInt(length));
  }

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

  List<T> joinWith(T Function() separator) {
    final result = <T>[];
    for (var i = 0; i < length; i++) {
      result.add(this[i]);
      if (i < length - 1) result.add(separator());
    }
    return result;
  }

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
}

extension IterableX<T> on Iterable<T> {
  T? minByOrNull<S>(S Function(T) orderBy, {int Function(S, S)? compare}) =>
      minBy(this, orderBy, compare: compare);

  T? maxByOrNull<S>(S Function(T) orderBy, {int Function(S, S)? compare}) =>
      maxBy(this, orderBy, compare: compare);

  Iterable<T> excluding(List<Type> types) {
    return where((element) => !types.contains(element.runtimeType));
  }

  /// Are all of a given type [T]. Returns false if the selection is empty.
  bool allAre<S extends T>() => isNotEmpty && every((t) => t is S);
}
