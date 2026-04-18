import "package:typewriter_panel/logic/search/query/query_models.dart";
import "package:typewriter_panel/logic/search/query/query_spans.dart";

QueryCursorContext resolveQueryCursorContext(
  QueryParseResult result,
  String input,
  int cursorOffset,
) {
  final clampedCursor = cursorOffset.clamp(0, input.length);

  for (final match
      in result.selectorMatches.whereType<KeyValueSelectorMatch>()) {
    final valueRange = match.valueRange;
    if (valueRange != null && _contains(valueRange, clampedCursor)) {
      final partial = _slice(input, valueRange, clampedCursor);
      return SelectorValueCursorContext(
        cursorOffset: clampedCursor,
        activeRange: valueRange,
        selectorId: match.selectorId,
        partialValue: partial,
        keyRange: match.keyRange,
        valueRange: valueRange,
      );
    }
  }

  for (final match
      in result.selectorMatches.whereType<KeyValueSelectorMatch>()) {
    if (_contains(match.keyRange, clampedCursor)) {
      final partial = _slice(input, match.keyRange, clampedCursor);
      return SelectorKeyCursorContext(
        cursorOffset: clampedCursor,
        activeRange: match.keyRange,
        partialKey: partial,
      );
    }
  }

  for (final match in result.selectorMatches.whereType<SymbolSelectorMatch>()) {
    if (_contains(match.tokenRange, clampedCursor)) {
      final partial = _slice(input, match.tokenRange, clampedCursor);
      return SelectorKeyCursorContext(
        cursorOffset: clampedCursor,
        activeRange: match.tokenRange,
        partialKey: partial,
      );
    }
  }

  final operatorRange = _findOperatorRange(input, clampedCursor);
  if (operatorRange != null) {
    final partial = _slice(input, operatorRange, clampedCursor);
    return OperatorCursorContext(
      cursorOffset: clampedCursor,
      activeRange: operatorRange,
      partialOperator: partial,
    );
  }

  for (final term in result.textTerms) {
    if (_contains(term.range, clampedCursor)) {
      final partial = _slice(input, term.range, clampedCursor);
      return TextTermCursorContext(
        cursorOffset: clampedCursor,
        activeRange: term.range,
        partialText: partial,
      );
    }
  }

  return UnknownCursorContext(
    cursorOffset: clampedCursor,
    activeRange: QueryRange(clampedCursor, clampedCursor),
  );
}

QueryRange? _findOperatorRange(String input, int cursorOffset) {
  if (input.isEmpty) {
    return null;
  }

  final at = cursorOffset == input.length ? cursorOffset - 1 : cursorOffset;
  if (at < 0 || at >= input.length) {
    return null;
  }

  if (input.startsWith("&&", at) ||
      (at > 0 && input.startsWith("&&", at - 1))) {
    final start = input.startsWith("&&", at) ? at : at - 1;
    return QueryRange(start, start + 2);
  }

  if (input.startsWith("||", at) ||
      (at > 0 && input.startsWith("||", at - 1))) {
    final start = input.startsWith("||", at) ? at : at - 1;
    return QueryRange(start, start + 2);
  }

  if (input[at] == "!") {
    return QueryRange(at, at + 1);
  }

  var start = at;
  while (start > 0 && !_isDelimiter(input[start - 1])) {
    start -= 1;
  }

  var end = at + 1;
  while (end < input.length && !_isDelimiter(input[end])) {
    end += 1;
  }

  final token = input.substring(start, end).toLowerCase();
  if (token == "and" || token == "or" || token == "not") {
    return QueryRange(start, end);
  }

  return null;
}

String _slice(String input, QueryRange range, int cursorOffset) {
  final end = cursorOffset.clamp(range.start, range.end);
  return input.substring(range.start, end);
}

bool _contains(QueryRange range, int offset) {
  return offset >= range.start && offset <= range.end;
}

bool _isDelimiter(String value) {
  return value.trim().isEmpty || value == "(" || value == ")";
}
