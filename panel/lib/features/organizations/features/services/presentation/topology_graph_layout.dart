part of "topology_graph.dart";

enum _TopologyNodeKind { host, realm, engine }

class _TopologyNode {
  const _TopologyNode({
    required this.kind,
    required this.hostId,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.position,
    required this.order,
  });

  final _TopologyNodeKind kind;
  final skir.RecordId hostId;
  final String title;
  final String subtitle;
  final String status;
  final Offset position;
  final int order;
}

class _TopologyLayout {
  _TopologyLayout(OrganizationTopology topology) {
    var order = 0;
    for (var index = 0; index < topology.hosts.length; index++) {
      final host = topology.hosts[index];
      final y = 56.0 + index * 190;
      nodes.add(
        _TopologyNode(
          kind: _TopologyNodeKind.host,
          hostId: host.hostId,
          title: host.entrypoint == skir.HostEntrypoint.paper
              ? "Paper host"
              : "Standalone host",
          subtitle: host.hostId.id,
          status: host.desiredTopologyRevision == host.appliedTopologyRevision
              ? "Reconciled"
              : "Reconciling",
          position: Offset(48, y),
          order: order++,
        ),
      );
      final realm = topology.realmOwnedBy(host.hostId);
      if (realm != null) {
        nodes.add(
          _TopologyNode(
            kind: _TopologyNodeKind.realm,
            hostId: host.hostId,
            title: "Realm",
            subtitle:
                "${realm.targetEngine.engineId} ${realm.targetEngine.majorVersion}.x",
            status: _childStatus(realm.state.status),
            position: Offset(354, y),
            order: order++,
          ),
        );
      }
      final engine = topology.engineOwnedBy(host.hostId);
      if (engine != null) {
        nodes.add(
          _TopologyNode(
            kind: _TopologyNodeKind.engine,
            hostId: host.hostId,
            title: "${engine.target.engineId.formatted} engine",
            subtitle: "${engine.target.majorVersion}.x on ${engine.realmId.id}",
            status: _childStatus(engine.state.status),
            position: Offset(660, y),
            order: order++,
          ),
        );
      }
    }
    size = Size(940, math.max(300, topology.hosts.length * 190 + 90));
  }

  final List<_TopologyNode> nodes = [];
  late final Size size;

  _TopologyNode? node(_TopologyNodeKind kind, skir.RecordId hostId) => nodes
      .where((node) => node.kind == kind && node.hostId == hostId)
      .firstOrNull;
}

class _TopologyEdgePainter extends CustomPainter {
  const _TopologyEdgePainter(
    this.layout, {
    required this.ownershipColor,
    required this.assignmentColor,
  });

  final _TopologyLayout layout;
  final Color ownershipColor;
  final Color assignmentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final ownership = Paint()
      ..color = ownershipColor
      ..strokeWidth = 2;
    final assignment = Paint()
      ..color = assignmentColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (final host in layout.nodes.where(
      (node) => node.kind == _TopologyNodeKind.host,
    )) {
      final realm = layout.node(_TopologyNodeKind.realm, host.hostId);
      final engine = layout.node(_TopologyNodeKind.engine, host.hostId);
      if (realm != null) {
        canvas.drawLine(_right(host), _left(realm), ownership);
      }
      if (engine != null) {
        canvas.drawLine(_right(host), _left(engine), ownership);
      }
      if (realm != null && engine != null) {
        canvas.drawLine(_right(realm), _left(engine), assignment);
      }
    }
  }

  Offset _left(_TopologyNode node) => node.position + const Offset(0, 54);
  Offset _right(_TopologyNode node) => node.position + const Offset(236, 54);

  @override
  bool shouldRepaint(_TopologyEdgePainter oldDelegate) =>
      oldDelegate.layout != layout ||
      oldDelegate.ownershipColor != ownershipColor ||
      oldDelegate.assignmentColor != assignmentColor;
}

String _childStatus(skir.ChildRuntimeStatus status) => switch (status) {
  skir.ChildRuntimeStatus.active => "Active",
  skir.ChildRuntimeStatus.staging => "Staging",
  skir.ChildRuntimeStatus.quiescing => "Quiescing",
  skir.ChildRuntimeStatus.failed => "Failed",
  skir.ChildRuntimeStatus.rolledBack => "Rolled back",
  skir.ChildRuntimeStatus.drifted => "Drifted",
  skir.ChildRuntimeStatus.absent => "Absent",
  skir.ChildRuntimeStatus_unknown() => "Unknown",
};
