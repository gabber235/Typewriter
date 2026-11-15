part of "services.dart";

/// Creates the confirmed editor snapshot for a service identity.
///
/// Only the editable name enters the document. Revision remains attached to
/// the snapshot so the eventual rename cannot silently overwrite newer data.
extension ServiceEditorSnapshotBuilder on skir.Service {
  EditorSnapshot get editorSnapshot => ServiceEditorSnapshot(this);
}

final class ServiceEditorSnapshot extends EditorSnapshot {
  const ServiceEditorSnapshot(this.service);

  final skir.Service service;

  @override
  EditorDocument get document => EditorDocument(
    rootType: _serviceIdentityType,
    catalog: _serviceIdentityCatalog,
    confirmedValue: service.identityValue,
    revision: service.revision,
  );

  @override
  EditorMutationResult validate(skir.ValuePath path, skir.DataValue value) {
    final text = value.authoredString;
    if (path == editorRootPath.field("name") && text != null) {
      return text.isValidIdentifier
          ? EditorMutationResult.applied(value)
          : EditorMutationResult.invalid([
              _serviceIdentityDiagnostic(_serviceNameRule, path),
            ]);
    }
    if (path == editorRootPath) {
      final fields = value.authoredRecord?.fields.toList(growable: false);
      final name = value.editorValueAt(editorRootPath.field("name"));
      if (fields?.length == 1 &&
          name?.authoredString?.isValidIdentifier == true) {
        return EditorMutationResult.applied(value);
      }
    }
    return EditorMutationResult.invalid([
      _serviceIdentityDiagnostic("The service identity is invalid", path),
    ]);
  }
}

/// The rule a service name follows, as the author reads it.
const _serviceNameRule =
    "Use at least three lowercase letters or digits separated by underscores";

EditorDiagnostic _serviceIdentityDiagnostic(
  String message,
  skir.ValuePath path,
) => EditorDiagnostic(
  code: EditorDiagnosticCode.invalidValue,
  message: message,
  path: path,
);

/// Bridges service identity editing to the organization resource session.
///
/// The resource refreshes canonical service data, validates the drafted name,
/// and translates backend success, conflict, deletion, and validation outcomes
/// into editor results. It never edits runtime topology.
final class ServiceEditPersistence extends ValueEditPersistence {
  const ServiceEditPersistence(this.repository, this.serviceId);
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
  Future<EditorSnapshot?> refreshSnapshot() async {
    final values = await repository.services();
    final service = values.firstWhereOrNull(
      (value) => value.serviceId == serviceId,
    );
    return service?.editorSnapshot;
  }

  @override
  PreparedCommit<TypedMutationResult> prepareValue(
    EditorSnapshot snapshot,
    EditorCommit commit,
  ) {
    final name = commit.rootValue
        .editorValueAt(editorRootPath.field("name"))
        ?.authoredString;
    if (name == null || name.trim().isEmpty) {
      throw StateError("Name must not be empty");
    }
    return repository
        .rename(serviceId, commit.expectedRevision, name)
        .mapResponse(
          (response) => switch (response) {
            skir.UpdateOrganizationServicesResponse_successWrapper(
              :final value,
            ) =>
              switch (value.firstWhereOrNull(
                (service) => service.serviceId == serviceId,
              )) {
                final service? => MutationSuccess(
                  revision: service.revision,
                  value: service.requireKnown().identityValue,
                ),
                null => unavailableMutation("The service could not be applied"),
              },
            skir.UpdateOrganizationServicesResponse_refusedErrorWrapper(
              :final value,
            ) =>
              switch (value.firstWhereOrNull(
                (refused) => refused.serviceId == serviceId,
              )) {
                final refused? => refused.reason.mutationResult(
                  commit.expectedRevision,
                ),
                null => unavailableMutation(
                  heldBackReason(
                    name: snapshot.serviceName,
                    noun: "service",
                    done: "renamed",
                  ),
                ),
              },
            _ => unavailableMutation("The service could not be applied"),
          },
        );
  }
}

extension on EditorSnapshot {
  /// The name of the service this snapshot edits, as the author reads it.
  String? get serviceName => switch (this) {
    ServiceEditorSnapshot(:final service) => service.displayName,
    ResultEditorSnapshot(:final delegate) => delegate.serviceName,
    _ => null,
  };
}

extension on skir.ServiceRenameRefusal {
  /// What this refusal means for the rename that received it.
  TypedMutationResult mutationResult(int expectedRevision) => switch (this) {
    skir.ServiceRenameRefusal_conflictErrorWrapper(:final value) =>
      MutationConflict(
        expectedRevision: expectedRevision,
        actualRevision: value.actual.revision,
        actualValue: value.actual.requireKnown().identityValue,
      ),
    skir.ServiceRenameRefusal_serviceNotFoundErrorWrapper() =>
      unavailableMutation("The service was deleted", targetDeleted: true),
    skir.ServiceRenameRefusal_validationErrorWrapper(
      value: skir.ServiceUpdateValidationError.nameInvalid,
    ) =>
      MutationInvalid([
        _serviceIdentityDiagnostic(
          _serviceNameRule,
          editorRootPath.field("name"),
        ),
      ]),
    skir.ServiceRenameRefusal_duplicateErrorWrapper() => invalidMutation(
      "The service was renamed twice in one change",
    ),
    skir.ServiceRenameRefusal_validationErrorWrapper() ||
    skir.ServiceRenameRefusal_invalidRecordIdErrorWrapper() => invalidMutation(
      "The service contains invalid values",
    ),
    skir.ServiceRenameRefusal_unknown() => unavailableMutation(
      "The service could not be applied",
    ),
  };
}
