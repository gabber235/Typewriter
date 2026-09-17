// ignore_for_file: prefer_initializing_formals

import "dart:async";

import "package:collection/collection.dart";
import "package:flutter/services.dart";
import "package:flutter/widgets.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// Coordinates one source, scope, interaction, and search surface lifecycle.
class SearchController<T> extends ChangeNotifier
    implements SearchCommandDispatcher {
  SearchController({
    required SearchSession<T> session,
    required List<QuerySelectorDefinition> baseSelectors,
    SearchPromptHost prompts = const UnsupportedSearchPromptHost(),
    List<SearchHostEffectExecutor<SearchHostEffect>> hostEffectExecutors =
        const [],
    FutureOr<void> Function()? onCloseRequested,
    FutureOr<void> Function(T value)? onCompleted,
  }) : _session = session,
       _prompts = prompts,
       _onCloseRequested = onCloseRequested,
       _onCompleted = onCompleted {
    _commands = _indexCommands(session.interaction.commands);
    _sourceController = SourceController(
      source: session.source,
      baseSelectors: baseSelectors,
      initialQuery: session.initialQuery,
    );
    _commandController = CommandController(
      effectCallback: _onCommandEffect,
      prompts: prompts,
      hostEffectExecutors: hostEffectExecutors,
    );

    _dependencies = {
      ...session.scope.dependencies,
      ...session.interaction.activation.dependencies,
      for (final command in session.interaction.commands)
        ...command.dependencies,
    };
    for (final dependency in _dependencies) {
      dependency.addListener(_onInteractionChange);
    }
    _sourceController.addListener(_onSourceChange);
    _commandController.addListener(_onCommandChange);
    _projectSourceSnapshot();
  }

  final SearchSession<T> _session;
  final SearchPromptHost _prompts;
  final FutureOr<void> Function()? _onCloseRequested;
  final FutureOr<void> Function(T value)? _onCompleted;

  late final SourceController _sourceController;
  late final CommandController _commandController;
  late final Map<SearchCommandId, SearchCommand> _commands;
  late final Set<Listenable> _dependencies;

  SearchSourceSnapshot _snapshot = SearchSourceSnapshot.idle();
  SearchSourceSnapshot get snapshot => _snapshot;
  List<QuerySelectorDefinition> get selectors => _sourceController.selectors;
  String get query => _sourceController.query;
  SearchQueryContext get queryContext => _sourceController.queryContext;
  List<QueryParseIssue> get validationIssues =>
      _sourceController.validationIssues;
  SearchSelectionMode get selectionMode => _session.interaction.selectionMode;
  SearchCommandExecutionState get commandState => _commandController.state;
  bool get activationRunning => _activationRunning;
  bool get isBusy => activationRunning || commandState is SearchCommandRunning;

  SearchCommand? command(SearchCommandId id) => _commands[id];

  Future<SearchSelectorCompletionResult> completeSelector(
    SearchSelectorCompletionRequest request,
  ) => _sourceController.completeSelector(request);

  List<SearchResult> _selectedResults = const [];
  List<SearchResult> get selectedResults => _selectedResults;

  final Set<String> _selectedIds = {};
  List<String> get selectedIds => List.unmodifiable(_selectedIds);
  int get selectedCount => _selectedIds.length;

  bool isSelected(String id) => _selectedIds.contains(id);

  List<ResolvedSearchCommand> commandsFor(SearchResult result) {
    final target = _targetFor(result);
    return _session.interaction.commands
        .map(
          (command) => ResolvedSearchCommand(
            command: command,
            state: command.evaluate(target),
          ),
        )
        .where((resolved) => resolved.state is! SearchCommandHidden)
        .sorted(
          (left, right) => right.command.presentation.priority.compareTo(
            left.command.presentation.priority,
          ),
        );
  }

  SearchActivationState activationState(SearchResult result) {
    return _session.interaction.activation.evaluate(
      SearchActivationEvaluationContext(query: queryContext, commands: this),
      result,
    );
  }

  var _activationRunning = false;

  Future<void> activate(SearchResult result) async {
    if (isBusy || activationState(result) is! SearchActivationEnabled) return;
    _activationRunning = true;
    notifyListeners();
    try {
      final outcome = await _session.interaction.activation.activate(
        SearchActivationContext(
          prompts: _prompts,
          commands: this,
          query: queryContext,
        ),
        result,
      );
      switch (outcome) {
        case SearchActivationComplete(:final value):
          await _onCompleted?.call(value);
        case SearchActivationCommand(:final id):
          executeCommand(id, resultId: result.id);
        case SearchActivationKeepOpen() || SearchActivationCancelled():
      }
    } on Object catch (error, stackTrace) {
      debugPrint(error.toString());
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _activationRunning = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  ResolvedSearchCommand? resolveCommand(
    SearchCommandId id,
    SearchResult result,
  ) {
    final command = _commands[id];
    if (command == null) return null;
    return ResolvedSearchCommand(
      command: command,
      state: command.evaluate(_targetFor(result)),
    );
  }

  @override
  SearchCommandSubmitResult executeCommand(
    SearchCommandId id, {
    String? resultId,
  }) {
    final command = _commands[id];
    if (command == null) return SearchCommandSubmitResult.commandNotFound;
    final target = _currentTarget(resultId);
    if (target == null) return SearchCommandSubmitResult.invalidSelection;
    return _commandController.execute(command, target);
  }

  SearchCommandTarget _targetFor(SearchResult primary) {
    final selection =
        _selectedIds.length > 1 && _selectedIds.contains(primary.id)
        ? _selectedResults
        : [primary];
    return SearchCommandTarget(
      primary: primary,
      selection: selection,
      query: queryContext,
    );
  }

  SearchCommandTarget? _currentTarget(String? resultId) {
    final ids = resultId == null
        ? _selectedIds.toSet()
        : _selectedIds.contains(resultId)
        ? _selectedIds.toSet()
        : {resultId};
    if (ids.isEmpty) return null;
    final results = snapshot.nodes.findResults(ids);
    if (results.length != ids.length) return null;
    final primary = resultId == null
        ? results.first
        : results.firstWhereOrNull((result) => result.id == resultId);
    if (primary == null) return null;
    return SearchCommandTarget(
      primary: primary,
      selection: results,
      query: queryContext,
    );
  }

  void toggleSelected(String id, {bool? isMultiSelect}) {
    final selected = isSelected(id);
    final multiSelect =
        selectionMode == SearchSelectionMode.multiple &&
        (isMultiSelect ?? HardwareKeyboard.instance.isShiftPressed);
    switch ((selected, multiSelect)) {
      case (true, true):
        _selectedIds.remove(id);
      case (true, false):
        if (_selectedIds.length > 1) {
          _selectedIds
            ..clear()
            ..add(id);
        } else {
          _selectedIds.clear();
        }
      case (false, true):
        _selectedIds.add(id);
      case (false, false):
        _selectedIds
          ..clear()
          ..add(id);
    }
    _syncSelectedResults();
    notifyListeners();
  }

  final Set<String> _collapsedSectionIds = {};
  List<String> get collapsedSectionIds =>
      List.unmodifiable(_collapsedSectionIds);

  bool isCollapsed(String id) => _collapsedSectionIds.contains(id);

  void toggleSection(String id) {
    if (!_collapsedSectionIds.remove(id)) {
      _collapsedSectionIds.add(id);
    }
    notifyListeners();
  }

  SearchResult? _currentPreview;
  SearchResult? get currentPreview => _currentPreview;

  void preview(SearchResult? result) {
    if (_currentPreview?.id == result?.id && _currentPreview == result) return;
    _currentPreview = result;
    notifyListeners();
  }

  void refresh() => _sourceController.triggerQuery();

  Future<SearchPreviewRequestResult> requestPreview(
    SearchPreviewRequest request,
  ) => _sourceController.source.preview(request);

  String? _queryPending;
  var _userPendingQueryAppliedAfterCommand = false;

  void updateQuery(String query) {
    if (commandState is SearchCommandRunning) {
      _queryPending = query;
      return;
    }
    _sourceController.updateQuery(query);
    _projectSourceSnapshot();
  }

  void close() => unawaited(Future.sync(() => _onCloseRequested?.call()));
  bool get canClose => _onCloseRequested != null;

  void _onSourceChange() {
    _projectSourceSnapshot();
    notifyListeners();
  }

  void _onInteractionChange() {
    _projectSourceSnapshot();
    notifyListeners();
  }

  void _projectSourceSnapshot() {
    final sourceSnapshot = _sourceController.snapshot;
    _snapshot = sourceSnapshot.copyWith(
      nodes: _projectNodes(sourceSnapshot.nodes),
    );
    _cleanupState();
    _syncSelectedResults();
  }

  List<SearchNode> _projectNodes(List<SearchNode> nodes) {
    final projected = <SearchNode>[];
    for (final node in nodes) {
      switch (node) {
        case SearchResultNode(:final result):
          if (_session.scope.evaluate(result, queryContext)
              case SearchResultVisible()) {
            projected.add(node);
          }
        case SearchSectionNode():
          final children = _projectNodes(node.children);
          if (children.isNotEmpty || node.children.isEmpty) {
            projected.add(node.copyWith(children: children));
          }
      }
    }
    return List.unmodifiable(projected);
  }

  void _syncSelectedResults() {
    _selectedResults = List.unmodifiable(
      snapshot.nodes.findResults(_selectedIds),
    );
  }

  void _cleanupState() {
    final oldPreviewId = _currentPreview?.id;
    _currentPreview = null;
    final remainingSelectedIds = _selectedIds.toSet();

    for (final node in snapshot.nodes.walk()) {
      if (node case SearchResultNode(:final result)) {
        remainingSelectedIds.remove(result.id);
        if (result.id == oldPreviewId) _currentPreview = result;
      }
    }
    _selectedIds.removeAll(remainingSelectedIds);
  }

  void _onCommandChange() {
    if (_queryPending != null && commandState is! SearchCommandRunning) {
      final pendingQuery = _queryPending!;
      _queryPending = null;
      _userPendingQueryAppliedAfterCommand = true;
      updateQuery(pendingQuery);
    }
    notifyListeners();
  }

  Future<void> _onCommandEffect(SearchSurfaceEffect effect) async {
    switch (effect) {
      case SearchSurfaceUpdateQuery(:final updateQuery):
        if (_queryPending != null || _userPendingQueryAppliedAfterCommand) {
          _userPendingQueryAppliedAfterCommand = false;
          return;
        }
        _sourceController.updateQuery(updateQuery);
      case SearchSurfaceRefresh():
        _userPendingQueryAppliedAfterCommand = false;
        _sourceController.triggerQuery();
      case SearchSurfaceClose():
        _userPendingQueryAppliedAfterCommand = false;
        await _onCloseRequested?.call();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    for (final dependency in _dependencies) {
      dependency.removeListener(_onInteractionChange);
    }
    _sourceController.removeListener(_onSourceChange);
    _commandController.removeListener(_onCommandChange);
    _sourceController.dispose();
    _commandController.dispose();
    super.dispose();
  }

  var _disposed = false;
}

Map<SearchCommandId, SearchCommand> _indexCommands(
  List<SearchCommand> commands,
) {
  final indexed = <SearchCommandId, SearchCommand>{};
  final shortcuts = <ShortcutActivator>{};
  for (final command in commands) {
    if (indexed.containsKey(command.id)) {
      throw ArgumentError.value(
        commands,
        "commands",
        "Duplicate search command ID ${command.id.value}.",
      );
    }
    final shortcut = command.presentation.shortcut;
    if (shortcut != null && !shortcuts.add(shortcut)) {
      throw ArgumentError.value(
        commands,
        "commands",
        "Duplicate search command shortcut $shortcut.",
      );
    }
    indexed[command.id] = command;
  }
  return Map.unmodifiable(indexed);
}
