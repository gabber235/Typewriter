import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/core/pump_panel.dart";
import "package:typewriter_testkit/src/drivers/mutations/save_activity_driver.dart";
import "package:typewriter_testkit/src/drivers/panel_driver.dart";
import "package:typewriter_testkit/src/shared/editing/value_editing_fixture.dart";
import "package:typewriter_testkit/src/shared/editors/editor_fixture.dart";
import "package:typewriter_testkit/src/support/value_editing_fixtures.dart";

/// A work session that ends with the current test.
ScopedWorkSession testWorkSession() {
  final work = ScopedWorkSession();
  addTearDown(work.dispose);
  return work;
}

/// Saves that run through a work session, the way a page action submits.
extension SubmitWork on ScopedWorkSession {
  /// Tracks and runs a submission [label] identified by [id] whose send
  /// answers [result].
  Future<void> submit<T>(
    String label,
    SubmissionResult<T> result, {
    Object id = "submission",
  }) async {
    final submission = MutationSubmission<T>(
      id: id,
      label: label,
      send: () async => result,
    );
    track(submission);
    await submission.run();
  }
}

/// The text field `target` of the resource [label], "paper@*" when saved,
/// edited in [work] to [draft] and saved under [policy] through [commit].
/// The resource stays leased until the test ends.
ValueEditing editedResource(
  ScopedWorkSession work,
  String label, {
  required Future<TypedMutationResult> Function(EditorCommit commit) commit,
  required String draft,
  EditorCommitPolicy policy = EditorCommitPolicy.applyResource,
}) {
  final key = EditorResourceKey(scope: "test", identity: label);
  final source = fakeEditorTarget(
    targetId: key.identity,
    scope: key.scope,
    label: label,
    document: recordEditorDocument(
      {"target": skir.DataValue.wrapStringValue("paper@*")},
      {"target": skir.TypeTemplate.wrapScalar(skir.ScalarKind.text)},
      1,
    ),
    validation: acceptTestEditorMutation,
    commitPolicy: policy,
    commit: commit,
  ).acquire(work);
  addTearDown(work.lease(WorkDriverId(domain: "value", scope: key)).release);
  source.update(
    editorRootPath.field("target"),
    skir.DataValue.wrapStringValue(draft),
  );
  return source;
}

/// Holds the value lease of [key] in [work] until the test ends, the way an
/// open editor keeps its resource.
void holdValueLease(ScopedWorkSession work, EditorResourceKey key) =>
    addTearDown(work.lease(WorkDriverId(domain: "value", scope: key)).release);

/// A record whose text fields title and description hold [title] and
/// [description], at [revision].
EditorDocument titledRecordDocument({
  String title = "Original",
  String description = "Original description",
  int revision = 1,
}) => recordEditorDocument(
  {
    "title": skir.DataValue.wrapStringValue(title),
    "description": skir.DataValue.wrapStringValue(description),
  },
  {
    "title": skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
    "description": skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
  },
  revision,
);

/// Confirms every save at the revision after the one it expected.
Future<TypedMutationResult> confirmNextRevision(EditorCommit commit) async =>
    MutationSuccess(
      revision: commit.expectedRevision + 1,
      value: commit.rootValue,
    );

/// The resource [key], labeled "Resource", holding [document] and saved
/// through [commit] under [commitPolicy].
ValueEditingRegistration resourceTarget(
  EditorResourceKey key, {
  required EditorDocument document,
  EditorCommitter commit = confirmNextRevision,
  EditorCommitPolicy commitPolicy = EditorCommitPolicy.applyResource,
  EditorMutationValidator validation = acceptTestEditorMutation,
  List<EditorDiagnostic> Function(skir.DataValue)? validateDraft,
  String? contract,
}) => fakeEditorTarget(
  targetId: key.identity,
  scope: key.scope,
  label: "Resource",
  document: document,
  commit: commit,
  commitPolicy: commitPolicy,
  validation: validation,
  validateDraft: validateDraft,
  contract: contract,
);

/// The target [id] in the scope "realm", labeled [id], over [document];
/// its saves succeed at revision 2.
ValueEditingRegistration realmTarget(String id, EditorDocument document) =>
    fakeEditorTarget(
      targetId: id,
      label: id,
      scope: "realm",
      document: document,
      commit: (commit) async =>
          MutationSuccess(revision: 2, value: commit.rootValue),
    );

