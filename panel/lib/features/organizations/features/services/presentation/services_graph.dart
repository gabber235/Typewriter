import "package:auto_route/auto_route.dart";
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/material_symbols.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

const double servicesGraphCellSize = 44;
const int _nodeWidth = 4;
const int _nodeHeight = 4;

class ServicesGraph extends ConsumerWidget {
  const ServicesGraph({
    required this.services,
    required this.topology,
    super.key,
  });

  final List<Service> services;
  final OrganizationTopology topology;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projection = _project(context, ref);
    if (projection.nodes.isEmpty) {
      return Center(
        child: EmptyState(
          title: "No services connected",
          description:
              "Start a Typewriter service and enter its registration token above.",
          icon: MaterialSymbols.dns,
        ),
      );
    }
    final data = const ServicesPackedLayout().layout(
      cellSize: servicesGraphCellSize,
      nodes: projection.nodes,
      connections: projection.connections,
    );
    return Graph(data: data);
  }

  _ServicesGraphProjection _project(BuildContext context, WidgetRef ref) {
    final servicesById = {
      for (final service in services) service.serviceId: service,
    };
    final hostsById = {for (final host in topology.hosts) host.hostId: host};
    final hostServiceIds = topology.hosts.map((host) => host.serviceId).toSet();
    final items = <_ServiceGraphItem>[
      for (final service in services)
        if (service.isCustom && !hostServiceIds.contains(service.serviceId))
          _customServiceItem(context, service),
      for (final host in topology.hosts)
        _hostItem(context, host, servicesById[host.serviceId]),
      for (final realm in topology.realmInstances)
        _realmItem(
          context,
          ref,
          realm,
          hostsById[realm.ownerHost.id],
          servicesById,
        ),
      for (final engine in topology.engineInstances)
        _engineItem(
          context,
          engine,
          hostsById[engine.ownerHost.id],
          servicesById,
        ),
    ];
    final nodes = [
      for (final item in items)
        ServicesPackedNode(
          id: item.graphId,
          width: _nodeWidth,
          height: _nodeHeight,
          builder: (_) => _ServiceGraphNode(item: item),
        ),
    ];
    final nodeIds = nodes.map((node) => node.id).toSet();
    final connections = <ServicesPackedConnection?>[
      for (final realm in topology.realmInstances)
        if (hostsById.containsKey(realm.ownerHost.id))
          _connection(
            id: "${realm.ownerHost.id}:${realm.realmId.id}",
            source: ServiceHostIdentifier(realm.ownerHost.id),
            target: RealmInstanceIdentifier(realm.realmId),
            color: realmServiceRoleColor,
            nodeIds: nodeIds,
          ),
      for (final engine in topology.engineInstances)
        if (hostsById.containsKey(engine.ownerHost.id))
          _connection(
            id: "${engine.ownerHost.id}:${engine.engineId.id}",
            source: ServiceHostIdentifier(engine.ownerHost.id),
            target: EngineInstanceIdentifier(engine.engineId),
            color: engineServiceRoleColor,
            nodeIds: nodeIds,
          ),
    ];
    return _ServicesGraphProjection(
      nodes: nodes,
      connections: connections.whereType<ServicesPackedConnection>().toList(),
    );
  }

  ServicesPackedConnection? _connection({
    required String id,
    required SelectableIdentifier source,
    required SelectableIdentifier target,
    required Color color,
    required Set<GraphIdentifier> nodeIds,
  }) {
    final sourceId = GraphIdentifier(source.id);
    final targetId = GraphIdentifier(target.id);
    if (!nodeIds.contains(sourceId) || !nodeIds.contains(targetId)) return null;
    return ServicesPackedConnection(
      id: id,
      source: sourceId,
      target: targetId,
      color: color,
    );
  }

  _ServiceGraphItem _customServiceItem(BuildContext context, Service service) =>
      _ServiceGraphItem(
        selectableId: ServiceIdentifier(service.serviceId),
        title: service.displayName,
        badge: "${service.role.label.formatted} service",
        status: service.isOnline ? "Connected" : "Offline",
        tone: service.isOnline ? _StatusTone.active : _StatusTone.offline,
        color: service.color,
        icon: service.icon,
        available: service.isOnline,
        nextRefresh: service.nextTimeout,
      );

  _ServiceGraphItem _hostItem(
    BuildContext context,
    TopologyHost host,
    Service? service,
  ) {
    final connected = service?.isOnline ?? false;
    final status = connected
        ? hostRuntimeStatusLabel(host.state.status)
        : "Offline";
    return _ServiceGraphItem(
      selectableId: ServiceHostIdentifier(host.hostId),
      title: service?.displayName ?? _recordLabel(host.hostId),
      badge: host.entrypoint == "PAPER" ? "Paper host" : "Standalone host",
      status: status,
      tone: connected ? _hostTone(host.state.status) : _StatusTone.offline,
      color: service?.color ?? standaloneServiceColor,
      icon: host.entrypoint == "PAPER"
          ? Icons.sports_esports_outlined
          : Icons.cloud_outlined,
      available: connected,
      nextRefresh: service?.nextTimeout ?? _distantRefresh,
    );
  }

  _ServiceGraphItem _realmItem(
    BuildContext context,
    WidgetRef ref,
    TopologyRealm realm,
    TopologyHost? host,
    Map<skir.RecordId, Service> services,
  ) {
    final service = host == null ? null : services[host.serviceId];
    final connected = service?.isOnline ?? false;
    return _ServiceGraphItem(
      selectableId: RealmInstanceIdentifier(realm.realmId),
      title: realm.ownerHost.name.formatted,
      badge: "Realm",
      status: connected
          ? childRuntimeStatusLabel(realm.state.status)
          : "Host offline",
      tone: connected ? _childTone(realm.state.status) : _StatusTone.offline,
      color: realmServiceRoleColor,
      icon: Icons.cloud_outlined,
      available: connected,
      nextRefresh: service?.nextTimeout ?? _distantRefresh,
      onDoubleTap: connected && host != null
          ? () => _openRealm(context, ref, realm.realmId)
          : null,
    );
  }

  _ServiceGraphItem _engineItem(
    BuildContext context,
    TopologyEngine engine,
    TopologyHost? host,
    Map<skir.RecordId, Service> services,
  ) {
    final service = host == null ? null : services[host.serviceId];
    final connected = service?.isOnline ?? false;
    return _ServiceGraphItem(
      selectableId: EngineInstanceIdentifier(engine.engineId),
      title:
          "${engine.target.engineId.formatted} ${engine.target.versionConstraint}",
      badge: "Engine",
      status: connected
          ? childRuntimeStatusLabel(engine.state.status)
          : "Host offline",
      tone: connected ? _childTone(engine.state.status) : _StatusTone.offline,
      color: engineServiceRoleColor,
      icon: Icons.memory_outlined,
      available: connected,
      nextRefresh: service?.nextTimeout ?? _distantRefresh,
    );
  }

  void _openRealm(BuildContext context, WidgetRef ref, skir.RecordId realmId) {
    final organizationId = ref.read(organizationIdProvider);
    if (organizationId == null) return;
    context.router.navigate(realmNavigationRoute(organizationId, realmId));
  }
}

