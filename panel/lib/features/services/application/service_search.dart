part of "services.dart";

const serviceSearchResultType = SearchResultType(
  id: "service",
  rowRendererId: "service",
  label: "Service",
);

/// One service as search shows it, joined with the card the services page
/// shows for it: its own card for a custom service, or its host's card.
@freezed
abstract class ServiceSearchItem with _$ServiceSearchItem {
  const factory ServiceSearchItem({
    required skir.Service service,
    required bool connected,

    /// The host the service runs, whose card stands for the service.
    skir.ServiceHost? host,
  }) = _ServiceSearchItem;

  const ServiceSearchItem._();

  /// The card the services page selects for this service.
  SelectableIdentifier get selectable => switch (host) {
    final host? => ServiceHostIdentifier(host.hostId),
    null => ServiceIdentifier(service.serviceId),
  };
}

/// The selected organization's services that the services page shows a card
/// for, for search: each custom service, and each service running a host.
///
/// Gives none while services or topology still belong to the organization
/// shown before, so search never lists another organization's services.
@riverpod
AsyncValue<List<ServiceSearchItem>> serviceSearchItems(Ref ref) {
  final reloading =
      ref.watch(
        canonicalServicesProvider.select((value) => value.isReloading),
      ) ||
      ref.watch(
        organizationTopologyProvider.select((value) => value.isReloading),
      );
  if (reloading) return const AsyncLoading();
  final services = ref.watch(projectedServicesProvider);
  if (services.mapUnready<List<ServiceSearchItem>>() case final unready?) {
    return unready;
  }
  final topology = ref.watch(organizationTopologyProvider);
  if (topology.mapUnready<List<ServiceSearchItem>>() case final unready?) {
    return unready;
  }
  final connections = ref.watch(serviceConnectionsProvider);
  final hosts = {
    for (final host in topology.requireValue.hosts) host.serviceId: host,
  };
  return AsyncData([
    for (final service in services.requireValue)
      if (hosts[service.serviceId] != null || service.isCustom)
        ServiceSearchItem(
          service: service,
          host: hosts[service.serviceId],
          connected: connections[service.serviceId] ?? false,
        ),
  ]);
}
