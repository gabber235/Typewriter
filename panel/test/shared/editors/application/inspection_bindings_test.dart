import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

ValueEditingRegistration _target(String id) => fakeEditorTarget(
  targetId: id,
  label: id,
  scope: "realm",
  document: EditorDocument(
    rootType: skir.TypeUse.wrapScalar(skir.ScalarKind.text),
    catalog: CheckedEditorCatalog(
      skir.EditorCatalogWireSnapshot.defaultInstance,
    ),
    confirmedValue: skir.DataValue.wrapStringValue("Original"),
    revision: 1,
  ),
  validation: acceptTestEditorMutation,
  commit: (commit) async =>
      MutationSuccess(revision: 2, value: commit.rootValue),
);

final class _Destination extends WorkDestination {
  bool disposed = false;

  @override
  bool get isCurrent => false;

  @override
  Future<void> open() async {}

  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }
}

void main() {
  test("disposing a value view preserves its leased owner", () {
    final session = ScopedWorkSession();
    addTearDown(session.dispose);
    final bindings = InspectionBindings(workspace: session);
    addTearDown(bindings.dispose);
    final owner = bindings.editor(_target("first"));
    owner.dispose();
    expect(owner.workspace.closed, isFalse);
    expect(
      owner.update(editorRootPath, skir.DataValue.wrapStringValue("Draft")),
      isA<AppliedEditorMutation>(),
    );
    owner.workspace.discard(owner.groupId);
    bindings.dispose();
    expect(owner.workspace.closed, isTrue);
  });
  test("duplicate view acquisition shares one workspace and releases once", () {
    final session = ScopedWorkSession();
    addTearDown(session.dispose);
    final bindings = InspectionBindings(workspace: session);
    addTearDown(bindings.dispose);
    final first = bindings.beginRefresh();
    final owner = first.editor(_target("first"));
    expect(first.editor(_target("first")), same(owner));
    first.commit();
    final second = bindings.beginRefresh();
    expect(second.editor(_target("first")).workspace, same(owner.workspace));
    second.commit();
    expect(owner.workspace.closed, isFalse);
    bindings.dispose();
    expect(owner.workspace.closed, isTrue);
  });
  test("rollback preserves the installed view and disposes prospective destinations", () {
    final session = ScopedWorkSession();
    addTearDown(session.dispose);
    final bindings = InspectionBindings(workspace: session);
    addTearDown(bindings.dispose);
    final destinations = <String, List<_Destination>>{};
    bindings.destinationFor = (identity) {
      final destination = _Destination();
      destinations.putIfAbsent(identity as String, () => []).add(destination);
      return destination;
    };
    final installed = bindings.beginRefresh();
    final first = installed.editor(_target("first"));
    installed.commit();
    final next = bindings.beginRefresh();
    next.editor(_target("first"));
    final abandoned = next.editor(_target("second"));
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
    final clean = initial.editor(_target("clean"));
    final dirty = initial.editor(_target("dirty"));
    dirty.update(editorRootPath, skir.DataValue.wrapStringValue("Draft"));
    initial.commit();
    final next = bindings.beginRefresh();
    final replacement = next.editor(_target("replacement"));
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
    final destinations = <_Destination>[];
    bindings.destinationFor = (_) {
      final value = _Destination();
      destinations.add(value);
      return value;
    };
    bindings.beginRefresh()
      ..editor(_target("first"))
      ..commit();
    bindings.beginRefresh()
      ..editor(_target("first"))
      ..commit();
    expect(destinations.first.disposed, isTrue);
    expect(destinations.last.disposed, isFalse);
    bindings.dispose();
    expect(destinations.last.disposed, isTrue);
  });
  test("dispose rolls back an active refresh and rejects nested refreshes", () {
    final session = ScopedWorkSession();
    addTearDown(session.dispose);
    final bindings = InspectionBindings(workspace: session);
    final owner = bindings.beginRefresh().editor(_target("prospective"));
    expect(bindings.beginRefresh, throwsStateError);
    bindings.dispose();
    expect(owner.workspace.closed, isTrue);
  });
}
