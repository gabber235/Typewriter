import "package:flutter/foundation.dart";
import "package:typewriter_panel/logic/search/core/core.dart";
import "package:typewriter_panel/logic/search/query/query_selector.dart";

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

  SearchSourceSnapshot get snapshot => _sourceController.snapshot;
  List<QuerySelectorDefinition> get selectors => _sourceController.selectors;

  SearchActionState get actionState => _actionController.state;

  Future<SearchPreviewRequestResult> preview(SearchPreviewRequest request) {
    return _sourceController.source.preview(request);
  }

  SearchActionSubmitResult executeAction(
    Type actionType, {
    SearchActionTarget target = const SearchActionTarget.selection(),
  }) {
    final resultIds = switch (target) {
      SearchSingleActionTarget(:final resultId) => {resultId},
      SearchSelectionActionTarget() => _selectedIds,
    };
    return _actionController.execute(actionType, resultIds, snapshot);
  }

  String? _queryPending;
  var _userPendingQueryAppliedAfterAction = false;

  final Set<String> _selectedIds = {};
  List<String> get selectedIds => List.unmodifiable(_selectedIds);

  bool isSelected(String id) => _selectedIds.contains(id);
  void toggleSelected(String id) {
    if (isSelected(id)) {
      _selectedIds.remove(id);
    } else {
      _selectedIds.add(id);
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

  void updateQuery(String query) {
    if (actionState is SearchActionRunning) {
      _queryPending = query;
      return;
    }
    _sourceController.updateQuery(query);
  }

  void _onSourceChange() {
    _cleanupState();
    notifyListeners();
  }

  void _cleanupState() {
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
