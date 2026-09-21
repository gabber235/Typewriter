// Translates the recursive type catalog while preserving reference identity.
//
// Decoding happens in two passes. Shell definitions establish the namespace
// needed to resolve recursive references, then complete definitions validate
// their representations. This is why catalog decoding cannot be a simple
// field by field mapping.
import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/editor_codec_support.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/type_catalog.dart"
    as wire;
import "package:typewriter_panel/typewriter_panel.dart";

part "editor_catalog_codec.freezed.dart";

/// A decoded catalog together with the registry that resolves its references.
@freezed
abstract class DecodedTypeCatalog with _$DecodedTypeCatalog {
  const factory DecodedTypeCatalog(TypeCatalog catalog, TypeRegistry registry) =
      _DecodedTypeCatalog;
}

/// Encodes domain catalog definitions for Skir transport.
extension TypeCatalogWireEncoding on TypeCatalog {
  TypeResult<wire.TypeCatalog> encodeWire() => encodeDefinitions().mapValue(
    (definitions) => wire.TypeCatalog(definitions: definitions),
  );

  TypeResult<List<wire.TypeDefinition>> encodeDefinitions() {
    final codec = SkirTypeCodec(TypeRegistry(this));
    final definitions = <wire.TypeDefinition>[];
    final diagnostics = <TypeDiagnostic>[];
    for (final definition in this.definitions) {
      final representation = codec.encodeExpression(definition.representation);
      final id = codec.encodeReference(definition.id);
      final parents = <wire.ResolvedTypeRef>[];
      diagnostics
        ..addAll(representation.diagnostics)
        ..addAll(id.diagnostics);
      for (final parent in definition.parents) {
        final encoded = codec.encodeReference(parent);
        diagnostics.addAll(encoded.diagnostics);
        if (encoded.valueOrNull case final item?) parents.add(item);
      }
      final parameters = <wire.TypeParameter>[];

      for (final parameter in definition.parameters) {
        final bound = parameter.bound is AnyType
            ? const TypeResult<wire.TypeExpression?>.success(null)
            : codec
                  .encodeExpression(parameter.bound)
                  .mapValue((value) => value);
        diagnostics.addAll(bound.diagnostics);
        parameters.add(
          wire.TypeParameter(
            name: parameter.name,
            variance: switch (parameter.variance) {
              TypeVariance.invariant => wire.TypeVariance.invariant,
              TypeVariance.covariant => wire.TypeVariance.covariant_,
              TypeVariance.contravariant => wire.TypeVariance.contravariant,
            },
            upperBounds: [?bound.valueOrNull],
          ),
        );
      }
      final encodedId = id.valueOrNull;
      final encodedRepresentation = representation.valueOrNull;
      if (encodedId == null || encodedRepresentation == null) continue;
      definitions.add(
        wire.TypeDefinition(
          displayName: definition.id.id.displayName,
          parameters: parameters,
          directParents: parents,
          representation: encodedRepresentation,
          typeId: encodedId.typeId,
          revision: encodedId.revision,
          kind: definition.kind._encodeWire,
          declarationOwner:
              definition.declarationOwner ?? definition.id.id._defaultOwner,
          defaultPresentationId: definition.defaultPresentationId == null
              ? null
              : (definition.defaultPresentationId!)._encodeWire,
          namedPresentations: [
            for (final entry in definition.namedPresentations.entries)
              wire.NamedPresentation(
                name: entry.key,
                presentationId: entry.value._encodeWire,
              ),
          ],
          outgoingConversionIds: const [],
          rolePresentations: [
            for (final entry in definition.rolePresentations.entries)
              wire.RolePresentation(
                role: entry.key._encodeWire,
                presentationId: entry.value._encodeWire,
              ),
          ],
          fieldMergePolicies: [
            for (final policy in definition.fieldMergePolicies)
              wire.FieldMergePolicy(
                fieldPath: policy.path.segments.map((segment) {
                  if (segment case FieldPathSegment(:final name)) return name;
                  throw ArgumentError(
                    "Merge policies currently support field paths only",
                  );
                }),
                strategy: policy.strategy._encodeWire,
              ),
          ],
        ),
      );
    }
    return diagnostics.isEmpty
        ? TypeResult.success(definitions)
        : TypeResult.failure(diagnostics);
  }
}

/// Starts domain decoding from a complete wire catalog.
extension WireTypeCatalogDecoding on wire.TypeCatalog {
  TypeResult<DecodedTypeCatalog> decodeDomain() =>
      definitions.decodeDefinitions();
}

