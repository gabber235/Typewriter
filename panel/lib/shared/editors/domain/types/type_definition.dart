import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "type_definition.freezed.dart";

/// Controls how a nominal type argument participates in assignability.
enum TypeVariance { invariant, covariant, contravariant }

/// Declares whether a nominal type can be instantiated or extended.
enum NominalTypeKind { concrete, openAbstract, sealedAbstract }

/// Semantic surface for which a nominal type can supply a presentation.
enum PresentationRole {
  referenceSummary,
  referenceOption,
  catalogOption,
  authoringResult,
  pageTile,
  graphNode,
  inspectorHeader,
}

/// Closed field reconciliation strategies understood by the editor.
enum FieldMergeStrategy { setMembership }

/// Associates one canonical field path with its reconciliation strategy.
@freezed
abstract class FieldMergePolicy with _$FieldMergePolicy {
  const factory FieldMergePolicy({
    required DataPath path,
    required FieldMergeStrategy strategy,
  }) = _FieldMergePolicy;
}

/// A generic parameter, including the values permitted for its argument.
@freezed
abstract class TypeParameter with _$TypeParameter {
  @Assert("name != \"\"", "Parameter name must not be empty.")
  const factory TypeParameter({
    required String name,
    @Default(AnyType()) TypeExpression bound,
    @Default(TypeVariance.invariant) TypeVariance variance,
  }) = _TypeParameter;
}

/// The catalog declaration from which a nominal type is resolved.
///
/// The representation is the editable structural view. Parents add inherited
/// constraints. The registry owns resolution, substitution, inheritance
/// checks, and the resulting ancestor set. The initial value is the portable
/// value used when authoring starts without an explicit value.
@freezed
abstract class TypeDefinition with _$TypeDefinition {
  const factory TypeDefinition({
    required ResolvedTypeRef id,
    required NominalTypeKind kind,
    String? declarationOwner,
    @Default(AnyType()) TypeExpression representation,
    @Default([]) List<TypeParameter> parameters,
    @Default([]) List<ResolvedTypeRef> parents,
    PresentationId? defaultPresentationId,
    @Default({}) Map<String, PresentationId> namedPresentations,
    @Default({}) Map<PresentationRole, PresentationId> rolePresentations,
    @Default([]) List<FieldMergePolicy> fieldMergePolicies,
    DataValue? initialValue,
  }) = _TypeDefinition;
}

/// The serialized set of nominal declarations available to an editor.
@freezed
abstract class TypeCatalog with _$TypeCatalog {
  const factory TypeCatalog(List<TypeDefinition> definitions) = _TypeCatalog;
}

/// A validated declaration with generic arguments and inherited structure.
///
/// `representation` is the effective editable shape after parent refinement.
/// `directParents` and `ancestors` are derived lookup data, not independent
/// sources of type authority.
@freezed
abstract class ResolvedType with _$ResolvedType {
  const factory ResolvedType({
    required ResolvedTypeRef reference,
    required NominalTypeKind kind,
    required TypeExpression representation,
    required Set<ResolvedTypeRef> ancestors,
    @Default({}) Set<ResolvedTypeRef> directParents,
    DataValue? initialValue,
  }) = _ResolvedType;

  const ResolvedType._();

  bool get isConcrete => kind == NominalTypeKind.concrete;
}
