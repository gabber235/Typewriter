import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/library/v2/authoring.dart"
    as wire_v2;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

const _updateSubject =
    "service.to.realm1.organization.org1.realm.book.update.v2";
const _watchSubject = "service.to.realm1.organization.org1.realm.book.watch";
const _listenSubject = "service.from.realm1.organization.org1.realm.book.watch";
const _invalidationSubject =
    "service.to.realm1.organization.org1.realm.library.invalidate.watch.v2";
final _organizationId = recordId("organization:org1");
final _realmId = recordId("service:realm1");

Book _book({String title = "Current", int revision = 1}) => Book(
  bookId: recordId("book:book1"),
  revision: revision,
  title: title,
  icon: "mdi:book",
  color: Colors.blue,
  tagIds: const [],
);

class _SeededBooks extends Books {
  _SeededBooks(this.books);

  final List<Book> books;

  @override
  Stream<List<Book>> build() => Stream.value(books);

  void observe(Book book) {
    state = AsyncData([book]);
  }
}

Future<void> _waitFor(bool Function() condition) async {
  await Future.doWhile(() async {
    if (condition()) return false;
    await Future<void>.delayed(const Duration(milliseconds: 5));
    return true;
  }).timeout(const Duration(seconds: 2));
}

void main() {
  test("watch ignores older and divergent equal revision Books", () async {
    final errors = <FlutterErrorDetails>[];
    final previousErrorHandler = FlutterError.onError;
    FlutterError.onError = errors.add;
    addTearDown(() => FlutterError.onError = previousErrorHandler);
    final nats = FakeNatsClient();
    _registerWatchHandlers(nats);
    final container = ProviderContainer.test(
      overrides: [
        organizationIdProvider.overrideWithValue(_organizationId),
        realmIdProvider.overrideWithValue(_realmId),
        natsProvider.overrideWithValue(nats),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(nats.dispose);
    final subscription = container.listen(booksProvider, (_, _) {});
    addTearDown(subscription.close);
    await _waitFor(() => nats.subscriptionSubjects.contains(_listenSubject));

    final current = _book(title: "Current", revision: 3);
    _emit(nats, skir.WatchBooksResponse.wrapList([current.toSkir()]));
    await _waitFor(
      () =>
          container.read(booksProvider).value?.singleOrNull?.revision ==
              current.revision &&
          container.read(booksProvider).value?.singleOrNull?.title ==
              current.title,
    );

    _emit(
      nats,
      skir.WatchBooksResponse.wrapUpdate(
        _book(title: "Older", revision: 2).toSkir(),
      ),
    );
    _emit(
      nats,
      skir.WatchBooksResponse.wrapUpdate(
        _book(title: "Divergent", revision: 3).toSkir(),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));

    final retained = container.read(booksProvider).requireValue.single;
    expect(retained.revision, current.revision);
    expect(retained.title, current.title);
    expect(errors, hasLength(1));
    expect(errors.single.exceptionAsString(), contains("Book book1"));
    expect(errors.single.exceptionAsString(), contains("revision 3"));
  });

  test("replayed Book remove remains absent", () async {
    final nats = FakeNatsClient();
    _registerWatchHandlers(nats);
    final container = ProviderContainer.test(
      overrides: [
        organizationIdProvider.overrideWithValue(_organizationId),
        realmIdProvider.overrideWithValue(_realmId),
        natsProvider.overrideWithValue(nats),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(nats.dispose);
    final subscription = container.listen(booksProvider, (_, _) {});
    addTearDown(subscription.close);
    await _waitFor(() => nats.subscriptionSubjects.contains(_listenSubject));
    final book = _book();
    _emit(nats, skir.WatchBooksResponse.wrapList([book.toSkir()]));
    await _waitFor(
      () =>
          container.read(booksProvider).value?.singleOrNull?.bookId ==
          book.bookId,
    );

    _emit(nats, skir.WatchBooksResponse.wrapRemove(book.bookId));
    await _waitFor(() => container.read(booksProvider).value?.isEmpty ?? false);
    _emit(nats, skir.WatchBooksResponse.wrapRemove(book.bookId));
    await pumpEventQueue();

    expect(container.read(booksProvider).requireValue, isEmpty);
  });

  test("delayed Book mutation cannot replace a newer observation", () async {
    final nats = FakeNatsClient();
    late _SeededBooks notifier;
    final container = ProviderContainer.test(
      overrides: [
        organizationIdProvider.overrideWithValue(_organizationId),
        realmIdProvider.overrideWithValue(_realmId),
        natsProvider.overrideWithValue(nats),
        panelTelemetryProvider.overrideWithValue(
          const AsyncData(NoopPanelTelemetry()),
        ),
        booksProvider.overrideWith(() => notifier = _SeededBooks([_book()])),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(nats.dispose);
    final subscription = container.listen(booksProvider, (_, _) {});
    addTearDown(subscription.close);
    await container.read(booksProvider.future);
    final newest = _book(title: "Newest", revision: 4);
    final delayed = _book(title: "Delayed", revision: 2);
    nats.registerHandler(_updateSubject, (data) {
      notifier.observe(newest);
      return wire_v2.UpdateBooksResponse.serializer.toBytes(
        wire_v2.UpdateBooksResponse.wrapSuccess([_wireBook(delayed)]),
      );
    });

    final result = await container
        .read(booksProvider.notifier)
        .updateBook(_book(title: "Requested"));

    expect(result, isA<MutationSuccess>());
    expect((result as MutationSuccess).revision, newest.revision);
    expect(container.read(booksProvider).requireValue, [newest]);
  });

  test("typed Book conflict installs canonical server state", () async {
    final nats = FakeNatsClient();
    final current = _book();
    final canonical = _book(title: "Remote", revision: 3);
    final container = ProviderContainer.test(
      overrides: [
        organizationIdProvider.overrideWithValue(_organizationId),
        realmIdProvider.overrideWithValue(_realmId),
        natsProvider.overrideWithValue(nats),
        panelTelemetryProvider.overrideWithValue(
          const AsyncData(NoopPanelTelemetry()),
        ),
        booksProvider.overrideWith(() => _SeededBooks([current])),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(nats.dispose);
    final subscription = container.listen(booksProvider, (_, _) {});
    addTearDown(subscription.close);
    await container.read(booksProvider.future);
    nats.registerHandler(
      _updateSubject,
      (data) => wire_v2.UpdateBooksResponse.serializer.toBytes(
        wire_v2.UpdateBooksResponse.wrapConflict([
          wire_v2.BookConflict(
            id: current.bookId,
            expectedRevision: current.revision,
            actual: _wireBook(canonical),
          ),
        ]),
      ),
    );

    final result = await container
        .read(booksProvider.notifier)
        .updateBook(current.copyWith(title: "Requested"));

    expect(result, isA<MutationConflict>());
    expect((result as MutationConflict).actualRevision, 3);
    final observed = container.read(booksProvider).requireValue.single;
    expect(observed.bookId, canonical.bookId);
    expect(observed.revision, canonical.revision);
    expect(observed.title, canonical.title);
  });
}

wire_v2.Book _wireBook(Book book) => wire_v2.Book(
  id: book.bookId,
  revision: book.revision,
  title: book.title,
  icon: book.icon,
  color: book.color.toSkirColor(),
  tags: book.tagIds,
);

void _emit(FakeNatsClient nats, skir.WatchBooksResponse response) {
  nats.emitMessageOnSubject(
    _listenSubject,
    skir.WatchBooksResponse.serializer.toBytes(response),
  );
}

void _registerWatchHandlers(FakeNatsClient nats) {
  nats
    ..registerHandler(
      _watchSubject,
      (_) => skir.WatchBooksResponse.serializer.toBytes(
        skir.WatchBooksResponse.wrapList([]),
      ),
    )
    ..registerHandler(
      _invalidationSubject,
      (_) => skir.WatchLibraryInvalidationsResponse.serializer.toBytes(
        skir.WatchLibraryInvalidationsResponse.createInitial(revision: 0),
      ),
    );
}
