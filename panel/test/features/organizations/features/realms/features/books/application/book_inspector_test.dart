import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

void main() {
  test(
    "Book selection opens and deletes through shared capabilities",
    () async {
      final transport = ScriptedAuthoringTransport(
        AsyncData(fixtureAuthoringDocument()),
      );
      final workspace = AuthoringWorkspace(
        transport: transport,
        initial: transport.observation.requireValue,
      );
      addTearDown(workspace.dispose);
      final book = Book(
        bookId: skir.ResourceId(value: "book:test"),
        title: "Test Book",
        icon: "mdi:book",
        color: Colors.blue,
        tagIds: const [],
      );
      var opened = false;
      var deleted = false;
      final selection = BookSelection(
        onOpen: () => opened = true,
        onDelete: () async => deleted = true,
        id: BookIdentifier(book.bookId),
        book: book,
        workspace: workspace,
        commands: fixtureAuthoringCommands(transport),
      );
      final owners = EditorOwnerRegistry();
      addTearDown(owners.dispose);

      final inspection = selection.buildInspection(owners);

      expect(inspection.body, isA<AuthoredResourceInspection>());
      expect(inspection.host, isNull);
      final open = selection.capabilities.whereType<OpenSelectionCapability>();
      final delete = selection.capabilities
          .whereType<DeleteSelectionCapability>();
      expect(open, hasLength(1));
      expect(delete, hasLength(1));
      await open.single.onOpen();
      await delete.single.onDelete();
      expect(opened, isTrue);
      expect(deleted, isTrue);
    },
  );
}
