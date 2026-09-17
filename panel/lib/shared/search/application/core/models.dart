import "dart:async";

import "package:collection/collection.dart";
import "package:flutter/foundation.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "models.freezed.dart";

/// Immutable contracts shared by search sources, controllers, and widgets.
///
/// Sources publish a [SearchSourceSnapshot] containing a hierarchical
/// [SearchNode] tree. Controllers turn raw input into [SearchQueryContext] and
/// coordinate interactions against result IDs still present in that tree.

/// A selector extracted from the normalized query.
@freezed
abstract class SearchParsedSelector with _$SearchParsedSelector {
  @Assert("selectorId != \"\"", "Selector ID must not be empty.")
  @Assert("key != \"\"", "Key must not be empty.")
  const factory SearchParsedSelector({
    required String selectorId,
    required String key,
    String? value,
  }) = _SearchParsedSelector;
}

enum SearchSelectorValidationStatus { accepted, rejected, unresolved }

@immutable
class SearchSelectorValidation {
  const SearchSelectorValidation({
    required this.selectorId,
    required this.value,
    required this.status,
  });

  final String selectorId;
  final String value;
  final SearchSelectorValidationStatus status;
}

@immutable
class SearchSelectorCompletionRequest {
  const SearchSelectorCompletionRequest({
    required this.selectorId,
    required this.partial,
    this.scope,
  });

  final String selectorId;
  final String partial;
  final SearchSelectorExpression? scope;

  @override
  bool operator ==(Object other) =>
      other is SearchSelectorCompletionRequest &&
      other.selectorId == selectorId &&
      other.partial == partial &&
      other.scope == scope;

  @override
  int get hashCode => Object.hash(selectorId, partial, scope);
}

@immutable
class SearchSelectorCompletionResult {
  const SearchSelectorCompletionResult({
    this.values = const [],
    this.exhaustive = false,
    this.warning,
  });

  final List<String> values;
  final bool exhaustive;
  final String? warning;
}

/// Boolean operators preserved in the parsed selector expression.
enum SearchSelectorOperator { and, or }

/// The selector expression used by sources that need boolean query semantics.
@freezed
sealed class SearchSelectorExpression with _$SearchSelectorExpression {
  const factory SearchSelectorExpression.leaf(SearchParsedSelector selector) =
      SearchSelectorLeafExpression;

  const factory SearchSelectorExpression.binary({
    required SearchSelectorOperator operator,
    required SearchSelectorExpression left,
    required SearchSelectorExpression right,
  }) = SearchSelectorBinaryExpression;

  const factory SearchSelectorExpression.not(
    SearchSelectorExpression expression,
  ) = SearchSelectorNotExpression;
}

/// Parsed query state passed from [SourceController] to a [SearchSource].
@freezed
abstract class SearchQueryContext with _$SearchQueryContext {
  const factory SearchQueryContext({
    required String normalizedQuery,
    required List<SearchParsedSelector> selectors,
    @Default(<String>[]) List<String> terms,
    SearchSelectorExpression? selectorExpression,
  }) = _SearchQueryContext;

  static const SearchQueryContext empty = SearchQueryContext(
    normalizedQuery: "",
    terms: [],
    selectors: [],
    selectorExpression: null,
  );
}

/// Controls whether guidance remains visible with results.
enum SearchGuidanceVisibility { always, emptyOnly }

/// Non error information a source wants the search UI to display.
@freezed
abstract class SearchGuidance with _$SearchGuidance {
  @Assert("id != \"\"", "ID must not be empty.")
  @Assert("title != \"\"", "Title must not be empty.")
  const factory SearchGuidance({
    required String id,
    required String title,
    String? description,
    @Default(SearchGuidanceVisibility.emptyOnly)
    SearchGuidanceVisibility visibility,
    @Default(0) int priority,
  }) = _SearchGuidance;
}

/// Severity presented for a source diagnostic.
enum SearchErrorSeverity { warning, error }

/// A source scoped warning or error rendered above the result tree.
@freezed
abstract class SearchErrorSummary with _$SearchErrorSummary {
  @Assert("id != \"\"", "ID must not be empty.")
  @Assert("message != \"\"", "Message must not be empty.")
  const factory SearchErrorSummary({
    required String id,
    required String message,
    required SearchErrorSeverity severity,
    String? sourceLabel,
  }) = _SearchErrorSummary;
}

/// Coarse lifecycle state represented by a source snapshot.
enum SearchSourceStatus { idle, loading, ready, error }

/// Immutable source projection consumed by search widgets.
///
/// Nodes may remain available while [status] is loading or error, allowing
/// decorators to retain stale results while exposing current feedback.
@freezed
abstract class SearchSourceSnapshot with _$SearchSourceSnapshot {
  const factory SearchSourceSnapshot({
    required SearchSourceStatus status,
    required List<SearchNode> nodes,
    @Default(<SearchGuidance>[]) List<SearchGuidance> guidance,
    @Default(<SearchErrorSummary>[]) List<SearchErrorSummary> errorSummaries,
    @Default(<SearchSelectorValidation>[])
    List<SearchSelectorValidation> selectorValidations,
  }) = _SearchSourceSnapshot;

  factory SearchSourceSnapshot.idle({
    List<SearchNode> nodes = const [],
    List<SearchGuidance> guidance = const [],
    List<SearchSelectorValidation> selectorValidations = const [],
  }) => SearchSourceSnapshot(
    status: SearchSourceStatus.idle,
    nodes: nodes,
    guidance: guidance,
    selectorValidations: selectorValidations,
  );

