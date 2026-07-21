import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

List<QuerySelectorDefinition> selectorsTagOnly() {
  return const [KeyValueSelectorDefinition(id: "tag", key: "#")];
}

List<QuerySelectorDefinition> selectorsTagAndTitle() {
  return const [
    KeyValueSelectorDefinition(id: "tag", key: "#"),
    KeyValueSelectorDefinition(id: "title", key: "title:"),
  ];
}

List<QuerySelectorDefinition> selectorsRoleEnum() {
  return [
    const KeyValueSelectorDefinition(id: "tag", key: "#"),
    const KeyValueSelectorDefinition(id: "title", key: "title:"),
    KeyValueSelectorDefinition(
      id: "role",
      key: "role:",
      value: QuerySelectorValue.enumValue(["admin", "author", "member"]),
    ),
  ];
}

List<QuerySelectorDefinition> selectorsLexerDefaults() {
  return [
    const KeyValueSelectorDefinition(id: "tag", key: "#"),
    const KeyValueSelectorDefinition(id: "title", key: "title:"),
    const KeyValueSelectorDefinition(
      id: "status",
      key: "status:",
      value: QuerySelectorValue.enumValue(["open", "closed", "draft"]),
    ),
    const KeyValueSelectorDefinition(
      id: "exact",
      key: "exact:",
      caseSensitive: true,
    ),
  ];
}

QueryEngine engineFor(List<QuerySelectorDefinition> selectors) {
  return QueryEngine(selectors);
}

QueryLexerResult lexQuery(
  String input, {
  List<QuerySelectorDefinition>? selectors,
}) {
  final lexer = QueryLexer(selectors ?? selectorsLexerDefaults());
  return lexer.tokenize(input);
}

QueryCheck checkQuery(
  String input, {
  List<QuerySelectorDefinition>? selectors,
  int? cursorOffset,
}) {
  final result = QueryEngine(
    selectors ?? selectorsLexerDefaults(),
  ).parse(input, cursorOffset: cursorOffset);
  return QueryCheck._(result);
}

QueryLexerCheck checkLex(
  String input, {
  List<QuerySelectorDefinition>? selectors,
}) {
  final result = lexQuery(input, selectors: selectors);
  return QueryLexerCheck._(result);
}

final class QueryCheck {
  QueryCheck._(this.result);

  final QueryParseResult result;
  bool _issuesAsserted = false;
  bool _queryAsserted = false;
  bool _expressionAsserted = false;
  TokenCheck? _root;

  QueryCheck expectNoIssues() {
    _assertIssuesNotAlreadyChecked();
    expect(result.issues, isEmpty);
    _issuesAsserted = true;
    return this;
  }

  QueryCheck expectIssues(List<QueryIssueCode> codes) {
    _assertIssuesNotAlreadyChecked();
    expect(_issueCodes(result.issues), containsAll(codes));
    _issuesAsserted = true;
    return this;
  }

  QueryCheck expectNoQuery() {
    _assertQueryNotAlreadyChecked();
    expect(_normalizeWhitespace(result.query), isEmpty);
    _queryAsserted = true;
    return this;
  }

  QueryCheck expectQuery(String normalized) {
    _assertQueryNotAlreadyChecked();
    expect(_normalizeWhitespace(result.query), normalized);
    _queryAsserted = true;
    return this;
  }

  QueryCheck expectNoExpression() {
    _assertExpressionNotAlreadyChecked();
    expect(result.expression, isNull);
    _expressionAsserted = true;
    return this;
  }

  QueryCheck expectExpression(void Function(TokenCheck token) visit) {
    _assertExpressionNotAlreadyChecked();
    final token = result.expression;
    expect(token, isNotNull);
    final root = TokenCheck._(token!, "expression");
    visit(root);
    _root = root;
    _expressionAsserted = true;
    return this;
  }

  QueryParseResult done() {
    if (!_issuesAsserted) {
      throw StateError(
        "Missing issues assertion. Call expectNoIssues() or expectIssues().",
      );
    }
    if (!_queryAsserted) {
      throw StateError(
        "Missing query assertion. Call expectNoQuery() or expectQuery().",
      );
    }
    if (!_expressionAsserted) {
      throw StateError(
        "Missing expression assertion. Call expectNoExpression() or expectExpression(...).",
      );
    }
    _root?._validate();
    return result;
  }

  void _assertIssuesNotAlreadyChecked() {
    if (_issuesAsserted) {
      throw StateError("Issues were already asserted for this query.");
    }
  }

  void _assertQueryNotAlreadyChecked() {
    if (_queryAsserted) {
      throw StateError("Query remainder was already asserted for this query.");
    }
  }

  void _assertExpressionNotAlreadyChecked() {
    if (_expressionAsserted) {
      throw StateError("Expression was already asserted for this query.");
    }
  }
}

final class QueryLexerCheck {
  QueryLexerCheck._(this.result);

  final QueryLexerResult result;
  bool _queryAsserted = false;
  bool _expressionAsserted = false;
  TokenCheck? _root;

  QueryLexerCheck expectNoQuery() {
    _assertQueryNotAlreadyChecked();
    expect(_normalizeWhitespace(result.query), isEmpty);
    _queryAsserted = true;
    return this;
  }

  QueryLexerCheck expectQuery(String normalized) {
    _assertQueryNotAlreadyChecked();
    expect(_normalizeWhitespace(result.query), normalized);
    _queryAsserted = true;
    return this;
  }

