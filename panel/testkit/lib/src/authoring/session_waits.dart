import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/core/eventually.dart";
import "package:typewriter_testkit/src/authoring/application/authoring_seeds.dart";
import "package:typewriter_testkit/src/authoring/document_facts.dart";
import "package:typewriter_testkit/src/authoring/realm_world.dart";
import "package:typewriter_testkit/src/core/world.dart";
import "package:typewriter_testkit/src/doubles/realm_library.dart";

/// Following an authoring session from a world without widgets.
/// What the broker answers a request while the Realm that owns it is away
/// and the panel stays connected: nothing received it.
const realmAway = NatsClientException(
  kind: NatsFailureKind.noResponders,
  message: "No NATS responder is available",
);

extension AuthoringSessionWaits on World {
  /// Waits until [session] shows [book] titled [title]; a failure names
  /// [description].
  Future<AuthoringSessionState> untilBookTitled(
    AuthoringSessionProvider session,
    skir.ResourceId book,
    String title, {
    required String description,
  }) => container.eventually(
    session,
    (state) =>
        state.resources[book]?.content.authoredField("title")?.authoredString ==
        title,
    description: description,
  );

  /// Answers catalog fetches on [catalogSubject] with the library catalog of
  /// [generation], and state queries on [stateSubject] with the Library
  /// holding [book] titled whatever [title] returns at that query.
  void serveTitledBook(
    String catalogSubject,
    String stateSubject, {
    required skir.CatalogGeneration generation,
    required Book book,
    required String Function() title,
  }) => nats
    ..registerHandler(
      catalogSubject,
      (_) => libraryCatalog(generation: generation).fetchReply,
    )
    ..registerHandler(
      stateSubject,
      (_) => realmDocument(
        books: [book.copyWith(title: title())],
        catalog: libraryCatalog(generation: generation),
      ).stateReply,
    );

  /// Serves [book] the way [serveTitledBook] does on the catalog and state
  /// [subjects], signs in, keeps [session] open and waits until it shows
  /// the book's first title.
  Future<void> openBookSession(
    AuthoringSessionProvider session,
    Book book,
    String Function() title, {
    required skir.CatalogGeneration generation,
    required ({String catalog, String state}) subjects,
  }) async {
    final first = title();
    serveTitledBook(
      subjects.catalog,
      subjects.state,
      generation: generation,
      book: book,
      title: title,
    );
    await whenSignedIn();
    keepOpen(session);
    await untilBookTitled(
      session,
      book.bookId,
      first,
      description: "initial state",
    );
  }

  /// Holds every request on [subject] until the test answers it; returns
  /// the held requests, oldest first. Failing one with [realmAway] answers
  /// it the way the broker does while the Realm is away.
  List<Completer<Uint8List>> holdRequests(String subject) {
    final held = <Completer<Uint8List>>[];
    nats.registerHandler(subject, (_) {
      final request = Completer<Uint8List>();
      held.add(request);
      return request.future;
    });
    return held;
  }

  /// Announces on [subject] that the authoring content of catalog
  /// [generation] changed.
  void announceAuthoringChanged(
    String subject,
    skir.CatalogGeneration generation,
  ) => nats.connection.emitMessageOnSubject(
    subject,
    skir.AuthoringChanged.serializer.toBytes(
      skir.AuthoringChanged(generation: generation),
    ),
  );
}
