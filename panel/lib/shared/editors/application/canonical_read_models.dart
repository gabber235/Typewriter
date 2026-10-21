part of "portable_expression.dart";

/// The framework read model roots. Every expression read schema derives from
/// these Skir types and the types they reach; Kotlin lists the same roots in
/// `CanonicalReadModels.kt`. Read schemas are read only and never appear in
/// type choices.
final canonicalReadModels = CanonicalReadModels([
  skir.TypeUse.serializer.typeDescriptor,
  skir.TypeSelection.serializer.typeDescriptor,
  skir.PublishedType.serializer.typeDescriptor,
  skir.ResourceAppearance.serializer.typeDescriptor,
]);

/// The namespace of every read model identity. Authored declarations cannot
/// use it.
const canonicalReadNamespace = "skir";

const _valueField = "value";
const _maxReadDepth = 512;

/// The finite expression read schema reachable from its roots, derived from
/// Skir reflection by the rule Kotlin's `CanonicalReadModel.kt` applies, and
/// pinned for both by `skir-src/editor/v1/fixtures/canonical_read_models.json`:
///
/// - A Skir struct is a record. Its fields are the Skir fields in field number
///   order, keyed by their Skir names.
/// - A Skir enum whose variants are all constants is an enumeration whose cases
///   are the variant names.
/// - Any other Skir enum is an abstract record without fields. Each variant is
///   a concrete record with the enum as its parent; a wrapper variant has one
///   field, `value`, holding the wrapped value, and a constant variant has
///   none.
/// - A record is identified by the qualified type id
///   ([canonicalReadNamespace], record id) at revision 1, where the record id
///   is Skir's own `<module path>:<qualified name>`, for example
///   `editor/v1/type_catalog.skir:TypeUse`. A variant appends
///   `.<variant name>`, for example `editor/v1/type_catalog.skir:TypeUse.named`.
/// - bool is a boolean, int32 and int64 are signed integers of that width,
///   hash64 is an unsigned 64 bit integer, float32 and float64 are floats of
///   that width, string is text, and bytes and timestamp keep their kind. An
///   optional is nullable and an array is the framework List.
/// - The kernel Color and Icon are the declared Color and Icon types, so a
///   read color equals an authored one.
///
/// Projection charges the invoking expression's budgets. Decoders read a read
/// value back into the Skir value its descriptor describes.
final class CanonicalReadModels {
  CanonicalReadModels(Iterable<skir.ReflectiveTypeDescriptor<dynamic>> roots) {
    for (final root in roots) {
      _declare(root);
    }
    definitions = List.unmodifiable(
      [for (final record in _records.values) ...record.definitions]
        ..sort((a, b) => _readIdName(a.id).compareTo(_readIdName(b.id))),
    );
    for (final definition in [...definitions, ...frameworkDefinitions]) {
      final fields = switch (definition.representation) {
        skir.RepresentationTemplate_recordWrapper(:final value) => value.fields,
        _ => const <skir.FieldDeclaration>[],
      };
      _published[definition.id] = skir.PublishedType(
        placementField: null,
        definition: definition,
        status: skir.DeclarationStatus.ready,
        effectiveFields: [
          for (final field in fields)
            skir.EffectiveFieldTemplate(
              key: field.owner.name,
              owner: field.owner,
              type: field.type,
              rules: const [],
            ),
        ],
        ancestorTemplates: definition.parents,
        display: defaultTypeDisplay(
          _frameworkReadNames[definition.id] ??
              _readIdName(definition.id).split(":").last,
        ),
        searchKey: null,
      );
    }
  }

  /// The derived definitions, ordered by identity. [frameworkDefinitions]
  /// holds the framework ones they reference.
  late final List<skir.TypeDefinition> definitions;

