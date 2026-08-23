import "package:flutter/material.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "element_definition.freezed.dart";

@freezed
abstract class ElementDefinition with _$ElementDefinition {
  @Assert("name != \"\"", "Name must not be empty.")
  const factory ElementDefinition({
    required ResolvedTypeRef rootType,
    required String name,
    required String description,
    required IconValue icon,
    @Default(Colors.grey) Color color,
    ElementDeprecation? deprecation,
  }) = _ElementDefinition;
}

@freezed
abstract class ElementDeprecation with _$ElementDeprecation {
  const factory ElementDeprecation({@Default("") String reason}) =
      _ElementDeprecation;
}

final class ElementDefinitionException implements Exception {
  const ElementDefinitionException(this.diagnostics);

  final List<TypeDiagnostic> diagnostics;

  @override
  String toString() => diagnostics.join("; ");
}

extension ElementDefinitionType on ElementDefinition {
  DeclaredTypeId get typeId {
    final id = rootType.id;
    if (id is DeclaredTypeId) return id;
    throw StateError("Element root type does not have a declared identity");
  }

  String get namespace => typeId.uuid;

  String get qualifiedName => typeId.displayName;

  bool get isDeprecated => deprecation != null;

  TypeResult<ResolvedType> resolve(TypeRegistry registry) {
    if (rootType.id is! DeclaredTypeId) {
      return TypeResult.failure([
        TypeDiagnostic(
          code: TypeDiagnosticCode.invalidTypeId,
          message: "Element root type must have a declared identity",
          type: rootType,
          pathPresent: false,
        ),
      ]);
    }
    final resolved = registry.resolveExact(rootType);
    final type = resolved.valueOrNull;
    if (type == null) return TypeResult.failure(resolved.diagnostics);
    if (!type.isConcrete) {
      return TypeResult.failure([
        TypeDiagnostic(
          code: TypeDiagnosticCode.invalidConcreteType,
          message: "Element root type must be concrete",
          type: rootType,
          pathPresent: false,
        ),
      ]);
    }
    if (type.representation is! RecordType) {
      return TypeResult.failure([
        TypeDiagnostic(
          code: TypeDiagnosticCode.incompatibleRepresentation,
          message: "Element root type must use a record representation",
          type: rootType,
          pathPresent: false,
        ),
      ]);
    }
    final iconDiagnostics = icon.validate();
    if (iconDiagnostics.isNotEmpty) {
      return TypeResult.failure(iconDiagnostics);
    }
    return TypeResult.success(type);
  }
}
