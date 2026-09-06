import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

const entryGraphCellSize = 50.0;

class EntryGraph extends HookConsumerWidget {
  const EntryGraph({
    required this.pageId,
    this.graphDirection = GraphDirection.leftToRight,
    super.key,
  });

  final String pageId;
  final GraphDirection graphDirection;

  (GraphElement, List<GraphEdge>) _graphFromElement(PageElement element) {
    return switch (element) {
      PageElementEntry(:final entry) => _graphFromEntry(entry),
      _ => (
        GraphElement(
          id: GraphIdentifier(element.id),
          x: 0,
          y: 0,
          width: 100,
          height: 100,
          builder: (context) => const SizedBox(),
        ),
        <GraphEdge>[],
      ),
    };
  }

  (GraphElement, List<GraphEdge>) _graphFromEntry(PageEntry entry) {
    return entry.maybeWhen(
      definition: (definition) => (
        GraphElement(
          id: EntryIdentifier(definition.id),
          x: definition.placement.x,
          y: definition.placement.y,
          width: definition.placement.width,
          height: definition.placement.height,
          builder: (context) {
            return SizedBox.expand(child: EntryNode(entry: entry));
          },
        ),
        [
          for (final edge in definition.outwardEdges)
            GraphEdge(
              id: edge.linkId,
              source: EntryIdentifier(definition.id),
              target: EntryIdentifier(edge.otherId),
              color: definition.elementDefinition.color,
              sourceSide: graphDirection.sourceSide,
              targetSide: graphDirection.targetSide,
            ),
        ],
      ),
      missingElementDefinition:
          (id, name, placement, inwardLinks, outwardLinks, metadata) => (
            GraphElement(
              id: EntryIdentifier(id),
              x: placement.x,
              y: placement.y,
              width: placement.width,
              height: placement.height,
              builder: (context) {
                return SizedBox.expand(child: EntryNode(entry: entry));
              },
            ),
            <GraphEdge>[],
          ),
      orElse: () => (
        GraphElement(
          id: GraphIdentifier(entry.id),
          x: 0,
          y: 0,
          width: 5,
          height: 5,
          builder: (context) {
            return SizedBox.expand(child: EntryNode(entry: entry));
          },
        ),
        <GraphEdge>[],
      ),
    );
  }

  GraphData _graphFromElements(List<PageElement> elements) {
    final graphElements = <GraphElement>[];
    final edges = <GraphEdge>[];

    for (final element in elements) {
      final (graphElement, graphEdges) = _graphFromElement(element);
      graphElements.add(graphElement);
      edges.addAll(graphEdges);
    }

    return GraphData(
      cellSize: entryGraphCellSize,
      elements: graphElements,
      edges: edges,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final organizationId = ref.watch(organizationIdProvider);
    final realmId = ref.watch(realmIdProvider);
    if (organizationId == null || realmId == null) {
      return const SizedBox.shrink();
    }
    final provider = pageElementsProvider(organizationId, realmId, pageId);
    final elements = ref.watch(provider);

    return elements(
      name: "elements",
      builder: (elements) {
        if (elements.isEmpty) {
          return EmptyEntryPage(
            pageId: pageId,
            placementKind: EntryPlacementKind.graph,
          );
        }
        return Stack(
          children: [
            Graph(
              data: _graphFromElements(elements),
              onElementsMoved: (changes) {
                final changed = changes
                    .map((entry) => (entry.id.id, entry.x, entry.y))
                    .toList(growable: false);
                ref.read(provider.notifier).moveAll(changed);
              },
              onElementsResized: (changes) {
                final changed = changes
                    .map((entry) => (entry.id.id, entry.width, entry.height))
                    .toList(growable: false);
                ref.read(provider.notifier).resizeAll(changed);
              },
            ),
            Align(
              alignment: Alignment.topCenter,
              child: PageDiagnosticsBanner(pageId: pageId),
            ),
            Positioned(
              right: context.spacing.space2,
              bottom: context.spacing.space2,
              child: AddEntryButton(
                pageId: pageId,
                placementKind: EntryPlacementKind.graph,
              ),
            ),
          ],
        );
      },
      loading: (_) => ShimmerBox.rectangle(
        width: double.infinity,
        height: double.infinity,
        borderRadius: context.shapes.largeBorderRadius,
      ),
    );
  }
}
