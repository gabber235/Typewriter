import "dart:async";
import "package:flutter/foundation.dart";
import "package:flutter/widgets.dart";
import "package:freezed_annotation/freezed_annotation.dart";

part "models.freezed.dart";

@freezed
abstract class SearchParsedSelector with _$SearchParsedSelector {
  const factory SearchParsedSelector({
    required String selectorId,
    required String key,
    String? value,
  }) = _SearchParsedSelector;
}

enum SearchSelectorOperator { and, or }

sealed class SearchSelectorExpression {
  const SearchSelectorExpression();
}

final class SearchSelectorLeafExpression extends SearchSelectorExpression {
  const SearchSelectorLeafExpression(this.selector);

  final SearchParsedSelector selector;

  @override
  bool operator ==(Object other) {
    return other is SearchSelectorLeafExpression && other.selector == selector;
  }

  @override
  int get hashCode => selector.hashCode;
}

final class SearchSelectorBinaryExpression extends SearchSelectorExpression {
  const SearchSelectorBinaryExpression({
    required this.operator,
    required this.left,
    required this.right,
  });

  final SearchSelectorOperator operator;
  final SearchSelectorExpression left;
  final SearchSelectorExpression right;

  @override
  bool operator ==(Object other) {
    return other is SearchSelectorBinaryExpression &&
        other.operator == operator &&
        other.left == left &&
        other.right == right;
  }

  @override
  int get hashCode => Object.hash(operator, left, right);
}

final class SearchSelectorNotExpression extends SearchSelectorExpression {
  const SearchSelectorNotExpression(this.expression);

  final SearchSelectorExpression expression;

  @override
  bool operator ==(Object other) {
    return other is SearchSelectorNotExpression &&
        other.expression == expression;
  }

  @override
  int get hashCode => expression.hashCode;
}

@freezed
abstract class SearchQueryContext with _$SearchQueryContext {
  const factory SearchQueryContext({
    required String normalizedQuery,
    required List<SearchParsedSelector> selectors,
    SearchSelectorExpression? selectorExpression,
  }) = _SearchQueryContext;
}

enum SearchGuidanceVisibility { always, emptyOnly }

@freezed
abstract class SearchGuidance with _$SearchGuidance {
  const factory SearchGuidance({
    required String id,
    required String title,
    String? description,
    @Default(SearchGuidanceVisibility.emptyOnly)
    SearchGuidanceVisibility visibility,
    @Default(0) int priority,
  }) = _SearchGuidance;
}

enum SearchErrorSeverity { warning, error }

@freezed
abstract class SearchErrorSummary with _$SearchErrorSummary {
  const factory SearchErrorSummary({
    required String id,
    required String message,
    required SearchErrorSeverity severity,
    String? sourceLabel,
  }) = _SearchErrorSummary;
}

enum SearchSourceStatus { idle, loading, ready, error }

@freezed
abstract class SearchSourceSnapshot with _$SearchSourceSnapshot {
  const factory SearchSourceSnapshot({
    required SearchSourceStatus status,
    required List<SearchNode> nodes,
    @Default({}) Map<Type, SearchAction> actions,
    @Default(<SearchGuidance>[]) List<SearchGuidance> guidance,
    @Default(<SearchErrorSummary>[]) List<SearchErrorSummary> errorSummaries,
  }) = _SearchSourceSnapshot;

  factory SearchSourceSnapshot.idle({
    List<SearchNode> nodes = const [],
    Map<Type, SearchAction> actions = const {},
    List<SearchGuidance> guidance = const [],
  }) => SearchSourceSnapshot(
    status: SearchSourceStatus.idle,
    nodes: nodes,
    actions: actions,
    guidance: guidance,
  );

  factory SearchSourceSnapshot.loading({
    List<SearchNode> nodes = const [],
    Map<Type, SearchAction> actions = const {},
    List<SearchGuidance> guidance = const [],
    List<SearchErrorSummary> errorSummaries = const [],
  }) => SearchSourceSnapshot(
    status: SearchSourceStatus.loading,
    nodes: nodes,
    actions: actions,
    guidance: guidance,
    errorSummaries: errorSummaries,
  );

  factory SearchSourceSnapshot.ready({
    required List<SearchNode> nodes,
    Map<Type, SearchAction> actions = const {},
    List<SearchGuidance> guidance = const [],
    List<SearchErrorSummary> errorSummaries = const [],
  }) => SearchSourceSnapshot(
    status: SearchSourceStatus.ready,
    nodes: nodes,
    actions: actions,
    guidance: guidance,
    errorSummaries: errorSummaries,
  );

  factory SearchSourceSnapshot.error({
    required List<SearchErrorSummary> errorSummaries,
    List<SearchNode> nodes = const [],
    Map<Type, SearchAction> actions = const {},
    List<SearchGuidance> guidance = const [],
  }) {
    assert(
      errorSummaries.any((s) => s.severity == SearchErrorSeverity.error),
      "Error snapshot requires at least one error severity summary",
    );
    return SearchSourceSnapshot(
      status: SearchSourceStatus.error,
      nodes: nodes,
      actions: actions,
      guidance: guidance,
      errorSummaries: errorSummaries,
    );
  }
}

@freezed
sealed class SearchNode with _$SearchNode {
  const factory SearchNode.section({
    required String id,
    required String title,
    String? subtitle,
    @Default(<SearchNode>[]) List<SearchNode> children,
  }) = SearchSectionNode;

