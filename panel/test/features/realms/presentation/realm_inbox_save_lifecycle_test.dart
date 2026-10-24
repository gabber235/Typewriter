import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../support/publication.dart";
import "../../../support/test_utils.dart";

void main() {
  testWidgets(
    "successful autosaves never become inbox issues while saved values refresh",
    (tester) async {
      final boundary = _SaveBoundary();
      final container = await _mount(tester, boundary);
      final issues = <int>[];
      final subscription = container.listen(
        realmInboxProvider(_scope),
        (_, next) => issues.add(next.issues.length),
        fireImmediately: true,
      );
      addTearDown(subscription.close);
      final editing = container.read(realmEditingProvider(_scope));
      final form = editing.attach(_tag);
      addTearDown(form.detach);

      _rename(form, "Draft");
      await tester.pump(const Duration(milliseconds: 250));
      expect(boundary.requests, hasLength(1));
      expect(form.phase, isA<EditGroupSaving>());
      expect(container.read(realmInboxProvider(_scope)).issues, isEmpty);

      boundary.accept(0);
      await tester.pump();
      await tester.pump();
      expect(boundary.observations, hasLength(1));
      final awaiting = form.phase! as EditGroupCommittedAwaitingRefresh;
      expect(awaiting.cause, isNull);
      expect(awaiting.submitted, isTrue);
      expect(form.saving, isTrue);
      expect(editing.canSave(form.editingGroup), isFalse);
      final pending = container.read(realmInboxProvider(_scope));
      final issueLabelWasVisible = find.text("1 issue").evaluate().isNotEmpty;

      _rename(form, "Later");
      await tester.pump(const Duration(milliseconds: 500));
      expect(boundary.requests, hasLength(1));
      expect(
        form.document.resource(_tag)!.authoredField("name"),
        _text("Later"),
      );
      boundary.observations[0].complete(_document("Draft"));
      await tester.pump();
      expect(
        editing.workspace.confirmed.resource(_tag)!.authoredField("name"),
        _text("Draft"),
      );
      expect(
        form.document.resource(_tag)!.authoredField("name"),
        _text("Later"),
      );

      await tester.pump(const Duration(milliseconds: 250));
      expect(boundary.requests, hasLength(2));
      boundary.accept(1);
      await tester.pump();
      boundary.observations[1].complete(_document("Later"));
      await tester.pump();
      expect(editing.hasPendingWork, isFalse);
      expect(container.read(realmInboxProvider(_scope)).issues, isEmpty);

      expect(
        issueLabelWasVisible,
        isFalse,
        reason: "The inbox must not report an issue during a successful save",
      );
      expect(
        pending.issues,
        isEmpty,
        reason: "An accepted save awaiting its observation is normal progress",
      );
      expect(pending.localWork.single.needsAttention, isFalse);
      expect(pending.localWork.single.saving, isTrue);
      expect(
        pending.localWork.single.phase,
        "Changes were applied. Refreshing saved values",
      );
      expect(issues, everyElement(0));
    },
  );

  testWidgets(
    "a failed refresh remains an inbox issue until observation recovers without resubmitting",
    (tester) async {
      final boundary = _SaveBoundary();
      final container = await _mount(tester, boundary);
      final editing = container.read(realmEditingProvider(_scope));
      final form = editing.attach(_tag);
      addTearDown(form.detach);
      _rename(form, "Draft");
      await tester.pump(const Duration(milliseconds: 250));
      boundary.accept(0);
      await tester.pump();

      final failure = StateError("Saved values could not be refreshed");
      boundary.observations.single.completeError(failure);
      await tester.pump();
      await tester.pump();
      expect(
        (form.phase! as EditGroupCommittedAwaitingRefresh).cause,
        same(failure),
      );
      final failed = container.read(realmInboxProvider(_scope));
      expect(failed.issues, hasLength(1));
      expect(failed.localWork.single.needsAttention, isTrue);
      expect(failed.localWork.single.saving, isFalse);
      expect(form.saving, isFalse);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(find.text("1 issue"), findsOneWidget);
      expect(editing.canSave(form.editingGroup), isFalse);
      expect(editing.canDiscard(form.editingGroup), isFalse);
      expect(editing.canRetry(form.editingGroup), isTrue);

      final recovering = editing.retry(form.editingGroup);
      await tester.pump();
      expect(boundary.requests, hasLength(1));
      expect(boundary.observations, hasLength(2));
      boundary.observations[1].complete(_document("Draft"));
      await recovering;
      await tester.pump();
      await tester.pump();
      expect(boundary.requests, hasLength(1));
      expect(editing.hasPendingWork, isFalse);
      expect(container.read(realmInboxProvider(_scope)).issues, isEmpty);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(find.text("1 issue"), findsNothing);
    },
  );
}

final _scope = AuthoringScope(
  organizationId: skir.recordId("organization:inbox"),
  realmId: skir.recordId("service:inbox"),
);
final _tag = skir.ResourceId(value: "tag:inbox");
final _name = skir.ValueLocation(
  resource: _tag,
  path: editorRootPath.field("name"),
);
skir.DataValue _text(String value) => skir.DataValue.wrapStringValue(value);
AuthoringDocument _document(String name) => fixtureAuthoringDocument(
  realm: true,
  tags: [
    Tag(
      tagId: _tag,
      name: name,
      color: Colors.grey,
      parentIds: const [],
      placement: const GraphPlacement(x: 0, y: 0, width: 7, height: 1),
    ),
  ],
);

void _rename(RealmEditingBinding form, String name) => form
    .edit(label: "Rename tag", apply: (edit) => edit.set(_name, _text(name)))
    .requireAccepted();

Future<ProviderContainer> _mount(
  WidgetTester tester,
  _SaveBoundary boundary,
) async {
  final publication = TestPublicationRepository(
    _scope,
    initial: publicationObservation(readyPublicationStatus()),
  );
  addTearDown(publication.close);
  await tester.pumpTestApp(
    child: Scaffold(body: RealmInboxButton(scope: _scope)),
    overrides: [
      ...authoringFixtureOverrides(
        scope: _scope,
        document: _document("Original"),
        publication: publication,
      ),
      realmEditPersistenceProvider(_scope).overrideWithValue(
        fixtureRealmPersistence(
          commit: boundary.commit,
          confirmed: boundary.observe,
        ),
      ),
      authoringSessionProvider(
        _scope.organizationId,
        _scope.realmId,
      ).overrideWithValue(const AuthoringSessionState()),
    ],
  );
  return ProviderScope.containerOf(
    tester.element(find.byType(RealmInboxButton)),
  );
}

/// Holds external acknowledgments and observations independently.
/// The production workspace, driver, inbox provider, and button remain active.
final class _SaveBoundary {
  final requests = <ScriptedAuthoringRequest>[];
  final observations = <Completer<AuthoringDocument>>[];

  Future<skir.CommitPreparedEditResponse> commit(skir.PreparedEdit edit) {
    final request = ScriptedAuthoringRequest(edit);
    requests.add(request);
    return request.response.future;
  }

  Future<AuthoringDocument> observe() {
    final observation = Completer<AuthoringDocument>();
    observations.add(observation);
    return observation.future;
  }

  void accept(int index) => requests[index].response.complete(
    skir.CommitPreparedEditResponse.committed,
  );
}
