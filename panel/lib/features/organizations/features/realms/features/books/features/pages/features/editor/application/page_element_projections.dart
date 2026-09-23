part of "page_elements.dart";

@riverpod
AsyncValue<AuthoringValue<Map<String, List<PageElement>>>>
decodedRealmDocumentValues(
  Ref ref,
  skir.RecordId organizationId,
  skir.RecordId realmId,
) {
  if (ref.watch(organizationIdProvider) != organizationId ||
      ref.watch(realmIdProvider) != realmId) {
    return const AsyncLoading();
  }
  final session = ref.watch(authoringSessionProvider(organizationId, realmId));
  final revision = session.sequence;
  if (revision == null) return const AsyncLoading();
  final roots = SkirTypeCodec(TypeRegistry(const TypeCatalog([])));
  ref.watch(
    realmEditorCatalogLeaseProvider(
      RealmEditorCatalogRequest(
        types: {
          for (final resource in session.resources.values)
            ?roots.decodeReference(resource.content.rootType).valueOrNull,
          for (final subject in session.presentations.values)
            ...[subject.content, subject.descriptor, subject.identity]
                .map(
                  (envelope) =>
                      roots.decodeReference(envelope.rootType).valueOrNull,
                )
                .nonNulls,
        },
      ),
    ),
  );
  final catalog = ref.watch(realmEditorCatalogProvider);
  if (catalog.isLoading) return const AsyncLoading();
  return catalog.when(
    data: (catalogState) => switch (catalogState) {
      RealmEditorCatalogReady(:final value) => AsyncData(
        AuthoringValue(
          value: {
            for (final selection in session.selections.entries)
              if (PageContentSelectionKey.parse(selection.key) case final key?)
                key.page.value: _decodePageElements(
                  key.page,
                  selection.value.resourceIds
                      .map((id) => session.resources[id])
                      .nonNulls,
                  selection.value.edgeIds
                      .map((id) => session.edges[id])
                      .nonNulls,
                  session.presentations,
                  value,
                ),
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
  if (projected.mapUnready<List<PageElement>>() case final value?) return value;
  return AsyncData(projected.requireValue.value);
}

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
          identity: skir.ResourceId(value: element.id),
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
  return canonical.when(
    data: (value) => AsyncData(
      value.value.where((element) => element.id == elementId).firstOrNull,
    ),
    error: AsyncError.new,
    loading: AsyncLoading.new,
  );
}
