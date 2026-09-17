// ignore_for_file: prefer_initializing_formals

import "dart:async";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "search_interaction.freezed.dart";

@freezed
abstract class SearchCommandId with _$SearchCommandId {
  @Assert("value != \"\"", "Command ID must not be empty.")
  const factory SearchCommandId(String value) = _SearchCommandId;
}

@freezed
abstract class SearchCommandPresentation with _$SearchCommandPresentation {
  @Assert("label != \"\"", "Command label must not be empty.")
  const factory SearchCommandPresentation({
    required String label,
    @Default(0) int priority,
    String? icon,
    Color? color,
    ShortcutActivator? shortcut,
  }) = _SearchCommandPresentation;
}

@freezed
sealed class SearchCommandState with _$SearchCommandState {
  const factory SearchCommandState.hidden() = SearchCommandHidden;

  @Assert("reason != \"\"", "Disabled reason must not be empty.")
  const factory SearchCommandState.disabled(String reason) =
      SearchCommandDisabled;

  const factory SearchCommandState.enabled() = SearchCommandEnabled;
}

@freezed
abstract class SearchCommandTarget with _$SearchCommandTarget {
  @Assert("selection.length > 0", "Selection must not be empty.")
  const factory SearchCommandTarget({
    required SearchResult primary,
    required List<SearchResult> selection,
    required SearchQueryContext query,
  }) = _SearchCommandTarget;
}

@freezed
abstract class SearchResultMatcher<P extends Object>
    with _$SearchResultMatcher<P> {
  const factory SearchResultMatcher(SearchResultType type) =
      _SearchResultMatcher<P>;

  const SearchResultMatcher._();

  P? match(SearchResult result) {
    if (result.type != type || result.payload is! P) return null;
    return result.payload as P;
  }
}

enum SearchCommandBatchMode { single, repeated, batch, custom }

typedef SearchCommandEvaluator<P extends Object> = SearchCommandState Function(
  P value,
  SearchCommandTarget target,
);
typedef SearchCommandExecutor<P extends Object> =
    Future<SearchCommandResult> Function(
      SearchCommandExecutionContext context,
      P value,
      SearchCommandTarget target,
    );
typedef SearchBatchCommandEvaluator<P extends Object> =
    SearchCommandState Function(List<P> values, SearchCommandTarget target);
typedef SearchBatchCommandExecutor<P extends Object> =
    Future<SearchCommandResult> Function(
      SearchCommandExecutionContext context,
      List<P> values,
      SearchCommandTarget target,
    );

abstract interface class SearchCommand {
  SearchCommandId get id;
  SearchCommandPresentation get presentation;
  Iterable<Listenable> get dependencies;
  SearchCommandBatchMode get batchMode;

  SearchCommandState evaluate(SearchCommandTarget target);

  Future<SearchCommandResult> execute(
    SearchCommandExecutionContext context,
    SearchCommandTarget target,
  );

  static SearchCommand single<P extends Object>({
    required SearchCommandId id,
    required SearchCommandPresentation presentation,
    required SearchResultMatcher<P> matcher,
    required SearchCommandExecutor<P> execute,
    Iterable<Listenable> dependencies = const [],
    SearchCommandEvaluator<P>? evaluate,
  }) => SingleSearchCommand<P>(
    id: id,
    presentation: presentation,
    matcher: matcher,
    dependencies: dependencies,
    evaluate: evaluate,
    execute: execute,
  );

  static SearchCommand repeated<P extends Object>({
    required SearchCommandId id,
    required SearchCommandPresentation presentation,
    required SearchResultMatcher<P> matcher,
    required SearchCommandExecutor<P> execute,
    Iterable<Listenable> dependencies = const [],
    SearchCommandEvaluator<P>? evaluate,
  }) => RepeatedSearchCommand<P>(
    id: id,
    presentation: presentation,
    matcher: matcher,
    dependencies: dependencies,
    evaluate: evaluate,
    execute: execute,
  );

  static SearchCommand batch<P extends Object>({
    required SearchCommandId id,
    required SearchCommandPresentation presentation,
    required SearchResultMatcher<P> matcher,
    required SearchBatchCommandExecutor<P> execute,
    Iterable<Listenable> dependencies = const [],
    SearchBatchCommandEvaluator<P>? evaluate,
  }) => BatchSearchCommand<P>(
    id: id,
    presentation: presentation,
    matcher: matcher,
    dependencies: dependencies,
    evaluate: evaluate,
    execute: execute,
  );

