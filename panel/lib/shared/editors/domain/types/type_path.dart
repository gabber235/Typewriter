import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "type_path.freezed.dart";

/// Resolves a data path against a type expression.
///
/// Record fields, list elements, and map values advance the structural type.
/// Named types are expanded through [TypeRegistry]. An invalid segment or
/// unresolved nominal reference returns diagnostics, allowing binding callers
/// to reject a target instead of guessing its type.
extension TypeExpressionPathResolution on TypeExpression {
  TypeResult<TypeExpression> resolvePath(
    DataPath path, {
    TypeRegistry? registry,
  }) {
    var current = this;
    for (final segment in path.segments) {
      final resolved = current._resolveSegment(segment, path, registry);
      if (resolved case TypeFailure(:final diagnostics)) {
        return TypeResult.failure(diagnostics);
      }
      current = resolved.valueOrNull!;
    }
    return TypeResult.success(current);
  }
}

extension on TypeExpression {
  TypeResult<TypeExpression> _resolveSegment(
    DataPathSegment segment,
    DataPath path,
    TypeRegistry? registry,
  ) {
    final parent = this;
    if (parent is NamedType) {
      if (registry == null) return parent._invalidPath(segment, path);
      final resolved = registry.resolve(parent);
      if (resolved case TypeFailure(:final diagnostics)) {
        return TypeResult.failure(diagnostics);
      }
      return resolved.valueOrNull!.representation._resolveSegment(
        segment,
        path,
        registry,
      );
    }
    final resolved = switch ((parent, segment)) {
      (RecordType(:final fields), FieldPathSegment(:final name)) =>
        fields[name]?.type,
      (ListType(:final element), IndexPathSegment()) => element,
      (MapType(:final value), MapKeyPathSegment()) => value,
      _ => null,
    };
    return resolved == null
        ? parent._invalidPath(segment, path)
        : TypeResult.success(resolved);
  }

  TypeFailure<TypeExpression> _invalidPath(
    DataPathSegment segment,
    DataPath path,
  ) => TypeFailure([
    TypeDiagnostic(
      code: TypeDiagnosticCode.invalidPath,
      message: "${segment.runtimeType} cannot resolve through $runtimeType",
      path: path,
    ),
  ]);
}

/// A structural step used to find references inside a type expression.
@freezed
sealed class TypeQuerySegment with _$TypeQuerySegment {
  const factory TypeQuerySegment.field(String name) = TypeFieldQuerySegment;

  const factory TypeQuerySegment.listElement() = TypeListElementQuerySegment;

  const factory TypeQuerySegment.mapValue() = TypeMapValueQuerySegment;
}

/// A reference declaration and its location within an enclosing type.
@freezed
abstract class TypeReferenceLocation with _$TypeReferenceLocation {
  const factory TypeReferenceLocation({
    required List<TypeQuerySegment> path,
    required ReferenceType type,
    @Default(false) bool collection,
    @Default(false) bool optional,
  }) = _TypeReferenceLocation;

  const TypeReferenceLocation._();

  ResolvedTypeRef get target => type.target;
}

/// Finds standard reference fields nested in records and collections.
///
/// The optional relation filters qualified reference names. Returned paths are
/// type query paths, not value paths, so a value must be expanded separately.
extension TypeExpressionReferenceQuery on TypeExpression {
  List<TypeReferenceLocation> queryReferences({String? relation}) {
    final locations = <TypeReferenceLocation>[];
    _collectReferences(const [], relation, locations);
    return List.unmodifiable(locations);
  }
}

extension on TypeExpression {
  void _collectReferences(
    List<TypeQuerySegment> path,
    String? relation,
    List<TypeReferenceLocation> locations,
  ) {
    final type = this;
    if (type case ReferenceType(:final target)) {
      if (NamedType(target)._matchesReferenceRelation(relation)) {
        locations.add(TypeReferenceLocation(path: path, type: type));
      }
      return;
    }
    if (type case NamedType(:final reference)) {
      final argument = reference.arguments.singleOrNull;
      if (reference.id == const TypeId.option() &&
          argument is ReferenceType &&
          NamedType(argument.target)._matchesReferenceRelation(relation)) {
        locations.add(
          TypeReferenceLocation(path: path, type: argument, optional: true),
        );
      }
      return;
    }
    switch (type) {
      case RecordType(:final fields):
        for (final field in fields.values) {
          field.type._collectReferences(
            [...path, TypeFieldQuerySegment(field.name)],
            relation,
            locations,
          );
        }
      case ListType(element: final ReferenceType reference):
        if (NamedType(reference.target)._matchesReferenceRelation(relation)) {
          locations.add(
            TypeReferenceLocation(
              path: path,
              type: reference,
              collection: true,
            ),
          );
        }
      case ListType(:final element):
        element._collectReferences(
          [...path, const TypeListElementQuerySegment()],
          relation,
          locations,
        );
      case MapType(:final value):
        value._collectReferences(
          [...path, const TypeMapValueQuerySegment()],
          relation,
          locations,
        );
      default:
        return;
    }
  }

  bool _matchesReferenceRelation(String? relation) {
    if (relation == null) return true;
    if (this is! NamedType) return false;
    final id = (this as NamedType).reference.id;
    if (id is! QualifiedTypeId) return false;
    return id.name.toLowerCase() == relation.toLowerCase() ||
        id.displayName == relation;
  }
}

/// Expands a type query into concrete paths in a value.
///
/// Collection elements produce one path per existing value. A terminal list
/// element query produces the append index, which lets editors target a new
/// item. Missing record fields and incompatible shapes produce no paths.
extension DataValueTypeQueryExpansion on DataValue {
  List<DataPath> expandTypeQueryPath(Iterable<TypeQuerySegment> query) =>
      List.unmodifiable(_expandTypeQuery(query.toList(), 0, DataPath.root));
}

extension on DataValue {
  Iterable<DataPath> _expandTypeQuery(
    List<TypeQuerySegment> query,
    int offset,
    DataPath path,
  ) sync* {
    final value = this;
    if (value is PolymorphicValue) {
      yield* value.value._expandTypeQuery(query, offset, path);
      return;
    }
    if (offset == query.length) {
      yield path;
      return;
    }
    final segment = query[offset];
    if (segment is TypeFieldQuerySegment && value is RecordValue) {
      final child = value.fields[segment.name];
      if (child != null) {
        yield* child._expandTypeQuery(
          query,
          offset + 1,
          path.field(segment.name),
        );
      }
      return;
    }
    if (segment is TypeListElementQuerySegment && value is ListValue) {
      if (offset == query.length - 1) {
        yield path.index(value.values.length);
        return;
      }
      for (final entry in value.values.indexed) {
        yield* entry.$2._expandTypeQuery(
          query,
          offset + 1,
          path.index(entry.$1),
        );
      }
      return;
    }

    if (segment is TypeMapValueQuerySegment && value is MapValue) {
      for (final entry in value.entries) {
        yield* entry.value._expandTypeQuery(
          query,
          offset + 1,
          path.mapKey(entry.key),
        );
      }
    }
  }
}
