// ignore_for_file: sort_constructors_first

import "package:petitparser/petitparser.dart";
import "package:typewriter_panel/logic/search/query/query_ast.dart";
import "package:typewriter_panel/logic/search/query/query_models.dart";
import "package:typewriter_panel/logic/search/query/query_selector.dart";
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
  final List<QuerySelectorMatch> selectorMatches;
  final List<QueryTextTerm> textTerms;

  const QueryGrammarResult({
    required this.expression,
    required this.issues,
    required this.tokens,
    required this.selectorMatches,
    required this.textTerms,
  });
}

class QueryGrammar {
  const QueryGrammar();

  QueryGrammarResult parse(
    String input, {
    required List<QuerySelectorDefinition> selectors,
  }) {
    final atomOutput = _parseAtoms(input, selectors);
    final issues = <QueryParseIssue>[...atomOutput.issues];
    final tokens = _tokenize(
      input,
      selectorMatches: atomOutput.selectorMatches,
      textTerms: atomOutput.textTerms,
    );
    final expandedTokens = _insertImplicitAnd(tokens);

    QueryExpressionNode? expression;
    if (expandedTokens.isNotEmpty) {
      final stream = _serializeTokens(expandedTokens);
      final parser = _buildExpressionParser(
        expandedTokens,
        stream.tokenIndexBySymbolOffset,
      );
      final result = parser.parse(stream.symbols);

      if (result is Success<QueryExpressionNode>) {
        expression = result.value;
      } else {
        issues.add(
          _mapFailureToIssue(
            input: input,
            tokens: expandedTokens,
            tokenIndexBySymbolOffset: stream.tokenIndexBySymbolOffset,
            failure: result as Failure,
          ),
        );
      }
    }

    return QueryGrammarResult(
      expression: expression,
      issues: List.unmodifiable(issues),
      tokens: List.unmodifiable(expandedTokens),
      selectorMatches: List.unmodifiable(atomOutput.selectorMatches),
      textTerms: List.unmodifiable(atomOutput.textTerms),
    );
  }

  _AtomParseOutput _parseAtoms(
    String input,
    List<QuerySelectorDefinition> selectors,
  ) {
    final selectorMatches = <QuerySelectorMatch>[];
    final textTerms = <QueryTextTerm>[];
    final issues = <QueryParseIssue>[];

    var index = 0;
    while (index < input.length) {
      final char = input[index];
      if (_isWhitespace(char)) {
        index += 1;
        continue;
      }

      final symbolMatch = _tryParseSymbolSelector(input, index, selectors, issues);
      if (symbolMatch != null) {
        if (symbolMatch.match != null) {
          selectorMatches.add(symbolMatch.match!);
        } else {
          textTerms.add(symbolMatch.fallbackTerm!);
        }
        index = symbolMatch.nextIndex;
        continue;
      }

      final keyValueMatch = _tryParseKeyValueSelector(
        input,
        index,
        selectors,
        issues,
      );
      if (keyValueMatch != null) {
        if (keyValueMatch.match != null) {
          selectorMatches.add(keyValueMatch.match!);
        } else {
          textTerms.add(keyValueMatch.fallbackTerm!);
        }
        index = keyValueMatch.nextIndex;
        continue;
      }

      if (_startsOperatorOrParenthesis(input, index)) {
        index = _consumeOperatorOrParenthesis(input, index);
        continue;
      }

      final termStart = index;
      while (index < input.length &&
          !_isWhitespace(input[index]) &&
          input[index] != "(" &&
          input[index] != ")") {
        index += 1;
      }
      final termText = input.substring(termStart, index);
      if (_isWordOperator(termText)) {
        continue;
      }

      textTerms.add(
        QueryTextTerm(text: termText, range: QueryRange(termStart, index)),
      );
    }

    return _AtomParseOutput(
      selectorMatches: selectorMatches,
      textTerms: textTerms,
      issues: issues,
    );
  }

