// ignore_for_file: sort_constructors_first

import "package:typewriter_panel/logic/search/query/query_ast.dart";
import "package:typewriter_panel/logic/search/query/query_models.dart";
import "package:typewriter_panel/logic/search/query/query_spans.dart";

enum QueryOperatorType { and, or, not }

class QueryTermReference {
  final bool isSelectorTerm;
  final int termIndex;
  final QueryRange range;

  const QueryTermReference({
    required this.isSelectorTerm,
    required this.termIndex,
    required this.range,
  });
}

sealed class QueryLexToken {
  final QueryRange range;

  const QueryLexToken(this.range);
}

final class QueryTermLexToken extends QueryLexToken {
  final QueryTermReference term;

  const QueryTermLexToken({required QueryRange range, required this.term})
    : super(range);
}

final class QueryOperatorLexToken extends QueryLexToken {
  final QueryOperatorType operatorType;
  final String raw;
  final bool implicit;

  const QueryOperatorLexToken({
    required QueryRange range,
    required this.operatorType,
    required this.raw,
    this.implicit = false,
  }) : super(range);
}

final class QueryParenthesisLexToken extends QueryLexToken {
  final bool isOpen;

  const QueryParenthesisLexToken({
    required QueryRange range,
    required this.isOpen,
  }) : super(range);
}

class QueryGrammarResult {
  final QueryExpressionNode? expression;
  final List<QueryParseIssue> issues;
  final List<QueryLexToken> tokens;

  const QueryGrammarResult({
    required this.expression,
    required this.issues,
    required this.tokens,
  });
}

class QueryGrammar {
  const QueryGrammar();

  QueryGrammarResult parse(
    String input, {
    required List<QuerySelectorMatch> selectorMatches,
    required List<QueryTextTerm> textTerms,
  }) {
    final issues = <QueryParseIssue>[];
    final tokens = _tokenize(
      input,
      selectorMatches: selectorMatches,
      textTerms: textTerms,
    );
    final expandedTokens = _insertImplicitAnd(tokens);
    final parser = _Parser(expandedTokens, issues);
    final expression = parser.parseExpression();

    if (!parser.isAtEnd) {
      final token = parser.current;
      issues.add(
        QueryParseIssue(
          code: QueryIssueCode.unexpectedToken,
          message: "Unexpected token",
          severity: QuerySeverity.warning,
          range: token?.range,
          recoveryFragment: token == null
              ? null
              : input.substring(token.range.start, token.range.end),
        ),
      );
    }

    return QueryGrammarResult(
      expression: expression,
      issues: List.unmodifiable(issues),
      tokens: List.unmodifiable(expandedTokens),
    );
  }

