import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

final _document = EditorDocument(
  rootType: skir.TypeUse.wrapScalar(skir.ScalarKind.text),
  catalog: CheckedEditorCatalog(skir.EditorCatalog.defaultInstance),
  confirmedValue: skir.DataValue.wrapStringValue("Original"),
  revision: 1,
);

void main() {
  test("disposing a value view preserves its leased owner", () {
    final session = ScopedWorkSession();
    addTearDown(session.dispose);
    final bindings = InspectionBindings(workspace: session);
    addTearDown(bindings.dispose);
    final owner = bindings.editor(
      fakeEditorTarget(
        targetId: "first",
        label: "first",
        scope: "realm",
        document: _document,
        commit: (commit) async =>
            MutationSuccess(revision: 2, value: commit.rootValue),
      ),
    )..dispose();
    expect(owner.workspace.closed, isFalse);
    expect(
      owner.update(editorRootPath, skir.DataValue.wrapStringValue("Draft")),
      isA<AppliedEditorMutation>(),
    );
    owner.workspace.discard(owner.groupId);
    bindings.dispose();
    expect(owner.workspace.closed, isTrue);
  });
  test("two views of the same target share one draft", () {
    final session = ScopedWorkSession();
    addTearDown(session.dispose);
    final bindings = InspectionBindings(workspace: session);
    addTearDown(bindings.dispose);
    final first = bindings.beginRefresh();
    final editing = first.editor(
      fakeEditorTarget(
        targetId: "first",
        label: "first",
        scope: "realm",
        document: _document,
        commit: (commit) async =>
            MutationSuccess(revision: 2, value: commit.rootValue),
      ),
    );
    final reading = first.editor(
      fakeEditorTarget(
        targetId: "first",
        label: "first",
        scope: "realm",
        document: _document,
        commit: (commit) async =>
            MutationSuccess(revision: 2, value: commit.rootValue),
      ),
    );
    editing.update(editorRootPath, skir.DataValue.wrapStringValue("Draft"));
    expect(
      reading.value(editorRootPath).valueOrNull,
      skir.DataValue.wrapStringValue("Draft"),
    );
    first.commit();

    final second = bindings.beginRefresh();
    final refreshed = second.editor(
      fakeEditorTarget(
        targetId: "first",
        label: "first",
        scope: "realm",
        document: _document,
        commit: (commit) async =>
            MutationSuccess(revision: 2, value: commit.rootValue),
      ),
    );
    second.commit();
    expect(
      refreshed.value(editorRootPath).valueOrNull,
      skir.DataValue.wrapStringValue("Draft"),
    );
    expect(refreshed.workspace.closed, isFalse);

    refreshed.discardDraft();
    bindings.dispose();
    expect(refreshed.workspace.closed, isTrue);
  });
  test("rollback preserves the installed view and disposes prospective destinations", () {
    final session = ScopedWorkSession();
    addTearDown(session.dispose);
    final bindings = InspectionBindings(workspace: session);
    addTearDown(bindings.dispose);
    final destinations = <String, List<FakeWorkDestination>>{};
    bindings.destinationFor = (identity) {
      final destination = FakeWorkDestination();
      destinations.putIfAbsent(identity as String, () => []).add(destination);
      return destination;
    };
    final installed = bindings.beginRefresh();
    final first = installed.editor(
      fakeEditorTarget(
        targetId: "first",
        label: "first",
        scope: "realm",
        document: _document,
        commit: (commit) async =>
            MutationSuccess(revision: 2, value: commit.rootValue),
      ),
    );
    installed.commit();
    final next = bindings.beginRefresh()
      ..editor(
        fakeEditorTarget(
          targetId: "first",
          label: "first",
          scope: "realm",
          document: _document,
          commit: (commit) async =>
              MutationSuccess(revision: 2, value: commit.rootValue),
        ),
      );
    final abandoned = next.editor(
      fakeEditorTarget(
        targetId: "second",
        label: "second",
        scope: "realm",
        document: _document,
        commit: (commit) async =>
            MutationSuccess(revision: 2, value: commit.rootValue),
      ),
    );
    next.rollback();
    expect(first.workspace.closed, isFalse);
    expect(abandoned.workspace.closed, isTrue);
    expect(destinations["first"]!.first.disposed, isFalse);
    expect(destinations["first"]!.last.disposed, isTrue);
    expect(destinations["second"]!.single.disposed, isTrue);
    bindings.dispose();
    expect(destinations["first"]!.first.disposed, isTrue);
  });
  test("replacement closes clean work and retains pending work", () {
    final session = ScopedWorkSession();
    addTearDown(session.dispose);
    final bindings = InspectionBindings(workspace: session);
    addTearDown(bindings.dispose);
    final initial = bindings.beginRefresh();
    final clean = initial.editor(
      fakeEditorTarget(
        targetId: "clean",
        label: "clean",
        scope: "realm",
        document: _document,
        commit: (commit) async =>
            MutationSuccess(revision: 2, value: commit.rootValue),
      ),
    );
    final dirty = initial.editor(
      fakeEditorTarget(
        targetId: "dirty",
        label: "dirty",
        scope: "realm",
        document: _document,
        commit: (commit) async =>
            MutationSuccess(revision: 2, value: commit.rootValue),
      ),
    )..update(editorRootPath, skir.DataValue.wrapStringValue("Draft"));
    initial.commit();
    final next = bindings.beginRefresh();
    final replacement = next.editor(
      fakeEditorTarget(
        targetId: "replacement",
        label: "replacement",
        scope: "realm",
        document: _document,
        commit: (commit) async =>
            MutationSuccess(revision: 2, value: commit.rootValue),
      ),
    );
    next.commit();
    expect(clean.workspace.closed, isTrue);
    expect(dirty.workspace.closed, isFalse);
    expect(replacement.workspace.closed, isFalse);
    bindings.dispose();
    expect(replacement.workspace.closed, isTrue);
    expect(dirty.workspace.closed, isFalse);
    dirty.discardDraft();
    expect(dirty.hasWork, isFalse);
  });
  test("commit replaces the retained destination", () {
    final session = ScopedWorkSession();
    addTearDown(session.dispose);
    final bindings = InspectionBindings(workspace: session);
    addTearDown(bindings.dispose);
    final destinations = <FakeWorkDestination>[];
    bindings.destinationFor = (_) {
      final value = FakeWorkDestination();
      destinations.add(value);
      return value;
    };
    bindings.beginRefresh()
      ..editor(
        fakeEditorTarget(
          targetId: "first",
          label: "first",
          scope: "realm",
          document: _document,
          commit: (commit) async =>
              MutationSuccess(revision: 2, value: commit.rootValue),
        ),
      )
      ..commit();
    bindings.beginRefresh()
      ..editor(
        fakeEditorTarget(
          targetId: "first",
          label: "first",
          scope: "realm",
          document: _document,
          commit: (commit) async =>
              MutationSuccess(revision: 2, value: commit.rootValue),
        ),
      )
      ..commit();
    expect(destinations.first.disposed, isTrue);
    expect(destinations.last.disposed, isFalse);
    bindings.dispose();
    expect(destinations.last.disposed, isTrue);
  });
  test("dispose closes the work of an active refresh", () {
    final session = ScopedWorkSession();
    addTearDown(session.dispose);
    final bindings = InspectionBindings(workspace: session);
    final prospective = bindings.beginRefresh().editor(
      fakeEditorTarget(
        targetId: "prospective",
        label: "prospective",
        scope: "realm",
        document: _document,
        commit: (commit) async =>
            MutationSuccess(revision: 2, value: commit.rootValue),
      ),
    );
    bindings.dispose();
    expect(prospective.workspace.closed, isTrue);
  });
  test("a refresh cannot begin while another is active", () {
    final session = ScopedWorkSession();
    addTearDown(session.dispose);
    final bindings = InspectionBindings(workspace: session);
    addTearDown(bindings.dispose);
    bindings.beginRefresh();
    expect(bindings.beginRefresh, throwsStateError);
  });
}
