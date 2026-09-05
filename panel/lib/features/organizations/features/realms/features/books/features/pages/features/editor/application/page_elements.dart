import "dart:async";

import "package:freezed_annotation/freezed_annotation.dart";
import "package:hooks_riverpod/hooks_riverpod.dart"
    show ProviderScope, WidgetRef;
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/type_catalog.dart"
    show TypedValue;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/library/v1/authoring.dart"
    as wire;
import "package:typewriter_panel/typewriter_panel.dart";

part "page_element_codec.dart";
part "page_element_access.dart";
part "page_element_models.dart";
part "page_element_mutation_context.dart";
part "page_element_mutations.dart";
part "page_element_values.dart";
part "page_elements.freezed.dart";
part "page_elements.g.dart";

@riverpod
AsyncValue<Map<String, List<PageElement>>> decodedRealmDocuments(
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
  if (session.sequence == null) return const AsyncLoading();
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
      RealmEditorCatalogReady(:final value) => AsyncData({
        for (final document in session.documents.entries)
          document.key.id: _decodePageElements(
            document.value,
            value,
            session.sequence!,
          ),
      }),
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
AsyncValue<Map<String, CachedPageEntry>> realmEntryIndex(
  Ref ref,
  skir.RecordId organizationId,
  skir.RecordId realmId,
) {
  return ref
      .watch(decodedRealmDocumentsProvider(organizationId, realmId))
      .whenData(
        (documents) => {
          for (final document in documents.entries)
            for (final element in document.value)
              if (element case PageElementEntry(
                entry: DefinitionPageEntry(:final definition),
              ))
                definition.id: CachedPageEntry(
                  pageId: document.key,
                  definition: definition,
                ),
        },
      );
}

@riverpod
PageDocumentHealth? pageDocumentHealth(
  Ref ref,
  skir.RecordId organizationId,
  skir.RecordId realmId,
  skir.RecordId pageId,
) {
  final activeOrganizationId = ref.watch(organizationIdProvider);
  final activeRealmId = ref.watch(realmIdProvider);
  if (activeOrganizationId != organizationId || activeRealmId != realmId) {
    return null;
  }
  final document = ref
      .watch(authoringSessionProvider(organizationId, realmId))
      .documents[pageId];
  if (document == null) return null;
  return PageDocumentHealth(
    diagnostics: document.diagnostics
        .map((diagnostic) => diagnostic.message)
        .toList(growable: false),
    compileBlocked:
        document.compileStatus is wire.PageCompileStatus_blockedWrapper,
    activeManifestId: switch (document.compileStatus) {
      wire.PageCompileStatus_activeWrapper(:final value) => value.manifestId,
      wire.PageCompileStatus_blockedWrapper(:final value) =>
        value.lastActiveManifestId,
      _ => null,
    },
  );
}

@riverpod
class PageElements extends _$PageElements
    with
        _PageElementMutationContext,
        _PageElementMutations,
        _PageElementValues {
  @override
  Future<List<PageElement>> build(
    skir.RecordId organizationId,
    skir.RecordId realmId,
    String pageId,
  ) async {
    _pageId = recordId("page:$pageId");
    if (ref.watch(organizationIdProvider) != organizationId ||
        ref.watch(realmIdProvider) != realmId) {
      throw ApiException.conflict("The selected realm changed");
    }
    _sessionProvider = authoringSessionProvider(organizationId, realmId);
    final lease = ref.watch(
      authoringPageScopeProvider(organizationId, realmId, _pageId),
    );
    final documentsProvider = decodedRealmDocumentsProvider(
      organizationId,
      realmId,
    );
    var scopeReady = false;
    final initial = Completer<List<PageElement>>();
    void applyDocuments(AsyncValue<Map<String, List<PageElement>>> documents) {
      if (!scopeReady) return;
      final AsyncValue<List<PageElement>>? projected = switch (documents) {
        AsyncData(:final value) when value[pageId] != null => AsyncData(
          value[pageId]!,
        ),
        AsyncData() => AsyncError(
          ApiException.notFound("Page"),
          StackTrace.current,
        ),
        AsyncError(:final error, :final stackTrace) => AsyncError(
          error,
          stackTrace,
        ),
        AsyncLoading() => null,
      };
      if (projected == null) return;
      if (!initial.isCompleted) {
        switch (projected) {
          case AsyncData(:final value):
            initial.complete(value);
          case AsyncError(:final error, :final stackTrace):
            initial.completeError(error, stackTrace);
          case AsyncLoading():
        }
        return;
      }
      state = projected;
    }

    ref.listen(documentsProvider, (_, documents) => applyDocuments(documents));
    await lease.ready;
    if (!ref.mounted) return initial.future;
    scopeReady = true;
    applyDocuments(ref.read(documentsProvider));
    return initial.future;
  }
}
