import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

typedef TypedAuthoringResource = ({
  skir.ResourceId id,
  ResourceDefinitionId definition,
  TypedValueEnvelope content,
});

typedef ResourceIdentity = ({skir.ResourceId id, skir.ResourceId? owner});

typedef TypedPresentationSubject = ({
  TypedValueEnvelope content,
  TypedValueEnvelope descriptor,
  TypedValueEnvelope identityEnvelope,
  ResourceIdentity identity,
});

typedef TypedCatalogPresentationSubject = ({
  ResolvedTypeRef target,
  TypedValueEnvelope descriptor,
  TypedValueEnvelope identity,
});

typedef SubjectPresentationModel = ({
  PresentationModel model,
  PresentationId presentation,
});

extension ResourceDefinitionWireEncoding on ResourceDefinitionId {
  skir.ResourceDefinitionId toWire() => skir.ResourceDefinitionId(value: value);
}

extension ResourceDefinitionWireDecoding on skir.ResourceDefinitionId {
  ResourceDefinitionId toDomain() => ResourceDefinitionId(value);
}

/// Encodes one editor preview as a generic typed resource commit.
///
/// Resource snapshots and element snapshots expose the same Realm commit
/// contract even though element editors add a synthetic placement sibling to
/// their local document.
abstract interface class TypedAuthoringSnapshot {
  TypedAuthoringCodec get codec;

  skir.AuthoringOperation encodePreviewCommit(EditorCommit commit);
}

const resourceIdentityTypeId = TypeId.qualified(
  namespace: "com.typewritermc.library",
  name: "ResourceIdentity",
);

/// Requests the exact catalog closure required to decode wire subjects.
///
/// Root type references are structural protocol data and can be decoded before
/// the matching catalog is available. Values remain undecoded until callers
/// obtain that exact generation snapshot.
TypeResult<RealmEditorCatalogRequest> presentationSubjectCatalogRequest(
  Iterable<skir.PresentationSubject> subjects, {
  Iterable<skir.TypedValueEnvelope> contexts = const [],
}) {
  final types = SkirTypeCodec(TypeRegistry(TypeCatalog([])));
  final decoded = <TypeResult<ResolvedTypeRef>>[
    for (final subject in subjects)
      for (final envelope in [
        subject.content,
        subject.descriptor,
        subject.identity,
      ])
        types.decodeReference(envelope.rootType),
    for (final context in contexts) types.decodeReference(context.rootType),
  ];
  final diagnostics = decoded
      .expand((result) => result.diagnostics)
      .toList(growable: false);
  if (diagnostics.isNotEmpty) return TypeResult.failure(diagnostics);
  return TypeResult.success(
    RealmEditorCatalogRequest(
      types: decoded.map((result) => result.valueOrNull!).toSet(),
    ),
  );
}

/// Decodes and encodes typed authoring values against one pinned catalog.
final class TypedAuthoringCodec {
  TypedAuthoringCodec(this.catalog)
    : registry = TypeRegistry(catalog.catalog),
      _wire = SkirEditorCodec(TypeRegistry(catalog.catalog));

  final RealmEditorCatalogSnapshot catalog;
  final TypeRegistry registry;
  final SkirEditorCodec _wire;

  ResolvedTypeRef requireConcreteRoot(ResourceDefinitionId definition) {
    final accepted = catalog.resourceDefinitions[definition]?.acceptedRoot;
    final root = switch (accepted) {
      NamedType(:final reference) => reference,
      _ => null,
    };
    if (root == null ||
        registry.resolveExact(root).valueOrNull?.isConcrete != true) {
      throw StateError(
        "Resource definition '${definition.value}' requires an explicit concrete root",
      );
    }
    return root;
  }

  skir.AuthoringResource encodeResource(
    skir.ResourceId id,
    ResourceDefinitionId definition,
    TypedValueEnvelope content,
  ) => skir.AuthoringResource(
    id: id,
    definition: definition.toWire(),
    content: encodeEnvelope(content).valueOrNull!,
  );

  bool isResourceType(
    TypedValueEnvelope content,
    ResourceDefinitionId definition,
  ) =>
      catalog.resourceDefinitions[definition]?.acceptedRoot ==
      NamedType(content.rootType);

  TypeResult<TypedValueEnvelope> decodeEnvelope(
    skir.TypedValueEnvelope envelope,
  ) => _combine(
    _wire.decodeType(envelope.rootType),
    _wire.decodeValue(envelope.rootValue),
    (type, value) => TypedValueEnvelope(rootType: type, rootValue: value),
  );

  TypeResult<skir.TypedValueEnvelope> encodeEnvelope(
    TypedValueEnvelope envelope,
  ) => _combine(
    _wire.encodeType(envelope.rootType),
    _wire.encodeValue(envelope.rootValue),
    (type, value) => skir.TypedValueEnvelope(rootType: type, rootValue: value),
  );

  TypeResult<TypedAuthoringResource> decodeResource(
    skir.AuthoringResource resource,
  ) => _mapResult(
    decodeEnvelope(resource.content),
    (content) => (
      id: resource.id,
      definition: resource.definition.toDomain(),
      content: content,
    ),
  );