  _AtomScanOutcome? _tryParseSymbolSelector(
    String input,
    int start,
    List<QuerySelectorDefinition> selectors,
    List<QueryParseIssue> issues,
  ) {
    final symbolSelectors = selectors.whereType<SymbolSelectorDefinition>();
    for (final selector in symbolSelectors) {
      if (!input.startsWith(selector.symbol, start)) {
        continue;
      }

      final tokenStart = start + selector.symbol.length;
      var end = tokenStart;
      while (end < input.length && !_isWhitespace(input[end])) {
        if (input[end] == "(" || input[end] == ")") {
          break;
        }
        end += 1;
      }

      final raw = input.substring(start, end);
      final token = input.substring(tokenStart, end);
      if (token.isEmpty) {
        issues.add(
          QueryParseIssue(
            code: QueryIssueCode.invalidSelectorValue,
            message: "Selector ${selector.id} is missing a token",
            severity: QuerySeverity.warning,
            range: QueryRange(start, end),
          ),
        );
        return _AtomScanOutcome(
          nextIndex: end,
          fallbackTerm: QueryTextTerm(text: raw, range: QueryRange(start, end)),
        );
      }

      return _AtomScanOutcome(
        nextIndex: end,
        match: SymbolSelectorMatch(
          selectorId: selector.id,
          rawText: raw,
          fullRange: QueryRange(start, end),
          symbol: selector.symbol,
          symbolRange: QueryRange(start, tokenStart),
          token: token,
          tokenRange: QueryRange(tokenStart, end),
        ),
      );
    }

    return null;
  }

  _AtomScanOutcome? _tryParseKeyValueSelector(
    String input,
    int start,
    List<QuerySelectorDefinition> selectors,
    List<QueryParseIssue> issues,
  ) {
    var cursor = start;
    while (cursor < input.length &&
        !_isWhitespace(input[cursor]) &&
        input[cursor] != ":") {
      if (input[cursor] == "(" || input[cursor] == ")") {
        return null;
      }
      cursor += 1;
    }

    if (cursor >= input.length || input[cursor] != ":") {
      return null;
    }

    final key = input.substring(start, cursor);
    if (key.isEmpty) {
      return null;
    }

    final keySelectors = selectors.whereType<KeyValueSelectorDefinition>();
    KeyValueSelectorDefinition? matchedSelector;
    for (final selector in keySelectors) {
      final keyMatches = selector.matchesKey(key);
      if (keyMatches) {
        matchedSelector = selector;
        break;
      }
    }

    if (matchedSelector == null) {
      return null;
    }

    final valueStart = cursor + 1;
    if (valueStart >= input.length) {
      issues.add(
        QueryParseIssue(
          code: QueryIssueCode.invalidSelectorValue,
          message: "Selector ${matchedSelector.id} is missing a value",
          severity: QuerySeverity.warning,
          range: QueryRange(start, valueStart),
        ),
      );
      return _AtomScanOutcome(
        nextIndex: valueStart,
        fallbackTerm: QueryTextTerm(
          text: input.substring(start, valueStart),
          range: QueryRange(start, valueStart),
        ),
      );
    }

    if (input[valueStart] == "\"") {
      final openQuote = valueStart;
      var closeQuote = openQuote + 1;
      while (closeQuote < input.length && input[closeQuote] != "\"") {
        closeQuote += 1;
      }

      if (closeQuote >= input.length) {
        final raw = input.substring(start);
        final value = input.substring(openQuote + 1);
        issues.add(
          QueryParseIssue(
            code: QueryIssueCode.unclosedQuote,
            message: "Selector ${matchedSelector.id} has an unclosed quote",
            severity: QuerySeverity.warning,
            range: QueryRange(openQuote, input.length),
            recoveryFragment: input.substring(openQuote),
          ),
        );
        return _AtomScanOutcome(
          nextIndex: input.length,
          match: KeyValueSelectorMatch(
            selectorId: matchedSelector.id,
            rawText: raw,
            fullRange: QueryRange(start, input.length),
            key: key,
            keyRange: QueryRange(start, cursor),
            value: value,
            valueRange: QueryRange(openQuote + 1, input.length),
            quoteRange: QueryRange(openQuote, input.length),
          ),
        );
      }

      final end = closeQuote + 1;
      final raw = input.substring(start, end);
      final value = input.substring(openQuote + 1, closeQuote);
      return _AtomScanOutcome(
        nextIndex: end,
        match: KeyValueSelectorMatch(
          selectorId: matchedSelector.id,
          rawText: raw,
          fullRange: QueryRange(start, end),
          key: key,
          keyRange: QueryRange(start, cursor),
          value: value,
          valueRange: QueryRange(openQuote + 1, closeQuote),
          quoteRange: QueryRange(openQuote, end),
        ),
      );
    }

    var end = valueStart;
    while (end < input.length && !_isWhitespace(input[end])) {
      if (input[end] == "(" || input[end] == ")") {
        break;
      }
      end += 1;
    }

    final raw = input.substring(start, end);
    final value = input.substring(valueStart, end);
    return _AtomScanOutcome(
      nextIndex: end,
      match: KeyValueSelectorMatch(
        selectorId: matchedSelector.id,
        rawText: raw,
        fullRange: QueryRange(start, end),
        key: key,
        keyRange: QueryRange(start, cursor),
        value: value,
        valueRange: QueryRange(valueStart, end),
        quoteRange: null,
      ),
    );
  }

