part of "services.dart";

Duration? _noRouteRetry(int retryCount, Object error) => null;

/// Adapts the organization scoped service projection to the current route.
///
/// The route provider owns no service data. It follows the selected
/// organization and watches [CanonicalOrganizationServices], returning an empty
/// projection when no organization is selected.
@Riverpod(retry: _noRouteRetry)
FutureOr<List<Service>> canonicalServices(Ref ref) {
  final organization = ref.watch(organizationIdProvider);
  if (organization == null) return const [];
  return ref.watch(canonicalOrganizationServicesProvider(organization).future);
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
/// [OrganizationTopologyController] and returns an empty topology without an
/// organization. Each canonical update recomputes this route projection.
@Riverpod(retry: _noRouteRetry)
FutureOr<OrganizationTopology> organizationTopology(Ref ref) {
  final organization = ref.watch(organizationIdProvider);
  if (organization == null) return OrganizationTopology.empty;
  return ref.watch(organizationTopologyControllerProvider(organization).future);
}