  TypedAuthoringResource decodeResourceOrThrow(
    skir.AuthoringResource resource,
  ) {
    final decoded = decodeResource(resource);
    if (decoded case TypeFailure(:final diagnostics)) {
      throw StateError(diagnostics.map((item) => item.message).join("; "));
    }
    return decoded.valueOrNull!;
  }

  TypeResult<TypedPresentationSubject> decodeSubject(
    skir.PresentationSubject subject,
  ) => _combine(
    decodeEnvelope(subject.content),
    _combine(
      decodeEnvelope(subject.descriptor),
      _flatMap(
        decodeEnvelope(subject.identity),
        (envelope) => _mapResult(
          _decodeIdentity(envelope),
          (identity) => (envelope, identity),
        ),
      ),
      (descriptor, identity) => (descriptor, identity),
    ),
    (content, rest) => (
      content: content,
      descriptor: rest.$1,
      identityEnvelope: rest.$2.$1,
      identity: rest.$2.$2,
    ),
  );

  TypeResult<TypedCatalogPresentationSubject> decodeCatalogSubject(
    skir.CatalogPresentationSubject subject,
  ) => _combine(
    _wire.decodeType(subject.target),
    _combine(
      decodeEnvelope(subject.descriptor),
      decodeEnvelope(subject.identity),
      (descriptor, identity) => (descriptor, identity),
    ),
    (target, values) =>
        (target: target, descriptor: values.$1, identity: values.$2),
  );

  /// Builds one read only role presentation from its declared subject inputs.
  ///
  /// A role may bind only the names defined by its host contract. Definitions
  /// choose any subset of those names. Authoring results may additionally bind
  /// a typed context supplied by the search host.
  TypeResult<SubjectPresentationModel> subjectPresentation(
    TypedPresentationSubject subject,
    PresentationRole role, {
    TypedValueEnvelope? context,
    Map<PresentationCollectionSourceId, PresentationCollectionSource>
        collections =
        const {},
  }) => _rolePresentation(
    target: subject.content.rootType,
    role: role,
    envelopes: {
      "content": subject.content,
      "descriptor": subject.descriptor,
      "identity": subject.identityEnvelope,
      "context": ?context,
    },
    allowed: role == PresentationRole.authoringResult
        ? const {"content", "descriptor", "identity", "context"}
        : const {"content", "descriptor", "identity"},
    collections: collections,
  );

  TypeResult<SubjectPresentationModel> catalogPresentation(
    TypedCatalogPresentationSubject subject, {
    Map<PresentationCollectionSourceId, PresentationCollectionSource>
        collections =
        const {},
  }) => _rolePresentation(
    target: subject.target,
    role: PresentationRole.catalogOption,
    envelopes: {"descriptor": subject.descriptor, "identity": subject.identity},
    allowed: const {"descriptor", "identity"},
    collections: collections,
  );

  TypeResult<SubjectPresentationModel> _rolePresentation({
    required ResolvedTypeRef target,
    required PresentationRole role,
    required Map<String, TypedValueEnvelope> envelopes,
    required Set<String> allowed,
    required Map<PresentationCollectionSourceId, PresentationCollectionSource>
    collections,
  }) {
    final resolvedRole = registry.resolvePresentationRole(target, role);
    if (resolvedRole case TypeFailure(:final diagnostics)) {
      return TypeResult.failure(diagnostics);
    }
    final presentationId = resolvedRole.valueOrNull!;
    final definition = catalog.presentations[presentationId];
    if (definition == null) {
      return _subjectFailure(
        "Presentation '$presentationId' is missing from the pinned catalog",
        target,
      );
    }
    final names = <String>{};
    final inputs = <BindingId, PresentationInput>{};
    for (final parameter in definition.inputs) {
      if (!names.add(parameter.name)) {
        return _subjectFailure(
          "Presentation '$presentationId' declares duplicate input '${parameter.name}'",
          target,
        );
      }
      if (!allowed.contains(parameter.name)) {
        return _subjectFailure(
          "Presentation '$presentationId' declares unsupported input '${parameter.name}'",
          target,
        );
      }
      final envelope = envelopes[parameter.name];
      if (envelope == null) {
        return _subjectFailure(
          "Presentation '$presentationId' requires unavailable input '${parameter.name}'",
          target,
        );
      }
      final actual = NamedType(envelope.rootType);
      if (!actual.isStructurallyAssignableTo(parameter.type, registry)) {
        return _subjectFailure(
          "Presentation '$presentationId' input '${parameter.name}' has an incompatible type",
          envelope.rootType,
        );
      }
      inputs[parameter.id] = PresentationInput.value(
        type: actual,
        value: EditorValue.ready(envelope.rootValue),
      );
    }
    final requiredCollections = <PresentationCollectionSource>[];
    for (final id in definition.collections.keys) {
      final source = collections[id];
      if (source == null) {
        return _subjectFailure(
          "Presentation '$presentationId' requires unavailable collection '$id'",
          target,
        );
      }
      requiredCollections.add(source);
    }
    return TypeResult.success((
      model: PresentationModel(
        catalog: catalog.catalog,
        inputs: inputs,
        root: definition.root,
        presentations: catalog.presentations.values.toList(),
        collections: PresentationCollections(requiredCollections),
      ),
      presentation: presentationId,
    ));
  }

