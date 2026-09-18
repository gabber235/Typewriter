import "package:flutter/foundation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// Owns one incomplete local value until it can become canonical data.
final class CreationDraft extends ChangeNotifier
    implements EditOwner, EditorStructureOwner {
  CreationDraft({
    required this.rootType,
    required TypeRegistry registry,
    Map<MaterializationLocation, DataValue> fixedValues = const {},
  }) : typeCatalog = registry.catalog,
       _registry = registry,
       _root = planCreationDraft(
         type: rootType,
         registry: registry,
         fixedValues: fixedValues,
       ) {
    _nextId = _maximumId(_root) + 1;
  }

  @override
  final TypeExpression rootType;
  @override
  final TypeCatalog typeCatalog;
  final TypeRegistry _registry;
  DraftValue _root;
  late int _nextId;
  bool _disposed = false;
  final Set<_CreationDraftInteraction> _interactions = {};

  DraftValue get root => _root;
  TypeRegistry get registry => _registry;

  @override
  bool get readOnly => _disposed;

  List<TypeDiagnostic> get diagnostics => finalize().diagnostics;

  @override
  EditorValue value(DataPath path) {
    final located = _locate(_root, rootType, path.segments, 0, _registry);
    if (located == null) {
      return EditorValue.invalid([
        TypeDiagnostic(
          code: TypeDiagnosticCode.invalidPath,
          message: "Draft path is unavailable",
          path: path,
        ),
      ]);
    }
    return _editorValue(located.$1, located.$2, path, _registry);
  }

  @override
  EditorMutationResult validate(DataPath path, DataValue value) {
    final located = _locate(_root, rootType, path.segments, 0, _registry);
    if (located == null) return _invalidPath(path);
    if (_draftShapeMatches(value, located.$2, _registry)) {
      return EditorMutationResult.applied(value);
    }
    final diagnostics = value.validateAgainst(
      located.$2,
      path: path,
      registry: _registry,
    );
    return diagnostics.isEmpty
        ? EditorMutationResult.applied(value)
        : EditorMutationResult.invalid(diagnostics);
  }

  @override
  EditorMutationResult update(
    DataPath path,
    DataValue value, {
    EditorStructuralMutation? structuralMutation,
  }) {
    if (_disposed) return const EditorMutationResult.conflict();
    final validation = validate(path, value);
    if (validation is! AppliedEditorMutation) return validation;
    final replacement = _freshDraft(locatedType(path)!, value);
    final next = _replace(
      _root,
      rootType,
      path.segments,
      0,
      replacement,
      _registry,
    );
    if (next == null) return _invalidPath(path);
    _root = next;
    notifyListeners();
    return validation;
  }

  TypeExpression? locatedType(DataPath path) =>
      _locate(_root, rootType, path.segments, 0, _registry)?.$2;

  @override
  EditorInteractionSession beginInteraction(DataPath path) {
    final interaction = _CreationDraftInteraction(this, path, _root);
    if (_disposed) {
      interaction.active = false;
    } else {
      _interactions.add(interaction);
    }
    return interaction;
  }

  @override
  EditorListStructure? listStructure(DataPath path) {
    final located = _locate(_root, rootType, path.segments, 0, _registry);
    if (located case (final ListDraftValue list, ListType())) {
      return EditorListStructure([for (final item in list.items) item.id]);
    }
    return null;
  }

  @override
  EditorMapStructure? mapStructure(DataPath path) {
    final located = _locate(_root, rootType, path.segments, 0, _registry);
    if (located case (
      final MapDraftValue map,
      MapType(key: final keyType, value: final valueType),
    )) {
      return EditorMapStructure([
        for (final entry in map.entries)
          EditorMapEntryStructure(
            id: entry.id,
            key: _editorValue(entry.key, keyType, path, _registry),
            value: _editorValue(entry.value, valueType, path, _registry),
            keyDiagnostics: _finalize(
              entry.key,
              keyType,
              DataPath.root,
              _registry,
            ).diagnostics,
            valueDiagnostics: _finalize(
              entry.value,
              valueType,
              DataPath.root,
              _registry,
            ).diagnostics,
          ),
      ]);
    }
    return null;
  }

  @override
  EditorPolymorphicStructure? polymorphicStructure(DataPath path) {
    final located = _locate(_root, rootType, path.segments, 0, _registry);
    if (located case (final PolymorphicDraftValue draft, NamedType())) {
      final concrete = draft.concreteType;
      final payload = draft.payload;
      final payloadType = concrete == null
          ? null
          : _registry.resolveExact(concrete).valueOrNull?.representation;
      return EditorPolymorphicStructure(
        concreteType: concrete,
        payload: payload == null || payloadType == null
            ? const EditorValue.missing()
            : _editorValue(payload, payloadType, path, _registry),
      );
    }
    return null;
  }

  @override
  EditorMutationResult appendListItem(DataPath path) => _changeList(
    path,
    (list, type) =>
        ListDraftValue(list.id, [...list.items, _newDraft(type.element)]),
  );

  @override
  EditorMutationResult removeListItem(DataPath path, int index) => _changeList(
    path,
    (list, type) => index < 0 || index >= list.items.length
        ? null
        : ListDraftValue(list.id, [...list.items]..removeAt(index)),
  );

  @override
  EditorMutationResult duplicateListItem(DataPath path, int index) =>
      _changeList(
        path,
        (list, type) => index < 0 || index >= list.items.length
            ? null
            : ListDraftValue(list.id, [
                ...list.items.take(index + 1),
                _cloneFresh(list.items[index]),
                ...list.items.skip(index + 1),
              ]),
      );

  @override
  EditorMutationResult reorderListItem(DataPath path, int from, int to) =>
      _changeList(path, (list, type) {
        if (from < 0 ||
            from >= list.items.length ||
            to < 0 ||
            to >= list.items.length) {
          return null;
        }
        final items = [...list.items];
        items.insert(to, items.removeAt(from));
        return ListDraftValue(list.id, items);
      });

  @override
  EditorMutationResult appendMapEntry(DataPath path) {
    final located = _locate(_root, rootType, path.segments, 0, _registry);
    if (located case (
      final MapDraftValue map,
      MapType(key: final key, value: final value),
    )) {
      return _replaceStructure(
        path,
        MapDraftValue(map.id, [
          ...map.entries,
          DraftMapEntry(
            id: _id(),
            key: _newDraft(key),
            value: _newDraft(value),
          ),
        ]),
      );
    }
    return _invalidPath(path);
  }

  @override
  EditorMutationResult removeMapEntry(DataPath path, DraftNodeId entry) =>
      _changeMap(path, (map, type) {
        if (!map.entries.any((item) => item.id == entry)) return null;
        return MapDraftValue(
          map.id,
          map.entries.where((item) => item.id != entry).toList(),
        );
      });

  @override
  EditorMutationResult updateMapKey(
    DataPath path,
    DraftNodeId entry,
    DataValue value,
  ) => _changeMap(path, (map, type) {
    final diagnostics = value.validateAgainst(type.key, registry: _registry);
    if (diagnostics.isNotEmpty) return null;
    return MapDraftValue(map.id, [
      for (final item in map.entries)
        if (item.id == entry)
          DraftMapEntry(
            id: item.id,
            key: _freshDraft(type.key, value),
            value: item.value,
          )
        else
          item,
    ]);
  });

  @override
  EditorMutationResult updateMapValue(
    DataPath path,
    DraftNodeId entry,
    DataValue value,
  ) => _changeMap(path, (map, type) {
    final diagnostics = value.validateAgainst(type.value, registry: _registry);
    if (diagnostics.isNotEmpty) return null;
    return MapDraftValue(map.id, [
      for (final item in map.entries)
        if (item.id == entry)
          DraftMapEntry(
            id: item.id,
            key: item.key,
            value: _freshDraft(type.value, value),
          )
        else
          item,
    ]);
  });

  @override
  EditorMutationResult selectConcreteType(DataPath path, ResolvedTypeRef type) {
    final located = _locate(_root, rootType, path.segments, 0, _registry);
    if (located case (
      final PolymorphicDraftValue draft,
      final NamedType named,
    )) {
      if (!NamedType(type).isStructurallyAssignableTo(named, _registry)) {
        return EditorMutationResult.invalid([
          TypeDiagnostic(
            code: TypeDiagnosticCode.invalidValue,
            message: "Concrete type does not refine the declared type",
            path: path,
          ),
        ]);
      }
      final resolved = _registry.resolveExact(type).valueOrNull;
      if (resolved == null || !resolved.isConcrete) return _invalidPath(path);
      return _replaceStructure(
        path,
        PolymorphicDraftValue(
          draft.id,
          concreteType: type,
          payload: _newDraft(resolved.representation),
        ),
      );
    }
    return _invalidPath(path);
  }

  @override
  EditorValue concretePayloadValue(DataPath path, DataPath payloadPath) {
    final located = _locate(_root, rootType, path.segments, 0, _registry);
    if (located case (final PolymorphicDraftValue draft, NamedType())) {
      final concrete = draft.concreteType;
      final payload = draft.payload;
      if (concrete == null || payload == null) {
        return const EditorValue.missing();
      }
      final type = _registry.resolveExact(concrete).valueOrNull?.representation;
      if (type == null) return const EditorValue.missing();
      final child = _locate(payload, type, payloadPath.segments, 0, _registry);
      if (child == null) return const EditorValue.missing();
      return _editorValue(
        child.$1,
        child.$2,
        path.followedBy(payloadPath),
        _registry,
      );
    }
    return const EditorValue.missing();
  }

  @override
  EditorMutationResult updateConcretePayloadAt(
    DataPath path,
    DataPath payloadPath,
    DataValue value,
  ) {
    final located = _locate(_root, rootType, path.segments, 0, _registry);
    if (located case (final PolymorphicDraftValue draft, NamedType())) {
      final concrete = draft.concreteType;
      final payload = draft.payload;
      if (concrete == null || payload == null) return _invalidPath(path);
      final type = _registry.resolveExact(concrete).valueOrNull?.representation;
      if (type == null) return _invalidPath(path);
      final child = _locate(payload, type, payloadPath.segments, 0, _registry);
      if (child == null) return _invalidPath(path.followedBy(payloadPath));
      final diagnostics = value.validateAgainst(child.$2, registry: _registry);
      if (diagnostics.isNotEmpty) {
        return EditorMutationResult.invalid(diagnostics);
      }
      final next = _replace(
        payload,
        type,
        payloadPath.segments,
        0,
        _freshDraft(child.$2, value),
        _registry,
      );
      if (next == null) return _invalidPath(path.followedBy(payloadPath));
      return _replaceStructure(
        path,
        PolymorphicDraftValue(draft.id, concreteType: concrete, payload: next),
      );
    }
    return _invalidPath(path);
  }

  @override
  EditorMutationResult updateConcretePayload(DataPath path, DataValue value) {
    final located = _locate(_root, rootType, path.segments, 0, _registry);
    if (located case (final PolymorphicDraftValue draft, NamedType())) {
      final concrete = draft.concreteType;
      if (concrete == null) return _invalidPath(path);
      final type = _registry.resolveExact(concrete).valueOrNull?.representation;
      if (type == null) return _invalidPath(path);
      final diagnostics = value.validateAgainst(type, registry: _registry);
      if (diagnostics.isNotEmpty) {
        return EditorMutationResult.invalid(diagnostics);
      }
      return _replaceStructure(
        path,
        PolymorphicDraftValue(
          draft.id,
          concreteType: concrete,
          payload: _freshDraft(type, value),
        ),
      );
    }
    return _invalidPath(path);
  }

  TypeResult<DataValue> finalize() =>
      _finalize(_root, rootType, DataPath.root, _registry);

  @override
  void dispose() {
    _disposed = true;
    for (final interaction in _interactions) {
      interaction.active = false;
    }
    _interactions.clear();
    super.dispose();
  }

  EditorMutationResult _changeList(
    DataPath path,
    ListDraftValue? Function(ListDraftValue, ListType) change,
  ) {
    final located = _locate(_root, rootType, path.segments, 0, _registry);
    if (located case (final ListDraftValue list, final ListType type)) {
      final next = change(list, type);
      return next == null ? _invalidPath(path) : _replaceStructure(path, next);
    }
    return _invalidPath(path);
  }

  EditorMutationResult _changeMap(
    DataPath path,
    MapDraftValue? Function(MapDraftValue, MapType) change,
  ) {
    final located = _locate(_root, rootType, path.segments, 0, _registry);
    if (located case (final MapDraftValue map, final MapType type)) {
      final next = change(map, type);
      return next == null ? _invalidPath(path) : _replaceStructure(path, next);
    }
    return _invalidPath(path);
  }

  EditorMutationResult _replaceStructure(
    DataPath path,
    DraftValue replacement,
  ) {
    final next = _replace(
      _root,
      rootType,
      path.segments,
      0,
      replacement,
      _registry,
    );
    if (next == null) return _invalidPath(path);
    _root = next;
    notifyListeners();
    return const EditorMutationResult.applied(UnitValue());
  }

  DraftNodeId _id() => DraftNodeId(_nextId++);

  DraftValue _newDraft(TypeExpression type) =>
      _reidentify(planCreationDraft(type: type, registry: _registry));

  DraftValue _freshDraft(TypeExpression type, DataValue value) => _reidentify(
    draftFromValue(type: type, value: value, registry: _registry),
  );

  DraftValue _cloneFresh(DraftValue value) => _reidentify(value);

  void _restore(DraftValue value) {
    _root = value;
    notifyListeners();
  }

  DraftValue _reidentify(DraftValue value) => switch (value) {
    MissingDraftValue() => MissingDraftValue(_id()),
    ScalarDraftValue(:final value) => ScalarDraftValue(_id(), value),
    RecordDraftValue(:final fields) => RecordDraftValue(_id(), {
      for (final entry in fields.entries) entry.key: _reidentify(entry.value),
    }),
    ListDraftValue(:final items) => ListDraftValue(_id(), [
      for (final item in items) _reidentify(item),
    ]),
    MapDraftValue(:final entries) => MapDraftValue(_id(), [
      for (final entry in entries)
        DraftMapEntry(
          id: _id(),
          key: _reidentify(entry.key),
          value: _reidentify(entry.value),
        ),
    ]),
    PolymorphicDraftValue(:final concreteType, :final payload) =>
      PolymorphicDraftValue(
        _id(),
        concreteType: concreteType,
        payload: payload == null ? null : _reidentify(payload),
      ),
  };
}

