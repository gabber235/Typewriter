import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

const _updateSubject = "service.to.realm1.organization.org1.realm.book.update";
const _listenSubject = "service.from.realm1.organization.org1.realm.book.watch";
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
    final nats = MockNatsClient();
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
          container.read(booksProvider).value?.single.revision ==
              current.revision &&
          container.read(booksProvider).value?.single.title == current.title,
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

  test("delayed Book mutation cannot replace a newer observation", () async {
    final nats = MockNatsClient();
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
      return skir.UpdateBookResponse.serializer.toBytes(
        skir.UpdateBookResponse.wrapSuccess(delayed.toSkir()),
      );
    });

    final result = await container
        .read(booksProvider.notifier)
        .updateBook(_book(title: "Requested"));

    expect(result, isA<MutationSuccess>());
    expect((result as MutationSuccess).revision, newest.revision);
    expect(container.read(booksProvider).requireValue, [newest]);
  });
}

void _emit(MockNatsClient nats, skir.WatchBooksResponse response) {
  nats.emitMessageOnSubject(
    _listenSubject,
    skir.WatchBooksResponse.serializer.toBytes(response),
  );
}
