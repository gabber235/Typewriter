import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "type_definition.freezed.dart";

enum TypeVariance { invariant, covariant, contravariant }

enum NominalTypeKind { concrete, openAbstract, sealedAbstract }

@freezed
abstract class TypeParameter with _$TypeParameter {
  @Assert("name != \"\"", "Parameter name must not be empty.")
  const factory TypeParameter({
    required String name,
    @Default(AnyType()) TypeExpression bound,
    @Default(TypeVariance.invariant) TypeVariance variance,
  }) = _TypeParameter;
}

@freezed
abstract class TypeDefinition with _$TypeDefinition {
  const factory TypeDefinition({
    required ResolvedTypeRef id,
    required NominalTypeKind kind,
    @Default(AnyType()) TypeExpression representation,
    @Default([]) List<TypeParameter> parameters,
    @Default([]) List<ResolvedTypeRef> parents,
    PresentationId? defaultPresentationId,
    @Default({}) Map<String, PresentationId> namedPresentations,
  }) = _TypeDefinition;
}

@freezed
abstract class TypeCatalog with _$TypeCatalog {
  const factory TypeCatalog(List<TypeDefinition> definitions) = _TypeCatalog;
}

@freezed
abstract class ResolvedType with _$ResolvedType {
  const factory ResolvedType({
    required ResolvedTypeRef reference,
    required NominalTypeKind kind,
    required TypeExpression representation,
    required Set<ResolvedTypeRef> ancestors,
    @Default({}) Set<ResolvedTypeRef> directParents,
  }) = _ResolvedType;

  const ResolvedType._();

  bool get isConcrete => kind == NominalTypeKind.concrete;
}
