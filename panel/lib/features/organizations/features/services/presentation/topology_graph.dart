import "dart:math" as math;

import "package:flutter/material.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "topology_graph_layout.dart";

class TopologyGraph extends StatefulWidget {
  const TopologyGraph({
    required this.topology,
    required this.selectedHostId,
    required this.onHostSelected,
    super.key,
  });

  final OrganizationTopology topology;
  final skir.RecordId? selectedHostId;
  final ValueChanged<skir.RecordId> onHostSelected;

  @override
  State<TopologyGraph> createState() => _TopologyGraphState();
}

class _TopologyGraphState extends State<TopologyGraph> {
  final TransformationController _transformation = TransformationController();

  @override
  void dispose() {
    _transformation.dispose();
    super.dispose();
  }

  void _zoom(double factor) {
    final current = _transformation.value.getMaxScaleOnAxis();
    final next = (current * factor).clamp(0.35, 2.25);
    _transformation.value = Matrix4.diagonal3Values(next, next, 1);
  }

  void _fit(Size viewport, Size content) {
    final scale = math
        .min(viewport.width / content.width, viewport.height / content.height)
        .clamp(0.35, 1.0);
    final dx = (viewport.width - content.width * scale) / 2;
    final dy = (viewport.height - content.height * scale) / 2;
    _transformation.value = Matrix4.diagonal3Values(scale, scale, 1)
      ..setTranslationRaw(dx, dy, 0);
  }

  @override
  Widget build(BuildContext context) {
    final layout = _TopologyLayout(widget.topology);
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = Size(constraints.maxWidth, constraints.maxHeight);
        return Stack(
          children: [
            Positioned.fill(
              child: FocusTraversalGroup(
                policy: OrderedTraversalPolicy(),
                child: InteractiveViewer(
                  transformationController: _transformation,
                  constrained: false,
                  minScale: 0.35,
                  maxScale: 2.25,
                  boundaryMargin: const EdgeInsets.all(160),
                  child: SizedBox(
                    width: layout.size.width,
                    height: layout.size.height,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _TopologyEdgePainter(
                              layout,
                              ownershipColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              assignmentColor: Theme.of(
                                context,
                              ).colorScheme.tertiary,
                            ),
                          ),
                        ),
                        for (final node in layout.nodes)
                          Positioned(
                            left: node.position.dx,
                            top: node.position.dy,
                            child: FocusTraversalOrder(
                              order: NumericFocusOrder(node.order.toDouble()),
                              child: _TopologyNodeCard(
                                node: node,
                                selected: node.hostId == widget.selectedHostId,
                                onPressed: () =>
                                    widget.onHostSelected(node.hostId),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: context.spacing.space3,
              bottom: context.spacing.space3,
              child: Material(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: context.shapes.mediumBorderRadius,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: "Zoom out",
                      onPressed: () => _zoom(0.8),
                      icon: const Icon(Icons.remove),
                    ),
                    IconButton(
                      tooltip: "Zoom to fit",
                      onPressed: () => _fit(viewport, layout.size),
                      icon: const Icon(Icons.fit_screen),
                    ),
                    IconButton(
                      tooltip: "Zoom in",
                      onPressed: () => _zoom(1.25),
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TopologyNodeCard extends StatelessWidget {
  const _TopologyNodeCard({
    required this.node,
    required this.selected,
    required this.onPressed,
  });

  final _TopologyNode node;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final icon = switch (node.kind) {
      _TopologyNodeKind.host => Icons.dns_outlined,
      _TopologyNodeKind.realm => Icons.hub_outlined,
      _TopologyNodeKind.engine => Icons.memory_outlined,
    };
    return Semantics(
      button: true,
      selected: selected,
      label: "${node.title}, ${node.subtitle}, ${node.status}",
      child: Material(
        color: selected ? colors.primaryContainer : colors.surfaceContainer,
        borderRadius: context.shapes.mediumBorderRadius,
        child: InkWell(
          onTap: onPressed,
          borderRadius: context.shapes.mediumBorderRadius,
          child: SizedBox(
            width: 236,
            height: 108,
            child: Padding(
              padding: EdgeInsets.all(context.spacing.space3),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: selected
                        ? colors.onPrimaryContainer
                        : colors.primary,
                  ),
                  SizedBox(width: context.spacing.space3),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          node.title,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          node.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          node.status,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
