import "package:flutter/foundation.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:typewriter_panel/logic/search/search.dart";

typedef ActionEffectCallback = void Function(SearchActionEffect effect);

class ActionController with ChangeNotifier {
  ActionController({required ActionEffectCallback effectCallback})
    : _effectCallback = effectCallback;

  final ActionEffectCallback _effectCallback;

  var _disposed = false;

  var _state = SearchActionState.idle();
  SearchActionState get state => _state;

  SearchActionSubmitResult execute(
    Type actionType,
    Set<String> resultIds,
    SearchSourceSnapshot snapshot,
  ) {
    if (_state is SearchActionRunning) {
      return SearchActionSubmitResult.busy;
    }

    if (resultIds.isEmpty) {
      return SearchActionSubmitResult.invalidSelection;
    }

    final action = snapshot.actions[actionType];
    if (action == null) {
      return SearchActionSubmitResult.actionNotFound;
    }

    final results = snapshot.nodes.findResults(resultIds);

    if (results.isEmpty) {
      return SearchActionSubmitResult.invalidSelection;
    }

    assert(() {
      final doNotHaveAction = results
          .where((r) => !r.actions.contains(actionType))
          .toList();
      if (doNotHaveAction.isEmpty) return true;

      throw StateError(
        "Result(s) do not have action $actionType: $doNotHaveAction, yet were trying to execute it.",
      );
    }());

    _execute(actionType, action, resultIds, results);
    return SearchActionSubmitResult.submitted;
  }

  Future<void> _execute(
    Type actionType,
    SearchAction action,
    Set<String> resultIds,
    List<SearchResult> results,
  ) async {
    if (_disposed) {
      return;
    }
    _state = SearchActionState.running(
      action: actionType,
      resultIds: resultIds,
    );
    notifyListeners();

    try {
      final SearchActionResult result;
      switch (action) {
        case SingleSearchAction():
          assert(
            results.length == 1,
            "For a SingleSearchAction, exactly one result must be selected.",
          );
          result = await action.execute(results.first);
        case RepeatedSearchAction():
          final actionResults = await Future.wait(
            results.map((r) => action.execute(r)),
          );
          result = actionResults.merge();
        case BatchSearchAction():
          result = await action.executeBatch(results);
        default:
          throw StateError("Unknown action type: $action");
      }

      if (_disposed) {
        return;
      }

      switch (result) {
        case SearchActionResultCompleted():
          _state = SearchActionState.completed(
            action: actionType,
            resultIds: resultIds,
          );
        case SearchActionResultFailed(:final message):
          _state = SearchActionState.failed(
            action: actionType,
            resultIds: resultIds,
            message: message,
          );
      }
      notifyListeners();

      _effectCallback(result.effect);
    } on Error catch (e) {
      debugPrint(e.toString());
      debugPrintStack(stackTrace: e.stackTrace);
      if (_disposed) {
        return;
      }
      _state = SearchActionState.failed(
        action: actionType,
        resultIds: resultIds,
        message: e.toString(),
      );
      notifyListeners();
    }
    await _clearAutoReset();
  }

  Future<void> _clearAutoReset() async {
    if (_disposed) {
      return;
    }

    await Future<void>.delayed(5.seconds);
    if (_disposed) {
      return;
    }

    if (_state is SearchActionRunning) {
      return;
    }

    _state = SearchActionState.idle();
  }

  @override
  void dispose() {
    assert(!_disposed);
    _disposed = true;
    super.dispose();
  }
}

extension on List<SearchNode> {
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
}
