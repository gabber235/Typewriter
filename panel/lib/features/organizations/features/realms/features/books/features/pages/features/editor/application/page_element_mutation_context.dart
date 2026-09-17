part of "page_elements.dart";

/// Shared mutation boundary for page element commands.
///
/// It resolves the current catalog and document from the page session instead
/// of retaining mutable snapshots across operations. Submission preserves the
/// backend response so conflicts remain visible to callers.
mixin _PageElementMutationContext on _$PageElements {
  late skir.RecordId _pageId;
  late AuthoringSessionProvider _sessionProvider;

  AuthoringSession get _commands => ref.read(_sessionProvider.notifier);

  Future<void> _submit(Future<skir.ApplyAuthoringBatchResponse> pending) async {
    final response = await pending;
    response.requireApplied(
      conflictMessage: "The page changed while it was being edited",
    );
  }

  ({TypeRegistry registry, SkirEditorCodec codec}) _codec() {
    final snapshot = ref.read(realmEditorCatalogProvider).value?.snapshot;
    if (snapshot == null) {
      throw ApiException.badRequest("The editor catalog is unavailable");
    }
    final registry = TypeRegistry(
      bootstrapTypeCatalog(snapshot.catalog.definitions),
    );
    return (registry: registry, codec: SkirEditorCodec(registry));
  }

  skir.PageDocument get _document {
    final document = ref.read(_sessionProvider).documents[_pageId];
    if (document == null) throw ApiException.notFound("Page");
    return document;
  }
}
