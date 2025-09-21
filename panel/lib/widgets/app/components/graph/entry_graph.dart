import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/logic/pages/entries.dart";
import "package:typewriter_panel/logic/pages/pages.dart";

import "package:typewriter_panel/utils/context.dart";
import "package:typewriter_panel/utils/riverpod.dart";
import "package:typewriter_panel/widgets/app/components/entry.dart";
import "package:typewriter_panel/widgets/app/components/graph/graph.dart";
import "package:typewriter_panel/widgets/app/components/panes.dart";
import "package:typewriter_panel/widgets/generic/components/empty_screen.dart";

import "package:typewriter_panel/widgets/generic/components/section.dart";
import "package:typewriter_panel/widgets/generic/components/shimmer.dart";

const entryGraphCellSize = 50.0;

/// Direction for graph layout flow
enum GraphDirection {
  leftToRight(EdgeSide.right, EdgeSide.left),
  rightToLeft(EdgeSide.left, EdgeSide.right),
  topToBottom(EdgeSide.bottom, EdgeSide.top),
  bottomToTop(EdgeSide.top, EdgeSide.bottom);

  const GraphDirection(this.sourceSide, this.targetSide);

  final EdgeSide sourceSide;
  final EdgeSide targetSide;

  T main<T>(T width, T height) => switch (this) {
    GraphDirection.leftToRight => width,
    GraphDirection.rightToLeft => width,
    GraphDirection.topToBottom => height,
    GraphDirection.bottomToTop => height,
  };
  T cross<T>(T width, T height) => switch (this) {
    GraphDirection.leftToRight => height,
    GraphDirection.rightToLeft => height,
    GraphDirection.topToBottom => width,
    GraphDirection.bottomToTop => width,
  };
}

extension PageTypeExtension on PageType {
  GraphDirection? get direction => switch (this) {
    PageType.static => GraphDirection.bottomToTop,
    PageType.sequence => GraphDirection.leftToRight,
    PageType.manifest => GraphDirection.topToBottom,
    PageType.scene => null,
  };
}

class EntryGraph extends HookConsumerWidget {
  const EntryGraph({
    required this.pageId,
    this.direction = GraphDirection.leftToRight,
    super.key,
  });

  final String pageId;
  final GraphDirection direction;

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
              sourceSide: direction.sourceSide,
              targetSide: direction.targetSide,
            ),
        ],
      ),
      orElse: () => (
        GraphElement(
          id: GraphIdentifier(entry.id),
          // TODO: Do placement correctly
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

  GraphData _graphFromEntries(List<PageEntry> entries) {
    final elements = <GraphElement>[];
    final edges = <GraphEdge>[];

    for (final entry in entries) {
      final (element, graphEdges) = _graphFromEntry(entry);
      elements.add(element);
      edges.addAll(graphEdges);
    }

    return GraphData(
      cellSize: entryGraphCellSize,
      elements: elements,
      edges: edges,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(pageEntriesProvider(pageId));

    return entries(
      name: "entries",
      builder: (entries) {
        if (entries.isEmpty) {
          return EmptyGraphPage();
        }
        return Graph(
          data: _graphFromEntries(entries),
          onElementsDragged: (changes) {
            final changed = changes
                .map((entry) => (entry.$1.id, entry.$2, entry.$3))
                .toList(growable: false);
            ref.read(pageEntriesProvider(pageId).notifier).moveAll(changed);
          },
          onElementsResize: (changes) {
            final changed = changes
                .map((entry) => (entry.$1.id, entry.$2, entry.$3))
                .toList(growable: false);
            ref.read(pageEntriesProvider(pageId).notifier).resizeAll(changed);
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
