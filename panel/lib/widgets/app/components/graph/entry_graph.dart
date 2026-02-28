import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/logic/graph/graph_data.dart";
import "package:typewriter_panel/logic/graph/graph_edge.dart";
import "package:typewriter_panel/logic/graph/graph_element.dart";
import "package:typewriter_panel/logic/graph/graph_identifier.dart";
import "package:typewriter_panel/logic/pages/entries.dart";
import "package:typewriter_panel/logic/pages/graph_direction.dart";
import "package:typewriter_panel/logic/pages/page_elements.dart";

import "package:typewriter_panel/utils/context.dart";
import "package:typewriter_panel/utils/riverpod.dart";
import "package:typewriter_panel/widgets/app/components/entry.dart";
import "package:typewriter_panel/widgets/app/components/graph/graph.dart";
import "package:typewriter_panel/widgets/app/components/graph/graph_drag.dart";
import "package:typewriter_panel/widgets/app/components/graph/graph_group.dart";
import "package:typewriter_panel/widgets/app/components/panes.dart";
import "package:typewriter_panel/widgets/generic/components/empty_screen.dart";

import "package:typewriter_panel/widgets/generic/components/section.dart";
import "package:typewriter_panel/widgets/generic/components/shimmer.dart";

class _GroupIdentifier implements GraphDragData, GraphIdentifier {
  const _GroupIdentifier(this.id);

  @override
  final String id;

  @override
  GraphIdentifier get graphId => this;

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is _GroupIdentifier && other.id == id);

  @override
  String toString() => "_GroupIdentifier($id)";
}

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
      PageElementGroup(:final id, :final name, :final placement) => (
        GraphElement(
          id: _GroupIdentifier(id),
          x: placement.x,
          y: placement.y,
          width: placement.width,
          height: placement.height,
          builder: (context) {
            return SizedBox.expand(
              child: GraphGroup(
                title: name,
                color: Theme.of(context).colorScheme.primary,
                data: _GroupIdentifier(id),
              ),
            );
          },
        ),
        <GraphEdge>[],
      ),
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
              id: edge.id,
              source: EntryIdentifier(definition.id),
              target: EntryIdentifier(edge.otherId),
              color: definition.blueprint.color,
              sourceSide: graphDirection.sourceSide,
              targetSide: graphDirection.targetSide,
            ),
        ],
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
    final elements = ref.watch(pageElementsProvider(pageId));

    return elements(
      name: "elements",
      builder: (elements) {
        if (elements.isEmpty) {
          return EmptyGraphPage();
        }
        return Graph(
          data: _graphFromElements(elements),
          onElementsDragged: (changes) {
            final changed = changes
                .map((entry) => (entry.$1.id, entry.$2, entry.$3))
                .toList(growable: false);
            ref.read(pageElementsProvider(pageId).notifier).moveAll(changed);
          },
          onElementsResize: (changes) {
            final changed = changes
                .map((entry) => (entry.$1.id, entry.$2, entry.$3))
                .toList(growable: false);
            ref.read(pageElementsProvider(pageId).notifier).resizeAll(changed);
          },
        );
      },
      loading: (_) => ShimmerBox.rectangle(
        width: double.infinity,
        height: double.infinity,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

class EmptyGraphPage extends StatelessWidget {
  const EmptyGraphPage({super.key});

  Future<String?> _showAddEntryDialog(BuildContext context) async =>
      throw UnimplementedError();

  @override
  Widget build(BuildContext context) {
    return Pane(
      id: "empty_graph_page",
      borderRadius: BorderRadius.circular(12),
      margin: EdgeInsets.only(top: 8, left: 8, right: context.isMobile ? 8 : 0),
      child: Section(
        margin: EdgeInsets.zero,
        child: EmptyScreen(
          title: "Add an entry",
          buttonText: "Add Entry",
          onPressed: () => _showAddEntryDialog(context),
        ),
      ),
    );
  }
}