  const factory SearchNode.result({required SearchResult result}) =
      SearchResultNode;
}

extension SearchNodes on List<SearchNode> {
  List<SearchResult> findResults(Set<String> resultIds) {
    final wanted = resultIds.toSet();
    final results = <SearchResult>[];
    final stack = [];

    for (var i = length - 1; i >= 0; i--) {
      stack.add(this[i]);
    }

    while (stack.isNotEmpty && wanted.isNotEmpty) {
      final node = stack.removeLast();

      switch (node) {
        case SearchSectionNode():
          for (var i = node.children.length - 1; i >= 0; i--) {
            stack.add(node.children[i]);
          }
        case SearchResultNode():
          if (wanted.remove(node.result.id)) {
            results.add(node.result);
          }
      }
    }

    return results;
  }

  Iterable<SearchNode> walk() sync* {
    final stack = [];

    for (var i = length - 1; i >= 0; i--) {
      stack.add(this[i]);
    }

    while (stack.isNotEmpty) {
      final node = stack.removeLast();

      yield node;

      switch (node) {
        case SearchSectionNode():
          for (var i = node.children.length - 1; i >= 0; i--) {
            stack.add(node.children[i]);
          }
        case SearchResultNode():
      }
    }
  }
}

@freezed
abstract class SearchResultType with _$SearchResultType {
  const factory SearchResultType({
    required String id,
    required String rowRendererId,
    String? previewRendererId,
    String? label,
  }) = _SearchResultType;
}

@freezed
abstract class SearchResult with _$SearchResult {
  const factory SearchResult({
    required String id,
    required SearchResultType type,
    required Object payload,
    @Default([]) List<Type> actions,
    String? title,
    String? subtitle,
    @Default(false) bool isStale,
  }) = _SearchResult;
}

enum SearchActionBatchMode { none, aggregate, repeated }

abstract class SearchAction {
  const SearchAction();

  String get label;
  int get priority;
  String? get icon => null;
  Color? get color => null;
  ShortcutActivator? get shortcut => null;
}

abstract class SingleSearchAction extends SearchAction {
  Future<SearchActionResult> execute(SearchResult result);
}

abstract class RepeatedSearchAction extends SearchAction {
  Future<SearchActionResult> execute(SearchResult result);
}

abstract class BatchSearchAction extends SearchAction {
  Future<SearchActionResult> executeBatch(List<SearchResult> results);
}

@freezed
abstract class SearchActionResult with _$SearchActionResult {
  const factory SearchActionResult.completed({
    @Default(SearchActionEffect.close()) SearchActionEffect effect,
  }) = SearchActionResultCompleted;

  const factory SearchActionResult.failed({
    required String message,
    @Default(SearchActionEffect.refresh()) SearchActionEffect effect,
  }) = SearchActionResultFailed;
}

extension SearchActionResults on List<SearchActionResult> {
  SearchActionResult merge() {
    if (isEmpty) {
      return SearchActionResult.completed();
    }

    final effects = map((r) => r.effect).toSet();
    final messages = whereType<SearchActionResultFailed>()
        .map((r) => r.message)
        .toSet();

    final effect = effects.merge();

    if (messages.isEmpty) {
      return SearchActionResult.completed(effect: effect);
    }

    final message = messages.length == 1
        ? messages.first
        : "Search failed: ${messages.join(", ")}";

    return SearchActionResult.failed(message: message, effect: effect);
  }
}

@freezed
abstract class SearchActionEffect with _$SearchActionEffect {
  const factory SearchActionEffect.updateQuery({required String updateQuery}) =
      SearchActionUpdateQuery;

  const factory SearchActionEffect.refresh() = SearchActionRefresh;

  const factory SearchActionEffect.close() = SearchActionClose;
}

extension SearchActionEffects on Set<SearchActionEffect> {
  SearchActionEffect merge() {
    if (isEmpty) {
      return SearchActionEffect.close();
    }

    final updates = whereType<SearchActionUpdateQuery>().toList();
    if (updates.isNotEmpty) {
      return updates.first;
    }

    final refreshes = any((e) => e is SearchActionRefresh);
    if (refreshes) {
      return SearchActionEffect.refresh();
    }

    return SearchActionEffect.close();
  }
}

enum SearchActionSubmitResult {
  submitted,
  busy,
  invalidSelection,
  actionNotFound,
}

@freezed
sealed class SearchActionState with _$SearchActionState {
  const factory SearchActionState.idle() = SearchActionIdle;

  const factory SearchActionState.running({
    required Type action,
    required Set<String> resultIds,
  }) = SearchActionRunning;

  const factory SearchActionState.completed({
    required Type action,
    required Set<String> resultIds,
  }) = SearchActionCompleted;

  const factory SearchActionState.failed({
    required Type action,
    required Set<String> resultIds,
    required String message,
  }) = SearchActionFailed;
}

@freezed
abstract class SearchPreviewRequest with _$SearchPreviewRequest {
  const factory SearchPreviewRequest({
    required String resultId,
    SearchQueryContext? queryContext,
  }) = _SearchPreviewRequest;
}

@freezed
abstract class SearchPreviewRequestResult with _$SearchPreviewRequestResult {
  const factory SearchPreviewRequestResult.data({required Object data}) =
      SearchPreviewRequestResultData;

  const factory SearchPreviewRequestResult.error({required String message}) =
      SearchPreviewRequestResultError;
}

enum SearchSelectionMode { single, multiple }
