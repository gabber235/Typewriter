import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "page_relation_fields.g.dart";

@riverpod
AsyncValue<RealmRelationField> pageElementsField(
  Ref ref,
  ResolvedTypeRef pageType,
) {
  final catalog = ref.watch(realmEditorCatalogProvider);
  if (catalog.isLoading) return const AsyncLoading();
  if (catalog.mapUnready<RealmRelationField>() case final value?) return value;
  final snapshot = catalog.requireValue;
  final field = snapshot.relationField(
    pageType,
    DataPath.root.field("elements"),
  );
  if (field == null) {
    return AsyncError(
      ApiException.badRequest("The Page has no elements relation"),
      StackTrace.current,
    );
  }
  return AsyncData(field);
}

@riverpod
AsyncValue<RealmRelationField> pageElementsFieldForPage(
  Ref ref,
  skir.ResourceId pageId,
) {
  final page = ref.watch(projectedPageProvider(pageId));
  if (page.mapUnready<RealmRelationField>() case final value?) return value;
  return ref.watch(pageElementsFieldProvider(page.requireValue.rootType));
}

@riverpod
AsyncValue<Map<ResolvedTypeRef, RealmRelationField>>
compatiblePageElementsFields(Ref ref, ResolvedTypeRef elementType) {
  final fields = ref.watch(pageElementsFieldsProvider);
  if (fields.mapUnready<Map<ResolvedTypeRef, RealmRelationField>>()
      case final value?) {
    return value;
  }
  final catalogState = ref.watch(realmEditorCatalogProvider);
  if (catalogState.isLoading) return const AsyncLoading();
  if (catalogState.mapUnready<Map<ResolvedTypeRef, RealmRelationField>>()
      case final pending?) {
    return pending;
  }
  final catalog = catalogState.requireValue;
  final registry = TypeRegistry(catalog.catalog);
  return AsyncData(
    Map.unmodifiable({
      for (final entry in fields.requireValue.entries)
        if (entry.value.accepts(elementType, registry)) entry.key: entry.value,
    }),
  );
}

@riverpod
AsyncValue<Map<ResolvedTypeRef, RealmRelationField>> pageElementsFields(
  Ref ref,
) {
  final catalog = ref.watch(realmEditorCatalogProvider);
  if (catalog.isLoading) return const AsyncLoading();
  if (catalog.mapUnready<Map<ResolvedTypeRef, RealmRelationField>>()
      case final value?) {
    return value;
  }
  final snapshot = catalog.requireValue;
  final fields = <ResolvedTypeRef, RealmRelationField>{};
  for (final definition in snapshot.types.values.where(
    (entry) => entry.editor != null,
  )) {
    final field = snapshot.relationField(
      definition.type,
      DataPath.root.field("elements"),
    );
    if (field != null) fields[definition.type] = field;
  }
  return AsyncData(Map.unmodifiable(fields));
}
