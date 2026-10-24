part of "checked_editor_catalog.dart";

/// Reference discovery: where authored records hold references and which
/// unselected forms could hold them.
extension CheckedReferenceDiscovery on CheckedEditorCatalog {
  ({skir.EndpointId endpoint, skir.TypeUse target})? referenceTypeAt(
    skir.AuthoringRecord record,
    skir.ValuePath path,
  ) => _referenceForUse(
    namedUse(
      valueTypeAt(
        record.configuration,
        path,
        value: skir.DataValue.createRecord(fields: record.fields),
      ),
    ),
  );

  ({skir.EndpointId endpoint, skir.TypeUse target})? _referenceForUse(
    skir.NamedTypeUse? use,
  ) {
    if (use == null) return null;
    final declaration = published(use.definition);
    if (declaration?.status != skir.DeclarationStatus.ready) return null;
    final representation = declaration?.definition.representation;
    if (representation is! skir.RepresentationTemplate_linkWrapper) return null;
    final target = applyTemplate(
      representation.value.target,
      skir.TypeSelection.wrapComplete(use),
    );
    return target == null
        ? null
        : (endpoint: representation.value.endpoint, target: target);
  }

  /// Exact reference paths in the authored value, including unfinished links.
  Iterable<
    ({skir.ValuePath path, skir.EndpointId endpoint, skir.TypeUse target})
  >
  referenceLocations(skir.AuthoringRecord record) sync* {
    for (final node in record._referenceValues) {
      final reference = referenceTypeAt(record, node.path);
      if (reference != null) {
        yield (
          path: node.path,
          endpoint: reference.endpoint,
          target: reference.target,
        );
      }
    }
  }

  /// Existing collection containers whose item contract is a direct reference.
  Iterable<
    ({skir.ValuePath path, skir.EndpointId endpoint, skir.TypeUse target})
  >
  referenceCollections(skir.AuthoringRecord record) sync* {
    for (final node in record._referenceValues) {
      if (node.value.authoredItems == null &&
          node.value.authoredPayload != skir.DataValue.unfilled) {
        continue;
      }
      final type = valueTypeAt(
        record.configuration,
        node.path,
        value: skir.DataValue.createRecord(fields: record.fields),
      );
      final reference = _referenceForUse(namedUse(collectionItemType(type)));
      if (reference != null) {
        yield (
          path: node.path,
          endpoint: reference.endpoint,
          target: reference.target,
        );
      }
    }
  }

  /// Unselected authored forms that could contain the requested counterpart.
  Iterable<skir.ValuePath> unselectedReferenceForms(
    skir.AuthoringRecord record,
    skir.EndpointId endpoint,
  ) sync* {
    for (final node in record._referenceValues) {
      final use = namedUse(
        valueTypeAt(
          record.configuration,
          node.path,
          value: skir.DataValue.createRecord(fields: record.fields),
        ),
      );
      if (use == null) continue;
      final selection = _selectionForUse(use, node.value);
      if (selection == null || !isAbstractRecordSelection(selection)) continue;
      if (_mayContainReference(skir.TypeUse.wrapNamed(use), endpoint, {})) {
        yield node.path;
      }
    }
  }

  bool _mayContainReference(
    skir.TypeUse? type,
    skir.EndpointId endpoint,
    Set<skir.NamedTypeUse> visited,
  ) {
    final use = namedUse(type);
    if (use == null || visited.contains(use)) return false;
    if (visited.length >= _maximumCheckedTypeDepth) return true;
    final selection = skir.TypeSelection.wrapComplete(use);
    final next = {...visited, use};
    final representation = published(use.definition)?.definition.representation;
    return switch (representation) {
      skir.RepresentationTemplate_linkWrapper(:final value) =>
        value.endpoint == endpoint,
      skir.RepresentationTemplate_recordWrapper(:final value) =>
        fields(selection).any(
              (field) => _mayContainReference(field.type, endpoint, next),
            ) ||
            (value.abstract_ &&
                concreteRecordSelections(selection).any(
                  (candidate) => fields(candidate).any(
                    (field) => _mayContainReference(field.type, endpoint, next),
                  ),
                )),
      skir.RepresentationTemplate_sequenceWrapper(:final value) =>
        _mayContainReference(
          applyTemplate(value.item, selection),
          endpoint,
          next,
        ),
      skir.RepresentationTemplate_mappingWrapper(:final value) =>
        _mayContainReference(
              applyTemplate(value.key, selection),
              endpoint,
              next,
            ) ||
            _mayContainReference(
              applyTemplate(value.value, selection),
              endpoint,
              next,
            ),
      _ => false,
    };
  }

