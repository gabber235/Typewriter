part of "type_validation.dart";

/// Additional value checks for nominal values and scalar representations.
///
/// These checks stay beside general validation because they need concrete
/// runtime details, including sanitized SVG content and polymorphic tags.
extension on FloatValue {
  List<TypeDiagnostic> validateFloatAgainst(FloatType type, DataPath path) {
    if (!value.isFinite) return [_invalid(path, "Float must be finite")];
    if (type.minimum case final minimum? when value < minimum) {
      return [_invalid(path, "Float must be at least $minimum")];
    }
    if (type.maximum case final maximum? when value > maximum) {
      return [_invalid(path, "Float must be at most $maximum")];
    }
    return const [];
  }
}

extension on DecimalValue {
  List<TypeDiagnostic> validateDecimalAgainst(DecimalType type, DataPath path) {
    if (type.minimum case final minimum?
        when compareDecimalStrings(value, minimum) < 0) {
      return [_invalid(path, "Decimal must be at least $minimum")];
    }
    if (type.maximum case final maximum?
        when compareDecimalStrings(value, maximum) > 0) {
      return [_invalid(path, "Decimal must be at most $maximum")];
    }
    if (type.scale case final scale? when value.decimalScale > scale) {
      return [_invalid(path, "Decimal scale exceeds $scale")];
    }
    return const [];
  }
}

extension on DataValue {
  List<TypeDiagnostic> _validateNamed(
    NamedType type,
    DataPath path,
    TypeRegistry? registry,
  ) {
    if (registry == null) {
      return [_invalid(path, "Nominal value validation requires a registry")];
    }
    final expected = registry.resolve(type);
    if (expected case TypeFailure(:final diagnostics)) return diagnostics;
    final resolvedExpected = expected.valueOrNull!;
    if (resolvedExpected.isConcrete) {
      if (this is PolymorphicValue) {
        return [_invalid(path, "Concrete values must not carry a type tag")];
      }
      final diagnostics = validateAgainst(
        resolvedExpected.representation,
        path: path,
        registry: registry,
      );
      if (diagnostics.isNotEmpty ||
          !type.reference._sameDeclaration(standardTypeRefs.svgIcon)) {
        return diagnostics;
      }
      return _validateSvgIcon(path);
    }
    if (this is! PolymorphicValue) {
      return [_invalid(path, "Abstract values require an exact concrete tag")];
    }

    final polymorphic = this as PolymorphicValue;

    final concrete = registry.resolveExact(polymorphic.concreteType);

    if (concrete case TypeFailure(:final diagnostics)) return diagnostics;

    final resolvedConcrete = concrete.valueOrNull!;
    if (!resolvedConcrete.isConcrete) {
      return [_invalid(path, "Polymorphic tag must identify a concrete type")];
    }
    if (!NamedType(polymorphic.concreteType)
        .isStructurallyAssignableTo(type, registry)) {
      return [
        _invalid(path, "Polymorphic type does not refine the abstract type"),
      ];
    }
    return polymorphic.value._validateNamed(
      NamedType(polymorphic.concreteType),
      path,
      registry,
    );
  }
}

extension on ResolvedTypeRef {
  bool _sameDeclaration(ResolvedTypeRef other) =>
      id == other.id && revision == other.revision;
}

extension on DataValue {
  List<TypeDiagnostic> _validateSvgIcon(DataPath path) {
    if (this case RecordValue(fields: {"source": StringValue(:final value)})) {
      return !value.isSanitizedSvg
          ? [_invalid(path.field("source"), "SVG content is not sanitized")]
          : const [];
    }
    return [_invalid(path, "SVG content must contain a string source field")];
  }
}