bool _draftShapeMatches(
  DataValue value,
  TypeExpression type,
  TypeRegistry registry,
) {
  if (type is AnyType) return true;
  if (type case NamedType()) {
    final resolved = registry.resolve(type).valueOrNull;
    if (resolved == null) return false;
    if (resolved.isConcrete) {
      return value is! PolymorphicValue &&
          _draftShapeMatches(value, resolved.representation, registry);
    }
    if (value is! PolymorphicValue) return false;
    final concrete = registry.resolveExact(value.concreteType).valueOrNull;
    return concrete != null &&
        concrete.isConcrete &&
        NamedType(value.concreteType)
            .isStructurallyAssignableTo(type, registry) &&
        _draftShapeMatches(value.value, concrete.representation, registry);
  }
  return switch ((value, type)) {
    (UnitValue(), UnitType()) ||
    (BooleanValue(), BooleanType()) ||
    (StringValue(), StringType()) ||
    (BytesValue(), BytesType()) ||
    (IntegerValue(), IntegerType()) ||
    (FloatValue(), FloatType()) ||
    (DecimalValue(), DecimalType()) ||
    (TimestampValue(), TimestampType()) ||
    (DurationValue(), DurationType()) => true,
    (_, EnumType(:final values)) => values.contains(value),
    (ReferenceValue(), ReferenceType()) =>
      value.validateAgainst(type, registry: registry).isEmpty,
    (ListValue(:final values), ListType(:final element)) => values.every(
      (item) => _draftShapeMatches(item, element, registry),
    ),
    (
      MapValue(entries: final entries),
      MapType(key: final key, value: final itemType),
    ) =>
      entries.every(
        (entry) =>
            _draftShapeMatches(entry.key, key, registry) &&
            _draftShapeMatches(entry.value, itemType, registry),
      ),
    (final RecordValue record, RecordType(:final fields)) =>
      record.fields.entries.every((entry) {
        final field = fields[entry.key];
        return field != null &&
            _draftShapeMatches(entry.value, field.type, registry);
      }),
    _ => false,
  };
}

