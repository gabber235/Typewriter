import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

void main() {
  test(
    "Book selection keeps inspection separate from resource operation policy",
    () async {
      final book = Book(
        bookId: skir.ResourceId(value: "book:test"),
        title: "Test Book",
        icon: "mdi:book",
        color: Colors.blue,
        tagIds: const [],
      );
      final document = fixtureAuthoringDocument(books: [book]);
      final transport = ScriptedAuthoringTransport(AsyncData(document));
      final workspace = RealmEditing(
        persistence: transport.persistence,
        submissions: _workSession(),
        initial: document,
      );
      addTearDown(workspace.dispose);
      final selection = AuthoringSelectableResource(
        id: AuthoringResourceIdentifier(
          organizationId: skir.recordId("organization:test"),
          realmId: skir.recordId("realm:test"),
          resourceId: book.bookId,
        ),
        resource: document.entry(book.bookId)!,
        appearance: document.catalog.appearanceOf(
          document.entry(book.bookId)!.content,
        ),
        workspace: workspace,
        commands: fixtureAuthoringCommands(transport),
      );
      final owners = InspectionBindings();
      addTearDown(owners.dispose);

      final inspection = selection.buildInspection(owners);

      expect(inspection.body, isA<AuthoredResourceInspection>());
      expect(inspection.host, isNull);
      expect(selection.capabilities, isEmpty);
      expect(workspace.document.entry(book.bookId), isNotNull);
    },
  );

  test("Tag selection opens the shared authored inspector", () async {
    final tag = Tag(
      tagId: skir.ResourceId(value: "tag:test"),
      name: "Test Tag",
      color: Colors.blue,
      parentIds: const [],
      placement: GraphPlacement(x: 0, y: 0, width: 4, height: 1),
    );
    final document = fixtureAuthoringDocument(tags: [tag]);
    final transport = ScriptedAuthoringTransport(AsyncData(document));
    final workspace = RealmEditing(
      persistence: transport.persistence,
      submissions: _workSession(),
      initial: document,
    );
    addTearDown(workspace.dispose);
    final selection = AuthoringSelectableResource(
      id: AuthoringResourceIdentifier(
        organizationId: skir.recordId("organization:test"),
        realmId: skir.recordId("realm:test"),
        resourceId: tag.tagId,
      ),
      resource: document.entry(tag.tagId)!,
      appearance: document.catalog.appearanceOf(
        document.entry(tag.tagId)!.content,
      ),
      workspace: workspace,
      commands: fixtureAuthoringCommands(transport),
    );
    final owners = InspectionBindings();
    addTearDown(owners.dispose);

    final inspection = selection.buildInspection(owners);

    expect(inspection.body, isA<AuthoredResourceInspection>());
    expect(inspection.host, isNull);
    expect(selection.capabilities, isEmpty);
    expect(workspace.document.entry(tag.tagId), isNotNull);
  });
}

ScopedWorkSession _workSession() {
  final session = ScopedWorkSession();
  addTearDown(session.dispose);
  return session;
}