class _ServiceGraphNode extends HookWidget {
  const _ServiceGraphNode({required this.item});

  final _ServiceGraphItem item;

  @override
  Widget build(BuildContext context) {
    final focusNode = useFocusNode();
    useRefreshAt(item.nextRefresh);
    return Selector(
      selectableId: item.selectableId,
      focusNode: focusNode,
      onDoubleTap: item.onDoubleTap,
      builder: (isSelected, isFocused, isHovered) => Semantics(
        label: "${item.badge}, ${item.title}, ${item.status}",
        selected: isSelected,
        button: true,
        child: ColoredBox(
          color: Surface.colorOf(context),
          child: Opacity(
            opacity: item.available || isSelected ? 1 : 0.58,
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
              footer: _NodeStatus(item: item, isSelected: isSelected),
              width: _nodeWidth * servicesGraphCellSize,
              height: _nodeHeight * servicesGraphCellSize,
            ),
          ),
        ),
      ),
    );
  }
}

class _NodeStatus extends StatelessWidget {
  const _NodeStatus({required this.item, required this.isSelected});

  final _ServiceGraphItem item;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final foreground = isSelected ? item.color.on(context) : null;
    final toneColor = switch (item.tone) {
      _StatusTone.active => context.colors.online,
      _StatusTone.warning => context.colors.warning,
      _StatusTone.error => Theme.of(context).colorScheme.error,
      _StatusTone.offline => context.colors.offline,
    };
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: foreground ?? toneColor,
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

class _ServicesGraphProjection {
  const _ServicesGraphProjection({
    required this.nodes,
    required this.connections,
  });

  final List<ServicesPackedNode> nodes;
  final List<ServicesPackedConnection> connections;
}

class _ServiceGraphItem {
  const _ServiceGraphItem({
    required this.selectableId,
    required this.title,
    required this.badge,
    required this.status,
    required this.tone,
    required this.color,
    required this.icon,
    required this.available,
    required this.nextRefresh,
    this.onDoubleTap,
  });

  final SelectableIdentifier selectableId;
  final String title;
  final String badge;
  final String status;
  final _StatusTone tone;
  final Color color;
  final IconData icon;
  final bool available;
  final DateTime nextRefresh;
  final VoidCallback? onDoubleTap;

  GraphIdentifier get graphId => GraphIdentifier(selectableId.id);
}

enum _StatusTone { active, warning, error, offline }

_StatusTone _hostTone(TopologyHostStatus status) => switch (status) {
  TopologyHostStatus.active => _StatusTone.active,
  TopologyHostStatus.reconciling ||
  TopologyHostStatus.drifted => _StatusTone.warning,
  TopologyHostStatus.failed => _StatusTone.error,
  TopologyHostStatus.offline ||
  TopologyHostStatus.unknown => _StatusTone.offline,
};

_StatusTone _childTone(TopologyRuntimeStatus status) => switch (status) {
  TopologyRuntimeStatus.active => _StatusTone.active,
  TopologyRuntimeStatus.staging ||
  TopologyRuntimeStatus.quiescing ||
  TopologyRuntimeStatus.drifted => _StatusTone.warning,
  TopologyRuntimeStatus.failed => _StatusTone.error,
  TopologyRuntimeStatus.absent ||
  TopologyRuntimeStatus.rolledBack ||
  TopologyRuntimeStatus.unknown => _StatusTone.offline,
};

String _recordLabel(skir.RecordId id) {
  final value = id.id.split(":").last.replaceAll("`", "");
  return value.formatted;
}

DateTime get _distantRefresh => DateTime.now().add(const Duration(days: 365));