/// Decodes definitions with a shell pass for recursive references.
extension WireTypeDefinitionListDecoding on Iterable<wire.TypeDefinition> {
  TypeResult<DecodedTypeCatalog> decodeDefinitions() {
    final wireDefinitions = toList();
    final diagnostics = <TypeDiagnostic>[];
    final shells = <TypeDefinition>[];

    for (final value in wireDefinitions) {
      final reference = value._decodeReference();
      final kind = value.kind._decodeDomain();
      diagnostics
        ..addAll(reference.diagnostics)
        ..addAll(kind.diagnostics);
      if (reference.valueOrNull case final id?) {
        if (kind.valueOrNull case final decodedKind?) {
          shells.add(
            TypeDefinition(
              id: id,
              kind: decodedKind,
              declarationOwner: value.declarationOwner,
              parameters: [
                for (final parameter in value.parameters)
                  TypeParameter(name: parameter.name),
              ],
            ),
          );
        }
      }
    }

    if (diagnostics.isNotEmpty) return TypeResult.failure(diagnostics);
    final codec = SkirTypeCodec(TypeRegistry(TypeCatalog(shells)));
    final definitions = <TypeDefinition>[];

    for (final entry in wireDefinitions.indexed) {
      final decoded = entry.$2._decodeDomain(shells[entry.$1].id, codec);
      diagnostics.addAll(decoded.diagnostics);
      if (decoded.valueOrNull case final definition?) {
        definitions.add(definition);
      }
    }

    if (diagnostics.isNotEmpty) return TypeResult.failure(diagnostics);
    final catalog = TypeCatalog(definitions);
    return TypeResult.success(
      DecodedTypeCatalog(catalog, TypeRegistry(catalog)),
    );
  }
}

extension on wire.TypeDefinition {
  TypeResult<TypeDefinition> _decodeDomain(
    ResolvedTypeRef id,
    SkirTypeCodec codec,
  ) {
    final value = this;
    final representation = codec.decodeExpression(value.representation);
    final kind = value.kind._decodeDomain();
    final diagnostics = <TypeDiagnostic>[
      ...representation.diagnostics,
      ...kind.diagnostics,
    ];
    final parents = <ResolvedTypeRef>[];
    for (final value in value.directParents) {
      final decoded = codec.decodeReference(value);
      diagnostics.addAll(decoded.diagnostics);
      if (decoded.valueOrNull case final parent?) parents.add(parent);
    }

    final parameters = <TypeParameter>[];
    for (final value in value.parameters) {
      final decoded = value._decodeDomain(codec);
      diagnostics.addAll(decoded.diagnostics);
      if (decoded.valueOrNull case final parameter?) parameters.add(parameter);
    }
    final namedPresentations = <String, PresentationId>{};
    for (final value in value.namedPresentations) {
      final decoded = value.presentationId._decodeDomain();
      diagnostics.addAll(decoded.diagnostics);
      if (decoded.valueOrNull case final presentation?) {
        namedPresentations[value.name] = presentation;
      }
    }
    final defaultPresentation = value.defaultPresentationId == null
        ? const TypeResult<PresentationId?>.success(null)
        : (value.defaultPresentationId!)._decodeDomain().mapValue(
            (value) => value,
          );
    diagnostics.addAll(defaultPresentation.diagnostics);

    final rolePresentations = <PresentationRole, PresentationId>{};
    for (final association in value.rolePresentations) {
      final role = association.role._decodeDomain();
      final presentation = association.presentationId._decodeDomain();
      diagnostics
        ..addAll(role.diagnostics)
        ..addAll(presentation.diagnostics);
      final decodedRole = role.valueOrNull;
      final decodedPresentation = presentation.valueOrNull;
      if (decodedRole == null || decodedPresentation == null) continue;
      if (rolePresentations.containsKey(decodedRole)) {
        diagnostics.add(
          invalidWire(
            "Presentation role '${decodedRole.name}' is declared more than once",
          ).diagnostics.single,
        );
        continue;
      }
      rolePresentations[decodedRole] = decodedPresentation;
    }

    final fieldMergePolicies = <FieldMergePolicy>[];
    final mergePaths = <DataPath>{};
    for (final policy in value.fieldMergePolicies) {
      final strategy = policy.strategy._decodeDomain();
      diagnostics.addAll(strategy.diagnostics);
      final path = DataPath([
        for (final name in policy.fieldPath) DataPathSegment.field(name),
      ]);
      if (path.segments.isEmpty || !mergePaths.add(path)) {
        diagnostics.add(
          invalidWire(
            path.segments.isEmpty
                ? "Merge policy path is empty"
                : "Merge policy path is declared more than once",
          ).diagnostics.single,
        );
        continue;
      }
      if (strategy.valueOrNull case final decoded?) {
        fieldMergePolicies.add(FieldMergePolicy(path: path, strategy: decoded));
      }
    }

    if (diagnostics.isNotEmpty) return TypeResult.failure(diagnostics);
    return TypeResult.success(
      TypeDefinition(
        id: id,
        kind: kind.valueOrNull!,
        declarationOwner: value.declarationOwner,
        representation: representation.valueOrNull!,
        parameters: parameters,
        parents: parents,
        defaultPresentationId: defaultPresentation.valueOrNull,
        namedPresentations: namedPresentations,
        rolePresentations: rolePresentations,
        fieldMergePolicies: fieldMergePolicies,
      ),
    );
  }