TypeResult<DataValue> materializeReadyValue(
  TypeExpression type,
  TypeRegistry registry, {
  Map<MaterializationLocation, DataValue> fixedValues = const {},
}) {
  final draft = CreationDraft(
    rootType: type,
    registry: registry,
    fixedValues: fixedValues,
  );
  try {
    return draft.finalize();
  } finally {
    draft.dispose();
  }
}

EditorValue _editorValue(
  DraftValue node,
  TypeExpression type,
  DataPath path,
  TypeRegistry registry,
) {
  if (node is MissingDraftValue) return const EditorValue.missing();
  final value = _projectDraft(node, type, path, registry).valueOrNull;
  return value == null ? const EditorValue.missing() : EditorValue.ready(value);
}

TypeResult<DataValue> _projectDraft(
  DraftValue node,
  TypeExpression type,
  DataPath path,
  TypeRegistry registry,
) {
  if (node is MissingDraftValue) {
    return _draftFailure(path, "A value is required");
  }
  if (type case NamedType()) {
    final resolved = registry.resolve(type).valueOrNull;
    if (resolved == null) {
      return _draftFailure(path, "Named type is unavailable");
    }
    if (resolved.isConcrete) {
      return _projectDraft(node, resolved.representation, path, registry);
    }
    if (node case PolymorphicDraftValue(:final concreteType, :final payload)) {
      if (concreteType == null || payload == null) {
        return _draftFailure(path, "Choose a concrete type");
      }
      final concrete = registry.resolveExact(concreteType).valueOrNull;
      if (concrete == null) {
        return _draftFailure(path, "Concrete type is unavailable");
      }
      final projected = _projectDraft(
        payload,
        concrete.representation,
        path,
        registry,
      );
      final value = projected.valueOrNull;
      return value == null
          ? TypeResult.failure(projected.diagnostics)
          : TypeResult.success(
              PolymorphicValue(concreteType: concreteType, value: value),
            );
    }
    return _draftFailure(path, "Choose a concrete type");
  }
  return switch ((node, type)) {
    (ScalarDraftValue(:final value), _) => TypeResult.success(value),
    (RecordDraftValue(:final fields), RecordType(fields: final types)) =>
      _projectRecord(fields, types, path, registry),
    (ListDraftValue(:final items), ListType(element: final element)) =>
      _projectList(items, element, path, registry),
    (
      MapDraftValue(:final entries),
      MapType(key: final key, value: final value),
    ) =>
      _projectMap(entries, key, value, path, registry),
    _ => _draftFailure(path, "Draft shape does not match its declared type"),
  };
}