  List<QueryLexToken> _tokenize(
    String input, {
    required List<QuerySelectorMatch> selectorMatches,
    required List<QueryTextTerm> textTerms,
  }) {
    final termByStart = <int, QueryTermReference>{};
    for (var index = 0; index < selectorMatches.length; index += 1) {
      final match = selectorMatches[index];
      termByStart[match.fullRange.start] = QueryTermReference(
        isSelectorTerm: true,
        termIndex: index,
        range: match.fullRange,
      );
    }
    for (var index = 0; index < textTerms.length; index += 1) {
      final term = textTerms[index];
      termByStart[term.range.start] = QueryTermReference(
        isSelectorTerm: false,
        termIndex: index,
        range: term.range,
      );
    }

    final tokens = <QueryLexToken>[];
    var cursor = 0;

    while (cursor < input.length) {
      final current = input[cursor];
      if (current.trim().isEmpty) {
        cursor += 1;
        continue;
      }

      final term = termByStart[cursor];
      if (term != null) {
        tokens.add(QueryTermLexToken(range: term.range, term: term));
        cursor = term.range.end;
        continue;
      }

      if (input.startsWith("&&", cursor)) {
        tokens.add(
          QueryOperatorLexToken(
            range: QueryRange(cursor, cursor + 2),
            operatorType: QueryOperatorType.and,
            raw: "&&",
          ),
        );
        cursor += 2;
        continue;
      }

      if (input.startsWith("||", cursor)) {
        tokens.add(
          QueryOperatorLexToken(
            range: QueryRange(cursor, cursor + 2),
            operatorType: QueryOperatorType.or,
            raw: "||",
          ),
        );
        cursor += 2;
        continue;
      }

      if (current == "!") {
        tokens.add(
          QueryOperatorLexToken(
            range: QueryRange(cursor, cursor + 1),
            operatorType: QueryOperatorType.not,
            raw: "!",
          ),
        );
        cursor += 1;
        continue;
      }

      if (current == "(") {
        tokens.add(
          QueryParenthesisLexToken(
            range: QueryRange(cursor, cursor + 1),
            isOpen: true,
          ),
        );
        cursor += 1;
        continue;
      }

      if (current == ")") {
        tokens.add(
          QueryParenthesisLexToken(
            range: QueryRange(cursor, cursor + 1),
            isOpen: false,
          ),
        );
        cursor += 1;
        continue;
      }

      final start = cursor;
      while (cursor < input.length &&
          input[cursor].trim().isNotEmpty &&
          input[cursor] != "(" &&
          input[cursor] != ")") {
        cursor += 1;
      }
      final raw = input.substring(start, cursor);
      final lowered = raw.toLowerCase();
      if (lowered == "and") {
        tokens.add(
          QueryOperatorLexToken(
            range: QueryRange(start, cursor),
            operatorType: QueryOperatorType.and,
            raw: raw,
          ),
        );
        continue;
      }
      if (lowered == "or") {
        tokens.add(
          QueryOperatorLexToken(
            range: QueryRange(start, cursor),
            operatorType: QueryOperatorType.or,
            raw: raw,
          ),
        );
        continue;
      }
      if (lowered == "not") {
        tokens.add(
          QueryOperatorLexToken(
            range: QueryRange(start, cursor),
            operatorType: QueryOperatorType.not,
            raw: raw,
          ),
        );
        continue;
      }

      tokens.add(
        QueryTermLexToken(
          range: QueryRange(start, cursor),
          term: QueryTermReference(
            isSelectorTerm: false,
            termIndex: -1,
            range: QueryRange(start, cursor),
          ),
        ),
      );
    }

    return tokens;
  }

  List<QueryLexToken> _insertImplicitAnd(List<QueryLexToken> originalTokens) {
    if (!originalTokens.isNotEmpty) {
      return const <QueryLexToken>[];
    }

    final expanded = <QueryLexToken>[originalTokens.first];
    for (var index = 1; index < originalTokens.length; index += 1) {
      final previous = expanded.last;
      final current = originalTokens[index];
      if (_needsImplicitAnd(previous, current)) {
        expanded.add(
          QueryOperatorLexToken(
            range: QueryRange(previous.range.end, current.range.start),
            operatorType: QueryOperatorType.and,
            raw: "AND",
            implicit: true,
          ),
        );
      }
      expanded.add(current);
    }

    return expanded;
  }

  bool _needsImplicitAnd(QueryLexToken previous, QueryLexToken current) {
    final previousIsTermLike = switch (previous) {
      QueryTermLexToken() => true,
      QueryParenthesisLexToken(isOpen: false) => true,
      _ => false,
    };

    final currentStartsTerm = switch (current) {
      QueryTermLexToken() => true,
      QueryParenthesisLexToken(isOpen: true) => true,
      QueryOperatorLexToken(operatorType: QueryOperatorType.not) => true,
      _ => false,
    };

    final previousIsOperator = previous is QueryOperatorLexToken;
    final currentIsOperator = current is QueryOperatorLexToken;

    return previousIsTermLike &&
        currentStartsTerm &&
        !previousIsOperator &&
        !currentIsOperator;
  }
}

class _Parser {
  final List<QueryLexToken> tokens;
  final List<QueryParseIssue> issues;
  int _index = 0;

  _Parser(this.tokens, this.issues);

  bool get isAtEnd => _index >= tokens.length;
  QueryLexToken? get current => isAtEnd ? null : tokens[_index];

  QueryExpressionNode? parseExpression() {
    return _parseOr();
  }

