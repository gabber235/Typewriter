import "package:collection/collection.dart";
import "package:typewriter_panel/typewriter_panel.dart";

QueryCursorContext resolveQueryCursorContext(
  List<QueryLexerToken> tokens,
  String input,
  int cursorOffset,
) {
  final clampedCursor = cursorOffset.clamp(0, input.length);

  final token = tokens.firstWhereOrNull(
    (token) => switch (token) {
      QueryLexerOperatorToken() =>
        token.operatorRange?.containsOffset(clampedCursor) ?? false,
      QueryLexerNegationToken() => token.operatorRange.containsOffset(
        clampedCursor,
      ),
      _ => token.range.containsOffset(clampedCursor),
    },
  );

  switch (token) {
    case null:
      final range = _wordRange(input, clampedCursor);
      return UnknownCursorContext(
        cursorOffset: clampedCursor,
        activeRange: range,
        partial: _slice(input, range, clampedCursor),
        side: _side(tokens, clampedCursor),
      );
    case QueryLexerKeyValueSelectorToken():
      final valueRange = token.valueRange;
      if (valueRange != null && valueRange.containsOffset(clampedCursor)) {
        final partial = _slice(input, valueRange, clampedCursor);
        return SelectorValueCursorContext(
          cursorOffset: clampedCursor,
          activeRange: valueRange,
          selectorId: token.selectorId,
          partialValue: partial,
          keyRange: token.keyRange,
          valueRange: valueRange,
        );
      }
      if (valueRange == null && token.keyRange.isAtEnd(clampedCursor)) {
        return SelectorValueCursorContext(
          cursorOffset: clampedCursor,
          activeRange: QueryRange(clampedCursor, clampedCursor),
          selectorId: token.selectorId,
          partialValue: "",
          keyRange: token.keyRange,
          valueRange: valueRange,
        );
      }
      return SelectorKeyCursorContext(
        cursorOffset: clampedCursor,
        activeRange: token.range,
        partialKey: _slice(input, token.range, clampedCursor),
      );
    case QueryLexerSelectorToken():
      return SelectorKeyCursorContext(
        cursorOffset: clampedCursor,
        activeRange: token.range,
        partialKey: _slice(input, token.range, clampedCursor),
      );
    case QueryLexerOperatorToken():
      return OperatorCursorContext(
        cursorOffset: clampedCursor,
        activeRange: token.operatorRange!,
        partialOperator: _slice(input, token.operatorRange!, clampedCursor),
      );
    case QueryLexerNegationToken():
      return OperatorCursorContext(
        cursorOffset: clampedCursor,
        activeRange: token.operatorRange,
        partialOperator: _slice(input, token.operatorRange, clampedCursor),
      );
  }
}

const _spaceCodeUnit = 32;

QueryRange _wordRange(String input, int cursorOffset) {
  final spaceIndices = input.codeUnits.indexed
      .where((e) => e.$2 == _spaceCodeUnit)
      .map((e) => e.$1)
      .toList();
  final end =
      spaceIndices.firstWhereOrNull((i) => cursorOffset <= i) ?? input.length;
  final start = spaceIndices.lastWhereOrNull((i) => i < cursorOffset) ?? -1;
  return QueryRange(start + 1, end);
}

String _slice(String input, QueryRange range, int cursorOffset) {
  final end = cursorOffset.clamp(range.start, range.end);
  return input.substring(range.start, end);
}

QuerySide _side(List<QueryLexerToken> tokens, int cursorOffset) {
  if (tokens.isEmpty) {
    return QuerySide.before;
  }

  final min = tokens.minByOrNull((t) => t.range.start)!.range.start;
  final max = tokens.maxByOrNull((t) => t.range.end)!.range.end;
  return min < cursorOffset && cursorOffset < max
      ? QuerySide.expression
      : cursorOffset < min
      ? QuerySide.before
      : QuerySide.after;
}
