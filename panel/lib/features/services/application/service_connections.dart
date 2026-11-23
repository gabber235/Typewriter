part of "services.dart";

/// Shares one deadline projection for the services of the organization
/// selected by the current route; empty without one.
@riverpod
Map<skir.RecordId, bool> serviceConnections(Ref ref) {
  final organization = ref.watch(organizationIdProvider);
  if (organization == null) return const {};
  return ref.watch(organizationServiceConnectionsProvider(organization));
}

/// Shares one deadline projection for the services of [organizationId]
/// across its consumers.
///
/// Each service counts as connected until its heartbeat deadline passes;
/// the projection checks again at the nearest deadline and when the panel
/// resumes.
@riverpod
Map<skir.RecordId, bool> organizationServiceConnections(
  Ref ref,
  skir.RecordId organizationId,
) {
  final services =
      ref.watch(canonicalOrganizationServicesProvider(organizationId)).value ??
      const <skir.Service>[];

  final now = clock.now();
  final deadline = services
      .map((service) => service.connectionDeadline)
      .whereType<DateTime>()
      .where((deadline) => deadline.isAfter(now))
      .minOrNull;

  if (deadline != null) {
    final timer = Timer(deadline.difference(now), ref.invalidateSelf);
    ref.onDispose(timer.cancel);
  }

  final lifecycle = AppLifecycleListener(onResume: ref.invalidateSelf);
  ref.onDispose(lifecycle.dispose);

  return {
    for (final service in services)
      service.serviceId: service.isConnectedAt(now),
  };
}

/// Resolves host connectivity in the organization selected by the current
/// route; false without one. See [organizationHostConnected].
@riverpod
bool hostConnected(Ref ref, skir.RecordId hostId) {
  final organization = ref.watch(organizationIdProvider);
  if (organization == null) return false;
  return ref.watch(organizationHostConnectedProvider(organization, hostId));
}

/// Resolves host connectivity through its linked service heartbeat.
///
/// Host runtime status describes reconciliation, not transport reachability.
/// This provider therefore follows [skir.ServiceHost.serviceId] into the shared
/// service deadline projection of [organizationId] and returns false when
/// either record is absent.
@riverpod
bool organizationHostConnected(
  Ref ref,
  skir.RecordId organizationId,
  skir.RecordId hostId,
) {
  final topology = ref
      .watch(organizationTopologyControllerProvider(organizationId))
      .value;
  final connections = ref.watch(
    organizationServiceConnectionsProvider(organizationId),
  );
  final host = topology?.hosts.firstWhereOrNull(
    (host) => host.hostId == hostId,
  );
  return connections[host?.serviceId] ?? false;
}
