import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/authoring/application/application.dart";
import "package:typewriter_testkit/src/core/trait.dart";
import "package:typewriter_testkit/src/core/world.dart";
import "package:typewriter_testkit/src/doubles/realm.dart";

/// A Book titled [title], identified by its snake cased title.
Book book(String title, {List<skir.ResourceId> tags = const []}) => Book(
  bookId: skir.ResourceId(value: "book:${title.snakeCase()}"),
  title: title,
  icon: "mdi:book",
  color: Colors.blue,
  tagIds: tags,
);

/// A Tag named [name], identified by its snake cased name.
Tag tag(String name, {List<skir.ResourceId> parents = const []}) => Tag(
  tagId: skir.ResourceId(value: "tag:${name.snakeCase()}"),
  name: name,
  color: Colors.teal,
  parentIds: parents,
);

/// A Page named [name], owned by [book] when given.
Page page(String name, {Book? book}) => Page(
  pageId: skir.ResourceId(value: "page:${name.snakeCase()}"),
  name: name,
  bookId: book?.bookId,
);

/// A Realm named [name] in the signed in user's organization, holding
/// [books], [tags] and [pages] in its Library and tags sections. Without a
/// location, the panel opens at its home.
Trait realm({
  String name = "Main",
  List<Book> books = const [],
  List<Tag> tags = const [],
  List<Page> pages = const [],
}) => _Realm(RealmSeed(name: name, books: books, tags: tags, pages: pages));

final class _Realm extends Trait {
  const _Realm(this.seed);

  final RealmSeed seed;

  @override
  Slot get slot => Slot.realm;

  @override
  String get description => "realm(${seed.name})";

  @override
  void applyTo(WorldBuilder world) => world.realm = seed;
}

/// The Realm offers [operations] on every resource.
Trait operations(List<RealmOperation> operations) => _Operations(operations);

final class _Operations extends Trait {
  const _Operations(this.operations);

  final List<RealmOperation> operations;

  @override
  Slot get slot => Slot.operations;

  @override
  String get description => "operations(${operations.join(", ")})";

  @override
  void applyTo(WorldBuilder world) => world.operations = operations;
}

/// Someone else saves [change] to the Realm [after] the panel opened.
Trait remoteChange(
  void Function(AuthoringEdit edit) change, {
  Duration after = Duration.zero,
}) => _RemoteChange(change, after);

final class _RemoteChange extends Trait {
  const _RemoteChange(this.change, this.after);

  final void Function(AuthoringEdit edit) change;
  final Duration after;

  @override
  Slot get slot => const Slot("remote change");

  @override
  String get description => "remoteChange(after: $after)";

  @override
  void applyTo(WorldBuilder world) => world.onStart(
    (started) => started.schedule(
      after,
      () => started.requireRealm.remoteChange(change),
    ),
  );
}
