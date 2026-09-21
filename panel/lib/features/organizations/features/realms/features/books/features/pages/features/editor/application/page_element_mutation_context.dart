part of "page_elements.dart";

/// Shared mutation boundary for page element commands.
///
/// It resolves the current catalog and document from the page session instead
/// of retaining mutable snapshots across operations. Submission preserves the
/// backend response so conflicts remain visible to callers.
mixin _PageElementMutationContext on _$PageElements {
  late skir.ResourceId _pageId;
  late AuthoringSessionProvider _sessionProvider;

  AuthoringSession get _commands => ref.read(_sessionProvider.notifier);

  Future<void> _submit(Future<skir.ApplyAuthoringBatchResponse> pending) async {
    final response = await pending;
    response.requireApplied(
      conflictMessage: "The page changed while it was being edited",
    );
  }

  ({
    RealmEditorCatalogSnapshot catalog,
    TypeRegistry registry,
    SkirEditorCodec codec,
    TypedAuthoringCodec authoring,
  })
  _codec() {
    final snapshot = ref.read(realmEditorCatalogProvider).value?.snapshot;
    if (snapshot == null) {
      throw ApiException.badRequest("The editor catalog is unavailable");
    }
    final registry = TypeRegistry(snapshot.catalog);
    return (
      catalog: snapshot,
      registry: registry,
      codec: SkirEditorCodec(registry),
      authoring: TypedAuthoringCodec(snapshot),
    );
  }

  AuthoringSessionState get _authoring => ref.read(_sessionProvider);
}
