import "dart:typed_data";

import "package:flutter_test/flutter_test.dart";
import "package:riverpod/riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/library/v1/authoring.dart"
    as wire;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

const _snapshotSubject =
    "service.to.realm1.organization.org1.realm.library.authoring.snapshot.get";
const _batchSubject =
    "service.to.realm1.organization.org1.realm.library.authoring.batch.apply";
const _eventSubject =
    "service.from.realm1.organization.org1.realm.library.authoring.changed";

void main() {
  test(
    "metadata commands submit without a page provider or snapshot",
    () async {
      final nats = FakeNatsClient();
      final submitted = <wire.ApplyAuthoringBatchRequest>[];
      nats.registerHandler(_batchSubject, (bytes) {
        final request = wire.ApplyAuthoringBatchRequest.serializer.fromBytes(
          bytes,
        );
        submitted.add(request);
        return wire.ApplyAuthoringBatchResponse.serializer.toBytes(
          wire.ApplyAuthoringBatchResponse.createApplied(
            sequence: submitted.length,
            batchId: request.batchId,
            changes: const [],
            indirectlyAffectedResources: const [],
          ),
        );
      });
      final container = ProviderContainer.test(
        overrides: [
          natsProvider.overrideWithValue(nats),
          panelTelemetryProvider.overrideWithValue(
            const AsyncData(NoopPanelTelemetry()),
          ),
        ],
      );
      final provider = authoringSessionProvider(_organization, _realm);
      final subscription = container.listen(provider, (_, _) {});
      final session = container.read(provider.notifier);
      final nameResult = await session.patchPage(
        id: _page,
        name: wire.StringChange(expected: "Initial", value: "Renamed"),
      );
      final priorityResult = await session.patchPage(
        id: _page,
        priority: wire.Int32Change(expected: 2, value: 5),
      );
      expect(
        nameResult,
        isA<wire.ApplyAuthoringBatchResponse_appliedWrapper>(),
      );
      expect(
        priorityResult,
        isA<wire.ApplyAuthoringBatchResponse_appliedWrapper>(),
      );
      final rename =
          submitted.first.operations.single
              as wire.AuthoringOperation_patchPageWrapper;
      final priority =
          submitted.last.operations.single
              as wire.AuthoringOperation_patchPageWrapper;
      expect(rename.value.name?.expected, "Initial");
      expect(rename.value.priority, isNull);
      expect(priority.value.priority?.expected, 2);
      expect(priority.value.priority?.value, 5);
      expect(priority.value.name, isNull);
      expect(
        nats.requests.map((request) => request.subject),
        everyElement(_batchSubject),
      );
      subscription.close();
      container.dispose();
      await nats.dispose();
    },
  );

  test("rejected page update preserves a concurrent remote value", () async {
    final nats = FakeNatsClient();
    nats
      ..registerHandler(_snapshotSubject, (_) => _snapshot("Initial", 1))
      ..registerHandler(_batchSubject, (_) {
        nats.emitMessageOnSubject(
          _eventSubject,
          wire.AuthoringChanged.serializer.toBytes(
            wire.AuthoringChanged(
              sequence: 2,
              batchId: "remote-2",
              changes: [
                wire.AuthoringResourceChange.wrapUpsertPage(
                  _wirePage("Remote"),
                ),
              ],
              indirectlyAffectedResources: const [],
            ),
          ),
        );
        return wire.ApplyAuthoringBatchResponse.serializer.toBytes(
          wire.ApplyAuthoringBatchResponse.createInvalid(
            diagnostics: [
              wire.AuthoringDiagnostic(
                code: "invalid",
                message: "Rejected",
                resource: null,
                path: null,
              ),
            ],
          ),
        );
      });
    final container = ProviderContainer.test(
      overrides: [
        natsProvider.overrideWithValue(nats),
        organizationIdProvider.overrideWithValue(_organization),
        realmIdProvider.overrideWithValue(_realm),
        panelTelemetryProvider.overrideWithValue(
          const AsyncData(NoopPanelTelemetry()),
        ),
      ],
    );
    final provider = pagesProvider(_page);
    final subscription = container.listen(provider, (_, _) {});
    await container.read(provider.future);

    final result = await container
        .read(authoringSessionProvider(_organization, _realm).notifier)
        .patchPage(
          id: _page,
          name: wire.StringChange(expected: "Initial", value: "Local"),
        );
    expect(result, isA<wire.ApplyAuthoringBatchResponse_invalidWrapper>());

    expect(container.read(provider).requireValue.name, "Remote");
    expect(container.read(provider).requireValue.authoringSequence, 2);

    subscription.close();
    container.dispose();
    await nats.dispose();
  });
}

final _organization = recordId("organization:org1");
final _realm = recordId("service:realm1");
final _book = recordId("book:book1");
final _page = recordId("page:page1");

wire.Page _wirePage(String name) => wire.Page(
  id: _page,
  book: _book,
  name: name,
  kind: skir.PageKindRef(id: skir.PageKindId(value: "test"), revision: 1),
  chapter: "",
  priority: 0,
);

Uint8List _snapshot(String name, int sequence) =>
    wire.GetAuthoringSnapshotResponse.serializer.toBytes(
      wire.GetAuthoringSnapshotResponse.createSuccess(
        sequence: sequence,
        slices: [
          wire.AuthoringSnapshotSlice.createPage(
            pageId: _page,
            document: wire.PageDocument(
              page: _wirePage(name),
              elements: const [],
              references: const [],
              crossPageTargets: const [],
              crossPageSources: const [],
              diagnostics: const [],
              compileStatus: wire.PageCompileStatus.notCompiled,
            ),
          ),
        ],
      ),
    );
