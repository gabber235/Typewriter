part of "authoring_session.dart";

/// Adapts one Realm authoring resource to the shared transactional editor.
///
/// The resource owns neither the editor draft nor canonical session state. It
/// supplies the snapshot scope, resource reservation, wire operation, and
/// authoritative response projection that the shared editor persistence layer
/// needs. [AuthoringSession] remains the owner of canonical state, while this
/// adapter makes a resource's accepted value available to its editor owner.
abstract class AuthoringEditorResource implements EditableResource {
  const AuthoringEditorResource(this.repository, this.id);
  final AuthoringResourceRepository repository;
  final skir.RecordId id;
  skir.AuthoringSnapshotScope get scope;
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

  /// Projects the resource from an authoritative snapshot slice.
  ///
  /// A missing resource returns null. Callers treat that result as deletion or
  /// unavailability rather than submitting a draft against stale state.
  FutureOr<EditorSnapshot?> project(skir.AuthoringSnapshot snapshot);

  /// Projects the complete resource returned by an applied authoring batch.
  ///
  /// The response contains resource changes rather than snapshot slices, so
  /// each resource type maps its matching change into its editor snapshot.
  /// The submitted snapshot supplies immutable decoding metadata when needed.
  /// Returning null means the response did not contain this resource and the
  /// caller must perform one authoritative refresh.
  FutureOr<EditorSnapshot?> projectApplied(
    skir.AuthoringChanged change,
    EditorSnapshot submitted,
  );

  /// Converts a captured editor commit into one guarded authoring operation.
  ///
  /// The commit contains the canonical base and the local result. Implementors
  /// must preserve the protocol's expected value checks so concurrent edits are
  /// reported as conflicts instead of being overwritten.
  skir.AuthoringOperation operation(
    EditorSnapshot snapshot,
    EditorCommit commit,
  );

  @override
  Future<EditorSnapshot?> refresh() async =>
      project(await repository.fetch(scope));

  /// Prepares persistence for this resource through the shared mutation owner.
  ///
  /// The response integration first projects an applied change. If the change
  /// does not contain this resource, it refreshes the authoritative scope.
  /// Conflicts always refresh. The resulting typed mutation outcome is passed
  /// to the editor owner; this adapter never promotes a sent draft to canonical
  /// state by itself.
  @override
  MutationIntent prepare(
    EditorSnapshot snapshot,
    EditorCommit commit,
    void Function(TypedMutationResult) accept,
  ) =>
      CombinedMutation<
        skir.AuthoringOperation,
        skir.ApplyAuthoringBatchResponse
      >(
        combiner: repository.combiner,
        resources: reservations,
        prepare: () =>
            MutationContribution<
              skir.AuthoringOperation,
              skir.ApplyAuthoringBatchResponse
            >(
              operation: operation(snapshot, commit),
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
