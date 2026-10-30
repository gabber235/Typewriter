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

/// A Tag named [name] in [color], identified by its snake cased name.
Tag tag(
  String name, {
  Color color = Colors.teal,
  List<skir.ResourceId> parents = const [],
}) => Tag(
  tagId: skir.ResourceId(value: "tag:${name.snakeCase()}"),
  name: name,
  color: color,
  parentIds: parents,
);

/// A Page named [name], owned by [book] when given.
Page page(String name, {Book? book}) => Page(
  pageId: skir.ResourceId(value: "page:${name.snakeCase()}"),
  name: name,
  bookId: book?.bookId,
);

/// A scene named [name] whose timeline shows [tracks], identified by its
/// snake cased name.
Scene scene(String name, {List<Track> tracks = const []}) => Scene(
  sceneId: skir.ResourceId(value: "scene:${name.snakeCase()}"),
  name: name,
  tracks: tracks,
);

/// A track named [name] holding [cues], identified by its snake cased name.
Track track(String name, {List<Cue> cues = const []}) => Track(
  trackId: skir.ResourceId(value: "track:${name.snakeCase()}"),
  name: name,
  cues: cues,
);

/// A cue named [name] spanning the frames [from] to [to], identified by its
/// snake cased name.
Cue cue(String name, {required int from, required int to}) => Cue(
  cueId: skir.ResourceId(value: "cue:${name.snakeCase()}"),
  name: name,
  startFrame: from,
  endFrame: to,
);

/// A Realm named [name] in the signed in user's organization, holding
/// [books], [tags] and [pages] in its Library and tags sections, and each of
/// [scenes] as a section of its own. Without a
/// location, the panel opens at its home.
///
/// [catalog] replaces the [libraryCatalog] the resources are typed by.
Trait realm({
  String name = "Main",
  List<Book> books = const [],
  List<Tag> tags = const [],
  List<Page> pages = const [],
  List<Scene> scenes = const [],
  CheckedEditorCatalog? catalog,
}) => _Realm(
  RealmSeed(
    name: name,
    books: books,
    tags: tags,
    pages: pages,
    scenes: scenes,
    catalog: catalog,
  ),
);

/// A Realm named [name] whose saved content is [document], for content the
/// library catalog cannot describe, such as resources of an extension.
Trait realmServing(AuthoringDocument document, {String name = "Main"}) =>
    _Realm(RealmSeed(name: name, saved: document));

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

/// The Realm answers saves only when the test does, through
/// [FakeRealm.saves]: a slow, refused or lost reply.
const Trait heldSaves = _HeldSaves();

final class _HeldSaves extends Trait {
  const _HeldSaves();

  @override
  Slot get slot => const Slot("saves");

  @override
  String get description => "heldSaves";

  @override
  void applyTo(WorldBuilder world) =>
      world.onStart((started) => started.requireRealm.holdSaves = true);
}
