typedef ValueComparator<T> = int Function(T left, T right);

T? maximumNullable<T>(
  T? left,
  T? right, {
  required ValueComparator<T> compare,
}) => switch ((left, right)) {
  (null, _) => right,
  (_, null) => left,
  (final a?, final b?) => compare(a, b) >= 0 ? a : b,
};

T? minimumNullable<T>(
  T? left,
  T? right, {
  required ValueComparator<T> compare,
}) => switch ((left, right)) {
  (null, _) => right,
  (_, null) => left,
  (final a?, final b?) => compare(a, b) <= 0 ? a : b,
};

T? maximumNullableComparable<T extends Comparable<dynamic>>(
  T? left,
  T? right,
) => maximumNullable(left, right, compare: (a, b) => a.compareTo(b));

T? minimumNullableComparable<T extends Comparable<dynamic>>(
  T? left,
  T? right,
) => minimumNullable(left, right, compare: (a, b) => a.compareTo(b));
