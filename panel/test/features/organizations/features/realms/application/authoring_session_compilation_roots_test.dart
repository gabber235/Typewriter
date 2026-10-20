import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../../../support/publication.dart";

void main() {
  for (final result in [
    skir.PublicationResult.wrapBlocked(
      skir.PublicationBlockers(
        first: skir.PublicationBlocker(details: publicationProblem()),
        additional: const [],
      ),
    ),
    skir.PublicationResult.wrapInterrupted(_publication),
    skir.PublicationResult.unknown,
  ]) {
    test(
      "publication transport journals ${result.kind.name} without inventing replay",
      () async {
        final nats = FakeNatsClient()
          ..registerHandler(
            _publishSubject,
            (_) => skir.PublishAuthoringResponse.serializer.toBytes(
              skir.PublishAuthoringResponse.wrapResult(result),
            ),
          );
        final container = ProviderContainer.test(
          overrides: [
            natsProvider.overrideWith(() => FakeNats(nats)),
            panelTelemetryProvider.overrideWithValue(
              const AsyncData(NoopPanelTelemetry()),
            ),
          ],
        );
        final source = container.read(
          realmPublicationRepositoryProvider(_organization, _realm),
        );
        final work = ScopedWorkSession();
        final commit = source.preparePublish(
          skir.PublicationCandidateId(value: "reviewed"),
        );
        expect(commit.replay, SubmissionReplay.unsupported);
        expect(commit.resources, {
          WorkDriverId(
            domain: "publication",
            scope: AuthoringScope(
              organizationId: _organization,
              realmId: _realm,
            ),
          ),
        });
        if (result == skir.PublicationResult.unknown) {
          await expectLater(
            work.execute(commit),
            throwsA(isA<SubmissionException<skir.PublishAuthoringResponse>>()),
          );
          expect(
            work.submissions.single.result,
            isA<SubmissionUncertain<skir.PublishAuthoringResponse>>(),
          );
        } else {
          final response = await work.execute(commit);
          expect(
            skir.PublicationResult.serializer.toBytes(
              (response as skir.PublishAuthoringResponse_resultWrapper).value,
            ),
            skir.PublicationResult.serializer.toBytes(result),
          );
          expect(
            work.submissions.single.result,
            isA<SubmissionRejected<skir.PublishAuthoringResponse>>(),
          );
        }
        expect(work.submissions.single.canReplay, isFalse);
        work.dispose();
        container.dispose();
        await nats.dispose();
      },
    );
  }

  test(
    "compiled status query preserves saved roots and selected membership",
    () async {
      final nats = FakeNatsClient();
      final root = skir.CompilationRoot(
        projection: skir.CompilationProjectionId(value: "typewriter.resource-graph"),
        resource: skir.ResourceId(value: "saved"),
      );
      skir.QueryCompiledResourceStatusRequest? captured;
      nats.registerHandler(_statusSubject, (bytes) {
        captured = skir.QueryCompiledResourceStatusRequest.serializer.fromBytes(
          bytes,
        );
        return skir.QueryCompiledResourceStatusResponse.serializer.toBytes(
          skir.QueryCompiledResourceStatusResponse.createSuccess(
            statuses: [
              skir.CompiledResourceStatus(
                root: root,
                state: skir.CompiledResourceState.wrapActive(_publication),
              ),
            ],
          ),
        );
      });
      final container = ProviderContainer.test(
        overrides: [
          natsProvider.overrideWith(() => FakeNats(nats)),
          panelTelemetryProvider.overrideWithValue(
            const AsyncData(NoopPanelTelemetry()),
          ),
        ],
      );
      final source = container.read(
        realmPublicationRepositoryProvider(_organization, _realm),
      );
      final states = await source.states(
        skir.CompilationStatusSelection.wrapSuppliedRoots([root]),
      );
      expect(
        captured!.selection,
        isA<skir.CompilationStatusSelection_suppliedRootsWrapper>().having(
          (selection) => selection.value.single,
          "selected root",
          root,
        ),
      );
      expect(states.single.root, root);
      expect(
        states.single.state,
        skir.CompiledResourceState.wrapActive(_publication),
      );
      expect(
        () => states.add(skir.CompiledResourceStatus.defaultInstance),
        throwsUnsupportedError,
      );
      container.dispose();
      await nats.dispose();
    },
  );

  test("publication transport fetches a coherent bounded view for each identity hint", () async {
    final nats = FakeNatsClient();
    var view = skir.PublicationView(
      id: skir.PublicationViewId(value: "first"),
      status: readyPublicationStatus(),
    );
    nats
      ..registerHandler(
        _watchSubject,
        (_) => skir.PublicationViewChanged.serializer.toBytes(
          skir.PublicationViewChanged(current: view.id),
        ),
      )
      ..registerHandler(_querySubject, (bytes) {
        final request = skir.QueryPublicationViewRequest.serializer.fromBytes(
          bytes,
        );
        if (request.expected != view.id) {
          return skir.QueryPublicationViewResponse.serializer.toBytes(
            skir.QueryPublicationViewResponse.wrapChanged(
              skir.PublicationViewChanged(current: view.id),
            ),
          );
        }
        final encoded = skir.PublicationView.serializer.toBytes(view);
        return skir.QueryPublicationViewResponse.serializer.toBytes(
          skir.QueryPublicationViewResponse.wrapChunk(
            skir.PublicationViewChunk(
              view: view.id,
              transfer: skir.BoundedTransferChunk(
                transferId: request.transferId,
                index: 0,
                chunkCount: 1,
                encodedSize: encoded.length,
                sha256: sha256.convert(encoded).toString(),
                payload: skir.ByteString.copy(encoded),
              ),
            ),
          ),
        );
      });
    final container = ProviderContainer.test(
      overrides: [
        natsProvider.overrideWith(() => FakeNats(nats)),
        panelTelemetryProvider.overrideWithValue(
          const AsyncData(NoopPanelTelemetry()),
        ),
      ],
    );
    final source = container.read(
      realmPublicationRepositoryProvider(_organization, _realm),
    );
    final observed = <PublicationObservation>[];
    final subscription = source.watch().listen(observed.add);
    await waitForPublication(
      () => observed.lastOrNull is AvailablePublicationObservation,
    );
    expect(observed.first, isA<FetchingPublicationObservation>());
    expect((observed.last as AvailablePublicationObservation).view.id, view.id);
    view = skir.PublicationView(
      id: skir.PublicationViewId(value: "second"),
      status: blockedPublicationStatus(),
    );
    nats.emitMessageOnSubject(
      _watchUpdateSubject,
      skir.PublicationViewChanged.serializer.toBytes(
        skir.PublicationViewChanged(current: view.id),
      ),
    );
    await waitForPublication(
      () =>
          observed.whereType<AvailablePublicationObservation>().last.view.id ==
          view.id,
    );
    expect(
      (observed.last as AvailablePublicationObservation).view.status,
      isA<skir.PublicationStatus_blockedWrapper>(),
    );
    expect(observed.whereType<FetchingPublicationObservation>(), hasLength(2));
    expect(
      nats.requests.where((request) => request.subject == _querySubject),
      hasLength(2),
    );
    await subscription.cancel();
    container.dispose();
    await nats.dispose();
  });
}

final _organization = skir.recordId("organization:org1");
final _realm = skir.recordId("service:realm1");
final _publication = skir.PublicationId(value: "publication:1");
const _statusSubject =
    "service.to.realm1.organization.org1.realm.editor.authoring.compiled.status.query";
const _publishSubject =
    "service.to.realm1.organization.org1.realm.editor.authoring.publish";
const _watchSubject =
    "service.to.realm1.organization.org1.realm.editor.authoring.publication.watch";
const _watchUpdateSubject =
    "service.from.realm1.organization.org1.realm.editor.authoring.publication.watch";

const _querySubject =
    "service.to.realm1.organization.org1.realm.editor.authoring.publication.query";
