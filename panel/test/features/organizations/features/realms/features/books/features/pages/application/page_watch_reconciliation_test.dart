import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

const _listenSubject = "service.from.realm1.organization.org1.realm.page.watch";
const _requestSubject = "service.to.realm1.organization.org1.realm.page.watch";
const _invalidationRequestSubject =
    "service.to.realm1.organization.org1.realm.library.invalidate.watch.v2";
final _organizationId = recordId("organization:org1");
final _realmId = recordId("service:realm1");
final _pageId = recordId("page:page1");

Page _page({String name = "Current"}) => Page(
  pageId: _pageId,
  revision: 1,
  bookId: recordId("book:book1"),
  name: name,
  kind: PageType.sequence.kind,
  chapter: "chapter",
  priority: 1,
);

Future<void> _pumpUntil(
  bool Function() condition, {
  required String reason,
}) async {
  for (var attempt = 0; attempt < 20; attempt++) {
    if (condition()) return;
    await pumpEventQueue(times: 1);
  }
  expect(condition(), isTrue, reason: reason);
}

class _PageWatchHarness {
  _PageWatchHarness() {
    nats
      ..registerHandler(
        _requestSubject,
        (_) => skir.WatchPageResponse.serializer.toBytes(
          skir.WatchPageResponse.wrapInitial(_page().toSkir()),
        ),
      )
      ..registerHandler(
        _invalidationRequestSubject,
        (_) => skir.WatchLibraryInvalidationsResponse.serializer.toBytes(
          skir.WatchLibraryInvalidationsResponse.createInitial(revision: 0),
        ),
      );
    container = ProviderContainer.test(
      overrides: [
        organizationIdProvider.overrideWithValue(_organizationId),
        realmIdProvider.overrideWithValue(_realmId),
        natsProvider.overrideWithValue(nats),
      ],
    );
    subscription = container.listen(
      pagesProvider(_pageId),
      (previous, next) => state = next,
      fireImmediately: true,
    );
  }

  final FakeNatsClient nats = FakeNatsClient();
  late final ProviderContainer container;
  late final ProviderSubscription<AsyncValue<Page>> subscription;
  AsyncValue<Page> state = const AsyncLoading();

  Page? get value => switch (state) {
    AsyncData<Page>(:final value) => value,
    _ => null,
  };

  Future<void> start() => _pumpUntil(() {
    if (state.hasError) fail("Page watch failed: ${state.error}");
    return nats.requests.isNotEmpty &&
        nats.subscriptionSubjects.contains(_listenSubject);
  }, reason: "Page watch did not subscribe");

  Future<void> restart() async {
    final requestCount = nats.requests.length;
    container.invalidate(pagesProvider(_pageId));
    await _pumpUntil(
      () =>
          nats.requests.length > requestCount &&
          nats.subscriptionSubjects.contains(_listenSubject),
      reason: "Page watch did not restart",
    );
  }

  Future<void> emitValue(skir.WatchPageResponse response, Page expected) async {
    emit(response);
    await _pumpUntil(
      () => value == expected,
      reason: "Page watch did not emit $expected",
    );
  }

  Future<void> emitError(skir.WatchPageResponse response) async {
    emit(response);
    await _pumpUntil(
      () => state.hasError,
      reason: "Page watch did not emit an error",
    );
  }

  void emit(skir.WatchPageResponse response) {
    nats.emitMessageOnSubject(
      _listenSubject,
      skir.WatchPageResponse.serializer.toBytes(response),
    );
  }

  void expectAbsent() {
    expect(state, isA<AsyncLoading<Page>>());
    expect(state.hasError, isTrue);
    expect(state, isNot(isA<AsyncData<Page>>()));
    expect(
      state.error,
      isA<ApiException>().having((error) => error.code, "code", 404),
    );
  }

  void dispose() {
    subscription.close();
    container.dispose();
    nats.dispose();
  }
}

void main() {
  late _PageWatchHarness harness;

  setUp(() async {
    harness = _PageWatchHarness();
    await harness.start();
  });

  tearDown(() => harness.dispose());

  test("identical initial replay retains one equal immutable Page", () async {
    final page = _page();
    final response = skir.WatchPageResponse.wrapInitial(page.toSkir());

    await harness.emitValue(response, page);
    harness.emit(response);
    await pumpEventQueue();

    expect(harness.value, page);
  });

  test("identical update replay retains one equal immutable Page", () async {
    final initial = _page();
    final updated = _page(name: "Updated");
    await harness.emitValue(
      skir.WatchPageResponse.wrapInitial(initial.toSkir()),
      initial,
    );
    final response = skir.WatchPageResponse.wrapUpdate(updated.toSkir());

    await harness.emitValue(response, updated);
    harness.emit(response);
    await pumpEventQueue();

    expect(harness.value, updated);
  });

  for (final absentCase in [
    (name: "remove", response: skir.WatchPageResponse.wrapRemove(_pageId)),
    (
      name: "not found",
      response: skir.WatchPageResponse.createPageNotFoundError(pageId: _pageId),
    ),
  ]) {
    test(
      "${absentCase.name} replay retains retrying not found state",
      () async {
        final page = _page();
        await harness.emitValue(
          skir.WatchPageResponse.wrapInitial(page.toSkir()),
          page,
        );

        await harness.emitError(absentCase.response);
        harness.expectAbsent();
        await harness.restart();
        await harness.emitError(absentCase.response);

        harness.expectAbsent();
      },
    );
  }
}
