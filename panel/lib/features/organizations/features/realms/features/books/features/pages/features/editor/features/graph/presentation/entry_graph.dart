import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// Renders the graph view for one page and routes committed layout changes
/// back to that page's element coordinator.
///
/// The input is the projected page element read model. It can therefore show
/// local edits before persistence completes, while [pageElementsProvider]
/// remains the owner of move and resize mutations. Entry definitions contribute
/// nodes and outward links. References, nonexistent targets, and missing
/// catalog definitions remain visible as nodes when possible, but do not invent
/// edges or editable data that the projection does not provide.
class EntryGraph extends HookConsumerWidget {
  const EntryGraph({
    required this.pageId,
    this.graphDirection = GraphDirection.leftToRight,
    super.key,
  });

  /// Identifier of the page whose projected elements are rendered.
  final String pageId;

  /// Direction used to choose the source and target sides of each connection.
  final GraphDirection graphDirection;

  /// Converts a page element into its renderable node and connections.
  ///
  /// Only locally owned entry definitions have enough information to emit
  /// outward edges. Other element variants still receive a placeholder node so
  /// the graph snapshot preserves identity without claiming relationships it
  /// cannot verify.
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

  /// Converts one entry projection while preserving degraded catalog states.
  ///
  /// A missing element definition keeps its saved placement but suppresses
  /// links because the target and source semantics are no longer authoritative.
  /// Other nondefinition variants use a small fallback node until their full
  /// page projection is available.
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
            return SizedBox.expand(
              child: EntryNode(pageId: pageId, entry: entry),
            );
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
                return SizedBox.expand(
                  child: EntryNode(pageId: pageId, entry: entry),
                );
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
            return SizedBox.expand(
              child: EntryNode(pageId: pageId, entry: entry),
            );
          },
        ),
        <GraphEdge>[],
      ),
    );
  }

  /// Builds the immutable shared graph snapshot from the page projection.
  ///
  /// Conversion is deliberately separate from persistence. This lets the
  /// shared graph preview interaction against the current projection and lets
  /// the page coordinator decide how a completed batch is reconciled.
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

  /// Subscribes to the selected realm and page projection.
  ///
  /// Missing organization or realm context produces no surface. Loading uses
  /// a full size placeholder. An empty page delegates creation guidance to the
  /// editor's empty state. Once data is ready, move and resize callbacks pass
  /// absolute placement values to the page element owner, while diagnostics
  /// and creation remain adjacent actions in the same surface.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final organizationId = ref.watch(organizationIdProvider);
    final realmId = ref.watch(realmIdProvider);
    if (organizationId == null || realmId == null) {
      return const SizedBox.shrink();
    }
    final provider = projectedPageElementsProvider(
      organizationId,
      realmId,
      pageId,
    );
    final elements = ref.watch(provider);
    final commands = pageElementsProvider(organizationId, realmId, pageId);
    final viewportCenter = useRef<Offset?>(null);

    return elements(
      name: "elements",
      builder: (elements) {
        return FloatingButton(
          icon: const Icon(Icons.add),
          onPressed: () => showAddElementSearch(
            context,
            pageId: pageId,
            preferredGraphAnchor: viewportCenter.value,
          ),
          child: Stack(
            children: [
              Graph(
                data: _graphFromElements(elements),
                onViewportCenterChanged: (center) {
                  viewportCenter.value = center;
                },
                onElementsMoved: (changes) {
                  final changed = changes
                      .map((entry) => (entry.id.id, entry.x, entry.y))
                      .toList(growable: false);
                  ref.read(commands.notifier).moveAll(changed);
                },
                onElementsResized: (changes) {
                  final changed = changes
                      .map((entry) => (entry.id.id, entry.width, entry.height))
                      .toList(growable: false);
                  ref.read(commands.notifier).resizeAll(changed);
                },
              ),
              Align(
                alignment: Alignment.topCenter,
                child: PageDiagnosticsBanner(pageId: pageId),
              ),
            ],
          ),
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
