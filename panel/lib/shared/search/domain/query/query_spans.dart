import "package:typewriter_panel/typewriter_panel.dart";

// ignore_for_file: sort_constructors_first

/// Half open source range used by parsing and editor replacement.
///
/// [start] is inclusive and [end] is exclusive. Cursor containment also
/// accepts [end] so a cursor immediately after a token remains associated
/// with that token.
class QueryRange {
  final int start;
  final int end;

  const QueryRange(this.start, this.end)
    : assert(start >= 0),
      assert(end >= start);

  /// Number of source code units in the range.
  int get length => end - start;

  /// Whether [offset] lies inside the range or at its editing boundary.
  bool containsOffset(int offset) => offset >= start && offset <= end;

  /// Whether [offset] is exactly the range's exclusive end.
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

/// Converts a PetitParser token range to the query range model.
extension TokenX<T> on Token<T> {
  QueryRange get range => QueryRange(start, stop);
}
