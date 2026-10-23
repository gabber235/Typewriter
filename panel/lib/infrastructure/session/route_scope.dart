import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "route_scope.g.dart";

/// Resolves the route's realm parameter to the typed topology identifier.
///
/// A missing parameter deliberately remains `null`; it represents the
/// organization level route, not a failed lookup. Authoring reads it, so it
/// sits below authoring.
@riverpod
skir.RecordId? realmId(Ref ref) {
  final id = ref.watch(routeParamProvider("realmId"));
  if (id == null) return null;
  return skir.recordId("realm_instance:$id");
}
