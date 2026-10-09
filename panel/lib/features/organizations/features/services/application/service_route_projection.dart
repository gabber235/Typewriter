part of "services.dart";

/// Adapts the organization scoped service projection to the current route.
///
/// The route provider owns no service data. It follows the selected
/// organization and delegates reads and mutations to
/// [CanonicalOrganizationServices], yielding an empty projection when no
/// organization is selected.
@riverpod
class CanonicalServices extends _$CanonicalServices {
  @override
  Stream<List<Service>> build() async* {
    final organization = ref.watch(organizationIdProvider);
    if (organization == null) {
      yield [];
      return;
    }
    final provider = canonicalOrganizationServicesProvider(organization);
    ref.listen(provider, (_, next) => state = next);
    yield await ref.read(provider.future);
  }
}

/// Overlays active local editor drafts on canonical service identities.
///
/// Canonical revisions and runtime observations remain untouched. Consumers
/// that render editable names should use this projection, while mutation
/// preparation must retain the canonical snapshot.
@riverpod
AsyncValue<List<Service>> projectedServices(Ref ref) {
  final canonical = ref.watch(canonicalServicesProvider);
  if (canonical.mapUnready<List<Service>>() case final value?) return value;

  final organization = ref.watch(organizationIdProvider);
  if (organization == null) return AsyncData(canonical.requireValue);

  final local = ref.watch(
    localWorkProvider.select((state) => state.editorValues),
  );
  return AsyncData([
    for (final service in canonical.requireValue)
      service.projected(
        local[EditorResourceKey(
          scope: EditorResourceScope(organizationId: organization),
          identity: service.serviceId,
        )],
      ),
  ]);
}

/// Resolves one service with its unsaved local identity draft applied.
@riverpod
AsyncValue<Service?> projectedService(Ref ref, skir.RecordId serviceId) {
  final canonical = ref.watch(canonicalServiceProvider(serviceId));
  if (canonical.mapUnready<Service?>() case final value?) return value;

  final organization = ref.watch(organizationIdProvider);
  if (organization == null) return canonical;

  final key = EditorResourceKey(
    scope: EditorResourceScope(organizationId: organization),
    identity: serviceId,
  );
  final local = ref.watch(
    localWorkProvider.select((state) => state.editorValues[key]),
  );
  return AsyncData(canonical.requireValue?.projected(local));
}

/// Exposes topology for the organization selected by the current route.
///
/// The route projection delegates lifecycle and reconciliation to
/// [OrganizationTopologyController] and yields an empty topology without an
/// organization.
@riverpod
Stream<OrganizationTopology> organizationTopologyStream(Ref ref) async* {
  final organization = ref.watch(organizationIdProvider);
  if (organization == null) {
    yield OrganizationTopology.empty;
    return;
  }
  yield await ref.watch(
    organizationTopologyControllerProvider(organization).future,
  );
}
