import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "value_editing_registration.freezed.dart";

typedef PortablePresentationHostBuilder = PortablePresentationHost Function(
  ValueEditing owner,
);

/// Reconnects transient editor views to the value driver retained by local work.
///
/// [persistence] supplies the stable resource key. Acquiring the registration
/// reuses that driver and admits the latest snapshot, so rebuilding an inspector
/// does not create a second draft. The session owns the driver and observation
/// subscription; presentation hosts are created for their individual views.
@freezed
abstract class ValueEditingRegistration with _$ValueEditingRegistration {
  const factory ValueEditingRegistration({
    required Object targetId,
    required String label,
    required ValueEditPersistence persistence,
    required EditorSnapshot snapshot,
    @Default(EditorCommitPolicy.autosaveChanges)
    EditorCommitPolicy commitPolicy,
    @Default(EditObservationAdmission.rebase)
    EditObservationAdmission observations,
    PortablePresentationHostBuilder? portablePresentation,
    VoidCallback Function(EditingWorkspace<ValueEditDocument, ValueEdit>)?
    observe,
  }) = _ValueEditingRegistration;
  const ValueEditingRegistration._();
  WorkDriverId get driverId =>
      WorkDriverId(domain: "value", scope: persistence.key);
  EditorDocument get document => snapshot.document;
  EditorValue value(skir.ValuePath path) =>
      document.confirmedValue.readEditorValue(path);
  EditorMutationResult validate(skir.ValuePath path, skir.DataValue value) =>
      snapshot.validate(path, value);
  List<EditorDiagnostic> validateDraft(skir.DataValue value) =>
      snapshot.validateDraft(value);
  PortablePresentationHost? buildPortablePresentationHost(ValueEditing owner) =>
      portablePresentation?.call(owner);

  /// Returns a view of the session owned driver without acquiring a view lease.
  /// Callers retaining the view must separately lease [driverId] in [session].
  ValueEditing acquire(LocalWorkCommands session) {
    final driver = session
        .getOrRegister<EditingWorkDriver<ValueEditDocument, ValueEdit>>(
          driverId,
          () {
            final owner = EditingWorkspace<ValueEditDocument, ValueEdit>(
              model: const ValueEditModel(),
              persistence: persistence,
              submissions: session,
              initial: ValueEditDocument.fromSnapshot(
                snapshot,
                identity: persistence.key,
              ),
            );
            final group = _groupFor(owner);
            final disposeObservation = observe?.call(owner);
            return EditingWorkDriver<ValueEditDocument, ValueEdit>(
              id: driverId,
              workspace: owner,
              onDispose: disposeObservation,
              projectValues: (state) {
                final paths = {
                  for (final edit in owner.edits(group)) ...edit.paths,
                };
                return paths.isEmpty || state.working == null
                    ? {}
                    : {
                        persistence.key: LocalEditorValue(
                          value: state.working!.value,
                          editedPaths: paths,
                        ),
                      };
              },
            );
          },
        );
    driver.workspace.persistence = persistence;
    final group = _groupFor(driver.workspace);
    driver.reviewFactory = portablePresentation == null
        ? null
        : (id) {
            final owner = ValueEditing.fromWorkspace(driver.workspace, id);
            final host = buildPortablePresentationHost(owner);
            return host == null
                ? null
                : WorkReviewContent(
                    body: PortablePresentationRenderer(
                      key: ValueKey(targetId),
                      host: host,
                    ),
                    dispose: host.dispose,
                  );
          };
    driver.workspace.acceptConfirmed(
      ValueEditDocument.fromSnapshot(snapshot, identity: persistence.key),
    );
    return ValueEditing.fromWorkspace(driver.workspace, group);
  }

  EditGroupId _groupFor(EditingWorkspace<ValueEditDocument, ValueEdit> owner) =>
      owner.createGroup(
        label: label,
        key: persistence.key,
        policy: commitPolicy,
        admission: commitPolicy == EditorCommitPolicy.applyResource
            ? EditWriteAdmission.lockWhileSubmitted
            : EditWriteAdmission.allowWhileSubmitted,
        repair: EditRepairAdmission.acceptCorrections,
        observations: observations,
        commits: commitPolicy == EditorCommitPolicy.applyResource
            ? EditCommitAdmission.completeGroup
            : EditCommitAdmission.applicableOperations,
      );
}