  /// The framework definitions the read definitions reference: the List and
  /// the declared Color and Icon types, published here so read schemas resolve
  /// in any catalog. Kotlin publishes the same definitions with its read
  /// models.
  List<skir.TypeDefinition> get frameworkDefinitions =>
      _frameworkReadDefinitions;
  final _records = <String, _ReadRecord>{};
  final _published = <skir.TypeDefinitionId, skir.PublishedType>{};

  skir.PublishedType? published(skir.TypeDefinitionId id) => _published[id];

  skir.TypeUse get typeUseUse =>
      skir.TypeUse.wrapNamed(useOf(skir.TypeUse.serializer.typeDescriptor));

  skir.TypeUse get typeSelectionUse => skir.TypeUse.wrapNamed(
    useOf(skir.TypeSelection.serializer.typeDescriptor),
  );

  skir.TypeUse get publishedTypeUse => skir.TypeUse.wrapNamed(
    useOf(skir.PublishedType.serializer.typeDescriptor),
  );

  /// The evaluated display of a resource: its label, accent and icon.
  skir.NamedTypeUse get resourceAppearanceUse =>
      useOf(skir.ResourceAppearance.serializer.typeDescriptor);

  /// The read type of the Skir record [descriptor] describes.
  skir.NamedTypeUse useOf(skir.ReflectiveTypeDescriptor<dynamic> descriptor) =>
      skir.NamedTypeUse(definition: _declare(descriptor), arguments: const []);

  /// Projects [value], described by [descriptor], to its read value, or to the
  /// read value at the field [path] below it. Reading a field of a null value
  /// is unfilled. Every visited value charges [consumeStep]; a list charges its
  /// items and a whole record its fields to [consumeItems].
  skir.DataValue project(
    Object? value,
    skir.ReflectiveTypeDescriptor<dynamic> descriptor,
    List<String> path,
    void Function() consumeStep,
    void Function(int) consumeItems,
  ) => _project(value, descriptor, path, consumeStep, consumeItems, 0);

  /// Reads [value] back as the Skir value [serializer] describes; rejects a
  /// value of any other read type.
  T decode<T>(skir.DataValue value, skir.Serializer<T> serializer) =>
      serializer.fromJson(_json(value, serializer.typeDescriptor, 0));

  skir.TypeSelection decodeTypeSelection(skir.DataValue value) =>
      decode(value, skir.TypeSelection.serializer);

  skir.TypeUse decodeTypeUse(skir.DataValue value) =>
      decode(value, skir.TypeUse.serializer);

  skir.TypeDefinitionId _declare(
    skir.ReflectiveTypeDescriptor<dynamic> descriptor,
  ) {
    if (descriptor is! skir.ReflectiveRecordDescriptor) {
      throw ArgumentError("A read model root must be a Skir struct or enum");
    }
    final name = _readRecordId(descriptor);
    final declared = _declaredReads[name];
    if (declared != null) return declared.use.definition;
    final known = _records[name];
    if (known != null) return known.id;
    final id = _readId(name);
    switch (descriptor) {
      case skir.ReflectiveStructDescriptor():
        final record = _StructRecord(id);
        _records[name] = record;
        record.fields = [
          for (final field in _readFields(descriptor))
            (field.name, _template(field.type)),
        ];
      case skir.ReflectiveEnumDescriptor():
        final variants = _readVariants(descriptor);
        if (variants.every(
          (variant) => variant is skir.ReflectiveEnumConstantVariant,
        )) {
          _records[name] = _EnumerationRecord(id, [
            for (final variant in variants) variant.name,
          ]);
        } else {
          final record = _UnionRecord(id);
          _records[name] = record;
          record.variants = [
            for (final variant in variants)
              _ReadVariant(
                _readId("$name.${variant.name}"),
                variant.name,
                variant is skir.ReflectiveEnumWrapperVariant
                    ? _template(variant.type)
                    : null,
              ),
          ];
        }
    }
    return id;
  }

