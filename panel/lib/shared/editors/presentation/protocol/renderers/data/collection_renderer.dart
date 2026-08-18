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
    final bindingIds = {
      source.schema.rowBindingId,
      childrenBindingId,
      childBindingId,
    };
    if (bindingIds.length != 3) {
      return presentationDiagnostic(context, [
        _collectionDiagnostic("Collection graph bindings must be distinct"),
      ]);
    }
    final rootSlots = rootSequence.item.presentationSlotIds;
    if (rootSlots.length != 1) {
      return presentationDiagnostic(context, [
        _collectionDiagnostic(
          "Collection graph root template must contain one slot",
        ),
      ]);
    }
    final nodeSlots = node.presentationSlotIds;
    final childSlots = children.item.presentationSlotIds;
    if (nodeSlots.length != 1 || childSlots.length != 1) {
      return presentationDiagnostic(context, [
        _collectionDiagnostic(
          "Collection graph templates must contain one logical child slot",
        ),
      ]);
    }
    if (nodeSlots.single != childSlots.single) {
      return presentationDiagnostic(context, [
        _collectionDiagnostic("Collection graph child slots do not match"),
      ]);
    }
    final rootSlotId = rootSlots.single;
    final slotId = nodeSlots.single;
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
        final occurrenceChildren = _orderedOccurrenceChildren(data.paths);
        final rootItemScopes = <PresentationRenderScope>[
          for (final row in data.rootRows)
            _rowScope(scope, source.schema, row.value).copyWith(
              expansionIdentity: _GraphOccurrenceIdentity(
                sourceId: sourceId,
                relation: relation,
                path: [row.key],
              ),
              presentationSlots: {
                ...scope.presentationSlots,
                rootSlotId: _renderGraphOccurrence(
                  context: context,
                  scope: scope,
                  schema: source.schema,
                  row: row,
                  occurrenceChildren: occurrenceChildren,
                  snapshot: data,
                  path: [row.key],
                  slotId: slotId,
                ),
              },
            ),
        ];
        final roots = renderSequence(
          context: context,
          presentation: rootSequence,
          scope: scope,
          itemScopes: rootItemScopes,
        );
        if (data.diagnostics.isEmpty) return roots;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [roots, presentationDiagnostic(context, data.diagnostics)],
        );
      },
    );
  }

  Widget _renderGraphOccurrence({
    required BuildContext context,
    required PresentationRenderScope scope,
    required PresentationCollectionSchema schema,
    required PresentationCollectionRow row,
    required Map<_GraphOccurrencePath, List<DataValue>> occurrenceChildren,
    required PresentationCollectionSnapshot snapshot,
    required List<DataValue> path,
    required String slotId,
  }) {
    final childRows = [
      for (final key
          in occurrenceChildren[_GraphOccurrencePath(path)] ??
              const <DataValue>[])
        ?snapshot.row(key),
    ];
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
      expansionIdentity: identity,
    );
    final childPaths = [
      for (final child in childRows) [...path, child.key],
    ];
    final itemScopes = [
      for (final (index, child) in childRows.indexed)
        occurrenceScope.copyWith(
          expressions: occurrenceScope.expressions.withBinding(
            childBindingId,
            BindingSnapshot(
              type: schema.rowType,
              value: child.value,
              revision: 0,
              writable: false,
            ),
          ),
          expansionIdentity: _GraphOccurrenceIdentity(
            sourceId: sourceId,
            relation: relation,
            path: childPaths[index],
          ),
          presentationSlots: {
            ...occurrenceScope.presentationSlots,
            slotId: _renderGraphOccurrence(
              context: context,
              scope: scope,
              schema: schema,
              row: child,
              occurrenceChildren: occurrenceChildren,
              snapshot: snapshot,
              path: childPaths[index],
              slotId: slotId,
            ),
          },
        ),
    ];
    return Builder(
      builder: (context) {
        final childContent = renderSequence(
          context: context,
          presentation: children,
          scope: occurrenceScope,
          itemScopes: itemScopes,
        );
        return _renderCollectionNode(
          node,
          occurrenceScope.copyWith(
            presentationSlots: {
              ...occurrenceScope.presentationSlots,
              slotId: childContent,
            },
          ),
        );
      },
    );
  }
}

Map<_GraphOccurrencePath, List<DataValue>> _orderedOccurrenceChildren(
  Iterable<PresentationCollectionPath> paths,
) {
  final childrenByOccurrence = <_GraphOccurrencePath, List<DataValue>>{};
  for (final path in paths) {
    for (var index = 0; index + 1 < path.keys.length; index++) {
      final occurrence = _GraphOccurrencePath(path.keys.take(index + 1));
      final children = childrenByOccurrence.putIfAbsent(occurrence, () => []);
      final child = path.keys[index + 1];
      if (!children.contains(child)) children.add(child);
    }
  }
  return childrenByOccurrence;
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
