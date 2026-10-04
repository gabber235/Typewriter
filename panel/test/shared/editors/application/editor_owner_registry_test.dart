import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

ResourceEditorTarget _target(String id) => fakeEditorTarget(
  targetId: id,
  label: id,
  scope: "realm",
  document: const EditorDocument(
    rootType: StringType(),
    typeCatalog: TypeCatalog([]),
    confirmedValue: StringValue("Original"),
    revision: 1,
  ),
  validation: acceptTestEditorMutation,
  commit: (commit) async =>
      MutationSuccess(revision: 2, value: commit.rootValue),
);

EditorResourceKey _key(String id) =>
    EditorResourceKey(scope: "realm", identity: id);

final class _Destination extends EditorDestination {
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
  test("committed refresh retains duplicate acquisition exactly once", () {
    final workspace = LocalWorkSession();
    final registry = EditorOwnerRegistry(workspace: workspace);
    addTearDown(workspace.dispose);
    addTearDown(registry.dispose);

    final first = registry.beginRefresh();
    final source = first.editor(_target("first"));
    expect(identical(first.editor(_target("first")), source), isTrue);
    first.commit();

    expect(workspace.resources[_key("first")]!.leases, 1);

    final second = registry.beginRefresh();
    expect(identical(second.editor(_target("first")), source), isTrue);
    second.commit();

    expect(workspace.resources[_key("first")]!.leases, 1);
  });

  test("rolled back refresh preserves installed lease and destination", () {
    final workspace = LocalWorkSession();
    final registry = EditorOwnerRegistry(workspace: workspace);
    addTearDown(workspace.dispose);
    addTearDown(registry.dispose);
    final destinations = <String, List<_Destination>>{};
    registry.destinationFor = (identity) {
      final key = identity as String;
      final destination = _Destination();
      destinations.putIfAbsent(key, () => []).add(destination);
      return destination;
    };

    registry.beginRefresh()
      ..editor(_target("first"))
      ..commit();
    final originalDestination = destinations["first"]!.single;

    final prospective = registry.beginRefresh()
      ..editor(_target("first"))
      ..editor(_target("second"));
    final prospectiveDestination = destinations["first"]!.last;
    final abandonedDestination = destinations["second"]!.single;
    prospective.rollback();

    expect(workspace.resources[_key("first")]!.leases, 1);
    expect(
      workspace.resources[_key("first")]!.destination,
      same(originalDestination),
    );
    expect(originalDestination.disposed, isFalse);
    expect(prospectiveDestination.disposed, isTrue);
    expect(abandonedDestination.disposed, isTrue);
    expect(workspace.resources[_key("second")], isNull);
  });

  test("committed replacement releases the previous owner", () {
    final workspace = LocalWorkSession();
    final registry = EditorOwnerRegistry(workspace: workspace);
    addTearDown(workspace.dispose);
    addTearDown(registry.dispose);

    registry.beginRefresh()
      ..editor(_target("first"))
      ..commit();

    registry.beginRefresh()
      ..editor(_target("second"))
      ..commit();

    expect(workspace.resources[_key("first")], isNull);
    expect(workspace.resources[_key("second")]!.leases, 1);
  });

  test("committed refresh replaces the retained destination", () {
    final workspace = LocalWorkSession();
    final registry = EditorOwnerRegistry(workspace: workspace);
    addTearDown(workspace.dispose);
    addTearDown(registry.dispose);
    final destinations = <_Destination>[];
    registry.destinationFor = (_) {
      final destination = _Destination();
      destinations.add(destination);
      return destination;
    };

    registry.beginRefresh()
      ..editor(_target("first"))
      ..commit();
    registry.beginRefresh()
      ..editor(_target("first"))
      ..commit();

    expect(destinations, hasLength(2));
    expect(destinations.first.disposed, isTrue);
    expect(workspace.resources[_key("first")]!.destination, destinations.last);
  });

  test("nested refresh is rejected and dispose rolls back active work", () {
    final workspace = LocalWorkSession();
    final registry = EditorOwnerRegistry(workspace: workspace);
    addTearDown(workspace.dispose);

    registry.beginRefresh().editor(_target("prospective"));
    expect(registry.beginRefresh, throwsStateError);

    registry.dispose();

    expect(workspace.resources[_key("prospective")], isNull);
  });
}