  skir.TypeTemplate _template(
    skir.ReflectiveTypeDescriptor<dynamic> descriptor,
  ) => switch (descriptor) {
    skir.ReflectiveOptionalDescriptor(:final otherType) =>
      skir.TypeTemplate.createNullable(value: _template(otherType)),
    skir.ReflectiveArrayDescriptor(:final itemType) =>
      skir.TypeTemplate.createNamed(
        definition: _readListId,
        arguments: [_template(itemType)],
      ),
    skir.PrimitiveDescriptor(:final primitiveType) =>
      skir.TypeTemplate.wrapScalar(_readScalar(primitiveType)),
    _ => skir.TypeTemplate.createNamed(
      definition: _declare(descriptor),
      arguments: const [],
    ),
  };

  skir.DataValue _project(
    Object? value,
    skir.ReflectiveTypeDescriptor<dynamic> descriptor,
    List<String> path,
    void Function() step,
    void Function(int) items,
    int depth,
  ) {
    if (depth > _maxReadDepth) {
      throw const FormatException(
        "Canonical projection exceeded its depth limit",
      );
    }
    step();
    if (value == null) {
      return path.isEmpty ? skir.DataValue.null_ : skir.DataValue.unfilled;
    }
    switch (descriptor) {
      case skir.ReflectiveOptionalDescriptor(:final otherType):
        return _project(value, otherType, path, step, items, depth + 1);
      case skir.PrimitiveDescriptor(:final primitiveType):
        if (path.isNotEmpty) {
          throw const FormatException("A canonical scalar has no fields");
        }
        return _readPrimitive(value, primitiveType);
      case skir.ReflectiveArrayDescriptor(:final itemType):
        if (path.isNotEmpty) {
          throw const FormatException(
            "A canonical collection needs an item binding before field access",
          );
        }
        final values = (value as Iterable<Object?>).toList(growable: false);
        items(values.length);
        return skir.DataValue.createListValue(
          items: [
            for (final (index, item) in values.indexed)
              skir.ListItem(
                id: skir.ItemId(value: "canonical:$index"),
                value: _project(
                  item,
                  itemType,
                  const [],
                  step,
                  items,
                  depth + 1,
                ),
              ),
          ],
        );
      case skir.ReflectiveRecordDescriptor():
        return _record(value, descriptor, path, step, items, depth);
    }
  }

  skir.DataValue _record(
    Object value,
    skir.ReflectiveRecordDescriptor<dynamic> descriptor,
    List<String> path,
    void Function() step,
    void Function(int) items,
    int depth,
  ) {
    final name = _readRecordId(descriptor);
    final declared = _declaredReads[name];
    if (declared != null) return _readSelect(declared.encode(value), path);
    final record = _records[name]!;
    skir.DataValue named(
      skir.TypeDefinitionId id,
      Map<String, skir.DataValue Function(List<String>)> fields,
    ) {
      if (path.isNotEmpty) {
        final field = fields[path.first];
        if (field == null) {
          throw FormatException("The canonical field ${path.first} is absent");
        }
        return field(path.sublist(1));
      }
      items(fields.length);
      return skir.DataValue.createNamed(
        actualType: skir.NamedTypeUse(definition: id, arguments: const []),
        payload: skir.DataValue.createRecord(
          fields: [
            for (final MapEntry(key: name, value: read) in fields.entries)
              skir.FieldValue(name: name, value: read(const [])),
          ],
        ),
      );
    }

    switch (record) {
      case _StructRecord():
        final struct =
            descriptor as skir.ReflectiveStructDescriptor<dynamic, dynamic>;
        return named(record.id, {
          for (final field in _readFields(struct))
            field.name: (remaining) => _project(
              field.get(value),
              field.type,
              remaining,
              step,
              items,
              depth + 1,
            ),
        });
      case _EnumerationRecord():
        if (path.isNotEmpty) {
          throw const FormatException("A canonical enum has no fields");
        }
        final variant = _readVariantOf(descriptor, value);
        return skir.DataValue.createNamed(
          actualType: skir.NamedTypeUse(
            definition: record.id,
            arguments: const [],
          ),
          payload: skir.DataValue.wrapEnumCase(variant.name),
        );
      case _UnionRecord():
        final variant = _readVariantOf(descriptor, value);
        final read = record.variants.firstWhere(
          (candidate) => candidate.name == variant.name,
        );
        return named(read.id, {
          if (variant is skir.ReflectiveEnumWrapperVariant)
            _valueField: (remaining) {
              return _project(
                variant.get(value),
                variant.type,
                remaining,
                step,
                items,
                depth + 1,
              );
            },
        });
    }
  }