  QueryExpressionNode? _parseOr() {
    var left = _parseAnd();
    while (_isOperator(QueryOperatorType.or)) {
      final operator = _consume() as QueryOperatorLexToken;
      final right = _parseAnd();
      if (left == null || right == null) {
        _reportUnexpectedOperand(operator.range);
        return left ?? right;
      }
      left = QueryOrNode(
        range: QueryRange(left.range.start, right.range.end),
        left: left,
        right: right,
      );
    }
    return left;
  }

  QueryExpressionNode? _parseAnd() {
    var left = _parseNot();
    while (_isOperator(QueryOperatorType.and)) {
      final operator = _consume() as QueryOperatorLexToken;
      final right = _parseNot();
      if (left == null || right == null) {
        _reportUnexpectedOperand(operator.range);
        return left ?? right;
      }
      left = QueryAndNode(
        range: QueryRange(left.range.start, right.range.end),
        left: left,
        right: right,
        implicit: operator.implicit,
      );
    }
    return left;
  }

  QueryExpressionNode? _parseNot() {
    if (_isOperator(QueryOperatorType.not)) {
      final operator = _consume() as QueryOperatorLexToken;
      final operand = _parseNot();
      if (operand == null) {
        _reportUnexpectedOperand(operator.range);
        return null;
      }
      return QueryNotNode(
        range: QueryRange(operator.range.start, operand.range.end),
        operand: operand,
      );
    }
    return _parsePrimary();
  }

  QueryExpressionNode? _parsePrimary() {
    final token = current;
    if (token == null) {
      return null;
    }

    if (token is QueryTermLexToken) {
      _consume();
      return QueryTermNode(
        range: token.range,
        termIndex: token.term.termIndex,
        isSelectorTerm: token.term.isSelectorTerm,
      );
    }

    if (token is QueryParenthesisLexToken && token.isOpen) {
      final opening = _consume() as QueryParenthesisLexToken;
      final expression = _parseOr();
      final closing = _matchClosingParen();
      if (closing == null) {
        issues.add(
          QueryParseIssue(
            code: QueryIssueCode.unclosedParenthesis,
            message: "Unclosed parenthesis",
            severity: QuerySeverity.warning,
            range: opening.range,
          ),
        );
        return expression;
      }

      if (expression == null) {
        _reportUnexpectedOperand(opening.range);
        return null;
      }

      return _copyWithRange(expression, opening.range.start, closing.range.end);
    }

    if (token is QueryParenthesisLexToken && !token.isOpen) {
      return null;
    }

    issues.add(
      QueryParseIssue(
        code: QueryIssueCode.unexpectedToken,
        message: "Unexpected token",
        severity: QuerySeverity.warning,
        range: token.range,
      ),
    );
    _consume();
    return null;
  }

  QueryExpressionNode _copyWithRange(
    QueryExpressionNode node,
    int start,
    int end,
  ) {
    final range = QueryRange(start, end);
    return switch (node) {
      QueryTermNode() => QueryTermNode(
        range: range,
        termIndex: node.termIndex,
        isSelectorTerm: node.isSelectorTerm,
      ),
      QueryNotNode() => QueryNotNode(range: range, operand: node.operand),
      QueryAndNode() => QueryAndNode(
        range: range,
        left: node.left,
        right: node.right,
        implicit: node.implicit,
      ),
      QueryOrNode() => QueryOrNode(
        range: range,
        left: node.left,
        right: node.right,
      ),
    };
  }

  QueryParenthesisLexToken? _matchClosingParen() {
    if (current case QueryParenthesisLexToken(isOpen: false)) {
      return _consume() as QueryParenthesisLexToken;
    }
    return null;
  }

  bool _isOperator(QueryOperatorType type) {
    final token = current;
    return token is QueryOperatorLexToken && token.operatorType == type;
  }

  QueryLexToken _consume() {
    final token = tokens[_index];
    _index += 1;
    return token;
  }

  void _reportUnexpectedOperand(QueryRange range) {
    issues.add(
      QueryParseIssue(
        code: QueryIssueCode.unexpectedToken,
        message: "Expected expression after operator",
        severity: QuerySeverity.warning,
        range: range,
      ),
    );
  }
}
