part of "../portable_presentation_renderer.dart";

final class _AuthoredCollectionRow {
  const _AuthoredCollectionRow({
    required this.resource,
    required this.row,
    required this.key,
    required this.canonicalKey,
    required this.selectable,
    required this.scope,
  });

  final skir.ResourceId resource;
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
    final definition = scope.material?.dependencies.collections
        .where((candidate) => candidate.sourceId == sourceId)
        .firstOrNull;
    final draft = scope.authoring;
    final catalog = scope.catalog;
    if (definition == null || draft == null || catalog == null) {
      return (
        definition: definition,
        rows: const [],
        problem: "The presentation collection is unavailable",
      );
    }
    final projected = definition.projection;
    final resources = definition.resources;
    if ((projected == null) == (resources == null)) {
      return (
        definition: definition,
        rows: const [],
        problem: "The presentation collection source is invalid",
      );
    }
    final rows = <_AuthoredCollectionRow>[];
    final entries = draft.resources.entries.toList()
      ..sort((left, right) => left.key.value.compareTo(right.key.value));
    for (final entry in entries) {
      final record = entry.value;
      final eligible = resources != null
          ? catalog
                .nominalDefinitions(record.configuration)
                .contains(resources.root)
          : catalog.matchesNamedTemplate(record.configuration, projected!.root);
      if (!eligible) continue;
      final row = resources != null
          ? _authoredResourceRow(record)
          : _authoredProjectionRow(definition, projected!, record, catalog);
      if (row == null) {
        return (
          definition: definition,
          rows: const [],
          problem: "A presentation collection row could not be projected",
        );
      }
      final resourceBinding =
          resources?.resourceBindingId ?? projected!.resourceBindingId;
      final rowScope = scope.withValues({
        definition.rowBindingId: row,
        resourceBinding: skir.DataValue.wrapStringValue(entry.key.value),
      });
      final key = rowScope.evaluate(definition.key);
      final selectable = rowScope.evaluate(definition.selectability);
      if (key is! PortableExpressionAvailable) {
        return (
          definition: definition,
          rows: const [],
          problem: "A presentation collection key is unavailable",
        );
      }
      final selected = switch (selectable) {
        PortableExpressionAvailable(
          value: skir.DataValue_booleanWrapper(:final value),
        ) =>
          value,
        _ => false,
      };
      rows.add(
        _AuthoredCollectionRow(
          resource: entry.key,
          row: row,
          key: key.value,
          canonicalKey: canonicalAuthoredValue(key.value),
          selectable: selected,
          scope: rowScope,
        ),
      );
    }
    return (definition: definition, rows: rows, problem: null);
  }

  skir.DataValue _authoredResourceRow(skir.AuthoringRecord record) {
    final payload = skir.DataValue.createRecord(fields: record.fields);
    return switch (record.configuration) {
      skir.TypeSelection_completeWrapper(:final value) =>
        skir.DataValue.createNamed(actualType: value, payload: payload),
      _ => payload,
    };
  }

  skir.DataValue? _authoredProjectionRow(
    skir.PresentationCollectionDefinition definition,
    skir.PresentationCollectionProjection projection,
    skir.AuthoringRecord record,
    CheckedEditorCatalog catalog,
  ) {
    skir.DataValue? row;
    for (final field in projection.fields) {
      final source = switch (field.source) {
        skir.PresentationCollectionProjectionValue_contentWrapper(
          :final value,
        ) =>
          switch (record.readAt(value)) {
            PortablePathValue(:final value) => value,
            PortablePathUnavailable() => skir.DataValue.unfilled,
          },
        skir.PresentationCollectionProjectionValue_literalWrapper(
          :final value,
        ) =>
          value,
        _ => null,
      };
      if (source == null) return null;
      if (field.target.segments.isEmpty) {
        if (row != null || projection.fields.length != 1) return null;
        row = source;
        continue;
      }
      row = _writeProjectionValue(
        row ?? skir.DataValue.createRecord(fields: const []),
        field.target.segments.toList(growable: false),
        source,
      );
      if (row == null) return null;
    }
    row ??= skir.DataValue.createRecord(fields: const []);
    if (row == skir.DataValue.unfilled) return row;
    final applied = catalog.applyTemplate(
      definition.rowType,
      record.configuration,
    );
    return applied == null
        ? row
        : _completeProjectedValue(row, applied, catalog);
  }

  skir.DataValue? _completeProjectedValue(
    skir.DataValue authored,
    skir.TypeUse expected,
    CheckedEditorCatalog catalog,
  ) {
    if (authored == skir.DataValue.unfilled) return authored;
    return switch (expected) {
      skir.TypeUse_nullableWrapper(:final value) =>
        authored == skir.DataValue.null_
            ? authored
            : _completeProjectedValue(authored, value.value, catalog),
      skir.TypeUse_namedWrapper(:final value) => _completeProjectedNamedValue(
        value: authored,
        expected: value,
        catalog: catalog,
      ),
      _ => authored,
    };
  }

  skir.DataValue? _completeProjectedNamedValue({
    required skir.DataValue value,
    required skir.NamedTypeUse expected,
    required CheckedEditorCatalog catalog,
  }) {
    final payload = switch (value) {
      skir.DataValue_namedWrapper(:final value)
          when value.actualType == expected =>
        value.payload,
      skir.DataValue_namedWrapper() => null,
      _ => value,
    };
    if (payload == null) return null;
    final representation = catalog
        .published(expected.definition)
        ?.definition
        .representation;
    if (representation is! skir.RepresentationTemplate_recordWrapper) {
      return skir.DataValue.createNamed(actualType: expected, payload: payload);
    }
    final projected = payload.authoredRecord;
    if (projected == null) return null;
    final fields = catalog.fields(skir.TypeSelection.wrapComplete(expected));
    final expectedNames = {for (final field in fields) field.template.key};
    if (projected.fields.any((field) => !expectedNames.contains(field.name))) {
      return null;
    }
    final completed = <skir.FieldValue>[];
    for (final field in fields) {
      final existing = projected.fields
          .where((candidate) => candidate.name == field.template.key)
          .firstOrNull;
      final expectedField = field.type;
      final fieldValue = existing?.value ?? skir.DataValue.unfilled;
      final normalized = expectedField == null
          ? fieldValue
          : _completeProjectedValue(fieldValue, expectedField, catalog);
      if (normalized == null) return null;
      completed.add(
        skir.FieldValue(name: field.template.key, value: normalized),
      );
    }
    return skir.DataValue.createNamed(
      actualType: expected,
      payload: skir.DataValue.createRecord(fields: completed),
    );
  }

  skir.DataValue? _writeProjectionValue(
    skir.DataValue current,
    List<skir.PathSegment> segments,
    skir.DataValue value,
  ) {
    if (segments.isEmpty) return value;
    final field = switch (segments.first) {
      skir.PathSegment_fieldWrapper(:final value) => value.name,
      _ => null,
    };
    if (field == null) return null;
    final payload = current.authoredPayload;
    final record = payload.authoredRecord;
    if (record == null) return null;
    final fields = <skir.FieldValue>[...record.fields];
    final index = fields.indexWhere((candidate) => candidate.name == field);
    final nested = _writeProjectionValue(
      index < 0
          ? skir.DataValue.createRecord(fields: const [])
          : fields[index].value,
      segments.sublist(1),
      value,
    );
    if (nested == null) return null;
    final replacement = skir.FieldValue(name: field, value: nested);
    if (index < 0) {
      fields.add(replacement);
    } else {
      fields[index] = replacement;
    }
    return current.withAuthoredPayload(
      skir.DataValue.createRecord(fields: fields),
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
    final record = row.scope.authoring?.resource(row.resource);
    final fallbackLabel =
        _authoredLinkTargetLabel(record) ?? row.resource.value;
    if (catalog == null || record == null) return Text(fallbackLabel);
    final appearance = definition.resources?.appearance;
    final material = appearance == null
        ? switch (catalog.selectPresentation(
            record.configuration,
            skir.PresentationRole.referenceOption,
          )) {
            SelectedEditorPresentation(:final material) => material,
            _ => null,
          }
        : catalog.presentationMaterial(appearance, record.configuration);
    if (material == null) return Text(fallbackLabel);
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
