import "package:auto_route/auto_route.dart";
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/material_symbols.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Logical pixel size of one cell in the services topology graph.
const double servicesGraphCellSize = 44;
const int _nodeWidth = 4;
const int _nodeHeight = 4;

/// Projects organization services and runtime topology into the shared graph UI.
///
/// Service identities are the source for custom service nodes and host labels.
/// Topology supplies hosts and child runtime observations. A host is linked to
/// its Realm and engine children only when both endpoints are present, so stale
/// or partial observations remain visible without drawing false relationships.
/// Connectivity comes from service heartbeats, not runtime lifecycle status.
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
          description: "Start a Typewriter service and enter its registration token above.",
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

  /// Builds a render projection without mutating either provider owned model.
  ///
  /// Custom services without a host are included directly. Host nodes join by
  /// service identity, and child runtime nodes join by owner host identity. The
  /// resulting edge list is filtered again before layout as a defensive boundary
  /// against partial topology snapshots.
  _ServicesGraphProjection _project(BuildContext context, WidgetRef ref) {
    final availability = ref.watch(serviceConnectionsProvider);
    final servicesById = {
      for (final service in services) service.serviceId: service,
    };
    final hostsById = {for (final host in topology.hosts) host.hostId: host};
    final hostServiceIds = topology.hosts.map((host) => host.serviceId).toSet();
    final items = <_ServiceGraphItem>[
      for (final service in services)
        if (service.isCustom && !hostServiceIds.contains(service.serviceId))
          _customServiceItem(
            context,
            service,
            availability[service.serviceId] ?? false,
          ),
      for (final host in topology.hosts)
        _hostItem(
          context,
          host,
          servicesById[host.serviceId],
          availability[host.serviceId] ?? false,
        ),
      for (final realm in topology.realmInstances)
        _realmItem(
          context,
          ref,
          realm,
          hostsById[realm.ownerHost.id],
          servicesById,
          availability,
        ),
      for (final engine in topology.engineInstances)
        _engineItem(
          context,
          engine,
          hostsById[engine.ownerHost.id],
          servicesById,
          availability,
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

  /// Creates an edge only when both projected endpoint nodes exist.
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

  _ServiceGraphItem _customServiceItem(
    BuildContext context,
    Service service,
    bool connected,
  ) => _ServiceGraphItem(
    selectableId: ServiceIdentifier(service.serviceId),
    title: service.displayName,
    badge: "${service.role.label.formatted} service",
    status: connected ? "Connected" : "Offline",
    tone: connected ? TopologyStatusTone.active : TopologyStatusTone.offline,
    color: service.color,
    icon: service.icon,
    available: connected,
  );

  _ServiceGraphItem _hostItem(
    BuildContext context,
    TopologyHost host,
    Service? service,
    bool connected,
  ) {
    final status = connected
        ? hostRuntimeStatusLabel(host.state.status)
        : "Offline";
    return _ServiceGraphItem(
      selectableId: ServiceHostIdentifier(host.hostId),
      title: service?.displayName ?? _recordLabel(host.hostId),
      badge: host.entrypoint == "PAPER" ? "Paper host" : "Standalone host",
      status: status,
      tone: connected
          ? topologyHostStatusTone(host.state.status)
          : TopologyStatusTone.offline,
      color: service?.color ?? standaloneServiceColor,
      icon: host.entrypoint == "PAPER"
          ? Icons.sports_esports_outlined
          : Icons.cloud_outlined,
      available: connected,
    );
  }

  _ServiceGraphItem _realmItem(
    BuildContext context,
    WidgetRef ref,
    TopologyRealm realm,
    TopologyHost? host,
    Map<skir.RecordId, Service> services,
    Map<skir.RecordId, bool> connections,
  ) {
    final service = host == null ? null : services[host.serviceId];
    final connected = connections[service?.serviceId] ?? false;
    return _ServiceGraphItem(
      selectableId: RealmInstanceIdentifier(realm.realmId),
      title: realm.ownerHost.name.formatted,
      badge: "Realm",
      status: connected
          ? childRuntimeStatusLabel(realm.state.status)
          : "Host offline",
      tone: connected
          ? topologyChildRuntimeStatusTone(realm.state.status)
          : TopologyStatusTone.offline,
      color: realmServiceRoleColor,
      icon: Icons.cloud_outlined,
      available: connected,

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
    Map<skir.RecordId, bool> connections,
  ) {
    final service = host == null ? null : services[host.serviceId];
    final connected = connections[service?.serviceId] ?? false;
    return _ServiceGraphItem(
      selectableId: EngineInstanceIdentifier(engine.engineId),
      title: "${engine.target.engineId} ${engine.target.versionConstraint}",
      badge: "Engine",
      status: connected
          ? childRuntimeStatusLabel(engine.state.status)
          : "Host offline",
      tone: connected
          ? topologyChildRuntimeStatusTone(engine.state.status)
          : TopologyStatusTone.offline,
      color: engineServiceRoleColor,
      icon: Icons.memory_outlined,
      available: connected,
    );
  }

  void _openRealm(BuildContext context, WidgetRef ref, skir.RecordId realmId) {
    final organizationId = ref.read(organizationIdProvider);
    if (organizationId == null) return;
    context.router.navigate(realmNavigationRoute(organizationId, realmId));
  }
}

/// Renders one projected service or runtime item inside the shared selector.
///
/// Selection is handled by the shared graph interaction model. The node only
/// supplies labels, status emphasis, and the optional navigation callback.
class _ServiceGraphNode extends HookWidget {
  const _ServiceGraphNode({required this.item});

  final _ServiceGraphItem item;

  @override
  Widget build(BuildContext context) {
    final focusNode = useFocusNode();
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
              footer: TopologyStatusIndicator(
                label: item.status,
                tone: item.tone,
                color: item.color,
                highlighted: isSelected,
              ),
              width: _nodeWidth * servicesGraphCellSize,
              height: _nodeHeight * servicesGraphCellSize,
            ),
          ),
        ),
      ),
    );
  }
}

