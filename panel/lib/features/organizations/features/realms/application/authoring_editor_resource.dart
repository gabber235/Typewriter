part of "authoring_session.dart";

typedef AuthoringContribution = ({
  CatalogGeneration generation,
  List<skir.AuthoringOperation> operations,
});

abstract class AuthoringEditorResource implements EditableResource {
  const AuthoringEditorResource(this.repository, this.id);

  final AuthoringResourceRepository repository;
  final skir.ResourceId id;

  skir.GraphSelection get selection => skir.GraphSelection(
    key: "resource:${id.value}",
    seed: skir.ResourceSeed.createIds(values: [id], requireAssignableTo: null),
    steps: const [],
  );

  @override
  EditorResourceKey get key => EditorResourceKey(
    scope: EditorResourceScope(
      organizationId: repository.organization,
      realmId: repository.realm,
    ),
    identity: id,
  );

  @override
  Set<Object> get reservations => {
    (repository.organization, repository.realm, id),
  };

  FutureOr<EditorSnapshot?> project(skir.AuthoringGraphSnapshot snapshot);

  FutureOr<EditorSnapshot?> projectApplied(
    skir.AuthoringChanged change,
    EditorSnapshot submitted,
  );

  AuthoringContribution operations(
    EditorSnapshot snapshot,
    EditorCommit commit,
  );

  @override
  Future<EditorSnapshot?> refresh() async =>
      project(await repository.fetch(selection));

  @override
  MutationIntent prepare(
    EditorSnapshot snapshot,
    EditorCommit commit,
    void Function(TypedMutationResult) accept,
  ) =>
      CombinedMutation<AuthoringContribution, skir.ApplyAuthoringBatchResponse>(
        combiner: repository.combiner,
        resources: reservations,
        prepare: () =>
            MutationContribution<
              AuthoringContribution,
              skir.ApplyAuthoringBatchResponse
            >(
              operation: operations(snapshot, commit),
              integrate: (result) async {
                switch (result) {
                  case SubmissionConfirmed(:final value) ||
                      SubmissionRejected(
                        response: final skir.ApplyAuthoringBatchResponse value,
                      ):
                    final actual = switch (value) {
                      skir.ApplyAuthoringBatchResponse_appliedWrapper(
                        :final value,
                      ) =>
                        await projectApplied(value, snapshot) ??
                            await refresh(),
                      skir.ApplyAuthoringBatchResponse_conflictWrapper() =>
                        await refresh(),
                      _ => null,
                    };
                    accept(
                      await acceptElementCommit(
                        value,
                        commit,
                        actual?.document,
                      ),
                    );
                  default:
                    break;
                }
              },
            ),
      );
}

class TypedAuthoringEditorResource extends AuthoringEditorResource {
  const TypedAuthoringEditorResource(super.repository, super.id);

  @override
  Future<EditorSnapshot?> project(skir.AuthoringGraphSnapshot snapshot) async {
    final resource = snapshot.resources
        .where((item) => item.id == id)
        .firstOrNull;
    if (resource == null) return null;
    return _snapshot(resource, snapshot.sequence, snapshot.generation);
  }

  @override
  Future<EditorSnapshot?> projectApplied(
    skir.AuthoringChanged change,
    EditorSnapshot submitted,
  ) async {
    for (final item in change.resources) {
      switch (item) {
        case skir.AuthoringResourceChange_upsertWrapper(:final value)
            when value.id == id:
          return _snapshot(value, change.sequence, change.generation);
        case skir.AuthoringResourceChange_removeWrapper(:final value)
            when value == id:
          return null;
        case skir.AuthoringResourceChange_unknown() ||
            skir.AuthoringResourceChange_upsertWrapper() ||
            skir.AuthoringResourceChange_removeWrapper():
      }
    }
    return null;
  }

  @override
  AuthoringContribution operations(
    EditorSnapshot snapshot,
    EditorCommit commit,
  ) {
    final current = snapshot as TypedAuthoringEditorSnapshot;
    return (
      generation: current.codec.catalog.generation,
      operations: [current.codec.encodeCommit(current.resource, commit)],
    );
  }

  Future<TypedAuthoringEditorSnapshot> _snapshot(
    skir.AuthoringResource resource,
    int revision,
    skir.CatalogGeneration generation,
  ) async {
    final rootType = SkirTypeCodec(TypeRegistry(const TypeCatalog([])))
        .decodeReference(resource.content.rootType)
        .valueOrNull;
    if (rootType == null) throw StateError("The resource type is invalid");
    final request = RealmEditorCatalogRequest(types: {rootType});
    final RealmEditorCatalogSnapshot catalog;
    try {
      catalog = await repository.fetchCatalog(generation, request);
    } on Object catch (error) {
      throw EditorContractUnavailableException(
        "The editor contract is unavailable (${error.runtimeType})",
      );
    }
    final codec = TypedAuthoringCodec(catalog);
    final decoded = codec.decodeResource(resource);
    if (decoded case TypeFailure(:final diagnostics)) {
      throw StateError(diagnostics.map((item) => item.message).join("; "));
    }
    return TypedAuthoringEditorSnapshot(
      resource: resource,
      content: decoded.valueOrNull!.content,
      revision: revision,
      codec: codec,
    );
  }
}

final class TypedAuthoringEditorSnapshot extends EditorSnapshot
    implements TypedAuthoringSnapshot, EditorContractSnapshot {
  const TypedAuthoringEditorSnapshot({
    required this.resource,
    required this.content,
    required this.revision,
    required this.codec,
  });

  final skir.AuthoringResource resource;
  final TypedValueEnvelope content;
  final int revision;
  @override
  final TypedAuthoringCodec codec;

  @override
  bool contractCompatibleWith(EditorSnapshot candidate) {
    if (candidate is! TypedAuthoringEditorSnapshot ||
        candidate.content.rootType != content.rootType) {
      return false;
    }
    if (candidate.codec.catalog.generation == codec.catalog.generation) {
      return true;
    }
    return editorCatalogContractsCompatible(
      codec.catalog,
      candidate.codec.catalog,
      RealmEditorCatalogRequest(types: {content.rootType}),
    );
  }

  @override
  skir.AuthoringOperation encodePreviewCommit(EditorCommit commit) =>
      codec.encodeCommit(resource, commit);

  @override
  EditorDocument get document => EditorDocument(
    rootType: NamedType(content.rootType),
    typeCatalog: codec.catalog.catalog,
    confirmedValue: content.rootValue,
    revision: revision,
    mergePolicies: codec.mergePolicies(content.rootType),
    diagnostics: const [],
  );
}