  static SearchCommand custom({
    required SearchCommandId id,
    required SearchCommandPresentation presentation,
    required SearchCommandState Function(SearchCommandTarget target) evaluate,
    required Future<SearchCommandResult> Function(
      SearchCommandExecutionContext context,
      SearchCommandTarget target,
    )
    execute,
    Iterable<Listenable> dependencies = const [],
  }) => CustomSearchCommand(
    id: id,
    presentation: presentation,
    dependencies: dependencies,
    evaluate: evaluate,
    execute: execute,
  );
}

abstract base class _TypedSearchCommand<P extends Object>
    implements SearchCommand {
  _TypedSearchCommand({
    required this.id,
    required this.presentation,
    required this.matcher,
    Iterable<Listenable> dependencies = const [],
  }) : dependencies = List.unmodifiable(dependencies);

  @override
  final SearchCommandId id;
  @override
  final SearchCommandPresentation presentation;
  final SearchResultMatcher<P> matcher;
  @override
  final List<Listenable> dependencies;

  List<P>? matchAll(SearchCommandTarget target) {
    final values = <P>[];
    for (final result in target.selection) {
      final value = matcher.match(result);
      if (value == null) return null;
      values.add(value);
    }
    return values;
  }
}

final class SingleSearchCommand<P extends Object>
    extends _TypedSearchCommand<P> {
  SingleSearchCommand({
    required super.id,
    required super.presentation,
    required super.matcher,
    required SearchCommandExecutor<P> execute,
    super.dependencies,
    SearchCommandEvaluator<P>? evaluate,
  }) : _evaluate = evaluate,
       _execute = execute;

  final SearchCommandEvaluator<P>? _evaluate;
  final SearchCommandExecutor<P> _execute;

  @override
  SearchCommandBatchMode get batchMode => SearchCommandBatchMode.single;

  @override
  SearchCommandState evaluate(SearchCommandTarget target) {
    if (target.selection.length != 1) {
      return const SearchCommandState.hidden();
    }
    final value = matcher.match(target.primary);
    if (value == null) return const SearchCommandState.hidden();
    return _evaluate?.call(value, target) ?? const SearchCommandState.enabled();
  }

  @override
  Future<SearchCommandResult> execute(
    SearchCommandExecutionContext context,
    SearchCommandTarget target,
  ) {
    final value = matcher.match(target.primary);
    if (value == null || target.selection.length != 1) {
      return Future.value(
        const SearchCommandResult.failed(message: "Invalid search result"),
      );
    }
    return _execute(context, value, target);
  }
}

final class RepeatedSearchCommand<P extends Object>
    extends _TypedSearchCommand<P> {
  RepeatedSearchCommand({
    required super.id,
    required super.presentation,
    required super.matcher,
    required SearchCommandExecutor<P> execute,
    super.dependencies,
    SearchCommandEvaluator<P>? evaluate,
  }) : _evaluate = evaluate,
       _execute = execute;

  final SearchCommandEvaluator<P>? _evaluate;
  final SearchCommandExecutor<P> _execute;

  @override
  SearchCommandBatchMode get batchMode => SearchCommandBatchMode.repeated;

  @override
  SearchCommandState evaluate(SearchCommandTarget target) {
    final values = matchAll(target);
    if (values == null || values.isEmpty) {
      return const SearchCommandState.hidden();
    }
    return _mergeCommandStates([
      for (final value in values)
        _evaluate?.call(value, target) ?? const SearchCommandState.enabled(),
    ]);
  }

  @override
  Future<SearchCommandResult> execute(
    SearchCommandExecutionContext context,
    SearchCommandTarget target,
  ) async {
    final values = matchAll(target);
    if (values == null || values.isEmpty) {
      return const SearchCommandResult.failed(message: "Invalid search result");
    }
    return (await Future.wait([
      for (final value in values) _execute(context, value, target),
    ])).merge();
  }
}

final class BatchSearchCommand<P extends Object>
    extends _TypedSearchCommand<P> {
  BatchSearchCommand({
    required super.id,
    required super.presentation,
    required super.matcher,
    required SearchBatchCommandExecutor<P> execute,
    super.dependencies,
    SearchBatchCommandEvaluator<P>? evaluate,
  }) : _evaluate = evaluate,
       _execute = execute;

  final SearchBatchCommandEvaluator<P>? _evaluate;
  final SearchBatchCommandExecutor<P> _execute;

  @override
  SearchCommandBatchMode get batchMode => SearchCommandBatchMode.batch;

  @override
  SearchCommandState evaluate(SearchCommandTarget target) {
    final values = matchAll(target);
    if (values == null || values.isEmpty) {
      return const SearchCommandState.hidden();
    }
    return _evaluate?.call(values, target) ??
        const SearchCommandState.enabled();
  }

  @override
  Future<SearchCommandResult> execute(
    SearchCommandExecutionContext context,
    SearchCommandTarget target,
  ) {
    final values = matchAll(target);
    if (values == null || values.isEmpty) {
      return Future.value(
        const SearchCommandResult.failed(message: "Invalid search result"),
      );
    }
    return _execute(context, values, target);
  }
}

