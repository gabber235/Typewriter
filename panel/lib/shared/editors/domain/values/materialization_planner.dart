import "dart:typed_data";

import "package:typewriter_panel/typewriter_panel.dart";

DraftValue planCreationDraft({
  required TypeExpression type,
  required TypeRegistry registry,
  Map<MaterializationLocation, DataValue> fixedValues = const {},
}) => _DraftPlanner(
  registry,
  fixedValues,
).build(type, const MaterializationLocation.root());

DraftValue planCreationDraftWithoutDefaults({
  required TypeExpression type,
  required TypeRegistry registry,
}) => _DraftPlanner(
  registry,
  const {},
  includeInitialValues: false,
).build(type, const MaterializationLocation.root());

final class _DraftPlanner {
  _DraftPlanner(
    this.registry,
    this.fixedValues, {
    this.includeInitialValues = true,
  });

  final TypeRegistry registry;
  final Map<MaterializationLocation, DataValue> fixedValues;
  final bool includeInitialValues;
  int _nextId = 0;

  DraftNodeId _id() => DraftNodeId(_nextId++);

  DraftValue build(TypeExpression type, MaterializationLocation location) {
    if (fixedValues[location] case final fixed?) {
      return _fromValue(type, fixed, location);
    }
    return switch (type) {
      AnyType() ||
      ParameterType() ||
      ReferenceType() => MissingDraftValue(_id()),
      UnitType() => ScalarDraftValue(_id(), const UnitValue()),
      BooleanType() => _defaultedScalar(type, const BooleanValue(false)),
      StringType() => _defaultedScalar(type, const StringValue("")),
      BytesType() => _defaultedScalar(type, BytesValue(Uint8List(0))),
      IntegerType() => _defaultedScalar(type, IntegerValue(BigInt.zero)),
      FloatType() => _defaultedScalar(type, const FloatValue(0)),
      DecimalType() => _defaultedScalar(type, DecimalValue("0")),
      TimestampType() => _defaultedScalar(
        type,
        TimestampValue(DateTime.fromMillisecondsSinceEpoch(0, isUtc: true)),
      ),
      DurationType() => _defaultedScalar(
        type,
        const DurationValue(Duration.zero),
      ),
      EnumType(:final values) =>
        includeInitialValues && values.length == 1
            ? ScalarDraftValue(_id(), values.single)
            : MissingDraftValue(_id()),
      ListType() => ListDraftValue(_id(), const []),
      MapType() => MapDraftValue(_id(), const []),
      RecordType(:final fields) => RecordDraftValue(_id(), {
        for (final field in fields.values)
          field.name: field.initialValue != null && includeInitialValues
              ? _fromValue(
                  field.type,
                  field.initialValue!,
                  location.child("field:${field.name}"),
                )
              : build(field.type, location.child("field:${field.name}")),
      }),
      NamedType() => _named(type, location),
    };
  }

  DraftValue _defaultedScalar(TypeExpression type, DataValue value) =>
      includeInitialValues &&
          value.validateAgainst(type, registry: registry).isEmpty
      ? ScalarDraftValue(_id(), value)
      : MissingDraftValue(_id());

  DraftValue _named(NamedType type, MaterializationLocation location) {
    if (includeInitialValues && type.reference.id == const TypeId.option()) {
      return _fromValue(
        type,
        PolymorphicValue(
          concreteType: standardTypeRefs.noneOf(
            type.reference.arguments.single,
          ),
          value: const UnitValue(),
        ),
        location,
      );
    }
    final resolved = registry.resolve(type).valueOrNull;
    if (resolved == null) return MissingDraftValue(_id());
    if (resolved.isConcrete) return build(resolved.representation, location);
    final options = registry.concreteDescendantsOf(type.reference).toList();
    if (includeInitialValues && options.length == 1) {
      return _polymorphic(options.single, location);
    }
    return PolymorphicDraftValue(_id(), concreteType: null, payload: null);
  }

  DraftValue _polymorphic(
    ResolvedTypeRef concrete,
    MaterializationLocation location,
  ) {
    final resolved = registry.resolveExact(concrete).valueOrNull;
    return PolymorphicDraftValue(
      _id(),
      concreteType: concrete,
      payload: resolved == null
          ? MissingDraftValue(_id())
          : build(resolved.representation, location.child("payload")),
    );
  }

  DraftValue fromValue(TypeExpression type, DataValue value) =>
      _fromValue(type, value, const MaterializationLocation.root());

  DraftValue _fromValue(
    TypeExpression type,
    DataValue value,
    MaterializationLocation location,
  ) {
    if (type case NamedType()) {
      final resolved = registry.resolve(type).valueOrNull;
      if (resolved != null && resolved.isConcrete) {
        return _fromValue(resolved.representation, value, location);
      }
      if (value case PolymorphicValue(:final concreteType, :final value)) {
        final concrete = registry.resolveExact(concreteType).valueOrNull;
        return PolymorphicDraftValue(
          _id(),
          concreteType: concreteType,
          payload: concrete == null
              ? MissingDraftValue(_id())
              : _fromValue(concrete.representation, value, location),
        );
      }
    }
    if ((type, value) case (
      RecordType(:final fields),
      final RecordValue record,
    )) {
      return RecordDraftValue(_id(), {
        for (final field in fields.values)
          field.name: record.fields[field.name] != null
              ? _fromValue(field.type, record.fields[field.name]!, location)
              : build(field.type, location),
      });
    }
    if ((type, value) case (
      ListType(:final element),
      ListValue(:final values),
    )) {
      return ListDraftValue(_id(), [
        for (final item in values) _fromValue(element, item, location),
      ]);
    }
    if ((type, value) case (
      MapType(:final key, value: final valueType),
      MapValue(entries: final entries),
    )) {
      return MapDraftValue(_id(), [
        for (final entry in entries)
          DraftMapEntry(
            id: _id(),
            key: _fromValue(key, entry.key, location),
            value: _fromValue(valueType, entry.value, location),
          ),
      ]);
    }
    return ScalarDraftValue(_id(), value);
  }
}

DraftValue draftFromValue({
  required TypeExpression type,
  required DataValue value,
  required TypeRegistry registry,
}) => _DraftPlanner(registry, const {}).fromValue(type, value);