  factory SearchSourceSnapshot.loading({
    List<SearchNode> nodes = const [],
    List<SearchGuidance> guidance = const [],
    List<SearchErrorSummary> errorSummaries = const [],
    List<SearchSelectorValidation> selectorValidations = const [],
  }) => SearchSourceSnapshot(
    status: SearchSourceStatus.loading,
    nodes: nodes,
    guidance: guidance,
    errorSummaries: errorSummaries,
    selectorValidations: selectorValidations,
  );

  factory SearchSourceSnapshot.ready({
    required List<SearchNode> nodes,
    List<SearchGuidance> guidance = const [],
    List<SearchErrorSummary> errorSummaries = const [],
    List<SearchSelectorValidation> selectorValidations = const [],
  }) => SearchSourceSnapshot(
    status: SearchSourceStatus.ready,
    nodes: nodes,
    guidance: guidance,
    errorSummaries: errorSummaries,
    selectorValidations: selectorValidations,
  );

  factory SearchSourceSnapshot.error({
    required List<SearchErrorSummary> errorSummaries,
    List<SearchNode> nodes = const [],
    List<SearchGuidance> guidance = const [],
    List<SearchSelectorValidation> selectorValidations = const [],
  }) {
    assert(
      errorSummaries.any((s) => s.severity == SearchErrorSeverity.error),
      "Error snapshot requires at least one error severity summary",
    );
    return SearchSourceSnapshot(
      status: SearchSourceStatus.error,
      nodes: nodes,
      guidance: guidance,
      errorSummaries: errorSummaries,
      selectorValidations: selectorValidations,
    );
  }
}

/// A result tree node. Sections may contain nested sections and results.
///
/// Child order is significant. Sources and tree builders preserve it for
/// display, traversal, ranking tie breaks, and stable row identity.
@freezed
sealed class SearchNode with _$SearchNode {
  @Assert("id != \"\"", "ID must not be empty.")
  @Assert("title != \"\"", "Title must not be empty.")
  const factory SearchNode.section({
    required String id,
    required String title,
    String? subtitle,
    @Default(<SearchNode>[]) List<SearchNode> children,
  }) = SearchSectionNode;

  const factory SearchNode.result({required SearchResult result}) =
      SearchResultNode;
}

/// Traversal helpers that preserve depth first, source order.
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

  SearchResult? get firstResult {
    return walk()
        .whereType<SearchResultNode>()
        .map((node) => node.result)
        .firstOrNull;
  }
}

/// Rendering identity for a [SearchResult].
@freezed
abstract class SearchResultType with _$SearchResultType {
  @Assert("id != \"\"", "ID must not be empty.")
  @Assert("rowRendererId != \"\"", "Row renderer ID must not be empty.")
  @Assert(
    "previewRendererId == null || previewRendererId != \"\"",
    "Preview renderer ID must be null or nonempty.",
  )
  const factory SearchResultType({
    required String id,
    required String rowRendererId,
    String? previewRendererId,
    String? label,
  }) = _SearchResultType;
}

/// Search data rendered as a row and optionally a preview.
@freezed
abstract class SearchResult with _$SearchResult {
  @Assert("id != \"\"", "ID must not be empty.")
  const factory SearchResult({
    required String id,
    required SearchResultType type,
    required Object payload,
    String? title,
    String? subtitle,
    @Default(false) bool isStale,
  }) = _SearchResult;
}

/// Controller instruction emitted after a command completes.
@freezed
abstract class SearchSurfaceEffect with _$SearchSurfaceEffect {
  const factory SearchSurfaceEffect.updateQuery({required String updateQuery}) =
      SearchSurfaceUpdateQuery;

  const factory SearchSurfaceEffect.refresh() = SearchSurfaceRefresh;

  const factory SearchSurfaceEffect.close() = SearchSurfaceClose;
}

/// Resolves multiple controller effects into one deterministic instruction.
///
/// Query updates take precedence over refresh, refresh takes precedence over
/// close, and an empty set closes the search surface.
extension SearchSurfaceEffects on Set<SearchSurfaceEffect> {
  SearchSurfaceEffect merge() {
    if (isEmpty) {
      return SearchSurfaceEffect.close();
    }

    final updates = whereType<SearchSurfaceUpdateQuery>().toList();
    if (updates.isNotEmpty) {
      return updates.first;
    }

    final refreshes = any((e) => e is SearchSurfaceRefresh);
    if (refreshes) {
      return SearchSurfaceEffect.refresh();
    }

    return SearchSurfaceEffect.close();
  }
}

abstract interface class SearchHostEffect {}

/// Identifies a result whose detail should be loaded.
@freezed
abstract class SearchPreviewRequest with _$SearchPreviewRequest {
  @Assert("resultId != \"\"", "Result ID must not be empty.")
  const factory SearchPreviewRequest({
    required String resultId,
    SearchQueryContext? queryContext,
  }) = _SearchPreviewRequest;
}

/// Success or user visible failure from a preview request.
@freezed
abstract class SearchPreviewRequestResult with _$SearchPreviewRequestResult {
  const factory SearchPreviewRequestResult.data({required Object data}) =
      SearchPreviewRequestResultData;

  @Assert("message != \"\"", "Message must not be empty.")
  const factory SearchPreviewRequestResult.error({required String message}) =
      SearchPreviewRequestResultError;
}

/// Selection behavior supported by the actions in the current snapshot.
enum SearchSelectionMode { single, multiple }

class SearchHostEffectExecutor<E extends SearchHostEffect>(
  final FutureOr<void> Function(E) onCall,
) {
  Type get effectType => E;

  bool accepts(SearchHostEffect effect) => effect is E;

  FutureOr<void> call(SearchHostEffect effect) => onCall(effect as E);
}