TypeResult<DataValue> _projectRecord(
  Map<String, DraftValue> fields,
  Map<String, TypeField> types,
  DataPath path,
  TypeRegistry registry,
) {
  final values = <String, DataValue>{};
  final diagnostics = <TypeDiagnostic>[];
  for (final field in types.values) {
    final node = fields[field.name];
    if (node == null) {
      diagnostics.add(
        TypeDiagnostic(
          code: TypeDiagnosticCode.missingField,
          message: "Required field '${field.name}' is absent",
          path: path.field(field.name),
        ),
      );
      continue;
    }
    final result = _projectDraft(
      node,
      field.type,
      path.field(field.name),
      registry,
    );
    diagnostics.addAll(result.diagnostics);
    if (result.valueOrNull case final value?) values[field.name] = value;
  }
  return diagnostics.isEmpty
      ? TypeResult.success(RecordValue(values))
      : TypeResult.failure(diagnostics);
}

TypeResult<DataValue> _projectList(
  List<DraftValue> items,
  TypeExpression element,
  DataPath path,
  TypeRegistry registry,
) {
  final values = <DataValue>[];
  final diagnostics = <TypeDiagnostic>[];
  for (final indexed in items.indexed) {
    final result = _projectDraft(
      indexed.$2,
      element,
      path.index(indexed.$1),
      registry,
    );
    diagnostics.addAll(result.diagnostics);
    if (result.valueOrNull case final value?) values.add(value);
  }
  return diagnostics.isEmpty
      ? TypeResult.success(ListValue(values))
      : TypeResult.failure(diagnostics);
}

