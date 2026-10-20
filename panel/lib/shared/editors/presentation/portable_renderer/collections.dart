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
    required this.authoredAddress,
    this.schema,
  });

  final PortablePresentationBindingSchema? schema;
  final skir.ResourceId resource;
  final skir.TypeSelection configuration;
  final String label;
  final skir.DataValue row;
  final skir.DataValue key;
  final String canonicalKey;
  final bool selectable;
  final PortablePresentationScope scope;
  final AuthoredBindingAddress authoredAddress;
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
    final rootKeys = <String>[];
    for (final root in _collectionKeyValues(roots)) {
      if (collection.rows.firstOrNull case final first?
          when !_sameCollectionKeyType(first.key, root)) {
        return _diagnostic("A collection graph root has the wrong key type");
      }
      final canonical = canonicalAuthoredValue(root);
      rootKeys.add(canonical);
    }
    final rootSlot = _slotId(element.rootSequence.item);
    final childSlot = _slotId(element.children.item);
    if (rootSlot == null || childSlot == null) {
      return _diagnostic("The collection graph slots are unavailable");
    }
    final maximumDepth = element.maximumDepth ?? collection.rows.length;

    final projection = _projectCollectionGraph(
      roots: rootKeys,
      adjacency: adjacency,
      availableKeys: rowsByKey.keys.toSet(),
      maximumDepth: maximumDepth,
      maximumOccurrences: childScope.budget.maxCollectionItems,
    );
    final graphIdentity = (
      childScope.material?.provider,
      childScope.resource,
      element.sourceId,
      node.nodeId,
    );

    // Follow invocation ownership without resetting disclosure on value edits.
    final invocationIdentity = <skir.ExpressionBindingId, Object>{
      for (final id in {
        ...childScope.bindings.keys,
        ...childScope.authoredAliases.keys,
      })
        if (childScope.bindings[id]?.location != null ||
            childScope.authoredAliases[id] != null)
          id: (
            childScope.bindings[id]?.location,
            childScope.authoredAliases[id],
          ),
    };
    final rootsByKey = {
      for (final occurrence in projection.roots)
        occurrence.canonicalKey: occurrence,
    };

    Widget renderNode(_CollectionGraphOccurrence occurrence) {
      final row = rowsByKey[occurrence.canonicalKey]!;
      final occurrencesByKey = {
        for (final child in occurrence.children) child.canonicalKey: child,
      };
      final children = [
        for (final key in occurrencesByKey.keys) rowsByKey[key]!,
      ];
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
      final nodeScope = row.scope
          .withValues(
            {element.childrenBindingId: childValues},
            schemas: {
              if (row.schema case CompletePortablePresentationBinding(
                :final use,
              ))
                element.childrenBindingId: CompletePortablePresentationBinding(
                  skir.TypeUse.createNamed(
                    definition: skir.TypeDefinitionId(
                      typeId: skir.TypeId.createQualified(
                        namespace: "typewriter",
                        name: "List",
                      ),
                      revision: 1,
                    ),
                    arguments: [use],
                  ),
                ),
            },
          )
          .copyWith(
            authoredAliases: {
              ...row.scope.authoredAliases,
              element.childrenBindingId: AuthoredBindingAddress(
                root: row.authoredAddress.root,
                path: const [],
              ),
            },
          );
      return PortablePresentationNodeRenderer(
        node: element.node,
        scope: nodeScope.withSlotBuilders({
          childSlot: (_) => _renderCollectionSequence(
            element.children,
            children,
            (child) => renderNode(occurrencesByKey[child.canonicalKey]!),
            element.childBindingId,
            childSlot,
            nodeScope,
            itemKey: (child) => _CollectionGraphOccurrenceKey(
              graph: graphIdentity,
              invocation: invocationIdentity,
              path: [...occurrence.path, child.canonicalKey],
            ),
          ),
        }),
      );
    }

    final rendered = _renderCollectionSequence(
      element.rootSequence,
      [for (final root in projection.roots) rowsByKey[root.canonicalKey]!],
      (row) => renderNode(rootsByKey[row.canonicalKey]!),
      collection.definition!.rowBindingId,
      rootSlot,
      childScope,
      itemKey: (row) => _CollectionGraphOccurrenceKey(
        graph: graphIdentity,
        invocation: invocationIdentity,
        path: [row.canonicalKey],
      ),
    );
    if (!projection.truncated) return rendered;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        rendered,
        _diagnostic("The collection graph occurrence limit was reached"),
      ],
    );
  }

  Widget _renderCollectionSequence(
    skir.SequencePresentation sequence,
    List<_AuthoredCollectionRow> rows,
    Widget Function(_AuthoredCollectionRow row) content,
    skir.ExpressionBindingId itemBinding,
    String slot,
    PortablePresentationScope fallbackScope, {
    required Object Function(_AuthoredCollectionRow row) itemKey,
  }) {
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
          .withValues(
            {itemBinding: row.row},
            schemas: {itemBinding: ?row.schema},
          )
          .copyWith(
            authoredAliases: {
              ...row.scope.authoredAliases,
              itemBinding: row.authoredAddress,
            },
          )
          .withSlotBuilders({slot: (_) => content(row)});
      children.add(
        PortablePresentationNodeRenderer(
          key: ValueKey(itemKey(row)),
          node: sequence.item,
          scope: scope,
        ),
      );
      itemScopes.add(scope);
    }
    return _renderSequence(
      children,
      sequence.layout,
      fallbackScope,
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
      final PortableCollectionProjectionHost value => value,
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
    final resourceBinding = definition.projection!.resourceBindingId;
    return (
      definition: definition,
      rows: [
        for (final row in projected.rows)
          _AuthoredCollectionRow(
            resource: row.resource,
            schema: row.schema,
            configuration: row.configuration,
            label: row.label,
            row: row.row,
            key: row.key,
            canonicalKey: row.canonicalKey,
            selectable: row.selectable,
            authoredAddress: AuthoredBindingAddress(
              root: AuthoredBindingRoot.collection(sourceId),
              path: [
                AuthoredPathStep.exact(
                  skir.PathSegment.createItem(
                    id: skir.ItemId(value: row.canonicalKey),
                  ),
                ),
              ],
            ),
            scope: scope
                .withValues(
                  {
                    definition.rowBindingId: row.row,
                    resourceBinding: row.resource.toExpressionValue(),
                  },
                  schemas: {
                    definition.rowBindingId: ?row.schema,
                    resourceBinding: CompletePortablePresentationBinding(
                      skir.TypeUse.wrapNamed(frameworkResourceIdUse),
                    ),
                  },
                )
                .copyWith(
                  authoredAliases: {
                    ...scope.authoredAliases,
                    definition.rowBindingId: AuthoredBindingAddress(
                      root: AuthoredBindingRoot.collection(sourceId),
                      path: [
                        AuthoredPathStep.exact(
                          skir.PathSegment.createItem(
                            id: skir.ItemId(value: row.canonicalKey),
                          ),
                        ),
                      ],
                    ),
                  },
                ),
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

/// Borrows the source projection host but owns feedback for this referenced
/// resource and catalog lifetime. Summary content excludes focus and pointer
/// interaction; option content leaves row activation with its enclosing picker.
final class _ResourceReferenceAppearance extends HookWidget {
  const _ResourceReferenceAppearance({
    required this.resource,
    required this.scope,
    required this.role,
    required this.render,
    required this.fallback,
  });

  final skir.ResourceId resource;
  final PortablePresentationScope scope;
  final skir.PresentationRole role;

  /// Renders the selected presentation of the resource with its appearance.
  final Widget Function(
    skir.PresentationNode,
    PortablePresentationScope,
    ResourceAppearance,
  )
  render;

  /// Stands in for the presentation: with the appearance when the resource
  /// is known, and with a problem when its presentation cannot render.
  final Widget Function(ResourceAppearance?, String? problem) fallback;

  @override
  Widget build(BuildContext context) {
    final operations = useMemoized(PortableOperationResults.new, [
      scope.host,
      resource,
      scope.catalog?.snapshot.generation,
    ]);
    useEffect(() => operations.dispose, [operations]);
    final host = scope.host;
    final catalog = scope.catalog;
    if (host == null ||
        host is! PortableCollectionProjectionHost ||
        catalog == null) {
      return fallback(null, null);
    }
    final projection = (host as PortableCollectionProjectionHost)
        .projectResource(resource, context: scope.invocation);
    if (projection == null) return fallback(null, null);
    final appearance = projection.appearance;
    final material = switch (catalog.selectPresentation(
      projection.configuration,
      role,
    )) {
      SelectedEditorPresentation(:final material) => material,
      _ => null,
    };
    if (material == null) return fallback(appearance, null);
    final configured = PortableExpressionBinding(
      value: projection.value,
      location: skir.ValueLocation(resource: resource, path: editorRootPath),
      schema: switch (projection.configuration) {
        skir.TypeSelection_completeWrapper(:final value) =>
          CompletePortablePresentationBinding(skir.TypeUse.wrapNamed(value)),
        skir.TypeSelection_pendingWrapper() =>
          PartialPortablePresentationBinding(projection.configuration),
        _ => null,
      },
    );
    final PortablePresentationScope targetScope;
    try {
      targetScope = scope
          .copyWith(
            resource: resource,
            role: material.role,
            operations: operations,
            reportStatus: operations.reportStatus,
            bindings: {
              ...scope.bindings,
              _configuredValueBindingId: configured,
              presentationSubjectIdentifierBindingId: resource
                  .toExpressionBinding(),
              presentationSubjectAppearanceBindingId: appearance
                  .toExpressionBinding(),
            },
            authoredAliases: {
              ...scope.authoredAliases,
              _configuredValueBindingId: AuthoredBindingAddress.binding(
                _configuredValueBindingId,
                configured,
              ),
            },
          )
          .withMaterial(material)
          .withActivePresentation(material.provider)
          .withReadOnly(true);
    } on FormatException catch (error) {
      return fallback(appearance, error.message);
    } on StateError catch (error) {
      return fallback(appearance, error.message);
    }
    final content = PortablePresentationChrome(
      role: role,
      child: render(material.layout, targetScope, appearance),
    );
    return _PortableDiagnosticBoundary(
      key: ValueKey((scope.catalog?.snapshot.generation, resource)),
      operations: operations,
      diagnostics: projection.diagnostics,
      diagnosticFallback: projection.diagnosticFallback,
      observations: [
        PortableDiagnosticObservation(
          target: PortableDiagnosticTarget.value(
            skir.ValueLocation(resource: resource, path: editorRootPath),
          ),
          value: projection.value,
        ),
      ],
      child: role == skir.PresentationRole.referencePreview
          ? ExcludeFocus(child: IgnorePointer(child: content))
          : content,
    );
  }
}