  skir.TypeSelection? _selectionAtValue(
    skir.TypeSelection declared,
    skir.DataValue? value,
  ) {
    if (value case skir.DataValue_namedWrapper(:final value)) {
      final actual = value.actualType;
      final compatible = switch (declared) {
        skir.TypeSelection_completeWrapper(:final value) => isReadableAs(
          skir.TypeUse.wrapNamed(actual),
          skir.TypeUse.wrapNamed(value),
        ),
        skir.TypeSelection_pendingWrapper() =>
          knownApplications(skir.TypeSelection.wrapComplete(actual)).any(
            (candidate) => knownApplications(declared).any(
              (expected) => isReadableAs(
                skir.TypeUse.wrapNamed(candidate),
                skir.TypeUse.wrapNamed(expected),
              ),
            ),
          ),
        _ => false,
      };
      return compatible ? skir.TypeSelection.wrapComplete(actual) : null;
    }
    return declared;
  }

  skir.TypeSelection? _selectionForUse(
    skir.NamedTypeUse declared,
    skir.DataValue? value,
  ) {
    if (value case skir.DataValue_namedWrapper(:final value)) {
      if (!isReadableAs(
        skir.TypeUse.wrapNamed(value.actualType),
        skir.TypeUse.wrapNamed(declared),
      )) {
        return null;
      }
      return skir.TypeSelection.wrapComplete(value.actualType);
    }
    return skir.TypeSelection.wrapComplete(declared);
  }

  skir.DataValue? _namedPayload(skir.DataValue? value) => switch (value) {
    skir.DataValue_namedWrapper(:final value) => value.payload,
    _ => value,
  };

  skir.DataValue? _fieldValue(skir.DataValue? value, String name) {
    final payload = _namedPayload(value);
    final fields = switch (payload) {
      skir.DataValue_recordWrapper(:final value) =>
        value.fields
            .where((field) => field.name == name)
            .toList(growable: false),
      _ => const <skir.FieldValue>[],
    };
    return fields.length == 1 ? fields.single.value : null;
  }

  skir.DataValue? _collectionItem(skir.DataValue? value, skir.ItemId id) {
    final items = switch (value) {
      skir.DataValue_listValueWrapper(:final value) => value.items,
      skir.DataValue_setValueWrapper(:final value) => value.items,
      _ => const <skir.ListItem>[],
    };
    final matching = items
        .where((candidate) => candidate.id == id)
        .toList(growable: false);
    return matching.length == 1 ? matching.single.value : null;
  }

  skir.DataValue? _mapRowValue(
    skir.DataValue? value,
    skir.ItemId id,
    skir.PathSegment branch,
  ) {
    final rows = switch (value) {
      skir.DataValue_mapValueWrapper(:final value) =>
        value.rows
            .where((candidate) => candidate.id == id)
            .toList(growable: false),
      _ => const <skir.MapRow>[],
    };
    if (rows.length != 1) return null;
    return switch (branch) {
      final value when value == skir.PathSegment.mapKey => rows.single.key,
      final value when value == skir.PathSegment.mapValue => rows.single.value,
      _ => null,
    };
  }
}

extension _AuthoredReferenceValues on skir.AuthoringRecord {
  Iterable<({skir.ValuePath path, skir.DataValue value})>
  get _referenceValues sync* {
    final pending = <(skir.DataValue, skir.ValuePath, int)>[
      (
        skir.DataValue.createRecord(fields: fields),
        skir.ValuePath(segments: const []),
        0,
      ),
    ];
    final visited = <skir.ValuePath>{};
    while (pending.isNotEmpty) {
      final (value, path, depth) = pending.removeLast();
      if (depth > _maximumCheckedTypeDepth) {
        throw StateError("The authored value exceeded its depth limit");
      }
      if (path.segments.isNotEmpty && visited.add(path)) {
        yield (path: path, value: value);
      }
      void add(skir.DataValue value, skir.PathSegment segment) => pending.add((
        value,
        skir.ValuePath(segments: [...path.segments, segment]),
        depth + 1,
      ));
      switch (value) {
        case skir.DataValue_namedWrapper(:final value):
          pending.add((value.payload, path, depth + 1));
        case skir.DataValue_recordWrapper(:final value):
          for (final field in value.fields.toList().reversed) {
            add(field.value, skir.PathSegment.createField(name: field.name));
          }
        case skir.DataValue_listValueWrapper(:final value):
          for (final item in value.items.toList().reversed) {
            add(item.value, skir.PathSegment.createItem(id: item.id));
          }
        case skir.DataValue_setValueWrapper(:final value):
          for (final item in value.items.toList().reversed) {
            add(item.value, skir.PathSegment.createItem(id: item.id));
          }
        case skir.DataValue_mapValueWrapper(:final value):
          for (final row in value.rows.toList().reversed) {
            final rowPath = skir.ValuePath(
              segments: [
                ...path.segments,
                skir.PathSegment.createItem(id: row.id),
              ],
            );
            pending
              ..add((
                row.value,
                skir.ValuePath(
                  segments: [...rowPath.segments, skir.PathSegment.mapValue],
                ),
                depth + 1,
              ))
              ..add((
                row.key,
                skir.ValuePath(
                  segments: [...rowPath.segments, skir.PathSegment.mapKey],
                ),
                depth + 1,
              ));
          }
        default:
      }
    }
  }
}
