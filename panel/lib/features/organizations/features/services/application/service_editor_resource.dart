part of "services.dart";

/// Creates the confirmed editor snapshot for a service identity.
///
/// Only the editable name enters the document. Revision remains attached to
/// the snapshot so the eventual rename cannot silently overwrite newer data.
extension ServiceEditorSnapshotBuilder on Service {
  EditorSnapshot get editorSnapshot => ServiceEditorSnapshot(this);
}

final class ServiceEditorSnapshot extends EditorSnapshot {
  const ServiceEditorSnapshot(this.service);

  final Service service;

  @override
  EditorDocument get document => EditorDocument(
    rootType: _serviceIdentityType,
    typeCatalog: _serviceIdentityCatalog,
    confirmedValue: service.identityValue,
    revision: service.revision,
  );

  @override
  EditorMutationResult validate(DataPath path, DataValue value) {
    if (path == DataPath.root.field("name") && value is StringValue) {
      return value.value.isValidIdentifier
          ? EditorMutationResult.applied(value)
          : EditorMutationResult.invalid([
              _serviceIdentityDiagnostic(
                "Use at least three lowercase letters or digits separated by underscores",
                path,
              ),
            ]);
    }
    if (path == DataPath.root && value is RecordValue) {
      final name = value.fields["name"];
      if (value.fields.length == 1 &&
          name is StringValue &&
          name.value.isValidIdentifier) {
        return EditorMutationResult.applied(value);
      }
    }
    return EditorMutationResult.invalid([
      _serviceIdentityDiagnostic("The service identity is invalid", path),
    ]);
  }
}

TypeDiagnostic _serviceIdentityDiagnostic(String message, DataPath path) =>
    TypeDiagnostic(
      code: TypeDiagnosticCode.invalidValue,
      message: message,
      path: path,
    );

/// Bridges service identity editing to the organization resource session.
///
/// The resource refreshes canonical service data, validates the drafted name,
/// and translates backend success, conflict, deletion, and validation outcomes
/// into editor results. It never edits runtime topology.
final class ServiceEditorResource implements EditableResource {
  const ServiceEditorResource(this.repository, this.serviceId);
  final ServiceResourceRepository repository;
  final skir.RecordId serviceId;
  @override
  EditorResourceKey get key => EditorResourceKey(
    scope: EditorResourceScope(organizationId: repository.organization),
    identity: serviceId,
  );
  @override
  Set<Object> get reservations => {(repository.organization, serviceId)};
  @override
  Future<EditorSnapshot?> refresh() async {
    final values = await repository.services();
    final service = values.firstWhereOrNull(
      (value) => value.serviceId == serviceId,
    );
    return service?.editorSnapshot;
  }

  @override
  MutationIntent prepare(
    EditorSnapshot snapshot,
    EditorCommit commit,
    void Function(TypedMutationResult) accept,
  ) {
    final name = DataPath.root
        .field("name")
        .read(commit.rootValue)
        .valueOrNull
        ?.asStringOrNull;
    if (name == null || name.trim().isEmpty) {
      throw StateError("Name must not be empty");
    }
    return IndependentMutation(
      PendingCommit(
        resources: reservations,
        prepare: () => repository
            .rename(serviceId, commit.expectedRevision, name)
            .copyWith(
              integrate: (result) async {
                switch (result) {
                  case SubmissionConfirmed(:final value) ||
                      SubmissionRejected(
                        response: final skir.UpdateOrganizationServiceResponse
                        value,
                      ):
                    switch (value) {
                      case skir.UpdateOrganizationServiceResponse_successWrapper(
                        :final value,
                      ):
                        final actual = Service.fromSkir(value);
                        repository.acceptService(actual);
                        accept(
                          MutationSuccess(
                            revision: actual.revision,
                            value: actual.identityValue,
                          ),
                        );
                      case skir.UpdateOrganizationServiceResponse_conflictErrorWrapper(
                        :final value,
                      ):
                        final actual = Service.fromSkir(value.actual);
                        repository.acceptService(actual);
                        accept(
                          MutationConflict(
                            expectedRevision: commit.expectedRevision,
                            actualRevision: actual.revision,
                            actualValue: actual.identityValue,
                          ),
                        );
                      case skir.UpdateOrganizationServiceResponse_serviceNotFoundErrorWrapper():
                        accept(
                          unavailableMutation(
                            "The service was deleted",
                            targetDeleted: true,
                          ),
                        );
                      case skir.UpdateOrganizationServiceResponse_validationErrorWrapper() ||
                          skir.UpdateOrganizationServiceResponse_invalidRecordIdErrorWrapper():
                        accept(
                          invalidMutation(
                            "The service contains invalid values",
                          ),
                        );
                      default:
                        accept(
                          unavailableMutation("The service could not be saved"),
                        );
                    }
                  default:
                    break;
                }
              },
            ),
      ),
    );
  }
}
