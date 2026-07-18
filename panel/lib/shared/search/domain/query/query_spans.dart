// ignore_for_file: sort_constructors_first

import "dart:math";

import "package:petitparser/petitparser.dart";

class QueryRange {
  final int start;
  final int end;

  const QueryRange(this.start, this.end)
    : assert(start >= 0),
      assert(end >= start);

  int get length => end - start;

  bool containsOffset(int offset) => offset >= start && offset <= end;
  bool isAtEnd(int offset) => offset == end;

  @override
  String toString() => "$start:$end";

  @override
  bool operator ==(Object other) =>
      other is QueryRange && start == other.start && end == other.end;

  @override
  int get hashCode => Object.hashAll([start, end]);

  QueryRange operator +(int offset) => QueryRange(start + offset, end + offset);
  QueryRange operator -(int offset) => QueryRange(start - offset, end - offset);

  QueryRange expandTo(QueryRange other) {
    return QueryRange(min(start, other.start), max(end, other.end));
  }

  QueryRange copyWith({int? start, int? end}) {
    return QueryRange(start ?? this.start, end ?? this.end);
  }
}

extension TokenX<T> on Token<T> {
  QueryRange get range => QueryRange(start, stop);
}
