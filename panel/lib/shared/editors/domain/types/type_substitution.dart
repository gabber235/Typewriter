import "package:typewriter_panel/typewriter_panel.dart";

extension ResolvedTypeRefSubstitution on ResolvedTypeRef {
  ResolvedTypeRef substitute(Map<String, TypeExpression> substitutions) =>
      withArguments(
        arguments.map((argument) => argument.substitute(substitutions)),
      );
}

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