  dynamic _json(
    skir.DataValue value,
    skir.ReflectiveTypeDescriptor<dynamic> descriptor,
    int depth,
  ) {
    if (depth > _maxReadDepth) {
      throw const FormatException("Canonical value exceeded its depth limit");
    }
    switch (descriptor) {
      case skir.ReflectiveOptionalDescriptor(:final otherType):
        return value == skir.DataValue.null_
            ? null
            : _json(value, otherType, depth + 1);
      case skir.PrimitiveDescriptor(:final primitiveType):
        return _readPrimitiveJson(value, primitiveType);
      case skir.ReflectiveArrayDescriptor(:final itemType):
        final items = switch (value) {
          skir.DataValue_listValueWrapper(:final value) => value.items,
          skir.DataValue_setValueWrapper(:final value) => value.items,
          _ => throw const FormatException("Expected a canonical list"),
        };
        return [
          for (final item in items) _json(item.value, itemType, depth + 1),
        ];
      case skir.ReflectiveRecordDescriptor():
        return _recordJson(value, descriptor, depth);
    }
  }

  dynamic _recordJson(
    skir.DataValue value,
    skir.ReflectiveRecordDescriptor<dynamic> descriptor,
    int depth,
  ) {
    if (value is! skir.DataValue_namedWrapper) {
      throw const FormatException("Expected a canonical named value");
    }
    final named = value.value;
    if (named.actualType.arguments.isNotEmpty) {
      throw const FormatException("Canonical read types take no arguments");
    }
    final actual = named.actualType.definition;
    final name = _readRecordId(descriptor);
    final declared = _declaredReads[name];
    if (declared != null) return declared.json(actual, named.payload);
    final record = _records[name]!;
    switch (record) {
      case _StructRecord():
        _expectReadType(actual, record.id);
        final fields = _readRecordFields(named.payload);
        return {
          for (final field in _readFields(
            descriptor as skir.ReflectiveStructDescriptor<dynamic, dynamic>,
          ))
            field.name: _json(
              _readField(fields, field.name),
              field.type,
              depth + 1,
            ),
        };
      case _EnumerationRecord():
        _expectReadType(actual, record.id);
        final payload = named.payload;
        if (payload is! skir.DataValue_enumCaseWrapper ||
            !record.cases.contains(payload.value)) {
          throw const FormatException("Unknown canonical enum case");
        }
        return payload.value;
      case _UnionRecord():
        final read = record.variants
            .where((variant) => variant.id == actual)
            .firstOrNull;
        if (read == null) {
          throw FormatException(
            "Expected a variant of ${_readIdName(record.id)}",
          );
        }
        final variant = _readVariants(
          descriptor as skir.ReflectiveEnumDescriptor<dynamic>,
        ).firstWhere((candidate) => candidate.name == read.name);
        if (variant is skir.ReflectiveEnumWrapperVariant) {
          return {
            "kind": read.name,
            "value": _json(
              _readField(_readRecordFields(named.payload), _valueField),
              variant.type,
              depth + 1,
            ),
          };
        }
        return read.name;
    }
  }
}

sealed class _ReadRecord {
  _ReadRecord(this.id);
  final skir.TypeDefinitionId id;
  List<skir.TypeDefinition> get definitions;
}

