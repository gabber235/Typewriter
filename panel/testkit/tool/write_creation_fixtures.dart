/// Writes the panel creation fixtures the Realm commits in
/// `PanelCreationCommitTest`: the library catalog, the seeded Library and
/// the edit the panel saves when an author creates a page with a new Book.
///
/// Run by `cargo xtask generate` (generator creation-fixtures) through
/// `flutter test`, because the panel needs the Flutter engine; it is a tool,
/// not a test, and asserts nothing. The output directory is the
/// `CREATION_FIXTURE_DIR` compile time define.
library;

import "dart:io";

import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_testkit/testing.dart";

const _directory = String.fromEnvironment("CREATION_FIXTURE_DIR");

void main() {
  testWidgets("write the panel creation fixtures", (tester) async {
    if (_directory.isEmpty) {
      throw StateError(
        "Pass --dart-define=CREATION_FIXTURE_DIR=<directory>; "
        "cargo xtask generate does",
      );
    }
    final fixture = ResourceCreationFixture.library();
    final library = fixture.libraryDocument();
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      realmServing(library),
    ]);

    final creation = await panel.create(fixture.request("Page"));
    await panel.search.result("Create Book").tap();
    final realm = panel.world.requireRealm;
    await panel.eventually(() => expect(realm.saves, hasLength(1)));
    if (creation.error case final error?) throw StateError("$error");

    final output = Directory(_directory)..createSync(recursive: true);
    void write(String name, List<int> bytes) =>
        File("${output.path}/$name").writeAsBytesSync(bytes);
    write(
      "catalog.skir",
      skir.EditorCatalog.serializer.toBytes(library.catalog.snapshot),
    );
    write(
      "seed.skir",
      skir.PreparedEdit.serializer.toBytes(fixture.librarySeed().prepare()),
    );
    write(
      "edit.skir",
      skir.PreparedEdit.serializer.toBytes(realm.saves.single.edit),
    );
  });
}
