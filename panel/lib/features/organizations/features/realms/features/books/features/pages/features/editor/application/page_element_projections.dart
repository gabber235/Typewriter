part of "page_elements.dart";

/// Decodes every authoring document into page element projections.
///
/// The authoring session supplies canonical documents and their revision. The
/// realm editor catalog supplies the schema needed to decode values. Catalog
/// failures remain diagnostics, while unresolved references are represented in
/// the projection for the UI to repair.
@riverpod
AsyncValue<AuthoringValue<Map<String, List<PageElement>>>>
decodedRealmDocumentValues(
  Ref ref,
  skir.RecordId organizationId,
  skir.RecordId realmId,
) {
  final activeOrganizationId = ref.watch(organizationIdProvider);
  final activeRealmId = ref.watch(realmIdProvider);
  if (activeOrganizationId != organizationId || activeRealmId != realmId) {
    return const AsyncLoading();
  }

  final session = ref.watch(authoringSessionProvider(organizationId, realmId));
  final revision = session.sequence;
  if (revision == null) return const AsyncLoading();
  ref.watch(
    realmEditorCatalogLeaseProvider(
      RealmEditorCatalogRequest(
        types: {
          for (final document in session.documents.values)
            for (final element in document.elements)
              ResolvedTypeRef(
                id: DeclaredTypeId(element.elementType),
                revision: element.schemaRevision,
              ),
        },
      ),
    ),
  );

  final catalog = ref.watch(realmEditorCatalogProvider);
  if (catalog.isLoading) return const AsyncLoading();
  return catalog.when(
    data: (state) => switch (state) {
      RealmEditorCatalogReady(:final value) => AsyncData(
        AuthoringValue(
          value: {
            for (final document in session.documents.entries)
              document.key.id: _decodePageElements(document.value, value),
          },
          revision: revision,
        ),
      ),
      RealmEditorCatalogUnavailable(:final diagnostics) => AsyncError(
        ElementDefinitionException(diagnostics),
        StackTrace.current,
      ),
      RealmEditorCatalogLoading() => const AsyncLoading(),
    },
    error: AsyncError.new,
    loading: AsyncLoading.new,
  );
}

@riverpod
AsyncValue<Map<String, List<PageElement>>> decodedRealmDocuments(
  Ref ref,
  skir.RecordId organizationId,
  skir.RecordId realmId,
) {
  final values = ref.watch(
    decodedRealmDocumentValuesProvider(organizationId, realmId),
  );
  if (values.mapUnready<Map<String, List<PageElement>>>() case final value?) {
    return value;
  }
  return AsyncData(values.requireValue.value);
}

@riverpod
AsyncValue<AuthoringValue<List<PageElement>>> authoringPageElements(
  Ref ref,
  skir.RecordId organizationId,
  skir.RecordId realmId,
  String pageId,
) {
  final page = ref.watch(pageElementsProvider(organizationId, realmId, pageId));
  if (page.mapUnready<AuthoringValue<List<PageElement>>>() case final value?) {
    return value;
  }
  final documents = ref.watch(
    decodedRealmDocumentValuesProvider(organizationId, realmId),
  );
  return documents.when(
    data: (value) {
      final elements = value.value[pageId];
      if (elements == null) {
        return AsyncError(ApiException.notFound("Page"), StackTrace.current);
      }
      return AsyncData(
        AuthoringValue(value: elements, revision: value.revision),
      );
    },
    error: AsyncError.new,
    loading: AsyncLoading.new,
  );
}

@riverpod
AsyncValue<AuthoringValue<Map<String, CachedPageEntry>>> authoringEntryIndex(
  Ref ref,
  skir.RecordId organizationId,
  skir.RecordId realmId,
) {
  final documents = ref.watch(
    decodedRealmDocumentValuesProvider(organizationId, realmId),
  );
  return documents.when(
    data: (value) => AsyncData(
      AuthoringValue(
        value: {
          for (final document in value.value.entries)
            for (final element in document.value)
              if (element case PageElementEntry(
                entry: DefinitionPageEntry(:final definition),
              ))
                definition.id: CachedPageEntry(
                  pageId: document.key,
                  definition: definition,
                ),
        },
        revision: value.revision,
      ),
    ),
    error: AsyncError.new,
    loading: AsyncLoading.new,
  );
}

@riverpod
AsyncValue<Map<String, CachedPageEntry>> realmEntryIndex(
  Ref ref,
  skir.RecordId organizationId,
  skir.RecordId realmId,
) {
  final values = ref.watch(
    authoringEntryIndexProvider(organizationId, realmId),
  );
  if (values.mapUnready<Map<String, CachedPageEntry>>() case final value?) {
    return value;
  }
  return AsyncData(values.requireValue.value);
}

@riverpod
AsyncValue<List<PageElement>> projectedPageElements(
  Ref ref,
  skir.RecordId organizationId,
  skir.RecordId realmId,
  String pageId,
) {
  final projected = ref.watch(
    projectedPageElementValuesProvider(organizationId, realmId, pageId),
  );
  if (projected.mapUnready<List<PageElement>>() case final value?) {
    return value;
  }
  return AsyncData(projected.requireValue.value);
}

/// Overlays local editor values onto canonical page elements.
///
/// Canonical revision and element identity remain unchanged. This is the read
/// model for responsive editors; persistence still belongs to the local work
/// and authoring session owners.
@riverpod
AsyncValue<AuthoringValue<List<PageElement>>> projectedPageElementValues(
  Ref ref,
  skir.RecordId organizationId,
  skir.RecordId realmId,
  String pageId,
) {
  final canonical = ref.watch(
    authoringPageElementsProvider(organizationId, realmId, pageId),
  );
  if (canonical.mapUnready<AuthoringValue<List<PageElement>>>()
      case final value?) {
    return value;
  }
  final local = ref.watch(
    localWorkProvider.select((state) => state.editorValues),
  );
  final value = canonical.requireValue;
  final projected = [
    for (final element in value.value)
      element.projected(
        local[EditorResourceKey(
          scope: EditorResourceScope(
            organizationId: organizationId,
            realmId: realmId,
          ),
          identity: recordId("element:${element.id}"),
        )],
      ),
  ];
  return AsyncData(
    AuthoringValue(value: projected.projectLinks(), revision: value.revision),
  );
}

@riverpod
AsyncValue<PageElement?> projectedPageElement(
  Ref ref,
  skir.RecordId organizationId,
  skir.RecordId realmId,
  String pageId,
  String elementId,
) {
  final canonical = ref.watch(
    projectedPageElementValuesProvider(organizationId, realmId, pageId),
  );
  if (canonical.mapUnready<PageElement?>() case final value?) {
    return value;
  }
  final element = canonical.requireValue.value
      .where((value) => value.id == elementId)
      .firstOrNull;
  return AsyncData(element);
}
