import "package:collection/collection.dart";
import "package:flutter/foundation.dart";
import "package:flutter/services.dart";
import "package:typewriter_panel/logic/search/search.dart";

class SearchController extends ChangeNotifier {
  SearchController({
    required SearchSource source,
    required List<QuerySelectorDefinition> baseSelectors,
    String initialQuery = "",
    VoidCallback? onCloseRequested,
  }) : _onCloseRequested = onCloseRequested {
    _sourceController = SourceController(
      source: source,
      baseSelectors: baseSelectors,
      initialQuery: initialQuery,
    );
    _actionController = ActionController(effectCallback: _onActionEffect);

    _sourceController.addListener(_onSourceChange);
    _actionController.addListener(_onActionChange);
  }

  late final SourceController _sourceController;
  late final ActionController _actionController;

  final VoidCallback? _onCloseRequested;
  void close() => _onCloseRequested?.call();
  bool get canClose => _onCloseRequested != null;

  SearchSourceSnapshot get snapshot => _sourceController.snapshot;
  List<QuerySelectorDefinition> get selectors => _sourceController.selectors;
  String get query => _sourceController.query;
  SearchQueryContext get queryContext => _sourceController.queryContext;

  List<SearchResult> _selectedResult = List.unmodifiable([]);
  List<SearchResult> get selectedResults => _selectedResult;

  SearchActionState get actionState => _actionController.state;

  SearchSelectionMode get selectionMode =>
      snapshot.actions.values.any(
        (a) => a is RepeatedSearchAction || a is BatchSearchAction,
      )
      ? SearchSelectionMode.multiple
      : SearchSelectionMode.single;

  List<SearchAction> actionsFor(SearchResult result) {
    if (_selectedIds.length > 1 && _selectedIds.contains(result.id)) {
      return actionsForSelected(result);
    }

    final actions = result.actions;
    return actions
        .map((action) => snapshot.actions[action])
        .nonNulls
        .sorted((a, b) => b.priority.compareTo(a.priority));
  }

  List<SearchAction> _actionsFor(List<Type> actions) {
    return actions
        .map((action) => snapshot.actions[action])
        .nonNulls
        .sorted((a, b) => b.priority.compareTo(a.priority));
  }

  List<SearchAction> actionsForSelected(SearchResult primaryResult) {
    assert(_selectedIds.length > 1 && _selectedIds.contains(primaryResult.id));

    final results = selectedResults;

    final actions = results.fold(primaryResult.actions.toSet(), (
      actions,
      result,
    ) {
      return actions.intersection(result.actions.toSet());
    }).toList();

    return _actionsFor(actions)
        .where(
          (action) =>
              action is RepeatedSearchAction || action is BatchSearchAction,
        )
        .toList();
  }

  SearchActionSubmitResult executeAction(Type actionType, {String? resultId}) {
    final Set<String> resultIds;
    if (resultId != null) {
      resultIds = selectedIds.contains(resultId)
          ? _selectedIds.toSet()
          : {resultId};
    } else {
      resultIds = _selectedIds.toSet();
    }
    return _actionController.execute(actionType, resultIds, snapshot);
  }

  String? _queryPending;
  var _userPendingQueryAppliedAfterAction = false;

  final Set<String> _selectedIds = {};
  List<String> get selectedIds => List.unmodifiable(_selectedIds);

  bool isSelected(String id) => _selectedIds.contains(id);
  void toggleSelected(String id, {bool? isMultiSelect}) {
    final selected = isSelected(id);
    final multiSelect =
        isMultiSelect ?? HardwareKeyboard.instance.isShiftPressed;
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
    notifyListeners();
  }

  int get selectedCount => _selectedIds.length;

  final Set<String> _collapsedSectionIds = {};
  List<String> get collapsedSectionIds =>
      List.unmodifiable(_collapsedSectionIds);

  bool isCollapsed(String id) => _collapsedSectionIds.contains(id);
  void toggleSection(String id) {
    if (isCollapsed(id)) {
      _collapsedSectionIds.remove(id);
    } else {
      _collapsedSectionIds.add(id);
    }
    notifyListeners();
  }

  SearchResult? _currentPreview;
  SearchResult? get currentPreview => _currentPreview;

  void preview(SearchResult? result) {
    _currentPreview = result;
    notifyListeners();
  }

  Future<SearchPreviewRequestResult> requestPreview(
    SearchPreviewRequest request,
  ) {
    return _sourceController.source.preview(request);
  }

  void updateQuery(String query) {
    if (actionState is SearchActionRunning) {
      _queryPending = query;
      return;
    }
    _sourceController.updateQuery(query);
  }

  void _onSourceChange() {
    _cleanupState();
    _selectedResult = List.unmodifiable(
      snapshot.nodes.findResults(_selectedIds),
    );
    notifyListeners();
  }

  void _cleanupState() {
    final oldPreviewId = _currentPreview?.id;
    _currentPreview = null;

    final leftOverSelectedIds = _selectedIds.toSet();

    final stack = <SearchNode>[];
    for (var i = snapshot.nodes.length - 1; i >= 0; i--) {
      stack.add(snapshot.nodes[i]);
    }

    while (stack.isNotEmpty && leftOverSelectedIds.isNotEmpty) {
      final node = stack.removeLast();
      switch (node) {
        case SearchSectionNode(:final children):
          for (var i = children.length - 1; i >= 0; i--) {
            stack.add(children[i]);
          }
        case SearchResultNode(:final result):
          leftOverSelectedIds.remove(result.id);
          if (result.id == oldPreviewId) {
            _currentPreview = result;
          }
      }
    }

    _selectedIds.removeAll(leftOverSelectedIds);
  }

  void _onActionChange() {
    if (_queryPending != null && actionState is! SearchActionRunning) {
      final pendingQuery = _queryPending!;
      _queryPending = null;
      _userPendingQueryAppliedAfterAction = true;
      updateQuery(pendingQuery);
    }
    notifyListeners();
  }

  void _onActionEffect(SearchActionEffect effect) {
    switch (effect) {
      case SearchActionUpdateQuery(:final updateQuery):
        // If the user did something while performing the action, we give that priority.
        if (_queryPending != null || _userPendingQueryAppliedAfterAction) {
          _userPendingQueryAppliedAfterAction = false;
          return;
        }
        // We want to bypass the updateQuery call here, so it always goes through.
        _sourceController.updateQuery(updateQuery);
      case SearchActionRefresh():
        _userPendingQueryAppliedAfterAction = false;
        _sourceController.triggerQuery();
      case SearchActionClose():
        _userPendingQueryAppliedAfterAction = false;
        _onCloseRequested?.call();
    }
  }

  @override
  void dispose() {
    super.dispose();
    _sourceController.dispose();
    _actionController.dispose();
  }
}
