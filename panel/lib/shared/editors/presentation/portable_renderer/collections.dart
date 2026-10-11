part of "../portable_presentation_renderer.dart";

final class _AuthoredCollectionRow {
  const _AuthoredCollectionRow({
    required this.resource,
    required this.configuration,
    required this.label,
    required this.row,
    required this.key,
    required this.canonicalKey,
    required this.selectable,
    required this.scope,
  });

  final skir.ResourceId resource;
  final skir.TypeSelection configuration;
  final String label;
  final skir.DataValue row;
  final skir.DataValue key;
  final String canonicalKey;
  final bool selectable;
  final PortablePresentationScope scope;
}

extension _PortableCollectionRendering on PortablePresentationNodeRenderer {
  Widget _renderCollectionLookup(
    skir.CollectionLookupElement element,
    PortablePresentationScope childScope,
  ) {
    final collection = _authoredCollection(element.sourceId, childScope);
    if (collection.problem != null) {
      return _diagnostic(collection.problem!);
    }
    final key = childScope.read(element.key);
    if (key == null || key == skir.DataValue.unfilled) {
      return PortablePresentationNodeRenderer(
        node: element.missing,
        scope: childScope,
      );
    }
    if (collection.rows.firstOrNull case final first?
        when !_sameCollectionKeyType(first.key, key)) {
      return _diagnostic("The collection lookup key has the wrong type");
    }
    final canonical = canonicalAuthoredValue(key);
    final matches = collection.rows
        .where((candidate) => candidate.canonicalKey == canonical)
        .toList(growable: false);
    if (matches.length > 1) {
      return _diagnostic("The collection lookup key is ambiguous");
    }
    final row = matches.firstOrNull;
    return PortablePresentationNodeRenderer(
      node: row?.scope == null ? element.missing : element.found,
      scope: row?.scope ?? childScope,
    );
  }

  Widget _renderCollectionGraph(
    skir.CollectionGraphElement element,
    PortablePresentationScope childScope,
  ) {
    final collection = _authoredCollection(element.sourceId, childScope);
    if (collection.problem != null) {
      return _diagnostic(collection.problem!);
    }
    final relation = collection.definition?.relations
        .where((candidate) => candidate.relationId == element.relationId)
        .firstOrNull;
    if (relation == null) {
      return _diagnostic("The collection graph relation is unavailable");
    }
    final evaluatedRoots = childScope.evaluate(element.roots);
    if (evaluatedRoots case PortableExpressionFailed(:final message)) {
      return _diagnostic(message);
    }
    final roots = switch (evaluatedRoots) {
      PortableExpressionAvailable(:final value) => value,
      PortableExpressionUnavailable() || PortableExpressionFailed() => null,
    };
    if (roots == null || roots == skir.DataValue.unfilled) {
      return _diagnostic("The collection graph roots are unavailable");
    }
    final rowsByKey = <String, _AuthoredCollectionRow>{};
    for (final row in collection.rows) {
      if (rowsByKey.containsKey(row.canonicalKey)) {
        return _diagnostic("The collection graph contains an ambiguous key");
      }
      rowsByKey[row.canonicalKey] = row;
    }
    final forward = <String, List<String>>{};
    final reverse = <String, List<String>>{};
    for (final row in collection.rows) {
      final targets = row.scope.evaluate(relation.targets);
      if (targets is! PortableExpressionAvailable) continue;
      final keys = <String>[];
      for (final value in _collectionKeyValues(targets.value)) {
        if (!_sameCollectionKeyType(row.key, value)) {
          return _diagnostic(
            "A collection graph relation produced the wrong key type",
          );
        }
        keys.add(canonicalAuthoredValue(value));
      }
      forward[row.canonicalKey] = keys;
      for (final target in keys) {
        reverse.putIfAbsent(target, () => []).add(row.canonicalKey);
      }
    }
    final adjacency = element.direction == skir.CollectionGraphDirection.reverse
        ? reverse
        : forward;
    final rootRows = <_AuthoredCollectionRow>[];
    final seen = <String>{};
    for (final root in _collectionKeyValues(roots)) {
      if (collection.rows.firstOrNull case final first?
          when !_sameCollectionKeyType(first.key, root)) {
        return _diagnostic("A collection graph root has the wrong key type");
      }
      final canonical = canonicalAuthoredValue(root);
      final row = rowsByKey[canonical];
      if (row != null && seen.add(canonical)) rootRows.add(row);
    }
    final rootSlot = _slotId(element.rootSequence.item);
    final childSlot = _slotId(element.children.item);
    if (rootSlot == null || childSlot == null) {
      return _diagnostic("The collection graph slots are unavailable");
    }
    final maximumDepth = element.maximumDepth ?? collection.rows.length;

    Widget renderNode(_AuthoredCollectionRow row, int depth) {
      final children = <_AuthoredCollectionRow>[];
      if (depth < maximumDepth) {
        for (final key in adjacency[row.canonicalKey] ?? const <String>[]) {
          final child = rowsByKey[key];
          if (child != null && seen.add(key)) children.add(child);
        }
      }
      final childValues = skir.DataValue.createListValue(
        items: [
          for (final child in children)
            skir.ListItem(
              id: skir.ItemId(
                value: sha256
                    .convert(utf8.encode(child.canonicalKey))
                    .toString(),
              ),
              value: child.row,
            ),
        ],
      );
      final nodeScope = row.scope.withValues({
        element.childrenBindingId: childValues,
      });
      return PortablePresentationNodeRenderer(
        node: element.node,
        scope: nodeScope.withSlotBuilders({
          childSlot: (_) => _renderCollectionSequence(
            element.children,
            children,
            (child) => renderNode(child, depth + 1),
            element.childBindingId,
            childSlot,
            nodeScope,
          ),
        }),
      );
    }

    return _renderCollectionSequence(
      element.rootSequence,
      rootRows,
      (row) => renderNode(row, 0),
      collection.definition!.rowBindingId,
      rootSlot,
      childScope,
    );
  }