  TypeResult<ResolvedTypeRef> _decodeReference() {
    final shell = SkirTypeCodec(TypeRegistry(TypeCatalog(const [])));
    return shell.decodeReference(
      wire.ResolvedTypeRef(
        typeId: typeId,
        revision: revision,
        arguments: const [],
      ),
    );
  }
}

extension on PresentationRole {
  wire.PresentationRole get _encodeWire => switch (this) {
    PresentationRole.referenceSummary => wire.PresentationRole.referenceSummary,
    PresentationRole.referenceOption => wire.PresentationRole.referenceOption,
    PresentationRole.catalogOption => wire.PresentationRole.catalogOption,
    PresentationRole.authoringResult => wire.PresentationRole.authoringResult,
    PresentationRole.pageTile => wire.PresentationRole.pageTile,
    PresentationRole.graphNode => wire.PresentationRole.graphNode,
    PresentationRole.inspectorHeader => wire.PresentationRole.inspectorHeader,
  };
}

extension on wire.PresentationRole {
  TypeResult<PresentationRole> _decodeDomain() => switch (this) {
    wire.PresentationRole.referenceSummary => const TypeResult.success(
      PresentationRole.referenceSummary,
    ),
    wire.PresentationRole.referenceOption => const TypeResult.success(
      PresentationRole.referenceOption,
    ),
    wire.PresentationRole.catalogOption => const TypeResult.success(
      PresentationRole.catalogOption,
    ),
    wire.PresentationRole.authoringResult => const TypeResult.success(
      PresentationRole.authoringResult,
    ),
    wire.PresentationRole.pageTile => const TypeResult.success(
      PresentationRole.pageTile,
    ),
    wire.PresentationRole.graphNode => const TypeResult.success(
      PresentationRole.graphNode,
    ),
    wire.PresentationRole.inspectorHeader => const TypeResult.success(
      PresentationRole.inspectorHeader,
    ),
    _ => invalidWire("Unknown presentation role"),
  };
}

extension on FieldMergeStrategy {
  wire.FieldMergeStrategy get _encodeWire => switch (this) {
    FieldMergeStrategy.setMembership => wire.FieldMergeStrategy.setMembership,
  };
}

extension on wire.FieldMergeStrategy {
  TypeResult<FieldMergeStrategy> _decodeDomain() => switch (this) {
    wire.FieldMergeStrategy.setMembership => const TypeResult.success(
      FieldMergeStrategy.setMembership,
    ),
    _ => invalidWire("Unknown field merge strategy"),
  };
}

extension on wire.TypeParameter {
  TypeResult<TypeParameter> _decodeDomain(SkirTypeCodec codec) {
    final value = this;
    final parameterName = value.name;
    if (value.name.isEmpty) return invalidWire("Type parameter name is empty");
    if (value.upperBounds.length > 1) {
      return invalidWire("Multiple parameter bounds are not supported");
    }
    final bound = value.upperBounds.isEmpty
        ? const TypeResult<TypeExpression>.success(AnyType())
        : codec.decodeExpression(value.upperBounds.first);
    final variance = switch (value.variance) {
      wire.TypeVariance.invariant => TypeVariance.invariant,
      wire.TypeVariance.covariant_ => TypeVariance.covariant,
      wire.TypeVariance.contravariant => TypeVariance.contravariant,
      _ => null,
    };

    if (variance == null) return invalidWire("Unknown type variance");
    return bound.mapValue(
      (value) =>
          TypeParameter(name: parameterName, bound: value, variance: variance),
    );
  }
}

extension on NominalTypeKind {
  wire.TypeDefinitionKind get _encodeWire => switch (this) {
    NominalTypeKind.concrete => wire.TypeDefinitionKind.concrete,
    NominalTypeKind.openAbstract => wire.TypeDefinitionKind.openAbstract,
    NominalTypeKind.sealedAbstract => wire.TypeDefinitionKind.sealedAbstract,
  };
}

extension on wire.TypeDefinitionKind {
  TypeResult<NominalTypeKind> _decodeDomain() => switch (this) {
    wire.TypeDefinitionKind.concrete => const TypeResult.success(
      NominalTypeKind.concrete,
    ),
    wire.TypeDefinitionKind.openAbstract => const TypeResult.success(
      NominalTypeKind.openAbstract,
    ),
    wire.TypeDefinitionKind.sealedAbstract => const TypeResult.success(
      NominalTypeKind.sealedAbstract,
    ),
    _ => invalidWire("Unknown nominal type kind"),
  };
}

extension on TypeId {
  String get _defaultOwner => switch (this) {
    OptionTypeId() || SomeTypeId() || NoneTypeId() => "builtin",
    DeclaredTypeId(:final uuid) => uuid,
    QualifiedTypeId(:final namespace) => namespace,
  };
}

extension on PresentationId {
  wire.PresentationId get _encodeWire =>
      wire.PresentationId(namespace: namespace, name: name);
}

extension on wire.PresentationId {
  TypeResult<PresentationId> _decodeDomain() {
    return namespace.isNotEmpty && name.isNotEmpty
        ? TypeResult.success(PresentationId(namespace: namespace, name: name))
        : invalidWire("Presentation id is not qualified");
  }
}
