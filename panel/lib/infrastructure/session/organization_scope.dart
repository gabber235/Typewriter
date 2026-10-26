import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "organization_scope.g.dart";

/// Resolves the organization route parameter into the typed record identity.
///
/// A missing route parameter yields null. No provider fabricates an organization
/// identity, so nested organization consumers can distinguish an absent route
/// from a missing membership projection.
@Riverpod(keepAlive: true)
skir.RecordId? organizationId(Ref ref) {
  final id = ref.watch(routeParamProvider("organizationId"));
  if (id == null) return null;
  return skir.recordId("organization:$id");
}
