import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

abstract interface class RealmPublicationSource {
  Future<skir.PublicationResult> publish();

  Stream<skir.PublicationReport> watch();
}

final class NatsRealmPublicationSource implements RealmPublicationSource {
  NatsRealmPublicationSource({
    required this.ref,
    required skir.RecordId organizationId,
    required skir.RecordId realmId,
  }) : _address = RealmServiceAddress(
         organizationId: organizationId,
         realmId: realmId,
       );

  final Ref ref;
  final RealmServiceAddress _address;

  @override
  Future<skir.PublicationResult> publish() async {
    final response = await ref.requestSkir(
      _address.request("editor.authoring.publish"),
      skir.PublishAuthoringRequest.serializer.toBytes(
        skir.PublishAuthoringRequest(),
      ),
      skir.PublishAuthoringResponse.serializer,
    );
    return switch (response) {
      skir.PublishAuthoringResponse_resultWrapper(:final value) => value,
      _ => throw ApiException.internalServerError(),
    };
  }

  @override
  Stream<skir.PublicationReport> watch() => ref.watchRequest(
    subject: _address.request("editor.authoring.publication.watch"),
    listenSubject: _address.event("editor.authoring.publication.watch"),
    requestBytes: skir.WatchPublicationRequest.serializer.toBytes(
      skir.WatchPublicationRequest(),
    ),
    serializer: skir.PublicationReport.serializer,
    transformer: (_, response) => response,
  );
}
