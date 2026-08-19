import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart" hide Tags;
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

const _updateSubject = "service.to.realm1.organization.org1.realm.tag.update";
const _deleteSubject = "service.to.realm1.organization.org1.realm.tag.delete";
const _listenSubject = "service.from.realm1.organization.org1.realm.tag.watch";
final _organizationId = recordId("organization:org1");
final _realmId = recordId("service:realm1");

Tag _tag({String name = "Current", int revision = 1}) => Tag(
  tagId: recordId("tag:tag1"),
  revision: revision,
  name: name,
  color: Colors.blue,
  parentIds: const [],
  placement: const Placement(x: 0, y: 0, width: 4, height: 1),
);

class _SeededTags extends Tags {
  _SeededTags(this.tags);

  final List<Tag> tags;

  @override
  Stream<List<Tag>> build() => Stream.value(tags);

  void observe(Tag tag) {
    state = AsyncData([tag]);
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
  test("watch ignores older and divergent equal revision Tags", () async {
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
    final subscription = container.listen(tagsProvider, (_, _) {});
    addTearDown(subscription.close);
    await _waitFor(() => nats.subscriptionSubjects.contains(_listenSubject));

    final current = _tag(name: "Current", revision: 3);
    _emit(nats, skir.WatchTagsResponse.wrapList([current.toSkir()]));
    await _waitFor(
      () =>
          container.read(tagsProvider).value?.single.revision ==
              current.revision &&
          container.read(tagsProvider).value?.single.name == current.name,
    );

    _emit(
      nats,
      skir.WatchTagsResponse.wrapUpdate(
        _tag(name: "Older", revision: 2).toSkir(),
      ),
    );
    _emit(
      nats,
      skir.WatchTagsResponse.wrapUpdate(
        _tag(name: "Divergent", revision: 3).toSkir(),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));

    final retained = container.read(tagsProvider).requireValue.single;
    expect(retained.revision, current.revision);
    expect(retained.name, current.name);
    expect(errors, hasLength(1));
    expect(errors.single.exceptionAsString(), contains("Tag tag1"));
    expect(errors.single.exceptionAsString(), contains("revision 3"));
  });

  test("replayed Tag remove remains absent", () async {
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
    final subscription = container.listen(tagsProvider, (_, _) {});
    addTearDown(subscription.close);
    await _waitFor(() => nats.subscriptionSubjects.contains(_listenSubject));
    final tag = _tag();
    _emit(nats, skir.WatchTagsResponse.wrapList([tag.toSkir()]));
    await _waitFor(
      () =>
          container.read(tagsProvider).value?.singleOrNull?.tagId == tag.tagId,
    );

    _emit(nats, skir.WatchTagsResponse.wrapRemove(tag.tagId));
    await _waitFor(() => container.read(tagsProvider).value?.isEmpty ?? false);
    _emit(nats, skir.WatchTagsResponse.wrapRemove(tag.tagId));
    await pumpEventQueue();

    expect(container.read(tagsProvider).requireValue, isEmpty);
  });

  test("delayed Tag mutation cannot replace a newer observation", () async {
    final nats = MockNatsClient();
    late _SeededTags notifier;
    final container = ProviderContainer.test(
      overrides: [
        organizationIdProvider.overrideWithValue(_organizationId),
        realmIdProvider.overrideWithValue(_realmId),
        natsProvider.overrideWithValue(nats),
        panelTelemetryProvider.overrideWithValue(
          const AsyncData(NoopPanelTelemetry()),
        ),
        tagsProvider.overrideWith(() => notifier = _SeededTags([_tag()])),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(nats.dispose);
    final subscription = container.listen(tagsProvider, (_, _) {});
    addTearDown(subscription.close);
    await container.read(tagsProvider.future);
    final newest = _tag(name: "Newest", revision: 4);
    final delayed = _tag(name: "Delayed", revision: 2);
    nats.registerHandler(_updateSubject, (data) {
      notifier.observe(newest);
      return skir.UpdateTagResponse.serializer.toBytes(
        skir.UpdateTagResponse.wrapSuccess(delayed.toSkir()),
      );
    });

    final result = await container
        .read(tagsProvider.notifier)
        .updateTag(_tag(name: "Requested"));

    expect(result, isA<MutationSuccess>());
    expect((result as MutationSuccess).revision, newest.revision);
    expect(container.read(tagsProvider).requireValue, [newest]);
  });

  test(
    "unexpected Tag update preserves canonical state and reports once",
    () async {
      final reports = <FlutterErrorDetails>[];
      final previousErrorHandler = FlutterError.onError;
      FlutterError.onError = reports.add;
      addTearDown(() => FlutterError.onError = previousErrorHandler);
      final nats = MockNatsClient();
      late _SeededTags notifier;
      final container = ProviderContainer.test(
        overrides: [
          organizationIdProvider.overrideWithValue(_organizationId),
          realmIdProvider.overrideWithValue(_realmId),
          natsProvider.overrideWithValue(nats),
          panelTelemetryProvider.overrideWithValue(
            const AsyncData(NoopPanelTelemetry()),
          ),
          tagsProvider.overrideWith(() => notifier = _SeededTags([_tag()])),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(nats.dispose);
      final subscription = container.listen(tagsProvider, (_, _) {});
      addTearDown(subscription.close);
      await container.read(tagsProvider.future);
      final newest = _tag(name: "Newest", revision: 4);
      nats.registerHandler(_updateSubject, (data) {
        notifier.observe(newest);
        throw StateError("transport failed");
      });

      final result = await container
          .read(tagsProvider.notifier)
          .updateTag(_tag(name: "Requested"));

      expect(result, isA<MutationUnavailable>());
      expect(
        (result as MutationUnavailable).diagnostics.single.message,
        "The tag update could not be completed",
      );
      expect(container.read(tagsProvider).requireValue, [newest]);
      expect(reports, hasLength(1));
      expect(reports.single.context.toString(), "while updating a tag");
    },
  );

  test(
    "unexpected Tag delete restores without replacing newer state",
    () async {
      final reports = <FlutterErrorDetails>[];
      final previousErrorHandler = FlutterError.onError;
      FlutterError.onError = reports.add;
      addTearDown(() => FlutterError.onError = previousErrorHandler);
      final nats = MockNatsClient();
      late _SeededTags notifier;
      final container = ProviderContainer.test(
        overrides: [
          organizationIdProvider.overrideWithValue(_organizationId),
          realmIdProvider.overrideWithValue(_realmId),
          natsProvider.overrideWithValue(nats),
          panelTelemetryProvider.overrideWithValue(
            const AsyncData(NoopPanelTelemetry()),
          ),
          tagsProvider.overrideWith(() => notifier = _SeededTags([_tag()])),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(nats.dispose);
      final subscription = container.listen(tagsProvider, (_, _) {});
      addTearDown(subscription.close);
      await container.read(tagsProvider.future);
      final newest = _tag(name: "Newest", revision: 4);
      nats.registerHandler(_deleteSubject, (data) {
        notifier.observe(newest);
        throw StateError("transport failed");
      });

      await expectLater(
        container.read(tagsProvider.notifier).deleteTag(_tag().tagId),
        throwsA(isA<StateError>()),
      );

      expect(container.read(tagsProvider).requireValue, [newest]);
      expect(reports, hasLength(1));
      expect(reports.single.context.toString(), "while deleting a tag");
    },
  );
}

void _emit(MockNatsClient nats, skir.WatchTagsResponse response) {
  nats.emitMessageOnSubject(
    _listenSubject,
    skir.WatchTagsResponse.serializer.toBytes(response),
  );
}