/// Displays a topology status label with the shared status tone treatment.
class TopologyStatusIndicator extends StatelessWidget {
  const TopologyStatusIndicator({
    required this.label,
    required this.tone,
    required this.color,
    this.highlighted = false,
    super.key,
  });

  final String label;
  final TopologyStatusTone tone;
  final Color color;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final foreground = highlighted ? color.on(context) : null;
    final toneColor = topologyStatusToneColor(context, tone);
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
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: foreground),
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

/// Display state for one selectable graph node.
///
/// [available] controls the de emphasis applied to stale or offline records.
/// Selection and navigation remain presentation concerns and do not alter the
/// underlying service or topology projections.
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
    this.onDoubleTap,
  });

  final SelectableIdentifier selectableId;
  final String title;
  final String badge;
  final String status;
  final TopologyStatusTone tone;
  final Color color;
  final IconData icon;
  final bool available;
  final VoidCallback? onDoubleTap;

  GraphIdentifier get graphId => GraphIdentifier(selectableId.id);
}

/// Maps operational host states to the limited visual vocabulary of the graph.
enum TopologyStatusTone { active, warning, error, offline }

TopologyStatusTone topologyHostStatusTone(TopologyHostStatus status) =>
    switch (status) {
      TopologyHostStatus.active => TopologyStatusTone.active,
      TopologyHostStatus.reconciling ||
      TopologyHostStatus.drifted => TopologyStatusTone.warning,
      TopologyHostStatus.failed => TopologyStatusTone.error,
      TopologyHostStatus.offline ||
      TopologyHostStatus.unknown => TopologyStatusTone.offline,
    };

TopologyStatusTone topologyChildRuntimeStatusTone(
  TopologyRuntimeStatus status,
) => switch (status) {
  TopologyRuntimeStatus.active => TopologyStatusTone.active,
  TopologyRuntimeStatus.staging ||
  TopologyRuntimeStatus.quiescing ||
  TopologyRuntimeStatus.drifted => TopologyStatusTone.warning,
  TopologyRuntimeStatus.failed => TopologyStatusTone.error,
  TopologyRuntimeStatus.absent ||
  TopologyRuntimeStatus.rolledBack ||
  TopologyRuntimeStatus.unknown => TopologyStatusTone.offline,
};

Color topologyStatusToneColor(BuildContext context, TopologyStatusTone tone) =>
    switch (tone) {
      TopologyStatusTone.active => context.colors.online,
      TopologyStatusTone.warning => context.colors.warning,
      TopologyStatusTone.error => Theme.of(context).colorScheme.error,
      TopologyStatusTone.offline => context.colors.offline,
    };

String _recordLabel(skir.RecordId id) {
  final value = id.id.split(":").last.replaceAll("`", "");
  return value.formatted;
}