TypeResult<DataValue> _projectMap(
  List<DraftMapEntry> entries,
  TypeExpression keyType,
  TypeExpression valueType,
  DataPath path,
  TypeRegistry registry,
) {
  final values = <DataMapEntry>[];
  final diagnostics = <TypeDiagnostic>[];
  for (final entry in entries) {
    final key = _projectDraft(entry.key, keyType, path, registry);
    final value = _projectDraft(entry.value, valueType, path, registry);
    diagnostics
      ..addAll(key.diagnostics)
      ..addAll(value.diagnostics);
    if ((key.valueOrNull, value.valueOrNull) case (final key?, final value?)) {
      values.add(DataMapEntry(key: key, value: value));
    }
  }
  return diagnostics.isEmpty
      ? TypeResult.success(MapValue(values))
      : TypeResult.failure(diagnostics);
}

TypeResult<DataValue> _finalize(
  DraftValue node,
  TypeExpression type,
  DataPath path,
  TypeRegistry registry,
) {
  if (node is MissingDraftValue) {
    return TypeResult.failure([
      TypeDiagnostic(
        code: TypeDiagnosticCode.missingField,
        message: "A value is required",
        path: path,
      ),
    ]);
  }
  if (type case NamedType()) {
    final resolved = registry.resolve(type).valueOrNull;
    if (resolved == null) {
      return _draftFailure(path, "Named type is unavailable");
    }
    if (resolved.isConcrete) {
      return _finalize(node, resolved.representation, path, registry);
    }
    if (node case PolymorphicDraftValue(:final concreteType, :final payload)) {
      if (concreteType == null || payload == null) {
        return _draftFailure(path, "Choose a concrete type");
      }
      final concrete = registry.resolveExact(concreteType).valueOrNull;
      if (concrete == null) {
        return _draftFailure(path, "Concrete type is unavailable");
      }
      final finalized = _finalize(
        payload,
        concrete.representation,
        path,
        registry,
      );
      final value = finalized.valueOrNull;
      if (value == null) return TypeResult.failure(finalized.diagnostics);
      return TypeResult.success(
        PolymorphicValue(concreteType: concreteType, value: value),
      );
    }
    return _draftFailure(path, "Choose a concrete type");
  }
  final result = switch ((node, type)) {
    (ScalarDraftValue(:final value), _) => TypeResult<DataValue>.success(value),
    (RecordDraftValue(:final fields), RecordType(fields: final types)) =>
      _finalizeRecord(fields, types, path, registry),
    (ListDraftValue(:final items), ListType(element: final element)) =>
      _finalizeList(items, element, path, registry),
    (
      MapDraftValue(:final entries),
      MapType(key: final key, value: final value),
    ) =>
      _finalizeMap(entries, key, value, path, registry),
    _ => _draftFailure(path, "Draft shape does not match its declared type"),
  };
  final value = result.valueOrNull;
  if (value == null) return result;
  final diagnostics = value.validateAgainst(
    type,
    path: path,
    registry: registry,
  );
  return diagnostics.isEmpty ? result : TypeResult.failure(diagnostics);
}

