import "dart:typed_data";

import "package:flutter_test/flutter_test.dart";
import "package:riverpod/riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

const _snapshotSubject =
    "service.to.realm1.organization.org1.realm.library.authoring.snapshot.get";
const _batchSubject =
    "service.to.realm1.organization.org1.realm.library.authoring.batch.apply";
const _eventSubject =
    "service.from.realm1.organization.org1.realm.library.authoring.changed";

void main() {
  test("page creation input builds and submits one page", () async {
    final nats = FakeNatsClient();
    late skir.ApplyAuthoringBatchRequest submitted;
    nats.registerHandler(_batchSubject, (bytes) {
      submitted = skir.ApplyAuthoringBatchRequest.serializer.fromBytes(bytes);
      return skir.ApplyAuthoringBatchResponse.serializer.toBytes(
        skir.ApplyAuthoringBatchResponse.createApplied(
          sequence: 1,
          batchId: submitted.batchId,
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

    final page = await container
        .read(provider.notifier)
        .createPageFromInput(
          _book,
          const PageCreationInput(
            name: "Created",
            kind: PageKindRef(id: "test", revision: 2),
            chapter: "chapter",
            priority: 3,
          ),
        );

    final operation =
        submitted.operations.single
            as skir.AuthoringOperation_createPageWrapper;
    expect(operation.value.page.id, page.pageId);
    expect(operation.value.page.book, _book);
    expect(operation.value.page.name, "Created");
    expect(operation.value.page.kind.revision, 2);
    expect(operation.value.page.chapter, "chapter");
    expect(operation.value.page.priority, 3);

    subscription.close();
    container.dispose();
    await nats.dispose();
  });

  test(
    "metadata commands submit without a page provider or snapshot",
    () async {
      final nats = FakeNatsClient();
      final submitted = <skir.ApplyAuthoringBatchRequest>[];
      nats.registerHandler(_batchSubject, (bytes) {
        final request = skir.ApplyAuthoringBatchRequest.serializer.fromBytes(
          bytes,
        );
        submitted.add(request);
        return skir.ApplyAuthoringBatchResponse.serializer.toBytes(
          skir.ApplyAuthoringBatchResponse.createApplied(
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
        name: skir.StringChange(expected: "Initial", value: "Renamed"),
      );
      final priorityResult = await session.patchPage(
        id: _page,
        priority: skir.Int32Change(expected: 2, value: 5),
      );
      expect(
        nameResult,
        isA<skir.ApplyAuthoringBatchResponse_appliedWrapper>(),
      );
      expect(
        priorityResult,
        isA<skir.ApplyAuthoringBatchResponse_appliedWrapper>(),
      );
      final rename =
          submitted.first.operations.single
              as skir.AuthoringOperation_patchPageWrapper;

      final priority =
          submitted.last.operations.single
              as skir.AuthoringOperation_patchPageWrapper;
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

  test("page metadata rejection retains the draft for review", () async {
    final nats = FakeNatsClient()
      ..registerHandler(_snapshotSubject, (_) => _snapshot("Initial", 1))
      ..registerHandler(_batchSubject, (bytes) {
        final request = skir.ApplyAuthoringBatchRequest.serializer.fromBytes(
          bytes,
        );
        final patch =
            (request.operations.single
                    as skir.AuthoringOperation_patchPageWrapper)
                .value;
        expect(patch.name?.expected, "Initial");
        expect(patch.name?.value, "Retained");
        expect(patch.priority, isNull);
        return skir.ApplyAuthoringBatchResponse.serializer.toBytes(
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
    final workspace = LocalWorkSession();
    final provider = authoringSessionProvider(_organization, _realm);
    final subscription = container.listen(provider, (_, _) {});
    final result =
        await PageEditing(
          container.read(provider.notifier),
          workspace,
          container
              .read(resourceRepositoriesProvider)
              .authoring(_organization, _realm),
        ).edit({
          _page: {DataPath.root.field("name"): const StringValue("Retained")},
        });

    expect(result, isA<MutationInvalid>());
    final owner = workspace.resources.values.single.source;
    expect(
      owner.value(DataPath.root.field("name")).valueOrNull,
      const StringValue("Retained"),
    );
    expect(
      owner.document.confirmedValue
          .readEditorValue(DataPath.root.field("name"))
          .valueOrNull,
      const StringValue("Initial"),
    );
    workspace.dispose();
    subscription.close();

    container.dispose();
    await nats.dispose();
  });

  test("rejected page update preserves a concurrent remote value", () async {
    final nats = FakeNatsClient();
    nats
      ..registerHandler(_snapshotSubject, (_) => _snapshot("Initial", 1))
      ..registerHandler(_batchSubject, (_) {
        nats.emitMessageOnSubject(
          _eventSubject,
          skir.AuthoringChanged.serializer.toBytes(
            skir.AuthoringChanged(
              sequence: 2,
              batchId: "remote-2",
              changes: [
                skir.AuthoringResourceChange.wrapUpsertPage(
                  _wirePage("Remote"),
                ),
              ],
              indirectlyAffectedResources: const [],
            ),
          ),
        );
        return skir.ApplyAuthoringBatchResponse.serializer.toBytes(
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
    final provider = canonicalPageProvider(_page);
    final subscription = container.listen(provider, (_, _) {});
    await container.read(provider.future);

    final result = await container
        .read(authoringSessionProvider(_organization, _realm).notifier)
        .patchPage(
          id: _page,
          name: skir.StringChange(expected: "Initial", value: "Local"),
        );
    expect(result, isA<skir.ApplyAuthoringBatchResponse_invalidWrapper>());

    expect(container.read(provider).requireValue.name, "Remote");
    expect(
      container.read(authoringSessionProvider(_organization, _realm)).sequence,
      2,
    );

    subscription.close();
    container.dispose();
    await nats.dispose();
  });
}

final _organization = recordId("organization:org1");
final _realm = recordId("service:realm1");
final _book = recordId("book:book1");
final _page = recordId("page:page1");

skir.Page _wirePage(String name) => skir.Page(
  id: _page,
  book: _book,
  name: name,
  kind: skir.PageKindRef(id: skir.PageKindId(value: "test"), revision: 1),
  chapter: "",
  priority: 0,
);

Uint8List _snapshot(String name, int sequence) =>
    skir.GetAuthoringSnapshotResponse.serializer.toBytes(
      skir.GetAuthoringSnapshotResponse.createSuccess(
        sequence: sequence,
        slices: [
          skir.AuthoringSnapshotSlice.createPage(
            pageId: _page,
            document: skir.PageDocument(
              page: _wirePage(name),
              elements: const [],
              references: const [],
              crossPageTargets: const [],
              crossPageSources: const [],
              diagnostics: const [],
              compileStatus: skir.PageCompileStatus.notCompiled,
            ),
          ),
        ],
      ),
    );