  bool _startsOperatorOrParenthesis(String input, int start) {
    if (input.startsWith("&&", start) || input.startsWith("||", start)) {
      return true;
    }
    final char = input[start];
    return char == "!" || char == "(" || char == ")";
  }

  int _consumeOperatorOrParenthesis(String input, int start) {
    if (input.startsWith("&&", start) || input.startsWith("||", start)) {
      return start + 2;
    }
    return start + 1;
  }

  bool _isWordOperator(String token) {
    final lowered = token.toLowerCase();
    return lowered == "and" || lowered == "or" || lowered == "not";
  }

  bool _isWhitespace(String char) => char.trim().isEmpty;

  Parser<QueryExpressionNode> _buildExpressionParser(
    List<QueryLexToken> tokens,
    List<int> tokenIndexBySymbolOffset,
  ) {
    final builder = ExpressionBuilder<QueryExpressionNode>();

    builder.primitive(_termParser(tokens, tokenIndexBySymbolOffset));

    builder
      ..group().wrapper(
        _openParenParser(tokens, tokenIndexBySymbolOffset),
        _closeParenParser(tokens, tokenIndexBySymbolOffset),
        (open, value, close) {
          return _copyWithRange(value, open.range.start, close.range.end);
        },
      )
      ..group().prefix(_notParser(tokens, tokenIndexBySymbolOffset), (
        op,
        value,
      ) {
        return QueryNotNode(
          range: QueryRange(op.range.start, value.range.end),
          operand: value,
        );
      })
      ..group().left(_andParser(tokens, tokenIndexBySymbolOffset), (
        left,
        op,
        right,
      ) {
        return QueryAndNode(
          range: QueryRange(left.range.start, right.range.end),
          left: left,
          right: right,
          implicit: op.implicit,
        );
      })
      ..group().left(_orParser(tokens, tokenIndexBySymbolOffset), (
        left,
        op,
        right,
      ) {
        return QueryOrNode(
          range: QueryRange(left.range.start, right.range.end),
          left: left,
          right: right,
        );
      });

    return builder.build().end();
  }

  Parser<QueryExpressionNode> _termParser(
    List<QueryLexToken> tokens,
    List<int> tokenIndexBySymbolOffset,
  ) {
    return char("t").token().map((token) {
      final lex =
          tokens[tokenIndexBySymbolOffset[token.start]] as QueryTermLexToken;
      return QueryTermNode(
        range: lex.range,
        termIndex: lex.term.termIndex,
        isSelectorTerm: lex.term.isSelectorTerm,
      );
    });
  }

  Parser<QueryParenthesisLexToken> _openParenParser(
    List<QueryLexToken> tokens,
    List<int> tokenIndexBySymbolOffset,
  ) {
    return char("(").token().map((token) {
      return tokens[tokenIndexBySymbolOffset[token.start]]
          as QueryParenthesisLexToken;
    });
  }

  Parser<QueryParenthesisLexToken> _closeParenParser(
    List<QueryLexToken> tokens,
    List<int> tokenIndexBySymbolOffset,
  ) {
    return char(")").token().map((token) {
      return tokens[tokenIndexBySymbolOffset[token.start]]
          as QueryParenthesisLexToken;
    });
  }

  Parser<QueryOperatorLexToken> _notParser(
    List<QueryLexToken> tokens,
    List<int> tokenIndexBySymbolOffset,
  ) {
    return char("!").token().map((token) {
      return tokens[tokenIndexBySymbolOffset[token.start]]
          as QueryOperatorLexToken;
    });
  }

  Parser<QueryOperatorLexToken> _andParser(
    List<QueryLexToken> tokens,
    List<int> tokenIndexBySymbolOffset,
  ) {
    return char("&").token().map((token) {
      return tokens[tokenIndexBySymbolOffset[token.start]]
          as QueryOperatorLexToken;
    });
  }