final class _StructRecord extends _ReadRecord {
  _StructRecord(super.id);
  late final List<(String, skir.TypeTemplate)> fields;

  @override
  List<skir.TypeDefinition> get definitions => [
    _readRecordDefinition(id, fields, parent: null, abstract: false),
  ];
}

final class _EnumerationRecord extends _ReadRecord {
  _EnumerationRecord(super.id, this.cases);
  final List<String> cases;

  @override
  List<skir.TypeDefinition> get definitions => [
    skir.TypeDefinition(
      id: id,
      parameters: const [],
      representation: skir.RepresentationTemplate.createEnumeration(
        cases: [for (final key in cases) skir.EnumVariant(key: key)],
      ),
      parents: const [],
    ),
  ];
}

final class _UnionRecord extends _ReadRecord {
  _UnionRecord(super.id);
  late final List<_ReadVariant> variants;

  @override
  List<skir.TypeDefinition> get definitions => [
    _readRecordDefinition(id, const [], parent: null, abstract: true),
    for (final variant in variants)
      _readRecordDefinition(
        variant.id,
        [if (variant.value case final value?) (_valueField, value)],
        parent: id,
        abstract: false,
      ),
  ];
}

final class _ReadVariant {
  const _ReadVariant(this.id, this.name, this.value);
  final skir.TypeDefinitionId id;
  final String name;
  final skir.TypeTemplate? value;
}

/// A Skir record that is the wire form of a framework declared type rather
/// than a read model of its own.
final class _DeclaredRead {
  const _DeclaredRead(this.use, this.encode, this.json);
  final skir.NamedTypeUse use;
  final skir.DataValue Function(Object value) encode;
  final dynamic Function(skir.TypeDefinitionId actual, skir.DataValue payload)
  json;
}

final _declaredReads = <String, _DeclaredRead>{
  "kernel/v1/color.skir:Color": _DeclaredRead(
    expressionColorUse,
    (value) => colorValue((value as skir.Color).argb.toUnsigned(32)),
    (actual, payload) {
      _expectReadType(actual, expressionColorUse.definition);
      if (payload is! skir.DataValue_integerWrapper) {
        throw const FormatException("Expected an ARGB color");
      }
      return {"argb": int.parse(payload.value).toSigned(32)};
    },
  ),
  "kernel/v1/icon.skir:Icon": _DeclaredRead(
    expressionIconUse,
    (value) => iconValue(value as skir.Icon),
    (actual, payload) {
      final icon = decodeIconValue(
        skir.DataValue.createNamed(
          actualType: skir.NamedTypeUse(
            definition: actual,
            arguments: const [],
          ),
          payload: payload,
        ),
      );
      return switch (icon) {
        skir.Icon_iconifyWrapper(:final value) => {
          "kind": "iconify",
          "value": value,
        },
        skir.Icon_svgWrapper(:final value) => {"kind": "svg", "value": value},
        _ => throw const FormatException("Expected a canonical icon"),
      };
    },
  ),
};

final _frameworkReadNames = {
  _readListId: "List",
  expressionColorUse.definition: "Color",
  expressionIconUse.definition: "Icon",
  _iconifyUse.definition: "Iconify",
  _svgIconUse.definition: "SVG",
};

