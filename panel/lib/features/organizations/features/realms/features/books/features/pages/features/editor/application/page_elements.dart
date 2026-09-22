import "dart:async";

import "package:flutter/widgets.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:hooks_riverpod/hooks_riverpod.dart"
    show ProviderScope, WidgetRef;
import "package:riverpod/riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "page_element_codec.dart";
part "page_element_access.dart";
part "page_element_links.dart";
part "page_element_models.dart";
part "page_element_mutation_context.dart";
part "page_element_mutations.dart";
part "page_element_projections.dart";
part "page_element_relationships.dart";
part "page_element_values.dart";
part "page_elements.freezed.dart";
part "page_elements.g.dart";

/// Logical pixels represented by one persisted page graph cell.
const entryGraphCellSize = 50.0;

/// Projects compile diagnostics for the selected page without hiding the last
/// active manifest when a new document is blocked.
@riverpod
PageDocumentHealth? pageDocumentHealth(
  Ref ref,
  skir.RecordId organizationId,
  skir.RecordId realmId,
  skir.ResourceId pageId,
) {
  final activeOrganizationId = ref.watch(organizationIdProvider);
  final activeRealmId = ref.watch(realmIdProvider);
  if (activeOrganizationId != organizationId || activeRealmId != realmId) {
    return null;
  }
  final session = ref.watch(authoringSessionProvider(organizationId, realmId));
  if (!session.resources.containsKey(pageId)) return null;
  final matchingStatuses = session.compiledStatuses.entries.where(
    (entry) => entry.key.resource == pageId,
  );
  final status = matchingStatuses.isEmpty ? null : matchingStatuses.first.value;
  final diagnostics = session.diagnostics
      .where((diagnostic) => diagnostic.resource == pageId)
      .map((diagnostic) => diagnostic.message)
      .toList(growable: false);
  return PageDocumentHealth(
    diagnostics: diagnostics,
    compileBlocked: status is skir.CompiledResourceState_blockedWrapper,
    activeManifestId: switch (status) {
      skir.CompiledResourceState_activeWrapper(:final value) =>
        value.manifestId,
      skir.CompiledResourceState_blockedWrapper(:final value) =>
        value.lastActiveManifestId,
      _ => null,
    },
  );
}

/// Owns the page scoped editing coordinator.
///
/// The provider acquires the page lease, waits for the authoring session and
/// catalog projection, then exposes mutations that submit through the shared
/// editor owners. Callers should use [withReadyPageElements] when invoking it
/// outside a widget that already holds the page lifecycle.
@riverpod
class PageElements extends _$PageElements
    with
        _PageElementMutationContext,
        _PageElementValues,
        _PageElementMutations {
  @override
  Future<List<PageElement>> build(
    skir.RecordId organizationId,
    skir.RecordId realmId,
    String pageId,
  ) async {
    _pageId = skir.ResourceId(value: pageId);
    if (ref.watch(organizationIdProvider) != organizationId ||
        ref.watch(realmIdProvider) != realmId) {
      throw ApiException.conflict("The selected realm changed");
    }
    _sessionProvider = authoringSessionProvider(organizationId, realmId);
    final lease = ref.watch(
      authoringSelectionLeaseProvider(
        organizationId,
        realmId,
        _pageId.pageAuthoringSelection,
      ),
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