TypeResult<DataValue> _finalizeRecord(
  Map<String, DraftValue> fields,
  Map<String, TypeField> types,
  DataPath path,
  TypeRegistry registry,
) {
  final values = <String, DataValue>{};
  final diagnostics = <TypeDiagnostic>[];
  for (final field in types.values) {
    final node = fields[field.name];
    if (node == null) {
      diagnostics.add(
        TypeDiagnostic(
          code: TypeDiagnosticCode.missingField,
          message: "Required field '${field.name}' is absent",
          path: path.field(field.name),
        ),
      );
      continue;
    }
    final result = _finalize(
      node,
      field.type,
      path.field(field.name),
      registry,
    );
    diagnostics.addAll(result.diagnostics);
    if (result.valueOrNull case final value?) values[field.name] = value;
  }
  return diagnostics.isEmpty
      ? TypeResult.success(RecordValue(values))
      : TypeResult.failure(diagnostics);
}

TypeResult<DataValue> _finalizeList(
  List<DraftValue> items,
  TypeExpression element,
  DataPath path,
  TypeRegistry registry,
) {
  final values = <DataValue>[];
  final diagnostics = <TypeDiagnostic>[];
  for (final indexed in items.indexed) {
    final result = _finalize(
      indexed.$2,
      element,
      path.index(indexed.$1),
      registry,
    );
    diagnostics.addAll(result.diagnostics);
    if (result.valueOrNull case final value?) values.add(value);
  }
  return diagnostics.isEmpty
      ? TypeResult.success(ListValue(values))
      : TypeResult.failure(diagnostics);
}

