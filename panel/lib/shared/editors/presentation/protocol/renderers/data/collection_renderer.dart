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
        final children = <Widget>[
          if (rootRows case final presentation?)
            renderSequence(
              context: context,
              presentation: presentation,
              scope: scope,
              itemScopes: [
                for (final row in data.rootRows)
                  _rowScope(scope, source.schema, row.value),
              ],
            ),
          if (reachedRows case final presentation?)
            renderSequence(
              context: context,
              presentation: presentation,
              scope: scope,
              itemScopes: [
                for (final row in _reachedRows(data))
                  _rowScope(scope, source.schema, row.value),
              ],
            ),
          if (paths case final presentation?)
            renderSequence(
              context: context,
              presentation: presentation,
              scope: scope,
              itemScopes: [
                for (final path in data.paths)
                  scope.copyWith(
                    expressions: scope.expressions.withBinding(
                      pathBindingId,
                      BindingSnapshot(
                        type: ListType(element: source.schema.keyType),
                        value: ListValue(path.keys),
                        revision: 0,
                        writable: false,
                      ),
                    ),
                  ),
              ],
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

  Iterable<PresentationCollectionRow> _reachedRows(
    PresentationCollectionSnapshot snapshot,
  ) {
    if (deduplicate) return snapshot.rows;
    return snapshot.paths.map((path) => snapshot.row(path.keys.last)).nonNulls;
  }
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
