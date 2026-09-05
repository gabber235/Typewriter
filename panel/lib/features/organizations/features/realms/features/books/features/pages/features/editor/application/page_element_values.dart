part of "page_elements.dart";

mixin _PageElementValues on _$PageElements, _PageElementMutationContext {
  Future<void> updateCueFieldValue(
    String cueId,
    DataPath path,
    DataValue value,
  ) => _updateFieldValue(cueId, path, value);

  Future<void> updateEntryFieldValue(
    String entryId,
    DataPath path,
    DataValue value,
  ) => _updateFieldValue(entryId, path, value);

  Future<void> _updateFieldValue(
    String elementId,
    DataPath path,
    DataValue value,
  ) async {
    state.ensureReady();
    final current = state.requireValue.singleWhere(
      (element) => element.id == elementId,
    );
    final expected = path.read(_elementValue(current)).valueOrNull;
    if (expected == null) {
      throw ApiException.badRequest("The edited field does not exist");
    }
    final mutation = _setMutation(_codec().codec, path, expected, value);
    state = AsyncData([
      for (final element in state.requireValue)
        if (element.id == elementId)
          element.updateFieldValue(path, value)
        else
          element,
    ]);
    try {
      await _submit(
        _commands.patchElement(
          id: recordId("element:$elementId"),
          valueMutations: [mutation],
        ),
      );
    } on Object {
      _replaceFromSession();
      rethrow;
    }
  }

  Future<TypedMutationResult> commitElementValue(
    String elementId,
    EditorCommit commit,
  ) async {
    state.ensureReady();
    final current = state.requireValue.singleWhere(
      (element) => element.id == elementId,
    );
    final before = _elementValue(current);
    final after = commit.rootValue;
    if (after is! RecordValue) {
      return invalidMutation("Element values must be records");
    }
    final codec = _codec().codec;
    final mutations = <wire.ExpectedElementValueMutation>[];
    for (final path in commit.changedPaths) {
      final expected = path.read(before).valueOrNull;
      final value = path.read(after).valueOrNull;
      if (expected == null || value == null) {
        return invalidMutation("An edited field could not be encoded");
      }
      mutations.add(_setMutation(codec, path, expected, value));
    }
    state = AsyncData([
      for (final element in state.requireValue)
        if (element.id == elementId)
          element.updateFieldValue(DataPath.root, after)
        else
          element,
    ]);
    try {
      final response = await _commands.patchElement(
        id: recordId("element:$elementId"),
        name: _elementName(current) == _wireElement(elementId).name
            ? null
            : wire.StringChange(
                expected: _wireElement(elementId).name,
                value: _elementName(current),
              ),
        valueMutations: mutations,
      );
      switch (response) {
        case wire.ApplyAuthoringBatchResponse_appliedWrapper(:final value):
          return TypedMutationResult.success(
            revision: value.sequence,
            value: after,
          );
        case wire.ApplyAuthoringBatchResponse_conflictWrapper():
          return _elementConflict(elementId, commit.expectedRevision);
        case wire.ApplyAuthoringBatchResponse_invalidWrapper() ||
            wire.ApplyAuthoringBatchResponse_internalErrorWrapper() ||
            wire.ApplyAuthoringBatchResponse_unknown():
          _replaceFromSession();
          return response.toMutationFailure(
            unavailableMessage: "The element update could not be completed",
          );
      }
    } on Object {
      _replaceFromSession();
      return unavailableMutation("The element update could not be completed");
    }
  }

  wire.ExpectedElementValueMutation _setMutation(
    SkirEditorCodec codec,
    DataPath path,
    DataValue expected,
    DataValue value,
  ) {
    final wirePath = codec.encodePath(path).valueOrNull;
    final wireExpected = codec.encodeValue(expected).valueOrNull;
    final wireValue = codec.encodeValue(value).valueOrNull;
    if (wirePath == null || wireExpected == null || wireValue == null) {
      throw ApiException.badRequest("The edited value could not be encoded");
    }
    return wire.ExpectedElementValueMutation(
      expected: wireExpected,
      mutation: wire.ElementValueMutation.createSetValue(
        path: wirePath,
        value: wireValue,
      ),
    );
  }

  TypedMutationResult _elementConflict(String elementId, int expectedSequence) {
    _replaceFromSession();
    final actual = state.requireValue.singleWhere(
      (element) => element.id == elementId,
    );
    return TypedMutationResult.conflict(
      expectedRevision: expectedSequence,
      actualRevision: ref.read(_sessionProvider).sequence ?? 0,
      actualValue: _elementValue(actual),
    );
  }
}