/// The framework List and the declared Color and Icon definitions, ordered by
/// identity as Kotlin's `StandardTypes` and generated declarations define them.
final _frameworkReadDefinitions = List<skir.TypeDefinition>.unmodifiable(
  [
    skir.TypeDefinition(
      id: _readListId,
      parameters: [
        skir.TypeParameter(
          key: skir.ParameterKey(owner: _readListId, index: 0),
          name: "T",
          bounds: const [],
        ),
      ],
      representation: skir.RepresentationTemplate.createSequence(
        item: skir.TypeTemplate.wrapParameter(
          skir.ParameterKey(owner: _readListId, index: 0),
        ),
        kind: skir.CollectionKind.list,
      ),
      parents: const [],
    ),
    skir.TypeDefinition(
      id: expressionColorUse.definition,
      parameters: const [],
      representation: skir.RepresentationTemplate.createScalar(
        kind: skir.ScalarKind.createInteger(
          width: skir.IntegerWidth.unsignedThirtyTwo,
        ),
      ),
      parents: const [],
    ),
    _readRecordDefinition(
      expressionIconUse.definition,
      const [],
      parent: null,
      abstract: true,
    ),
    _readRecordDefinition(
      _iconifyUse.definition,
      [("value", skir.TypeTemplate.wrapScalar(skir.ScalarKind.text))],
      parent: expressionIconUse.definition,
      abstract: false,
    ),
    _readRecordDefinition(
      _svgIconUse.definition,
      [("source", skir.TypeTemplate.wrapScalar(skir.ScalarKind.text))],
      parent: expressionIconUse.definition,
      abstract: false,
    ),
  ]..sort((a, b) => _readIdName(a.id).compareTo(_readIdName(b.id))),
);

final _readListId = skir.TypeDefinitionId(
  typeId: skir.TypeId.createQualified(namespace: "typewriter", name: "List"),
  revision: 1,
);

skir.TypeDefinitionId _readId(String record) => skir.TypeDefinitionId(
  typeId: skir.TypeId.createQualified(
    namespace: canonicalReadNamespace,
    name: record,
  ),
  revision: 1,
);

String _readRecordId(skir.ReflectiveRecordDescriptor<dynamic> descriptor) =>
    "${descriptor.modulePath}:${descriptor.qualifiedName}";

String _readIdName(skir.TypeDefinitionId id) => switch (id.typeId) {
  skir.TypeId_qualifiedWrapper(:final value) => value.name,
  skir.TypeId_declaredWrapper(:final value) => value.value,
  _ => "",
};

void _expectReadType(
  skir.TypeDefinitionId actual,
  skir.TypeDefinitionId expected,
) {
  if (actual != expected) {
    throw FormatException(
      "Expected the canonical type ${_readIdName(expected)}",
    );
  }
}

skir.TypeDefinition _readRecordDefinition(
  skir.TypeDefinitionId id,
  List<(String, skir.TypeTemplate)> fields, {
  required skir.TypeDefinitionId? parent,
  required bool abstract,
}) => skir.TypeDefinition(
  id: id,
  parameters: const [],
  representation: skir.RepresentationTemplate.createRecord(
    fields: [
      for (final (name, type) in fields)
        skir.FieldDeclaration(
          owner: skir.FieldOwner(definition: id, name: name),
          type: type,
          overrides: const [],
          hasConstructorDefault: false,
        ),
    ],
    abstract_: abstract,
  ),
  parents: [
    if (parent != null)
      skir.NamedTypeTemplate(definition: parent, arguments: const []),
  ],
);

List<skir.ReflectiveStructField<dynamic, dynamic, dynamic>> _readFields(
  skir.ReflectiveStructDescriptor<dynamic, dynamic> descriptor,
) => descriptor.fields.toList()..sort((a, b) => a.number.compareTo(b.number));

List<skir.ReflectiveEnumVariant<dynamic>> _readVariants(
  skir.ReflectiveEnumDescriptor<dynamic> descriptor,
) =>
    descriptor.variants.where((variant) => variant.number != 0).toList()
      ..sort((a, b) => a.number.compareTo(b.number));

skir.ReflectiveEnumVariant<dynamic> _readVariantOf(
  skir.ReflectiveRecordDescriptor<dynamic> descriptor,
  Object value,
) {
  final variant = (descriptor as skir.ReflectiveEnumDescriptor<dynamic>)
      .getVariant(value);
  if (variant.number == 0) {
    throw const FormatException("Unknown canonical enum variant");
  }
  return variant;
}

