import "dart:async";
import "dart:typed_data";

import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:riverpod/riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../../../support/provider_test_utils.dart";

const _snapshotSubject =
    "service.to.realm1.organization.org1.realm.library.authoring.snapshot.get";
const _batchSubject =
    "service.to.realm1.organization.org1.realm.library.authoring.batch.apply";
const _eventSubject =
    "service.from.realm1.organization.org1.realm.library.authoring.changed";

void main() {
  test("buffers startup events and recovers gaps and reconnects", () async {
    final harness = _Harness();
    var sequence = 1;
    var title = "Initial";
    var emitDuringFirstSnapshot = true;
    harness.nats.registerHandler(_snapshotSubject, (payload) {
      expect(harness.nats.subscriptionSubjects, contains(_eventSubject));
      if (emitDuringFirstSnapshot) {
        emitDuringFirstSnapshot = false;
        harness.emit(_change(2, title: "Buffered"));
      }
      return _snapshot(sequence, title: title);
    });

    final provider = authoringSessionProvider(_org, _realm);
    final subscription = harness.container.listen(provider, (_, _) {});
    final lease = harness.container.read(provider.notifier).acquireLibrary();
    await lease.ready;
    await waitForProvider(
      harness.container,
      provider,
      (state) => state.sequence == 2,
      description: "startup event sequence 2",
    );
    expect(harness.container.read(provider).books[_book]?.title, "Buffered");

    harness.emit(_change(2, title: "Duplicate"));
    await Future<void>.delayed(Duration.zero);
    expect(harness.container.read(provider).books[_book]?.title, "Buffered");

    sequence = 3;
    title = "Recovered gap";
    harness.emit(_change(4, title: "Must not apply"));
    await waitForProvider(
      harness.container,
      provider,
      (state) => state.sequence == 4,
      description: "gap recovery sequence 4",
    );
    expect(
      harness.container.read(provider).books[_book]?.title,
      "Must not apply",
    );

    sequence = 4;
    title = "Recovered reconnect";
    harness.nats
      ..setConnectionState(
        const NatsReconnecting(
          NatsClientException(
            kind: NatsFailureKind.unavailable,
            message: "offline",
          ),
        ),
      )
      ..setConnectionState(const NatsConnected());
    await waitForProvider(
      harness.container,
      provider,
      (state) => state.books[_book]?.title == "Recovered reconnect",
      description: "reconnected book snapshot",
    );
    expect(
      harness.container.read(provider).books[_book]?.title,
      "Recovered reconnect",
    );

    lease.release();
    subscription.close();
    await Future<void>.delayed(Duration.zero);
    expect(harness.nats.subscriptionSubjects, isEmpty);
    await harness.dispose();
  });

  test("conflict refresh preserves a newer authoring event", () async {
    final harness = _Harness();
    var sequence = 1;
    var title = "Initial";
    harness.nats.registerHandler(
      _snapshotSubject,
      (_) => _snapshot(sequence, title: title),
    );
    harness.nats.registerHandler(_batchSubject, (_) {
      sequence = 2;
      title = "Newer event";
      harness.emit(_change(sequence, title: title));
      return skir.ApplyAuthoringBatchResponse.serializer.toBytes(
        skir.ApplyAuthoringBatchResponse.createConflict(conflicts: const []),
      );
    });

    final provider = authoringSessionProvider(_org, _realm);
    final subscription = harness.container.listen(provider, (_, _) {});
    final lease = harness.container.read(provider.notifier).acquireLibrary();
    await lease.ready;
    final response = await harness.container.read(provider.notifier).apply([
      skir.AuthoringOperation.createPatchBook(
        id: _book,
        title: skir.StringChange(expected: "Initial", value: "Local"),
        icon: null,
        color: null,
        tags: null,
      ),
    ]);

    expect(response, isA<skir.ApplyAuthoringBatchResponse_conflictWrapper>());
    expect(harness.container.read(provider).sequence, 2);
    expect(harness.container.read(provider).books[_book]?.title, "Newer event");
    lease.release();
    subscription.close();
    await harness.dispose();
  });

  test("ambiguous batch failure refreshes committed state", () async {
    final harness = _Harness();
    var sequence = 1;
    var title = "Initial";
    harness.nats.registerHandler(
      _snapshotSubject,
      (_) => _snapshot(sequence, title: title),
    );
    harness.nats.registerHandler(_batchSubject, (_) {
      sequence = 2;
      title = "Committed";
      throw const NatsClientException(
        kind: NatsFailureKind.timeout,
        message: "response lost",
      );
    });

    final provider = authoringSessionProvider(_org, _realm);
    final subscription = harness.container.listen(provider, (_, _) {});
    final lease = harness.container.read(provider.notifier).acquireLibrary();
    await lease.ready;

    await expectLater(
      harness.container.read(provider.notifier).apply([
        skir.AuthoringOperation.createPatchBook(
          id: _book,
          title: skir.StringChange(expected: "Initial", value: "Local"),
          icon: null,
          color: null,
          tags: null,
        ),
      ]),
      throwsA(isA<SubmissionException>()),
    );
    await waitForProvider(
      harness.container,
      provider,
      (state) => state.books[_book]?.title == "Committed",
      description: "committed snapshot after ambiguous failure",
    );
    expect(harness.container.read(provider).sequence, 2);

    lease.release();
    subscription.close();
    await harness.dispose();
  });

  test("invalid updates restore books and tags from the session", () async {
    final harness = _Harness();
    harness.nats.registerHandler(
      _snapshotSubject,
      (_) => _snapshot(1, title: "Initial"),
    );
    harness.nats.registerHandler(
      _batchSubject,
      (_) => skir.ApplyAuthoringBatchResponse.serializer.toBytes(
        skir.ApplyAuthoringBatchResponse.createInvalid(
          diagnostics: [
            skir.AuthoringDiagnostic(
              code: "invalid",
              message: "Rejected",
              resource: null,
              path: null,
            ),
          ],
        ),
      ),
    );

    final booksSubscription = harness.container.listen(
      canonicalBooksProvider,
      (_, _) {},
    );
    final tagsSubscription = harness.container.listen(
      canonicalTagsProvider,
      (_, _) {},
    );
    final book = (await harness.container.read(canonicalBooksProvider.future))
        .single;
    final tag = (await harness.container.read(canonicalTagsProvider.future))
        .single;

    final bookResult = await harness.container
        .read(canonicalBooksProvider.notifier)
        .updateBook(book.copyWith(title: "Rejected book"), expected: book);
    final tagResult = await harness.container
        .read(canonicalTagsProvider.notifier)
        .updateTag(tag.copyWith(name: "Rejected tag"), expected: tag);

    expect(bookResult, isA<MutationInvalid>());
    expect(tagResult, isA<MutationInvalid>());
    expect(
      harness.container.read(canonicalBooksProvider).requireValue.single.title,
      "Initial",
    );
    expect(
      harness.container.read(canonicalTagsProvider).requireValue.single.name,
      "Initial tag",
    );

    booksSubscription.close();
    tagsSubscription.close();
    await harness.dispose();
  });

  test("resource projection does not loop snapshot acquisition", () async {
    final harness = _Harness();
    var snapshots = 0;
    harness.nats.registerHandler(_snapshotSubject, (_) {
      snapshots++;
      return _snapshot(1, title: "Initial");
    });

    final subscription = harness.container.listen(
      canonicalBooksProvider,
      (_, _) {},
    );
    await harness.container.read(canonicalBooksProvider.future);
    harness.emit(_change(2, title: "Updated"));
    await waitForProvider(
      harness.container,
      canonicalBooksProvider,
      (state) => state.value?.single.title == "Updated",
      description: "updated book projection",
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(snapshots, 1);
    subscription.close();
    await harness.dispose();
  });

  test("scope acquired during refresh waits for a complete snapshot", () async {
    final harness = _Harness();
    final firstSnapshot = Completer<Uint8List>();
    final requests = <skir.GetAuthoringSnapshotRequest>[];
    harness.nats.registerHandler(_snapshotSubject, (payload) {
      final request = skir.GetAuthoringSnapshotRequest.serializer.fromBytes(
        payload,
      );
      requests.add(request);
      if (requests.length == 1) return firstSnapshot.future;
      return skir.GetAuthoringSnapshotResponse.serializer.toBytes(
        skir.GetAuthoringSnapshotResponse.createSuccess(
          sequence: 1,
          slices: [
            skir.AuthoringSnapshotSlice.createLibrary(
              books: const [],
              tags: const [],
            ),
            skir.AuthoringSnapshotSlice.createPage(
              pageId: _page,
              document: null,
            ),
          ],
        ),
      );
    });

    final provider = authoringSessionProvider(_org, _realm);
    final subscription = harness.container.listen(provider, (_, _) {});
    final libraryLease = harness.container
        .read(provider.notifier)
        .acquireLibrary();
    await waitForProvider(
      harness.container,
      provider,
      (state) => state.refreshing,
      description: "first snapshot refresh",
    );

    final pageLease = harness.container
        .read(provider.notifier)
        .acquirePage(_page);
    var pageReady = false;
    unawaited(pageLease.ready.then((_) => pageReady = true));
    firstSnapshot.complete(_snapshot(1, title: "Initial"));
    await libraryLease.ready;
    await pageLease.ready;

    expect(requests, hasLength(2));
    expect(requests.last.scopes.map((scope) => scope.kind), [
      skir.AuthoringSnapshotScope_kind.libraryConst,
      skir.AuthoringSnapshotScope_kind.pageWrapper,
    ]);
    expect(pageReady, isTrue);

    pageLease.release();
    libraryLease.release();
    subscription.close();
    await harness.dispose();
  });
}

final _org = recordId("organization:org1");
final _realm = recordId("service:realm1");
final _book = recordId("book:book1");
final _tag = recordId("tag:tag1");
final _page = recordId("page:page1");

Uint8List _snapshot(int sequence, {required String title}) =>
    skir.GetAuthoringSnapshotResponse.serializer.toBytes(
      skir.GetAuthoringSnapshotResponse.createSuccess(
        sequence: sequence,
        slices: [
          skir.AuthoringSnapshotSlice.createLibrary(
            books: [
              skir.Book(
                id: _book,
                title: title,
                icon: "mdi:book",
                color: Colors.blue.toSkirColor(),
                tags: const [],
              ),
            ],
            tags: [
              skir.Tag(
                id: _tag,
                name: "Initial tag",
                color: Colors.blue.toSkirColor(),
                parents: const [],
                placement: skir.GraphPlacement(x: 0, y: 0, width: 4, height: 1),
              ),
            ],
          ),
        ],
      ),
    );

skir.AuthoringChanged _change(int sequence, {required String title}) =>
    skir.AuthoringChanged(
      sequence: sequence,
      batchId: "batch-$sequence",
      changes: [
        skir.AuthoringResourceChange.createUpsertBook(
          id: _book,
          title: title,
          icon: "mdi:book",
          color: Colors.blue.toSkirColor(),
          tags: const [],
        ),
      ],
      indirectlyAffectedResources: const [],
    );

final class _Harness {
  _Harness() {
    container = ProviderContainer.test(
      overrides: [
        natsProvider.overrideWithValue(nats),
        organizationIdProvider.overrideWithValue(_org),
        realmIdProvider.overrideWithValue(_realm),
        panelTelemetryProvider.overrideWithValue(
          const AsyncData(NoopPanelTelemetry()),
        ),
      ],
    );
  }

  final FakeNatsClient nats = FakeNatsClient();
  late final ProviderContainer container;

  void emit(skir.AuthoringChanged change) {
    nats.emitMessageOnSubject(
      _eventSubject,
      skir.AuthoringChanged.serializer.toBytes(change),
    );
  }

  Future<void> dispose() async {
    container.dispose();
    await nats.dispose();
  }
}
