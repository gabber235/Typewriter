import "package:auto_route/auto_route.dart";
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/material_symbols.dart";
import "package:responsive_framework/responsive_framework.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

const double _cardWidth = 180;
const double _cardAspectRatio = 1.05;

/// Projects custom services and all runtime topology resources into one grid.
///
/// Every card participates in the application selection model. Official host
/// services are represented by their host card because the host inspector owns
/// both records. Custom services remain independent cards. Ordering is stable:
/// custom services, hosts, Realms, then execution engines.
class ServicesGrid extends ConsumerWidget {
  const ServicesGrid({
    required this.services,
    required this.topology,
    super.key,
  });

  final List<Service> services;
  final OrganizationTopology topology;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = _items(context, ref);
    if (items.isEmpty) {
      return Center(
        child: EmptyState(
          title: "No services connected",
          description:
              "Start a Typewriter service and enter its registration token above.",
          icon: MaterialSymbols.dns,
        ),
      );
    }
    return ClipPath(
      clipper: VerticalClipper(additionalWidth: 100),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.spacing.space2,
          vertical: context.spacing.space4,
        ),
        child: ResponsiveGridView.builder(
          gridDelegate: ResponsiveGridDelegate(
            crossAxisExtent: _cardWidth,
            mainAxisSpacing: context.spacing.space4,
            crossAxisSpacing: context.spacing.space4,
            childAspectRatio: _cardAspectRatio,
          ),
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          itemCount: items.length,
          itemBuilder: (context, index) => _GridItemCard(item: items[index]),
        ),
      ),
    );
  }

  List<_GridItem> _items(BuildContext context, WidgetRef ref) {
    final hostServiceIds = topology.hosts.map((host) => host.serviceId).toSet();
    final servicesById = {
      for (final service in services) service.serviceId: service,
    };
    final hostsById = {for (final host in topology.hosts) host.hostId: host};
    return [
      for (final service in services)
        if (service.isCustom && !hostServiceIds.contains(service.serviceId))
          _GridItem(
            id: ServiceIdentifier(service.serviceId),
            title: service.displayName,
            badge: "Service",
            status: service.isOnline ? "Connected" : "Offline",
            color: service.color,
            icon: service.icon,
            connected: service.isOnline,
          ),
      for (final host in topology.hosts)
        _hostItem(host, servicesById[host.serviceId]),
      for (final realm in topology.realmInstances)
        _realmItem(context, ref, realm, hostsById, servicesById),
      for (final engine in topology.engineInstances)
        _engineItem(engine, hostsById, servicesById),
    ];
  }

  _GridItem _hostItem(skir.ServiceHost host, Service? service) => _GridItem(
    id: ServiceHostIdentifier(host.hostId),
    title: service?.displayName ?? host.hostId.id,
    badge: host.entrypoint == "PAPER" ? "Paper host" : "Standalone host",
    status: host.topologyRevision.desired == host.topologyRevision.applied
        ? "${service?.isOnline ?? false ? "Connected" : "Offline"}, reconciled"
        : "Reconciling topology",
    color: service?.color ?? standaloneServiceColor,
    icon: host.entrypoint == "PAPER"
        ? Icons.sports_esports_outlined
        : Icons.cloud_outlined,
    connected: service?.isOnline ?? false,
  );

  _GridItem _realmItem(
    BuildContext context,
    WidgetRef ref,
    skir.RealmInstance realm,
    Map<skir.RecordId, skir.ServiceHost> hosts,
    Map<skir.RecordId, Service> services,
  ) {
    final host = hosts[realm.ownerHostId];
    final service = host == null ? null : services[host.serviceId];
    final connected = service?.isOnline ?? false;
    return _GridItem(
      id: RealmInstanceIdentifier(realm.realmId),
      title: service?.displayName ?? realm.realmId.id,
      badge: "Realm",
      status: connected
          ? childRuntimeStatusLabel(realm.state.status)
          : "Host offline",
      color: realmServiceRoleColor,
      icon: Icons.cloud_outlined,
      connected: connected,
      onDoubleTap: connected && host != null
          ? () => _openRealm(context, ref, host.serviceId)
          : null,
    );
  }

  _GridItem _engineItem(
    skir.EngineInstance engine,
    Map<skir.RecordId, skir.ServiceHost> hosts,
    Map<skir.RecordId, Service> services,
  ) {
    final host = hosts[engine.ownerHostId];
    final connected =
        host != null && (services[host.serviceId]?.isOnline ?? false);
    return _GridItem(
      id: EngineInstanceIdentifier(engine.engineId),
      title: "${engine.target.engineId.formatted} engine",
      badge: "Engine",
      status: connected
          ? childRuntimeStatusLabel(engine.state.status)
          : "Host offline",
      color: engineServiceRoleColor,
      icon: Icons.memory_outlined,
      connected: connected,
    );
  }

  void _openRealm(
    BuildContext context,
    WidgetRef ref,
    skir.RecordId serviceId,
  ) {
    final organizationId = ref.read(organizationIdProvider);
    if (organizationId == null) return;
    context.router.navigate(
      OrganizationRoute(
        organizationId: organizationId.id,
        children: [RealmRoute(realmId: serviceId.id)],
      ),
    );
  }
}

class _GridItemCard extends HookWidget {
  const _GridItemCard({required this.item});

  final _GridItem item;

  @override
  Widget build(BuildContext context) {
    final focusNode = useFocusNode();
    return Selector(
      selectableId: item.id,
      focusNode: focusNode,
      onDoubleTap: item.onDoubleTap,
      builder: (isSelected, isFocused, isHovered) => Semantics(
        label: "${item.badge}, ${item.title}, ${item.status}",
        selected: isSelected,
        button: true,
        child: Opacity(
          opacity: item.connected || isSelected ? 1 : 0.58,
          child: GridSelectableCard(
            title: item.title,
            baseColor: item.color,
            onBaseColor: item.color.on(context),
            badgeOnColor: item.color.on(context),
            isSelected: isSelected,
            isFocused: isFocused,
            isHovered: isHovered,
            badgeLabel: item.badge,
            header: Icon(item.icon, size: 30),
            footer: _GridItemStatus(item: item, isSelected: isSelected),
          ),
        ),
      ),
    );
  }
}

class _GridItemStatus extends StatelessWidget {
  const _GridItemStatus({required this.item, required this.isSelected});

  final _GridItem item;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final foreground = isSelected ? item.color.on(context) : null;
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                foreground ??
                (item.connected
                    ? context.colors.online
                    : context.colors.offline),
          ),
        ),
        SizedBox(width: context.spacing.space1),
        Expanded(
          child: Text(
            item.status,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: foreground),
          ),
        ),
      ],
    );
  }
}

class _GridItem {
  const _GridItem({
    required this.id,
    required this.title,
    required this.badge,
    required this.status,
    required this.color,
    required this.icon,
    required this.connected,
    this.onDoubleTap,
  });

  final SelectableIdentifier id;
  final String title;
  final String badge;
  final String status;
  final Color color;
  final IconData icon;
  final bool connected;
  final VoidCallback? onDoubleTap;
}