skir.ScalarKind _readScalar(skir.PrimitiveType type) => switch (type) {
  skir.PrimitiveType.bool => skir.ScalarKind.boolean,
  skir.PrimitiveType.int32 => skir.ScalarKind.createInteger(
    width: skir.IntegerWidth.signedThirtyTwo,
  ),
  skir.PrimitiveType.int64 => skir.ScalarKind.createInteger(
    width: skir.IntegerWidth.signedSixtyFour,
  ),
  skir.PrimitiveType.hash64 => skir.ScalarKind.createInteger(
    width: skir.IntegerWidth.unsignedSixtyFour,
  ),
  skir.PrimitiveType.float32 => skir.ScalarKind.createFloat(
    width: skir.FloatWidth.thirtyTwo,
  ),
  skir.PrimitiveType.float64 => skir.ScalarKind.createFloat(
    width: skir.FloatWidth.sixtyFour,
  ),
  skir.PrimitiveType.timestamp => skir.ScalarKind.timestamp,
  skir.PrimitiveType.string => skir.ScalarKind.text,
  skir.PrimitiveType.bytes => skir.ScalarKind.bytes,
};

skir.DataValue _readPrimitive(Object value, skir.PrimitiveType type) =>
    switch (type) {
      skir.PrimitiveType.bool => skir.DataValue.wrapBoolean(value as bool),
      skir.PrimitiveType.int32 ||
      skir.PrimitiveType.int64 ||
      skir.PrimitiveType.hash64 => skir.DataValue.wrapInteger(value.toString()),
      skir.PrimitiveType.float32 || skir.PrimitiveType.float64 =>
        skir.DataValue.wrapFloat((value as num).toDouble()),
      skir.PrimitiveType.timestamp => skir.DataValue.wrapTimestamp(
        value as DateTime,
      ),
      skir.PrimitiveType.string => skir.DataValue.wrapStringValue(
        value as String,
      ),
      skir.PrimitiveType.bytes => skir.DataValue.wrapBytes(
        value as skir.ByteString,
      ),
    };

dynamic _readPrimitiveJson(skir.DataValue value, skir.PrimitiveType type) =>
    switch ((type, value)) {
      (skir.PrimitiveType.bool, skir.DataValue_booleanWrapper(:final value)) =>
        value,
      (
        skir.PrimitiveType.int32 ||
            skir.PrimitiveType.int64 ||
            skir.PrimitiveType.hash64,
        skir.DataValue_integerWrapper(:final value),
      ) =>
        value,
      (
        skir.PrimitiveType.float32 || skir.PrimitiveType.float64,
        skir.DataValue_floatWrapper(:final value),
      ) =>
        value,
      (
        skir.PrimitiveType.timestamp,
        skir.DataValue_timestampWrapper(:final value),
      ) =>
        value.millisecondsSinceEpoch,
      (
        skir.PrimitiveType.string,
        skir.DataValue_stringValueWrapper(:final value),
      ) =>
        value,
      (skir.PrimitiveType.bytes, skir.DataValue_bytesWrapper(:final value)) =>
        value.toBase64(),
      _ => throw FormatException(
        "The canonical value does not match its ${type.name} field",
      ),
    };

Map<String, skir.DataValue> _readRecordFields(skir.DataValue payload) =>
    switch (payload) {
      skir.DataValue_recordWrapper(:final value) => {
        for (final field in value.fields) field.name: field.value,
      },
      _ => throw const FormatException("Expected a canonical record"),
    };

skir.DataValue _readField(Map<String, skir.DataValue> fields, String name) =>
    fields[name] ??
    (throw FormatException("The canonical field $name is absent"));

/// The value at the field [path] below a projected declared value.
skir.DataValue _readSelect(skir.DataValue value, List<String> path) {
  var current = value;
  for (final name in path) {
    final payload = switch (current) {
      skir.DataValue_namedWrapper(:final value) => value.payload,
      _ => current,
    };
    current = _readField(_readRecordFields(payload), name);
  }
  return current;
}