  Widget _renderCollectionSequence(
    skir.SequencePresentation sequence,
    List<_AuthoredCollectionRow> rows,
    Widget Function(_AuthoredCollectionRow row) content,
    skir.ExpressionBindingId itemBinding,
    String slot,
    PortablePresentationScope fallbackScope,
  ) {
    if (rows.isEmpty) {
      final empty = sequence.empty;
      return empty == null
          ? const SizedBox.shrink()
          : PortablePresentationNodeRenderer(node: empty, scope: fallbackScope);
    }
    final children = <Widget>[];
    final itemScopes = <PortablePresentationScope>[];
    for (final indexed in rows.indexed) {
      if (indexed.$1 > 0 && sequence.separator != null) {
        children.add(
          PortablePresentationNodeRenderer(
            node: sequence.separator!,
            scope: indexed.$2.scope,
          ),
        );
        itemScopes.add(indexed.$2.scope);
      }
      final row = indexed.$2;
      final scope = row.scope
          .withValues({itemBinding: row.row})
          .withSlotBuilders({slot: (_) => content(row)});
      children.add(
        PortablePresentationNodeRenderer(node: sequence.item, scope: scope),
      );
      itemScopes.add(scope);
    }
    return _renderSequence(
      children,
      sequence.layout,
      rows.first.scope,
      itemScopes: itemScopes,
    );
  }

  ({
    skir.PresentationCollectionDefinition? definition,
    List<_AuthoredCollectionRow> rows,
    String? problem,
  })
  _authoredCollection(String sourceId, PortablePresentationScope scope) {
    final host = scope.host;
    if (host is! PortableCollectionProjectionHost) {
      return (
        definition: null,
        rows: const [],
        problem: "The presentation collection is unavailable",
      );
    }
    final collectionHost = switch (host) {
      PortableCollectionProjectionHost value => value,
      _ => throw StateError("Collection host checked before projection"),
    };
    final material = scope.material;
    if (material == null) {
      return (
        definition: null,
        rows: const [],
        problem: "The presentation collection is unavailable",
      );
    }
    final projected = collectionHost.projectCollection(
      sourceId,
      material: material,
      context: scope.invocation,
    );
    final definition = projected.definition;
    if (definition == null || projected.problem != null) {
      return (
        definition: definition,
        rows: const [],
        problem: projected.problem,
      );
    }
    final resourceBinding =
        definition.resources?.resourceBindingId ??
        definition.projection!.resourceBindingId;
    return (
      definition: definition,
      rows: [
        for (final row in projected.rows)
          _AuthoredCollectionRow(
            resource: row.resource,
            configuration: row.configuration,
            label: row.label,
            row: row.row,
            key: row.key,
            canonicalKey: row.canonicalKey,
            selectable: row.selectable,
            scope: scope.withValues({
              definition.rowBindingId: row.row,
              resourceBinding: skir.DataValue.wrapStringValue(
                row.resource.value,
              ),
            }),
          ),
      ],
      problem: null,
    );
  }

  Iterable<skir.DataValue> _collectionKeyValues(skir.DataValue value) {
    final items = value.authoredItems;
    if (items != null) return items.map((item) => item.value);
    return [value];
  }

  bool _sameCollectionKeyType(skir.DataValue expected, skir.DataValue actual) {
    if (expected.kind != actual.kind) return false;
    return switch ((expected, actual)) {
      (
        skir.DataValue_namedWrapper(value: final expectedNamed),
        skir.DataValue_namedWrapper(value: final actualNamed),
      ) =>
        expectedNamed.actualType == actualNamed.actualType,
      _ => true,
    };
  }

  String? _slotId(skir.PresentationNode node) => switch (node.element) {
    skir.PresentationElement_slotWrapper(:final value) => value.slotId,
    _ => null,
  };
}

final class _AuthoredCollectionRowAppearance extends StatelessWidget {
  const _AuthoredCollectionRowAppearance({
    required this.row,
    required this.definition,
  });

  final _AuthoredCollectionRow row;
  final skir.PresentationCollectionDefinition definition;

  @override
  Widget build(BuildContext context) {
    final catalog = row.scope.catalog;
    if (catalog == null) return Text(row.label);
    final appearance = definition.resources?.appearance;
    final material = appearance == null
        ? switch (catalog.selectPresentation(
            row.configuration,
            skir.PresentationRole.referenceOption,
          )) {
            SelectedEditorPresentation(:final material) => material,
            _ => null,
          }
        : catalog.presentationMaterial(appearance, row.configuration);
    if (material == null) return Text(row.label);
    final scope = row.scope
        .withValues({
          _configuredValueBindingId: row.row,
          presentationSubjectIdentifierBindingId:
              skir.DataValue.wrapStringValue(row.resource.value),
        })
        .withMaterial(material)
        .withActivePresentation(material.provider);
    return PortablePresentationNodeRenderer(
      node: material.layout,
      scope: scope,
    );
  }
}
