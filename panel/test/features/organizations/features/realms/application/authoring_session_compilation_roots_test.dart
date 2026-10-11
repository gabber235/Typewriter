import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/infrastructure/messaging/nats.dart";

void main() {
  for (final result in [
    skir.PublicationResult.wrapBlocked([]),
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
        final commit = source.preparePublish();
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
        projection: skir.CompilationProjectionId(value: "typewriter.page"),
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

  test(
    "publication transport uses the Realm route and streams transitions",
    () async {
      final nats = FakeNatsClient();
      skir.PublishAuthoringRequest? published;
      nats
        ..registerHandler(_watchSubject, (_) {
          return skir.PublicationReport.serializer.toBytes(
            _attempt(skir.PublicationState.checking),
          );
        })
        ..registerHandler(_publishSubject, (bytes) {
          published = skir.PublishAuthoringRequest.serializer.fromBytes(bytes);
          return skir.PublishAuthoringResponse.serializer.toBytes(
            skir.PublishAuthoringResponse.wrapResult(
              skir.PublicationResult.publishing,
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
      final transitions = <skir.PublicationReport>[];
      final subscription = source.watch().listen(transitions.add);
      await _waitUntil(() => transitions.isNotEmpty);

      final work = ScopedWorkSession();
      final response = await work.execute(source.preparePublish());
      final result =
          (response as skir.PublishAuthoringResponse_resultWrapper).value;
      work.dispose();
      expect(result, skir.PublicationResult.publishing);
      expect(published, skir.PublishAuthoringRequest.defaultInstance);

      for (final state in [
        skir.PublicationState.compiling,
        skir.PublicationState.activating,
        skir.PublicationState.complete,
      ]) {
        nats.emitMessageOnSubject(
          _watchUpdateSubject,
          skir.PublicationReport.serializer.toBytes(_attempt(state)),
        );
      }
      await _waitUntil(() => transitions.length == 4);
      expect(transitions.map((attempt) => attempt.state), [
        skir.PublicationState.checking,
        skir.PublicationState.compiling,
        skir.PublicationState.activating,
        skir.PublicationState.complete,
      ]);
      expect(nats.requests.map((request) => request.subject), [
        _watchSubject,
        _publishSubject,
      ]);

      await subscription.cancel();
      container.dispose();
      await nats.dispose();
    },
  );
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

skir.PublicationReport _attempt(skir.PublicationState state) =>
    skir.PublicationReport(id: _publication, findings: const [], state: state);

Future<void> _waitUntil(bool Function() predicate) async {
  for (var index = 0; index < 100 && !predicate(); index++) {
    await Future<void>.delayed(Duration.zero);
  }
  expect(predicate(), isTrue);
}