TypeResult<DataValue> _finalizeMap(
  List<DraftMapEntry> entries,
  TypeExpression keyType,
  TypeExpression valueType,
  DataPath path,
  TypeRegistry registry,
) {
  final values = <DataMapEntry>[];
  final diagnostics = <TypeDiagnostic>[];
  for (final entry in entries) {
    final key = _finalize(entry.key, keyType, path, registry);
    final value = _finalize(entry.value, valueType, path, registry);
    diagnostics
      ..addAll(key.diagnostics)
      ..addAll(value.diagnostics);
    if ((key.valueOrNull, value.valueOrNull) case (final key?, final value?)) {
      values.add(DataMapEntry(key: key, value: value));
    }
  }
  return diagnostics.isEmpty
      ? TypeResult.success(MapValue(values))
      : TypeResult.failure(diagnostics);
}

TypeFailure<DataValue> _draftFailure(DataPath path, String message) =>
    TypeFailure([
      TypeDiagnostic(
        code: TypeDiagnosticCode.invalidValue,
        message: message,
        path: path,
      ),
    ]);

(DraftValue, TypeExpression)? _locate(
  DraftValue node,
  TypeExpression type,
  List<DataPathSegment> segments,
  int offset,
  TypeRegistry registry,
) {
  if (offset == segments.length) return (node, type);
  if (type case NamedType()) {
    final resolved = registry.resolve(type).valueOrNull;
    if (resolved == null) return null;
    if (resolved.isConcrete) {
      return _locate(node, resolved.representation, segments, offset, registry);
    }
    if (node case PolymorphicDraftValue(:final concreteType, :final payload)) {
      if (concreteType == null || payload == null) return null;
      final concrete = registry.resolveExact(concreteType).valueOrNull;
      if (concrete == null) return null;
      return _locate(
        payload,
        concrete.representation,
        segments,
        offset,
        registry,
      );
    }
    return null;
  }
  return switch ((node, type, segments[offset])) {
    (
      RecordDraftValue(:final fields),
      RecordType(fields: final types),
      FieldPathSegment(:final name),
    )
        when fields[name] != null && types[name] != null =>
      _locate(fields[name]!, types[name]!.type, segments, offset + 1, registry),
    (
      ListDraftValue(:final items),
      ListType(:final element),
      IndexPathSegment(:final index),
    )
        when index < items.length =>
      _locate(items[index], element, segments, offset + 1, registry),
    (
      MapDraftValue(:final entries),
      MapType(value: final valueType),
      MapKeyPathSegment(:final key),
    ) =>
      _locateMap(entries, key, valueType, segments, offset + 1, registry),
    _ => null,
  };
}

(DraftValue, TypeExpression)? _locateMap(
  List<DraftMapEntry> entries,
  DataValue key,
  TypeExpression valueType,
  List<DataPathSegment> segments,
  int offset,
  TypeRegistry registry,
) {
  for (final entry in entries) {
    if (_finalize(
          entry.key,
          const AnyType(),
          DataPath.root,
          registry,
        ).valueOrNull ==
        key) {
      return _locate(entry.value, valueType, segments, offset, registry);
    }
  }
  return null;
}

