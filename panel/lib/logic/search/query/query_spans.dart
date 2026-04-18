// ignore_for_file: sort_constructors_first

class QueryRange {
  final int start;
  final int end;

  const QueryRange(this.start, this.end)
    : assert(start >= 0),
      assert(end >= start);

  int get length => end - start;

  bool containsOffset(int offset) => offset >= start && offset <= end;
}

class QueryRecoveryRange {
  final QueryRange range;
  final String fragment;

  const QueryRecoveryRange({required this.range, required this.fragment});
}
