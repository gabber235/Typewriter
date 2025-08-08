import "package:collection/collection.dart";
import "package:typewriter_panel/main.dart";

extension ListX<T> on List<T> {
  T? randomOrNull() {
    if (isEmpty) return null;
    return elementAt(random.nextInt(length));
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
}

extension IterableX<T> on Iterable<T> {
  T? minByOrNull<S>(S Function(T) orderBy, {int Function(S, S)? compare}) =>
      minBy(this, orderBy, compare: compare);

  T? maxByOrNull<S>(S Function(T) orderBy, {int Function(S, S)? compare}) =>
      maxBy(this, orderBy, compare: compare);
}
