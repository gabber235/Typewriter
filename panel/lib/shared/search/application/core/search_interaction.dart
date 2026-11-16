// ignore_for_file: prefer_initializing_formals

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

/// The one result a command acts on, the focused result, and the query it
/// was found by.
@freezed
abstract class SearchCommandTarget with _$SearchCommandTarget {
  const factory SearchCommandTarget({
    required SearchResult result,
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

/// Describes an operation against the focused result and its query.
///
/// Evaluation supplies visibility and an actionable disabled reason before
/// execution. Dependencies trigger reevaluation when external availability
/// changes. Host side effects are returned as data for the surface host to
/// execute.
abstract interface class SearchCommand {
  SearchCommandId get id;
  SearchCommandPresentation get presentation;
  Iterable<Listenable> get dependencies;

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
}

/// A command for results of one type: it matches the result's payload with
/// [matcher] and is hidden for results it does not match.
final class SingleSearchCommand<P extends Object> implements SearchCommand {
  SingleSearchCommand({
    required this.id,
    required this.presentation,
    required this.matcher,
    required SearchCommandExecutor<P> execute,
    Iterable<Listenable> dependencies = const [],
    SearchCommandEvaluator<P>? evaluate,
  }) : dependencies = List.unmodifiable(dependencies),
       _evaluate = evaluate,
       _execute = execute;

  @override
  final SearchCommandId id;
  @override
  final SearchCommandPresentation presentation;
  final SearchResultMatcher<P> matcher;
  @override
  final List<Listenable> dependencies;
  final SearchCommandEvaluator<P>? _evaluate;
  final SearchCommandExecutor<P> _execute;

  @override
  SearchCommandState evaluate(SearchCommandTarget target) {
    final value = matcher.match(target.result);
    if (value == null) return const SearchCommandState.hidden();
    return _evaluate?.call(value, target) ?? const SearchCommandState.enabled();
  }

  @override
  Future<SearchCommandResult> execute(
    SearchCommandExecutionContext context,
    SearchCommandTarget target,
  ) {
    final value = matcher.match(target.result);
    if (value == null) {
      return Future.value(
        const SearchCommandResult.failed(message: "Invalid search result"),
      );
    }
    return _execute(context, value, target);
  }
}

@freezed
abstract class ResolvedSearchCommand with _$ResolvedSearchCommand {
  const factory ResolvedSearchCommand({
    required SearchCommand command,
    required SearchCommandState state,
  }) = _ResolvedSearchCommand;
}

/// Filters a session's source results using query and external dependencies.
/// Scope projection affects visibility before commands resolve current targets.
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
    required String resultId,
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

/// Defines what the primary activation of a result means for this surface.
///
/// Picker activations can return [T]; command activations defer to a registered
/// command. Evaluation and execution share the session dispatcher and query,
/// allowing disabled command state to propagate to primary activation.
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

enum SearchCommandSubmitResult {
  submitted,
  busy,
  resultNotFound,
  commandNotFound,
  notApplicable,
}

@freezed
sealed class SearchCommandExecutionState with _$SearchCommandExecutionState {
  const factory SearchCommandExecutionState.idle() = SearchCommandIdle;

  const factory SearchCommandExecutionState.running({
    required SearchCommandId command,
    required String resultId,
  }) = SearchCommandRunning;

  const factory SearchCommandExecutionState.completed({
    required SearchCommandId command,
    required String resultId,
  }) = SearchCommandCompleted;

  @Assert("message != \"\"", "Message must not be empty.")
  const factory SearchCommandExecutionState.failed({
    required SearchCommandId command,
    required String resultId,
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
