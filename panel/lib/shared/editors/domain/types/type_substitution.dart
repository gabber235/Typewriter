import "package:typewriter_panel/typewriter_panel.dart";

/// Applies generic arguments to every expression inside a nominal reference.
/// Unmatched parameters remain unchanged so validation can report them later.
extension ResolvedTypeRefSubstitution on ResolvedTypeRef {
  ResolvedTypeRef substitute(Map<String, TypeExpression> substitutions) =>
      withArguments(
        arguments.map((argument) => argument.substitute(substitutions)),
      );
}

/// Rewrites generic parameters through an immutable type expression tree.
///
/// Constraints, collection shape, record metadata, and enum values are
/// retained. Only parameter occurrences and nested nominal arguments change.
extension TypeExpressionSubstitution on TypeExpression {
  TypeExpression substitute(Map<String, TypeExpression> substitutions) {
    final type = this;
    return switch (type) {
      ParameterType(:final name) => substitutions[name] ?? this,
      ListType() => ListType(
        element: type.element.substitute(substitutions),
        minimumLength: type.minimumLength,
        maximumLength: type.maximumLength,
        unique: type.unique,
      ),
      MapType() => MapType(
        key: type.key.substitute(substitutions),
        value: type.value.substitute(substitutions),
        minimumLength: type.minimumLength,
        maximumLength: type.maximumLength,
      ),
      RecordType() => RecordType(
        closed: type.closed,
        fields: type.fields.map(
          (name, field) => MapEntry(
            name,
            TypeField(
              name: name,
              type: field.type.substitute(substitutions),
              initialValue: field.initialValue,
              defaulted: field.defaulted,
            ),
          ),
        ),
      ),
      EnumType(:final valueType, :final values) => EnumType(
        valueType: valueType.substitute(substitutions),
        values: values,
      ),
      NamedType(:final reference) => NamedType(
        reference.substitute(substitutions),
      ),
      _ => type,
    };
  }
}

/// Applies nominal type arguments carried inside portable polymorphic values.
extension DataValueTypeSubstitution on DataValue {
  DataValue substituteTypes(Map<String, TypeExpression> substitutions) =>
      switch (this) {
        ListValue(:final values) => ListValue([
          for (final value in values) value.substituteTypes(substitutions),
        ]),
        MapValue(:final entries) => MapValue([
          for (final entry in entries)
            DataMapEntry(
              key: entry.key.substituteTypes(substitutions),
              value: entry.value.substituteTypes(substitutions),
            ),
        ]),
        RecordValue(:final fields) => RecordValue({
          for (final entry in fields.entries)
            entry.key: entry.value.substituteTypes(substitutions),
        }),
        PolymorphicValue(:final concreteType, :final value) => PolymorphicValue(
          concreteType: concreteType.substitute(substitutions),
          value: value.substituteTypes(substitutions),
        ),
        _ => this,
      };
}
