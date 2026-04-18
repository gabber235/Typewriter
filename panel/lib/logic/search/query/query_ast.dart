// ignore_for_file: sort_constructors_first

import "package:typewriter_panel/logic/search/query/query_spans.dart";

sealed class QueryExpressionNode {
  final QueryRange range;

  const QueryExpressionNode(this.range);
}

final class QueryTermNode extends QueryExpressionNode {
  final int termIndex;
  final bool isSelectorTerm;

  const QueryTermNode({
    required QueryRange range,
    required this.termIndex,
    required this.isSelectorTerm,
  }) : super(range);
}

final class QueryNotNode extends QueryExpressionNode {
  final QueryExpressionNode operand;

  const QueryNotNode({required QueryRange range, required this.operand})
    : super(range);
}

final class QueryAndNode extends QueryExpressionNode {
  final QueryExpressionNode left;
  final QueryExpressionNode right;
  final bool implicit;

  const QueryAndNode({
    required QueryRange range,
    required this.left,
    required this.right,
    required this.implicit,
  }) : super(range);
}

final class QueryOrNode extends QueryExpressionNode {
  final QueryExpressionNode left;
  final QueryExpressionNode right;

  const QueryOrNode({
    required QueryRange range,
    required this.left,
    required this.right,
  }) : super(range);
}