  Parser<QueryOperatorLexToken> _orParser(
    List<QueryLexToken> tokens,
    List<int> tokenIndexBySymbolOffset,
  ) {
    return char("|").token().map((token) {
      return tokens[tokenIndexBySymbolOffset[token.start]]
          as QueryOperatorLexToken;
    });
  }

  QueryParseIssue _mapFailureToIssue({
    required String input,
    required List<QueryLexToken> tokens,
    required List<int> tokenIndexBySymbolOffset,
    required Failure failure,
  }) {
    final lastOperator = _lastOperatorIfTrailing(tokens);
    if (lastOperator != null) {
      return QueryParseIssue(
        code: QueryIssueCode.unexpectedToken,
        message: "Expected expression after operator",
        severity: QuerySeverity.warning,
        range: lastOperator.range,
      );
    }

    final unclosed = _unclosedParenthesis(tokens);
    if (unclosed != null) {
      return QueryParseIssue(
        code: QueryIssueCode.unclosedParenthesis,
        message: "Unclosed parenthesis",
        severity: QuerySeverity.warning,
        range: unclosed.range,
      );
    }

    if (tokenIndexBySymbolOffset.isEmpty) {
      return const QueryParseIssue(
        code: QueryIssueCode.unexpectedToken,
        message: "Unexpected token",
        severity: QuerySeverity.warning,
      );
    }

    final lastIndex = tokenIndexBySymbolOffset.length - 1;
    final position = failure.position.clamp(0, lastIndex);
    final token = tokens[tokenIndexBySymbolOffset[position]];
    return QueryParseIssue(
      code: QueryIssueCode.unexpectedToken,
      message: "Unexpected token",
      severity: QuerySeverity.warning,
      range: token.range,
      recoveryFragment: input.substring(token.range.start, token.range.end),
    );
  }

  QueryOperatorLexToken? _lastOperatorIfTrailing(List<QueryLexToken> tokens) {
    if (tokens.isEmpty) {
      return null;
    }
    final last = tokens.last;
    if (last case QueryOperatorLexToken()) {
      return last;
    }
    return null;
  }

  QueryParenthesisLexToken? _unclosedParenthesis(List<QueryLexToken> tokens) {
    final stack = <QueryParenthesisLexToken>[];
    for (final token in tokens) {
      if (token case QueryParenthesisLexToken(isOpen: true)) {
        stack.add(token);
      } else if (token case QueryParenthesisLexToken(isOpen: false)) {
        if (stack.isNotEmpty) {
          stack.removeLast();
        }
      }
    }
    if (stack.isEmpty) {
      return null;
    }
    return stack.last;
  }

  _SerializedTokenStream _serializeTokens(List<QueryLexToken> tokens) {
    final buffer = StringBuffer();
    final tokenIndexBySymbolOffset = <int>[];

    for (var index = 0; index < tokens.length; index += 1) {
      final token = tokens[index];
      if (token is QueryTermLexToken) {
        buffer.write("t");
        tokenIndexBySymbolOffset.add(index);
        continue;
      }
      if (token is QueryOperatorLexToken) {
        final symbol = switch (token.operatorType) {
          QueryOperatorType.and => "&",
          QueryOperatorType.or => "|",
          QueryOperatorType.not => "!",
        };
        buffer.write(symbol);
        tokenIndexBySymbolOffset.add(index);
        continue;
      }
      if (token is QueryParenthesisLexToken) {
        buffer.write(token.isOpen ? "(" : ")");
        tokenIndexBySymbolOffset.add(index);
      }
    }

    return _SerializedTokenStream(
      symbols: buffer.toString(),
      tokenIndexBySymbolOffset: List.unmodifiable(tokenIndexBySymbolOffset),
    );
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

class _SerializedTokenStream {
  final String symbols;
  final List<int> tokenIndexBySymbolOffset;

  const _SerializedTokenStream({
    required this.symbols,
    required this.tokenIndexBySymbolOffset,
  });
}

class _AtomParseOutput {
  final List<QuerySelectorMatch> selectorMatches;
  final List<QueryTextTerm> textTerms;
  final List<QueryParseIssue> issues;

  const _AtomParseOutput({
    required this.selectorMatches,
    required this.textTerms,
    required this.issues,
  });
}

class _AtomScanOutcome {
  const _AtomScanOutcome({
    required this.nextIndex,
    this.match,
    this.fallbackTerm,
  }) : assert(match != null || fallbackTerm != null);

  final int nextIndex;
  final QuerySelectorMatch? match;
  final QueryTextTerm? fallbackTerm;
}