final class CustomSearchCommand implements SearchCommand {
  CustomSearchCommand({
    required this.id,
    required this.presentation,
    required SearchCommandState Function(SearchCommandTarget target) evaluate,
    required Future<SearchCommandResult> Function(
      SearchCommandExecutionContext context,
      SearchCommandTarget target,
    )
    execute,
    Iterable<Listenable> dependencies = const [],
  }) : dependencies = List.unmodifiable(dependencies),
       _evaluate = evaluate,
       _execute = execute;

  @override
  final SearchCommandId id;
  @override
  final SearchCommandPresentation presentation;
  @override
  final List<Listenable> dependencies;
  final SearchCommandState Function(SearchCommandTarget target) _evaluate;
  final Future<SearchCommandResult> Function(
    SearchCommandExecutionContext context,
    SearchCommandTarget target,
  )
  _execute;

  @override
  SearchCommandBatchMode get batchMode => SearchCommandBatchMode.custom;

  @override
  SearchCommandState evaluate(SearchCommandTarget target) => _evaluate(target);

  @override
  Future<SearchCommandResult> execute(
    SearchCommandExecutionContext context,
    SearchCommandTarget target,
  ) => _execute(context, target);
}

SearchCommandState _mergeCommandStates(List<SearchCommandState> states) {
  if (states.any((state) => state is SearchCommandHidden)) {
    return const SearchCommandState.hidden();
  }
  final reasons = states
      .whereType<SearchCommandDisabled>()
      .map((state) => state.reason)
      .toSet();
  if (reasons.isNotEmpty) {
    return SearchCommandState.disabled(reasons.join("; "));
  }
  return const SearchCommandState.enabled();
}

@freezed
abstract class ResolvedSearchCommand with _$ResolvedSearchCommand {
  const factory ResolvedSearchCommand({
    required SearchCommand command,
    required SearchCommandState state,
  }) = _ResolvedSearchCommand;
}

abstract interface class SearchScope {
  Iterable<Listenable> get dependencies;

  SearchResultVisibility evaluate(
    SearchResult result,
    SearchQueryContext query,
  );
}

@freezed
sealed class SearchResultVisibility with _$SearchResultVisibility {
  const factory SearchResultVisibility.visible() = SearchResultVisible;
  const factory SearchResultVisibility.hidden() = SearchResultHidden;
}

final class AllSearchScope implements SearchScope {
  const AllSearchScope();

  @override
  Iterable<Listenable> get dependencies => const [];

  @override
  SearchResultVisibility evaluate(
    SearchResult result,
    SearchQueryContext query,
  ) => const SearchResultVisibility.visible();
}

typedef SearchScopeEvaluator = SearchResultVisibility Function(
  SearchResult result,
  SearchQueryContext query,
);

final class PredicateSearchScope implements SearchScope {
  PredicateSearchScope({
    required SearchScopeEvaluator evaluate,
    Iterable<Listenable> dependencies = const [],
  }) : dependencies = List.unmodifiable(dependencies),
       _evaluate = evaluate;

  @override
  final List<Listenable> dependencies;
  final SearchScopeEvaluator _evaluate;

  @override
  SearchResultVisibility evaluate(
    SearchResult result,
    SearchQueryContext query,
  ) => _evaluate(result, query);
}

@freezed
sealed class SearchActivationState with _$SearchActivationState {
  const factory SearchActivationState.hidden() = SearchActivationHidden;

  @Assert("reason != \"\"", "Disabled reason must not be empty.")
  const factory SearchActivationState.disabled(String reason) =
      SearchActivationDisabled;

  const factory SearchActivationState.enabled() = SearchActivationEnabled;
}

@freezed
sealed class SearchActivationResult<T> with _$SearchActivationResult<T> {
  const factory SearchActivationResult.complete(T value) =
      SearchActivationComplete<T>;
  const factory SearchActivationResult.command(SearchCommandId id) =
      SearchActivationCommand<T>;
  const factory SearchActivationResult.keepOpen() = SearchActivationKeepOpen<T>;
  const factory SearchActivationResult.cancelled() =
      SearchActivationCancelled<T>;
}

