import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "page_creation_slots.g.dart";

enum RealmPageCreationPlacement { graph, timelineTrack }

extension RealmPageCreationSlotPresentation on RealmAuthoringCreationSlot {
  RealmPageCreationPlacement get pagePlacement => id.value.endsWith("/graph")
      ? RealmPageCreationPlacement.graph
      : RealmPageCreationPlacement.timelineTrack;
}

/// Returns the Realm supplied creation slot for one page kind.
///
/// The page catalog only chooses which slot applies to the page editor. The
/// slot itself owns the accepted concrete roots, host relation, and created
/// resource definition.
@riverpod
AsyncValue<RealmAuthoringCreationSlot> pageCreationSlot(
  Ref ref,
  PageKindRef pageKind,
) {
  final catalog = ref.watch(realmEditorCatalogProvider);
  if (catalog.mapUnready<RealmAuthoringCreationSlot>() case final value?) {
    return value;
  }
  final snapshot = catalog.requireValue.snapshot;
  if (snapshot == null) {
    return AsyncError(
      ApiException.badRequest("The editor catalog is unavailable"),
      StackTrace.current,
    );
  }
  final definition = snapshot.pageCatalog.definitions[pageKind];
  if (definition == null) {
    return AsyncError(
      ApiException.badRequest("The page kind is unavailable"),
      StackTrace.current,
    );
  }
  final slot = definition.creationSlot(snapshot);
  if (slot == null) {
    return AsyncError(
      ApiException.badRequest("The page kind has no creation slot"),
      StackTrace.current,
    );
  }
  return AsyncData(slot);
}

/// Returns the live creation slot for one projected page.
@riverpod
AsyncValue<RealmAuthoringCreationSlot> pageCreationSlotForPage(
  Ref ref,
  skir.ResourceId pageId,
) {
  final page = ref.watch(projectedPageProvider(pageId));
  if (page.mapUnready<RealmAuthoringCreationSlot>() case final value?) {
    return value;
  }
  return ref.watch(pageCreationSlotProvider(page.requireValue.kind));
}

/// Returns every page slot that accepts [elementType].
@riverpod
AsyncValue<Map<PageKindRef, RealmAuthoringCreationSlot>>
compatiblePageCreationSlots(Ref ref, ResolvedTypeRef elementType) {
  final catalog = ref.watch(realmEditorCatalogProvider);
  if (catalog.mapUnready<Map<PageKindRef, RealmAuthoringCreationSlot>>()
      case final value?) {
    return value;
  }
  final snapshot = catalog.requireValue.snapshot;
  if (snapshot == null) {
    return AsyncError(
      ApiException.badRequest("The editor catalog is unavailable"),
      StackTrace.current,
    );
  }
  final slots = <PageKindRef, RealmAuthoringCreationSlot>{};
  for (final definition in snapshot.pageCatalog.definitions.values) {
    final slot = definition.creationSlot(snapshot);
    if (slot?.acceptsRoot(elementType) == true) {
      slots[definition.kind] = slot!;
    }
  }
  return AsyncData(Map.unmodifiable(slots));
}

/// Returns the creation slot selected for every page kind in the catalog.
@riverpod
AsyncValue<Map<PageKindRef, RealmAuthoringCreationSlot>> pageCreationSlots(
  Ref ref,
) {
  final catalog = ref.watch(realmEditorCatalogProvider);
  if (catalog.mapUnready<Map<PageKindRef, RealmAuthoringCreationSlot>>()
      case final value?) {
    return value;
  }
  final snapshot = catalog.requireValue.snapshot;
  if (snapshot == null) {
    return AsyncError(
      ApiException.badRequest("The editor catalog is unavailable"),
      StackTrace.current,
    );
  }
  final slots = <PageKindRef, RealmAuthoringCreationSlot>{};
  for (final definition in snapshot.pageCatalog.definitions.values) {
    final slot = definition.creationSlot(snapshot);
    if (slot != null) slots[definition.kind] = slot;
  }
  return AsyncData(Map.unmodifiable(slots));
}

extension on RealmPageDefinition {
  RealmAuthoringCreationSlot? creationSlot(
    RealmEditorCatalogSnapshot snapshot,
  ) {
    final placement = switch (editor) {
      RealmGraphPageEditor() => "graph",
      RealmTimelinePageEditor() => "timeline",
    };
    return snapshot.creationSlots[CoreAuthoringCreationSlotIds.pageElements(
      kind,
      placement,
    )];
  }
}
