part of "authored_presentation_host.dart";

/// Collection items and map rows: projection and insertion.
extension _AuthoredPresentationCollections on AuthoredPresentationHost {
  Future<PortablePresentationWriteResult> _addCollectionItem(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  }) async {
    final target = location(reference, context: context);
    final current = read(reference, context: context);
    final items = switch (current) {
      final value when value == skir.DataValue.unfilled => <skir.ListItem>[],
      _ => current?.authoredItems?.toList(),
    };
    if (target == null || items == null || edit == null) {
      return _reject("The collection binding is unavailable", target: target);
    }
    final item = skir.ItemId(value: "panel:${const Uuid().v4()}");
    final itemReference = skir.BindingRef(
      bindingId: reference.bindingId,
      path: skir.ValuePath(
        segments: [
          ...reference.path.segments,
          skir.PathSegment.createItem(id: item),
        ],
      ),
    );
    final expected = expectedType(itemReference, context: context);
    var unwrapped = expected;
    while (unwrapped is skir.TypeUse_nullableWrapper) {
      unwrapped = unwrapped.value.value;
    }
    final named = switch (unwrapped) {
      skir.TypeUse_namedWrapper(:final value) => value,
      _ => null,
    };
    final representation = named == null
        ? null
        : authored.catalog
              .published(named.definition)
              ?.definition
              .representation;
    final requiresPreparation = switch (representation) {
      skir.RepresentationTemplate_recordWrapper(:final value) =>
        !value.abstract_,
      _ => false,
    };
    if (!requiresPreparation) {
      return _stage("Add collection item", (operation) {
        operation.insert(
          target,
          items.lastOrNull?.id,
          skir.ListItem(id: item, value: authored.defaultValue(expected)),
        );
      }, target: target);
    }
    final prepare = prepareValue;
    if (named == null || prepare == null) {
      return _reject("The collection item cannot be prepared", target: target);
    }
    final selection = skir.TypeSelection.wrapComplete(named);
    final request = skir.ValuePreparationRequest(
      catalog: authored.generation,
      target: skir.PreparationTarget.wrapRecord(selection),
      suppliedValue: skir.DataValue.createRecord(fields: const []),
    );
    final result = await edit!.prepare(
      label: "Add collection item",
      from: authored,
      apply: (operation) async {
        operation.expect(target);
        final prepared = await prepare(request);
        if (_disposed || !enabled || readOnly) {
          throw StateError("The presentation closed during preparation");
        }
        operation.insertPrepared(
          target,
          items.lastOrNull?.id,
          item,
          request,
          prepared,
        );
      },
    );
    if (result case EditStageRejected(:final message)) {
      return _reject(message, target: target);
    }
    return const PortablePresentationWriteApplied();
  }

  PortableCollectionProjection _projectCollection(
    String sourceId, {
    required skir.PresentationMaterial material,
    required PortableInvocationContext context,
  }) {
    final definition = material.dependencies.collections
        .where((candidate) => candidate.sourceId == sourceId)
        .firstOrNull;
    final queries = context.queries;
    final observation = queries?.authored;
    final checked = queries?.catalog;
    if (definition == null ||
        observation == null ||
        checked == null ||
        context.catalogGeneration != observation.generation) {
      return PortableCollectionProjection(
        definition: definition,
        rows: const [],
        problem: "The presentation collection is unavailable",
      );
    }
    final projected = definition.projection;
    if (projected == null) {
      return PortableCollectionProjection(
        definition: definition,
        rows: const [],
        problem: "The presentation collection source is invalid",
      );
    }
    final rows = <PortableCollectionRowProjection>[];
    final entries = observation.resources.entries.toList()
      ..sort((left, right) => left.key.value.compareTo(right.key.value));
    for (final entry in entries) {
      final record = entry.value;
      if (!checked.matchesNamedTemplate(record.configuration, projected.root)) {
        continue;
      }
      final row = _projectionRow(definition, projected, record, checked);
      if (row == null) {
        return PortableCollectionProjection(
          definition: definition,
          rows: const [],
          problem: "A presentation collection row could not be projected",
        );
      }
      final bindings = {
        ...context.bindings,
        definition.rowBinding.id: PortableExpressionBinding(value: row),
        projected.resourceBinding.id: entry.key.toExpressionBinding(),
      };
      final key = PortableExpressionEvaluator.located(
        bindings,
        budget: budget,
        catalog: checked,
        queries: queries,
      ).evaluate(definition.key);
      final selectable = PortableExpressionEvaluator.located(
        bindings,
        budget: budget,
        catalog: checked,
        queries: queries,
      ).evaluate(definition.selectability);
      if (key is! PortableExpressionAvailable) {
        return PortableCollectionProjection(
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
        PortableCollectionRowProjection(
          resource: entry.key,
          configuration: record.configuration,
          label: checked.appearanceOf(record).label,
          row: row,
          key: key.value,
          canonicalKey: canonicalAuthoredValue(key.value),
          selectable: selected,
        ),
      );
    }
    return PortableCollectionProjection(definition: definition, rows: rows);
  }

  skir.DataValue? _projectionRow(
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
      definition.rowBinding.type,
      record.configuration,
    );
    return applied == null
        ? row
        : _completeProjectedValue(row, applied, catalog);
  }

  skir.DataValue? _completeProjectedValue(
    skir.DataValue authoredValue,
    skir.TypeUse expected,
    CheckedEditorCatalog catalog,
  ) {
    if (authoredValue == skir.DataValue.unfilled) return authoredValue;
    return switch (expected) {
      skir.TypeUse_nullableWrapper(value: final nullable) =>
        authoredValue == skir.DataValue.null_
            ? authoredValue
            : _completeProjectedValue(authoredValue, nullable.value, catalog),
      skir.TypeUse_namedWrapper(value: final named) =>
        _completeProjectedNamedValue(authoredValue, named, catalog),
      _ => authoredValue,
    };
  }

  skir.DataValue? _completeProjectedNamedValue(
    skir.DataValue authoredValue,
    skir.NamedTypeUse expected,
    CheckedEditorCatalog catalog,
  ) {
    final payload = switch (authoredValue) {
      skir.DataValue_namedWrapper(:final value)
          when value.actualType == expected =>
        value.payload,
      skir.DataValue_namedWrapper() => null,
      _ => authoredValue,
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
      final fieldValue = existing?.value ?? skir.DataValue.unfilled;
      final normalized = field.type == null
          ? fieldValue
          : _completeProjectedValue(fieldValue, field.type!, catalog);
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
    final record = current.authoredPayload.authoredRecord;
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

  Future<PortablePresentationWriteResult> _addMapRow(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  }) async {
    final target = location(reference, context: context);
    final payload = read(reference, context: context)?.authoredPayload;
    final rows = switch (payload) {
      skir.DataValue_mapValueWrapper(:final value) => value.rows.toList(),
      final value when value == skir.DataValue.unfilled => <skir.MapRow>[],
      _ => null,
    };
    if (target == null || rows == null) {
      return _reject("The map binding is unavailable", target: target);
    }
    final item = skir.ItemId(value: "panel:${const Uuid().v4()}");
    skir.TypeUse? branchType(skir.PathSegment branch) => expectedType(
      skir.BindingRef(
        bindingId: reference.bindingId,
        path: skir.ValuePath(
          segments: [
            ...reference.path.segments,
            skir.PathSegment.createItem(id: item),
            branch,
          ],
        ),
      ),
      context: context,
    );
    final binding = edit;
    if (!enabled || readOnly || binding == null) {
      return _reject("This presentation is read only", target: target);
    }
    final keyType = branchType(skir.PathSegment.mapKey);
    final valueType = branchType(skir.PathSegment.mapValue);
    final observation = authored;
    Future<(skir.ValuePreparationRequest, skir.PreparedValue)?> prepareBranch(
      skir.TypeUse? type,
    ) async {
      // Nullable entries start at null, matching local shape initialization.
      if (type is! skir.TypeUse_namedWrapper) return null;
      final representation = observation.catalog
          .published(type.value.definition)
          ?.definition
          .representation;
      if (representation is! skir.RepresentationTemplate_recordWrapper ||
          representation.value.abstract_) {
        return null;
      }
      final prepare = prepareValue;
      if (prepare == null) {
        throw StateError("The map branch cannot be prepared");
      }
      final request = skir.ValuePreparationRequest(
        catalog: observation.generation,
        target: skir.PreparationTarget.wrapRecord(
          skir.TypeSelection.wrapComplete(type.value),
        ),
        suppliedValue: skir.DataValue.createRecord(fields: const []),
      );
      final prepared = await prepare(request);
      if (_disposed || !enabled || readOnly) {
        throw StateError("The presentation closed during preparation");
      }
      return (request, prepared);
    }

    final result = await binding.prepare(
      label: "Add map row",
      from: observation,
      apply: (operation) async {
        final current = operation.expect(target);
        if (current is! PortablePathValue<skir.DataValue> ||
            current.value.authoredPayload != payload) {
          throw StateError("The map changed before this edit");
        }
        final key = await prepareBranch(keyType);
        final value = await prepareBranch(valueType);
        if (_disposed || !enabled || readOnly) {
          throw StateError("The presentation closed during preparation");
        }
        operation.replaceMap(target, [
          ...rows,
          skir.MapRow(
            id: item,
            key: observation.defaultValue(keyType),
            value: observation.defaultValue(valueType),
          ),
        ]);
        for (final (branch, prepared) in [
          (skir.PathSegment.mapKey, key),
          (skir.PathSegment.mapValue, value),
        ]) {
          if (prepared == null) continue;
          operation.applyPreparedRecord(
            skir.ValueLocation(
              resource: target.resource,
              path: skir.ValuePath(
                segments: [
                  ...target.path.segments,
                  skir.PathSegment.createItem(id: item),
                  branch,
                ],
              ),
            ),
            prepared.$1,
            prepared.$2,
          );
        }
      },
    );
    return switch (result) {
      EditStageRejected(:final message) => _reject(message, target: target),
      _ => const PortablePresentationWriteApplied(),
    };
  }
}