  TypeFailure<SubjectPresentationModel> _subjectFailure(
    String message,
    ResolvedTypeRef type,
  ) => TypeFailure([
    TypeDiagnostic(
      code: TypeDiagnosticCode.invalidPresentation,
      message: message,
      type: type,
    ),
  ]);

  TypeResult<ResourceIdentity> _decodeIdentity(TypedValueEnvelope envelope) {
    if (envelope.rootType.id != resourceIdentityTypeId) {
      return TypeResult.failure([
        TypeDiagnostic(
          code: TypeDiagnosticCode.invalidValue,
          message: "Presentation subject identity has an unexpected type",
          type: envelope.rootType,
        ),
      ]);
    }
    final validation = envelope.rootValue.validateAgainst(
      NamedType(envelope.rootType),
      registry: registry,
    );
    if (validation.isNotEmpty) return TypeResult.failure(validation);
    final id = DataPath.root.field("id").read(envelope.rootValue).valueOrNull;
    final owner = DataPath.root
        .field("owner")
        .read(envelope.rootValue)
        .valueOrNull;
    if (id is! StringValue) {
      return TypeResult.failure([
        const TypeDiagnostic(
          code: TypeDiagnosticCode.invalidValue,
          message: "Resource identity id is invalid",
        ),
      ]);
    }
    return switch (owner) {
      PolymorphicValue(
        concreteType: ResolvedTypeRef(id: SomeTypeId()),
        value: final RecordValue value,
      )
          when value.fields["value"] is StringValue =>
        TypeResult.success((
          id: skir.ResourceId(value: id.value),
          owner: skir.ResourceId(
            value: (value.fields["value"]! as StringValue).value,
          ),
        )),
      PolymorphicValue(concreteType: ResolvedTypeRef(id: NoneTypeId())) =>
        TypeResult.success((id: skir.ResourceId(value: id.value), owner: null)),
      _ => TypeResult.failure([
        const TypeDiagnostic(
          code: TypeDiagnosticCode.invalidValue,
          message: "Resource identity owner is invalid",
        ),
      ]),
    };
  }

  Map<DataPath, EditorMergePolicy> mergePolicies(ResolvedTypeRef rootType) {
    final definition = registry.definition(rootType);
    if (definition == null) return const {};
    return {
      for (final policy in definition.fieldMergePolicies)
        policy.path: switch (policy.strategy) {
          FieldMergeStrategy.setMembership => EditorMergePolicy.set,
        },
    };
  }

  skir.AuthoringOperation encodeCommit(
    skir.AuthoringResource baseResource,
    EditorCommit commit,
  ) {
    final base =
        decodeEnvelope(baseResource.content).valueOrNull ??
        (throw StateError("The resource content is invalid"));
    final proposed = base.copyWith(rootValue: commit.rootValue);
    final normalizedPaths = <DataPath>{
      for (final path in commit.changedPaths)
        _normalizeChangedPath(path, base.rootType),
    };
    final proposedResource = baseResource.toMutable()
      ..content = encodeEnvelope(proposed).valueOrNull!;
    return skir.AuthoringOperation.createCommit(
      id: baseResource.id,
      base: baseResource,
      proposed: proposedResource,
      changedPaths: normalizedPaths.map(
        (path) => _wire.encodePath(path).valueOrNull!,
      ),
    );
  }

  DataPath _normalizeChangedPath(DataPath path, ResolvedTypeRef rootType) {
    final policies =
        registry.definition(rootType)?.fieldMergePolicies ?? const [];
    for (final policy in policies) {
      if (path.isAtOrBelow(policy.path)) return policy.path;
    }
    return path;
  }
}

TypeResult<R> _mapResult<T, R>(
  TypeResult<T> result,
  R Function(T value) convert,
) => switch (result) {
  TypeSuccess(:final value) => TypeResult.success(convert(value)),
  TypeFailure(:final diagnostics) => TypeResult.failure(diagnostics),
};

TypeResult<R> _flatMap<T, R>(
  TypeResult<T> result,
  TypeResult<R> Function(T value) convert,
) => switch (result) {
  TypeSuccess(:final value) => convert(value),
  TypeFailure(:final diagnostics) => TypeResult.failure(diagnostics),
};

TypeResult<R> _combine<A, B, R>(
  TypeResult<A> first,
  TypeResult<B> second,
  R Function(A first, B second) combine,
) {
  final diagnostics = [...first.diagnostics, ...second.diagnostics];
  if (diagnostics.isNotEmpty) return TypeResult.failure(diagnostics);
  return TypeResult.success(
    combine(first.valueOrNull as A, second.valueOrNull as B),
  );
}
