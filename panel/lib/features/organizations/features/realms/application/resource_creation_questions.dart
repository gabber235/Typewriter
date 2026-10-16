part of "resource_creation.dart";

/// Retains one presented choice and the pending workspace before its answer.
final class _CreationQuestion {
  _CreationQuestion(this.step, this.previous, this.restore);

  final skir.PreparationStep step;
  final _CreationQuestion? previous;
  final VoidCallback restore;
  String query = "";
  bool presented = false;
}

final class _CreationBack implements Exception {
  const _CreationBack(this.target);
  final _CreationQuestion target;
}

extension on _ResourceCreationOperation {
  _CreationQuestion _checkpoint(
    skir.PreparationStep step,
    _CreationQuestion? previous,
  ) {
    final nodes = Map.of(_nodes);
    final references = List.of(_references);
    final embedded = Map.of(_embedded);
    final values = Map.of(_values);
    return _CreationQuestion(step, previous, () {
      _nodes
        ..clear()
        ..addAll(nodes);
      _references
        ..clear()
        ..addAll(references);
      _embedded
        ..clear()
        ..addAll(embedded);
      _values
        ..clear()
        ..addAll(values);
    });
  }

  Future<T?> _presentQuestion<T>(
    Future<T?> Function(
      String initialQuery,
      ValueChanged<String>? onQueryChanged,
      VoidCallback? onBack,
    )
    present,
  ) async {
    final question = _questions.lastOrNull;
    if (question != null) question.presented = true;
    var back = false;
    final result = await present(
      question?.query ?? "",
      question == null ? null : (query) => question.query = query,
      question?.previous == null ? null : () => back = true,
    );
    _checkCurrent();
    if (back) throw _CreationBack(question!.previous!);
    return result;
  }

  Future<ReferenceChoice?> _showReferenceQuestion({
    required List<ReferencePickerCandidate<ReferenceChoice>> candidates,
    required String searchHint,
  }) => _presentQuestion(
    (query, onQueryChanged, onBack) => showReferencePicker<ReferenceChoice>(
      context,
      candidates: candidates,
      searchHint: searchHint,
      initialQuery: query,
      onQueryChanged: onQueryChanged,
      onBack: onBack,
      cancelled: _cancelledSignal.future,
    ),
  );

  Future<skir.TypeSelection?> _chooseConcreteType(skir.TypeSelection expected) {
    if (catalog.concreteRecordSelections(expected).length == 1) {
      return showCreationConcreteTypePicker(
        context,
        expected: expected,
        catalog: catalog,
      );
    }
    return _presentQuestion(
      (query, onQueryChanged, onBack) => showCreationConcreteTypePicker(
        context,
        expected: expected,
        catalog: catalog,
        initialQuery: query,
        onQueryChanged: onQueryChanged,
        onBack: onBack,
        cancelled: _cancelledSignal.future,
      ),
    );
  }
}