typedef SearchPrompt<T> = Future<T?> Function(BuildContext context);

abstract interface class SearchPromptHost {
  Future<T?> show<T>(SearchPrompt<T> prompt);
}

final class UnsupportedSearchPromptHost implements SearchPromptHost {
  const UnsupportedSearchPromptHost();

  @override
  Future<T?> show<T>(SearchPrompt<T> prompt) {
    throw UnsupportedError("This search surface does not support prompts");
  }
}

abstract interface class SearchCommandDispatcher {
  ResolvedSearchCommand? resolveCommand(
    SearchCommandId id,
    SearchResult result,
  );

  SearchCommandSubmitResult executeCommand(
    SearchCommandId id, {
    String? resultId,
  });
}

@freezed
abstract class SearchCommandExecutionContext
    with _$SearchCommandExecutionContext {
  const factory SearchCommandExecutionContext({
    required SearchPromptHost prompts,
  }) = _SearchCommandExecutionContext;
}

@freezed
abstract class SearchActivationContext with _$SearchActivationContext {
  const factory SearchActivationContext({
    required SearchPromptHost prompts,
    required SearchCommandDispatcher commands,
    required SearchQueryContext query,
  }) = _SearchActivationContext;
}

@freezed
abstract class SearchActivationEvaluationContext
    with _$SearchActivationEvaluationContext {
  const factory SearchActivationEvaluationContext({
    required SearchQueryContext query,
    required SearchCommandDispatcher commands,
  }) = _SearchActivationEvaluationContext;
}

abstract interface class SearchActivation<T> {
  factory SearchActivation.command({
    required SearchCommandId? Function(SearchResult result) resolve,
    required Iterable<Listenable> dependencies,
  }) = CommandSearchActivation<T>;

  factory SearchActivation.custom({
    required Iterable<Listenable> dependencies,
    required SearchActivationState Function(
      SearchActivationEvaluationContext context,
      SearchResult result,
    )
    evaluate,
    required Future<SearchActivationResult<T>> Function(
      SearchActivationContext context,
      SearchResult result,
    )
    activate,
  }) = CustomSearchActivation<T>;

  Iterable<Listenable> get dependencies;

  SearchActivationState evaluate(
    SearchActivationEvaluationContext context,
    SearchResult result,
  );

  Future<SearchActivationResult<T>> activate(
    SearchActivationContext context,
    SearchResult result,
  );
}

final class CommandSearchActivation<T> implements SearchActivation<T> {
  CommandSearchActivation({
    required SearchCommandId? Function(SearchResult result) resolve,
    Iterable<Listenable> dependencies = const [],
  }) : _resolve = resolve,
       dependencies = List.unmodifiable(dependencies);

  final SearchCommandId? Function(SearchResult result) _resolve;
  @override
  final List<Listenable> dependencies;

  @override
  SearchActivationState evaluate(
    SearchActivationEvaluationContext context,
    SearchResult result,
  ) {
    final id = _resolve(result);
    if (id == null) return const SearchActivationState.hidden();
    final resolved = context.commands.resolveCommand(id, result);
    return switch (resolved?.state) {
      SearchCommandEnabled() => const SearchActivationState.enabled(),
      SearchCommandDisabled(:final reason) => SearchActivationState.disabled(
        reason,
      ),
      SearchCommandHidden() || null => const SearchActivationState.hidden(),
    };
  }

  @override
  Future<SearchActivationResult<T>> activate(
    SearchActivationContext context,
    SearchResult result,
  ) async {
    final id = _resolve(result);
    if (id == null) return const SearchActivationResult.cancelled();
    return SearchActivationResult.command(id);
  }
}

final class CustomSearchActivation<T> implements SearchActivation<T> {
  CustomSearchActivation({
    required SearchActivationState Function(
      SearchActivationEvaluationContext context,
      SearchResult result,
    )
    evaluate,
    required Future<SearchActivationResult<T>> Function(
      SearchActivationContext context,
      SearchResult result,
    )
    activate,
    Iterable<Listenable> dependencies = const [],
  }) : dependencies = List.unmodifiable(dependencies),
       _evaluate = evaluate,
       _activate = activate;

  @override
  final List<Listenable> dependencies;
  final SearchActivationState Function(
    SearchActivationEvaluationContext context,
    SearchResult result,
  )
  _evaluate;
  final Future<SearchActivationResult<T>> Function(
    SearchActivationContext context,
    SearchResult result,
  )
  _activate;

