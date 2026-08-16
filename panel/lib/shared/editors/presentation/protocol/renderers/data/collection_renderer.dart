part of "../../data_renderer.dart";

extension CollectionLookupRendering on CollectionLookupElement {
  Widget render(BuildContext context, PresentationRenderScope scope) {
    final source = scope.collections[sourceId];
    if (source == null) {
      return presentationDiagnostic(context, [
        _collectionDiagnostic("Collection source is unavailable"),
      ]);
    }
    final resolved = scope.resolve(key);
    if (resolved case TypeFailure(:final diagnostics)) {
      return presentationDiagnostic(context, diagnostics);
    }
    final selectedKey = resolved.valueOrNull!.value;
    return StreamBuilder<PresentationCollectionSnapshot>(
      stream: source.watch(PresentationCollectionQuery.keys([selectedKey])),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.loading) {
          return loading == null
              ? const LinearProgressIndicator()
              : _renderCollectionNode(loading!, scope);
        }
        final data = snapshot.data!;
        if (data.diagnostics.isNotEmpty) {
          return presentationDiagnostic(context, data.diagnostics);
        }
        final row = data.row(selectedKey);
        if (row == null) {
          return _renderCollectionNode(missing, scope);
        }
        return _renderCollectionNode(
          found,
          _rowScope(scope, source.schema, row.value),
        );
      },
    );
  }
}

extension CollectionGraphRendering on CollectionGraphElement {
  Widget render(BuildContext context, PresentationRenderScope scope) {
    final source = scope.collections[sourceId];
    if (source == null) {
      return presentationDiagnostic(context, [
        _collectionDiagnostic("Collection source is unavailable"),
      ]);
    }
    if (childrenBindingId == source.schema.rowBindingId) {
      return presentationDiagnostic(context, [
        _collectionDiagnostic(
          "Collection children binding collides with the row binding",
        ),
      ]);
    }
    final slotIds = node.presentationSlotIds;
    if (slotIds.length != 1) {
      return presentationDiagnostic(context, [
        _collectionDiagnostic(
          slotIds.isEmpty
              ? "Collection graph node does not contain a child slot"
              : "Collection graph node contains distinct child slots",
        ),
      ]);
    }
    final slotId = slotIds.single;
    final resolved = scope.resolve(roots);
    if (resolved case TypeFailure(:final diagnostics)) {
      return presentationDiagnostic(context, diagnostics);
    }
    final value = resolved.valueOrNull!.value;
    final rootKeys = switch (value) {
      ListValue(:final values) => values,
      UnitValue() => const <DataValue>[],
      _ => [value],
    };
    final query = PresentationCollectionQuery.graph(
      roots: rootKeys,
      relation: relation,
      direction: direction,
      maximumDepth: maximumDepth,
    );
    return StreamBuilder<PresentationCollectionSnapshot>(
      stream: source.watch(query),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.loading) {
          return const LinearProgressIndicator();
        }
        final data = snapshot.data!;
        final adjacency = _orderedAdjacency(data.paths);
        final children = <Widget>[
          for (final row in data.rootRows)
            _renderGraphOccurrence(
              context: context,
              scope: scope,
              schema: source.schema,
              row: row,
              adjacency: adjacency,
              snapshot: data,
              path: [row.key],
              slotId: slotId,
            ),
          if (data.diagnostics.isNotEmpty)
            presentationDiagnostic(context, data.diagnostics),
        ];
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        );
      },
    );
  }

  Widget _renderGraphOccurrence({
    required BuildContext context,
    required PresentationRenderScope scope,
    required PresentationCollectionSchema schema,
    required PresentationCollectionRow row,
    required Map<DataValue, List<DataValue>> adjacency,
    required PresentationCollectionSnapshot snapshot,
    required List<DataValue> path,
    required String slotId,
  }) {
    final childRows = [
      for (final key in adjacency[row.key] ?? const <DataValue>[])
        ?snapshot.row(key),
    ];
    final childWidgets = [
      for (final child in childRows)
        _renderGraphOccurrence(
          context: context,
          scope: scope,
          schema: schema,
          row: child,
          adjacency: adjacency,
          snapshot: snapshot,
          path: [...path, child.key],
          slotId: slotId,
        ),
    ];
    final childContent = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: childWidgets,
    );
    final rowScope = _rowScope(scope, schema, row.value);
    final identity = _GraphOccurrenceIdentity(
      sourceId: sourceId,
      relation: relation,
      path: path,
    );
    final occurrenceScope = rowScope.copyWith(
      expressions: rowScope.expressions.withBinding(
        childrenBindingId,
        BindingSnapshot(
          type: ListType(element: schema.rowType),
          value: ListValue([for (final child in childRows) child.value]),
          revision: 0,
          writable: false,
        ),
      ),
      presentationSlots: {...scope.presentationSlots, slotId: childContent},
      expansionIdentity: identity,
    );
    return _renderCollectionNode(node, occurrenceScope);
  }
}

Map<DataValue, List<DataValue>> _orderedAdjacency(
  Iterable<PresentationCollectionPath> paths,
) {
  final adjacency = <DataValue, List<DataValue>>{};
  for (final path in paths) {
    for (var index = 0; index + 1 < path.keys.length; index++) {
      final children = adjacency.putIfAbsent(path.keys[index], () => []);
      final child = path.keys[index + 1];
      if (!children.contains(child)) children.add(child);
    }
  }
  return adjacency;
}

final class _GraphOccurrenceIdentity {
  _GraphOccurrenceIdentity({
    required this.sourceId,
    required this.relation,
    required List<DataValue> path,
  }) : path = List.unmodifiable(path);

  final PresentationCollectionSourceId sourceId;
  final PresentationCollectionRelationId relation;
  final List<DataValue> path;

  @override
  bool operator ==(Object other) {
    if (other is! _GraphOccurrenceIdentity ||
        other.sourceId != sourceId ||
        other.relation != relation ||
        other.path.length != path.length) {
      return false;
    }
    for (var index = 0; index < path.length; index++) {
      if (other.path[index] != path[index]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(sourceId, relation, Object.hashAll(path));
}

PresentationRenderScope _rowScope(
  PresentationRenderScope scope,
  PresentationCollectionSchema schema,
  DataValue row,
) => scope.copyWith(
  expressions: scope.expressions.withBinding(
    schema.rowBindingId,
    BindingSnapshot(
      type: schema.rowType,
      value: row,
      revision: 0,
      writable: false,
    ),
  ),
);

Widget _renderCollectionNode(
  PresentationNode node,
  PresentationRenderScope scope,
) => PresentationNodeRenderer(
  node: node.localizeFailures(
    scope.expressions,
    registry: scope.registry,
    budget: scope.budget,
  ),
  scope: scope,
);

TypeDiagnostic _collectionDiagnostic(String message) => TypeDiagnostic(
  code: TypeDiagnosticCode.invalidPresentation,
  message: message,
);