  QueryLexerCheck expectNoExpression() {
    _assertExpressionNotAlreadyChecked();
    expect(result.expression, isNull);
    _expressionAsserted = true;
    return this;
  }

  QueryLexerCheck expectExpression(void Function(TokenCheck token) visit) {
    _assertExpressionNotAlreadyChecked();
    final token = result.expression;
    expect(token, isNotNull);
    final root = TokenCheck._(token!, "expression");
    visit(root);
    _root = root;
    _expressionAsserted = true;
    return this;
  }

  QueryLexerResult done() {
    if (!_queryAsserted) {
      throw StateError(
        "Missing query assertion. Call expectNoQuery() or expectQuery().",
      );
    }
    if (!_expressionAsserted) {
      throw StateError(
        "Missing expression assertion. Call expectNoExpression() or expectExpression(...).",
      );
    }
    _root?._validate();
    return result;
  }

  void _assertQueryNotAlreadyChecked() {
    if (_queryAsserted) {
      throw StateError("Query remainder was already asserted for this query.");
    }
  }

  void _assertExpressionNotAlreadyChecked() {
    if (_expressionAsserted) {
      throw StateError("Expression was already asserted for this query.");
    }
  }
}

final class TokenCheck {
  TokenCheck._(this._token, this._path);

  final QueryLexerToken _token;
  final String _path;

  bool _kindAsserted = false;
  BinaryTokenCheck? _binary;
  UnaryTokenCheck? _unary;

  TokenCheck range(QueryRange expected) {
    expect(_token.range, expected);
    return this;
  }

  TokenCheck isSelector({required String id, required String? value}) {
    _assertKindNotAlreadyChecked();
    expect(_token, isA<QueryLexerKeyValueSelectorToken>());
    final selector = _token as QueryLexerKeyValueSelectorToken;
    expect(selector.selectorId, id);
    expect(selector.value, value);
    _kindAsserted = true;
    return this;
  }

  BinaryTokenCheck isAnd() {
    _assertKindNotAlreadyChecked();
    expect(_token, isA<QueryLexerOperatorToken>());
    final operator = _token as QueryLexerOperatorToken;
    expect(operator.type, QueryLexerOperatorType.and);
    _kindAsserted = true;
    final binary = BinaryTokenCheck._(operator, _path);
    _binary = binary;
    return binary;
  }

  BinaryTokenCheck isOr() {
    _assertKindNotAlreadyChecked();
    expect(_token, isA<QueryLexerOperatorToken>());
    final operator = _token as QueryLexerOperatorToken;
    expect(operator.type, QueryLexerOperatorType.or);
    _kindAsserted = true;
    final binary = BinaryTokenCheck._(operator, _path);
    _binary = binary;
    return binary;
  }

  UnaryTokenCheck isNot() {
    _assertKindNotAlreadyChecked();
    expect(_token, isA<QueryLexerNegationToken>());
    final negation = _token as QueryLexerNegationToken;
    _kindAsserted = true;
    final unary = UnaryTokenCheck._(negation, _path);
    _unary = unary;
    return unary;
  }

  QueryLexerToken token() {
    return _token;
  }

  void _validate() {
    if (!_kindAsserted) {
      throw StateError(
        "$_path was not asserted with isSelector/isAnd/isOr/isNot.",
      );
    }
    _binary?._validate();
    _unary?._validate();
  }

  void _assertKindNotAlreadyChecked() {
    if (_kindAsserted) {
      throw StateError("$_path already has a token kind assertion.");
    }
  }
}

final class BinaryTokenCheck {
  BinaryTokenCheck._(this._token, this._path)
    : _left = TokenCheck._(_token.left, "$_path.left"),
      _right = TokenCheck._(_token.right, "$_path.right");

  final QueryLexerOperatorToken _token;
  final String _path;
  final TokenCheck _left;
  final TokenCheck _right;

  bool _leftVisited = false;
  bool _rightVisited = false;

  TokenCheck left() {
    _leftVisited = true;
    return _left;
  }

  TokenCheck right() {
    _rightVisited = true;
    return _right;
  }

  BinaryTokenCheck operatorRange(QueryRange? expected) {
    expect(_token.operatorRange, expected);
    return this;
  }

  void _validate() {
    if (!_leftVisited || !_rightVisited) {
      throw StateError(
        "$_path requires both left() and right() to be visited.",
      );
    }
    _left._validate();
    _right._validate();
  }
}

final class UnaryTokenCheck {
  UnaryTokenCheck._(this._token, this._path)
    : _inner = TokenCheck._(_token.token, "$_path.inner");

  final QueryLexerNegationToken _token;
  final String _path;
  final TokenCheck _inner;

  bool _innerVisited = false;

  TokenCheck inner() {
    _innerVisited = true;
    return _inner;
  }

  UnaryTokenCheck operatorRange(QueryRange expected) {
    expect(_token.operatorRange, expected);
    return this;
  }

  void _validate() {
    if (!_innerVisited) {
      throw StateError("$_path requires inner() to be visited.");
    }
    _inner._validate();
  }
}

List<QueryIssueCode> _issueCodes(List<QueryParseIssue> issues) {
  return issues.map((issue) => issue.code).toList();
}

String _normalizeWhitespace(String input) {
  return input.replaceAll(RegExp(r"\s+"), " ").trim();
}