  @override
  SearchActivationState evaluate(
    SearchActivationEvaluationContext context,
    SearchResult result,
  ) => _evaluate(context, result);

  @override
  Future<SearchActivationResult<T>> activate(
    SearchActivationContext context,
    SearchResult result,
  ) => _activate(context, result);
}

@freezed
abstract class SearchInteraction<T> with _$SearchInteraction<T> {
  const factory SearchInteraction({
    required SearchActivation<T> activation,
    required SearchSelectionMode selectionMode,
    @Default([]) List<SearchCommand> commands,
  }) = _SearchInteraction<T>;
}

@freezed
abstract class SearchSession<T> with _$SearchSession<T> {
  const factory SearchSession({
    required SearchSource source,
    required SearchInteraction<T> interaction,
    @Default(AllSearchScope()) SearchScope scope,
    @Default("") String initialQuery,
  }) = _SearchSession<T>;
}

@freezed
sealed class SearchCommandResult with _$SearchCommandResult {
  const factory SearchCommandResult.completed({
    @Default(SearchSurfaceEffect.close()) SearchSurfaceEffect surfaceEffect,
    @Default([]) List<SearchHostEffect> hostEffects,
  }) = SearchCommandResultCompleted;

  @Assert("message != \"\"", "Message must not be empty.")
  const factory SearchCommandResult.failed({
    required String message,
    @Default(SearchSurfaceEffect.refresh()) SearchSurfaceEffect surfaceEffect,
  }) = SearchCommandResultFailed;

  const factory SearchCommandResult.cancelled() = SearchCommandResultCancelled;
}

extension SearchCommandResults on List<SearchCommandResult> {
  SearchCommandResult merge() {
    if (isEmpty) return const SearchCommandResult.completed();
    final actionable = where(
      (result) => result is! SearchCommandResultCancelled,
    ).toList();
    if (actionable.isEmpty) return const SearchCommandResult.cancelled();

    final effects = actionable
        .map(
          (result) => switch (result) {
            SearchCommandResultCompleted(:final surfaceEffect) => surfaceEffect,
            SearchCommandResultFailed(:final surfaceEffect) => surfaceEffect,
            SearchCommandResultCancelled() => throw StateError(
              "Cancelled results were removed before effect merging",
            ),
          },
        )
        .toSet();
    final messages = actionable
        .whereType<SearchCommandResultFailed>()
        .map((result) => result.message)
        .toSet();
    if (messages.isNotEmpty) {
      return SearchCommandResult.failed(
        message: messages.length == 1
            ? messages.first
            : "Search failed: ${messages.join(", ")}",
        surfaceEffect: effects.merge(),
      );
    }
    return SearchCommandResult.completed(
      surfaceEffect: effects.merge(),
      hostEffects: actionable
          .whereType<SearchCommandResultCompleted>()
          .expand((result) => result.hostEffects)
          .toList(),
    );
  }
}

enum SearchCommandSubmitResult {
  submitted,
  busy,
  invalidSelection,
  commandNotFound,
  notApplicable,
}

@freezed
sealed class SearchCommandExecutionState with _$SearchCommandExecutionState {
  const factory SearchCommandExecutionState.idle() = SearchCommandIdle;

  @Assert("resultIds.length > 0", "Result IDs must not be empty.")
  const factory SearchCommandExecutionState.running({
    required SearchCommandId command,
    required Set<String> resultIds,
  }) = SearchCommandRunning;

  @Assert("resultIds.length > 0", "Result IDs must not be empty.")
  const factory SearchCommandExecutionState.completed({
    required SearchCommandId command,
    required Set<String> resultIds,
  }) = SearchCommandCompleted;

  @Assert("resultIds.length > 0", "Result IDs must not be empty.")
  @Assert("message != \"\"", "Message must not be empty.")
  const factory SearchCommandExecutionState.failed({
    required SearchCommandId command,
    required Set<String> resultIds,
    required String message,
  }) = SearchCommandFailed;
}

@freezed
abstract class SearchContribution<T> with _$SearchContribution<T> {
  const factory SearchContribution({
    required SearchSession<T> session,
    @Default([]) List<QuerySelectorDefinition> baseSelectors,
    @Default([])
    List<SearchHostEffectExecutor<SearchHostEffect>> hostEffectExecutors,
  }) = _SearchContribution<T>;
}

typedef SearchContributionBuilder<T> = SearchContribution<T> Function(
  Ref ref,
  BuildContext context,
);
