import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "realm_relation_field_provider.g.dart";

@riverpod
AsyncValue<RealmRelationField> relationFieldForResource(
  Ref ref,
  skir.ResourceId owner,
  DataPath path,
) {
  final catalog = ref.watch(realmEditorCatalogProvider);
  if (catalog.mapUnready<RealmRelationField>() case final pending?) {
    return pending;
  }
  final snapshot = catalog.requireValue.snapshot;
  final organizationId = ref.watch(organizationIdProvider);
  final realmId = ref.watch(realmIdProvider);
  if (snapshot == null || organizationId == null || realmId == null) {
    return AsyncError(
      ApiException.badRequest("The Realm catalog is unavailable"),
      StackTrace.current,
    );
  }
  final session = ref.watch(authoringSessionProvider(organizationId, realmId));
  final resource = session.resources[owner];
  if (resource == null) {
    return AsyncError(ApiException.notFound("Resource"), StackTrace.current);
  }
  final decoded = TypedAuthoringCodec(snapshot).decodeResourceOrThrow(resource);
  final field = snapshot.relationField(decoded.content.rootType, path);
  if (field == null) {
    return AsyncError(
      ApiException.badRequest("The resource has no relation at $path"),
      StackTrace.current,
    );
  }
  return AsyncData(field);
}
