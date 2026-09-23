part of "page_elements.dart";

/// Applies typed field edits through the shared local work owner.
///
/// The current canonical value and schema revision are resolved when building
/// the [EditorTarget]. Successful and uncertain mutations are left to the
/// shared reconciliation pipeline, while conflicts and validation failures are
/// translated into caller visible API errors.
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

  Future<void> updateEntryFieldValues(
    Map<String, ({DataPath path, DataValue value})> updates,
  ) async {
    if (updates.isEmpty) return;
    final owners = EditorOwnerRegistry(
      workspace: ref.read(localWorkControllerProvider),
    );
    try {
      final changes = <TransactionalEditorSource, Map<DataPath, DataValue>>{
        for (final update in updates.entries)
          owners.editor(_target(update.key)) as TransactionalEditorSource: {
            elementValuePath.followedBy(update.value.path): update.value.value,
          },
      };
      final results = await EditorBatch.submit(changes: changes);
      for (final result in results.values) {
        switch (result) {
          case MutationSuccess() || MutationUncertain():
            continue;
          case MutationConflict():
            throw ApiException.conflict("A reference field changed elsewhere");
          case MutationInvalid(:final diagnostics) ||
              MutationUnavailable(:final diagnostics):
            throw ApiException.badRequest(
              diagnostics.map((value) => value.message).join("; "),
            );
          case MutationPermissionDenied(:final message):
            throw ApiException.badRequest(message);
        }
      }
    } finally {
      owners.dispose();
    }
  }

  Future<void> _updateFieldValue(
    String elementId,
    DataPath path,
    DataValue value,
  ) async {
    final owners = EditorOwnerRegistry(
      workspace: ref.read(localWorkControllerProvider),
    );
    try {
      final result = await owners.editor(_target(elementId)).applyChanges({
        elementValuePath.followedBy(path): value,
      });
      switch (result) {
        case MutationSuccess():
          return;
        case MutationUncertain():
          return;
        case MutationConflict():
          throw ApiException.conflict("The field changed elsewhere");
        case MutationInvalid(:final diagnostics) ||
            MutationUnavailable(:final diagnostics):
          throw ApiException.badRequest(
            diagnostics.map((value) => value.message).join("; "),
          );
        case MutationPermissionDenied(:final message):
          throw ApiException.badRequest(message);
      }
    } finally {
      owners.dispose();
    }
  }

  EditorTarget _target(String elementId) {
    state.ensureReady();
    final current = state.requireValue.singleWhere(
      (element) => element.id == elementId,
    );
    switch (current) {
      case PageElementEntry(entry: DefinitionPageEntry()) || PageElementCue():
        break;
      default:
        throw ApiException.badRequest("The element has no editable value");
    }
    final codec = _codec();
    final session = ref.read(_sessionProvider);
    return session.authoringResourceTarget(
      repository: ref
          .read(resourceRepositoriesProvider)
          .authoring(this.organizationId, this.realmId),
      identity: EntryIdentifier(elementId),
      label: _elementName(current),
      typeCatalog: codec.registry.catalog,
    );
  }
}