/// The [resourceTarget] for [key], acquired in [work] and leased there until
/// the test ends, the way an open editor holds it.
ValueEditing heldResource(
  ScopedWorkSession work,
  EditorResourceKey key, {
  required EditorDocument document,
  EditorCommitter commit = confirmNextRevision,
  EditorCommitPolicy commitPolicy = EditorCommitPolicy.applyResource,
  EditorMutationValidator validation = acceptTestEditorMutation,
  List<EditorDiagnostic> Function(skir.DataValue)? validateDraft,
  String? contract,
}) {
  final editing = resourceTarget(
    key,
    document: document,
    commit: commit,
    commitPolicy: commitPolicy,
    validation: validation,
    validateDraft: validateDraft,
    contract: contract,
  ).acquire(work);
  holdValueLease(work, key);
  return editing;
}

/// The local work scope of the user `user` in the organization
/// `organization:[organization]`, or outside every organization when null.
LocalWorkScope workScopeIn(String? organization) => LocalWorkScope(
  userId: "user",
  organizationId: organization == null
      ? null
      : skir.recordId("organization:$organization"),
);

/// The local work the panel lists.
extension ListedWork on ProviderContainer {
  /// The labels of the work the panel lists, in its order.
  List<String> get listedWork => [
    for (final entry in read(localWorkProvider).entries.values) entry.label,
  ];
}

/// A draft in [work] of the text resource [targetId] read as [label], saved
/// as [saved] and edited to [draft]; its saves succeed at revision 2. The
/// resource stays leased until the test ends.
ValueEditing textDraft(
  ScopedWorkSession work,
  Object targetId, {
  required String label,
  required String draft,
  String saved = "Original",
  Object? scope,
}) {
  final registration = textEditorTarget(
    targetId,
    label: label,
    scope: scope,
    value: saved,
    commit: (change) async =>
        MutationSuccess(revision: 2, value: change.rootValue),
  );
  final source = registration.acquire(work);
  addTearDown(
    work
        .lease(
          WorkDriverId(domain: "value", scope: registration.persistence.key),
        )
        .release,
  );
  source.update(editorRootPath, skir.DataValue.wrapStringValue(draft));
  return source;
}

/// A fresh work session whose resource [label], edited to "unsupported",
/// already failed to save with [diagnostics].
Future<ScopedWorkSession> rejectedWork(
  String label,
  List<EditorDiagnostic> diagnostics,
) async {
  final work = testWorkSession();
  final source = editedResource(
    work,
    label,
    draft: "unsupported",
    commit: (_) async => MutationInvalid(diagnostics),
  );
  expect(await source.flush(), isA<MutationInvalid>());
  return work;
}

/// Where work in the panel leads back to.
extension WorkDestinations on PanelDriver {
  /// The inspector of [identity] on the route the panel shows now, as the
  /// destination of work made there. Whoever holds it disposes it.
  InspectorDestination inspectorDestination(Object identity) =>
      InspectorDestination(
        container: container,
        router: container.read(appRouterProvider),
        path: path,
        identity: identity,
      );
}

/// The save activity of one draft that leads back to its resource.
extension OpenDraftActivity on WidgetTester {
  /// Pumps the save activity of a fresh work session whose one text draft of
  /// [resource] reads "Host configuration", saved as "original" and edited
  /// to "draft". The draft leads back to [resource]'s inspector, and the
  /// activity's "1 draft" list is open.
  Future<({PanelDriver panel, ValueEditing draft})> openDraftActivity(
    ServiceIdentifier resource,
  ) async {
    final work = testWorkSession();
    final draft = textDraft(
      work,
      resource,
      label: "Host configuration",
      saved: "original",
      draft: "draft",
    );
    final panel = await pumpPanel(const [], at: saveActivityOf(work));
    work.setDestination(
      WorkDriverId(
        domain: "value",
        scope: EditorResourceKey(scope: null, identity: resource.resourceId),
      ),
      panel.inspectorDestination(resource),
    );
    await panel.activity.open("1 draft");
    return (panel: panel, draft: draft);
  }
}
