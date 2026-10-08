import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/infrastructure/messaging/nats.dart";

void main() {
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
          natsProvider.overrideWithValue(nats),
          panelTelemetryProvider.overrideWithValue(
            const AsyncData(NoopPanelTelemetry()),
          ),
        ],
      );
      final source = container.read(
        realmPublicationSourceProvider(_organization, _realm),
      );
      final transitions = <skir.PublicationReport>[];
      final subscription = source.watch().listen(transitions.add);
      await _waitUntil(() => transitions.isNotEmpty);

      final result = await source.publish();
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