DraftValue? _replace(
  DraftValue node,
  TypeExpression type,
  List<DataPathSegment> segments,
  int offset,
  DraftValue replacement,
  TypeRegistry registry,
) {
  if (offset == segments.length) return replacement;
  if (type case NamedType()) {
    final resolved = registry.resolve(type).valueOrNull;
    if (resolved == null) return null;
    if (resolved.isConcrete) {
      return _replace(
        node,
        resolved.representation,
        segments,
        offset,
        replacement,
        registry,
      );
    }
    if (node case PolymorphicDraftValue(:final concreteType, :final payload)) {
      if (concreteType == null || payload == null) return null;
      final concrete = registry.resolveExact(concreteType).valueOrNull;
      if (concrete == null) return null;
      final next = _replace(
        payload,
        concrete.representation,
        segments,
        offset,
        replacement,
        registry,
      );
      return next == null
          ? null
          : PolymorphicDraftValue(
              node.id,
              concreteType: concreteType,
              payload: next,
            );
    }
    return null;
  }
  final segment = segments[offset];
  if ((node, type, segment) case (
    RecordDraftValue(:final fields),
    RecordType(fields: final types),
    FieldPathSegment(:final name),
  )) {
    final child = fields[name];
    final fieldType = types[name]?.type;
    if (child == null || fieldType == null) return null;
    final next = _replace(
      child,
      fieldType,
      segments,
      offset + 1,
      replacement,
      registry,
    );
    return next == null
        ? null
        : RecordDraftValue(node.id, {...fields, name: next});
  }
  if ((node, type, segment) case (
    ListDraftValue(:final items),
    ListType(:final element),
    IndexPathSegment(:final index),
  )) {
    if (index >= items.length) return null;
    final next = _replace(
      items[index],
      element,
      segments,
      offset + 1,
      replacement,
      registry,
    );
    if (next == null) return null;
    return ListDraftValue(node.id, [...items]..[index] = next);
  }
  if ((node, type, segment) case (
    MapDraftValue(:final entries),
    MapType(value: final valueType),
    MapKeyPathSegment(:final key),
  )) {
    for (var index = 0; index < entries.length; index++) {
      final entry = entries[index];
      if (_finalize(
            entry.key,
            const AnyType(),
            DataPath.root,
            registry,
          ).valueOrNull !=
          key) {
        continue;
      }
      final next = _replace(
        entry.value,
        valueType,
        segments,
        offset + 1,
        replacement,
        registry,
      );
      if (next == null) return null;
      final changed = [...entries]
        ..[index] = DraftMapEntry(id: entry.id, key: entry.key, value: next);
      return MapDraftValue(node.id, changed);
    }
  }
  return null;
}

int _maximumId(DraftValue value) => switch (value) {
  MissingDraftValue() || ScalarDraftValue() => value.id.value,
  RecordDraftValue(:final fields) => fields.values.fold(
    value.id.value,
    (maximum, child) =>
        _maximumId(child) > maximum ? _maximumId(child) : maximum,
  ),
  ListDraftValue(:final items) => items.fold(
    value.id.value,
    (maximum, child) =>
        _maximumId(child) > maximum ? _maximumId(child) : maximum,
  ),
  MapDraftValue(:final entries) => entries.fold(
    value.id.value,
    (maximum, entry) => [
      entry.id.value,
      _maximumId(entry.key),
      _maximumId(entry.value),
      maximum,
    ].reduce((a, b) => a > b ? a : b),
  ),
  PolymorphicDraftValue(:final payload) =>
    payload == null
        ? value.id.value
        : (_maximumId(payload) > value.id.value
              ? _maximumId(payload)
              : value.id.value),
};

EditorMutationResult _invalidPath(DataPath path) =>
    EditorMutationResult.invalid([
      TypeDiagnostic(
        code: TypeDiagnosticCode.invalidPath,
        message: "Draft path is unavailable",
        path: path,
      ),
    ]);

final class _CreationDraftInteraction implements EditorInteractionSession {
  _CreationDraftInteraction(this.owner, this.path, this.origin);

  final CreationDraft owner;
  @override
  final DataPath path;
  final DraftValue origin;
  @override
  bool active = true;

  @override
  Future<void> commit() async => _close();

  @override
  void cancel() {
    if (!active) return;
    _close();
    owner._restore(origin);
  }

  void _close() {
    active = false;
    owner._interactions.remove(this);
  }
}
