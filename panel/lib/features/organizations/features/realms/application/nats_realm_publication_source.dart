import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

abstract interface class RealmPublicationRepository {
  PreparedCommit<skir.PublishAuthoringResponse> preparePublish();

  Future<List<skir.CompiledResourceStatus>> states(
    List<skir.CompilationRoot> roots,
  );

  Stream<skir.PublicationReport> watch();
}

final class NatsRealmPublicationRepository
    implements RealmPublicationRepository {
  NatsRealmPublicationRepository({
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
  PreparedCommit<skir.PublishAuthoringResponse> preparePublish() =>
      ref.prepareSkir(
        _address.request("editor.authoring.publish"),
        skir.PublishAuthoringRequest.serializer.toBytes(
          skir.PublishAuthoringRequest(),
        ),
        skir.PublishAuthoringResponse.serializer,
        label: "Publish saved content",
        resources: {
          WorkDriverId(
            domain: "publication",
            scope: AuthoringScope(
              organizationId: _address.organizationId,
              realmId: _address.realmId,
            ),
          ),
        },
        replay: SubmissionReplay.unsupported,
        classify: classifyPublicationResponse,
      );

  @override
  Future<List<skir.CompiledResourceStatus>> states(
    List<skir.CompilationRoot> roots,
  ) async {
    final response = await ref.requestSkir(
      _address.request("editor.authoring.compiled.status.query"),
      skir.QueryCompiledResourceStatusRequest.serializer.toBytes(
        skir.QueryCompiledResourceStatusRequest(roots: roots),
      ),
      skir.QueryCompiledResourceStatusResponse.serializer,
    );
    return switch (response) {
      skir.QueryCompiledResourceStatusResponse_successWrapper(:final value) =>
        List.unmodifiable(value.statuses),
      _ => throw ApiException.internalServerError(),
    };
  }

  @override
  Stream<skir.PublicationReport> watch() =>
      ref.watchProjection<
        skir.PublicationReport,
        skir.PublicationReport,
        skir.PublicationReport
      >(
        subject: _address.request("editor.authoring.publication.watch"),
        eventSubject: _address.event("editor.authoring.publication.watch"),
        requestBytes: skir.WatchPublicationRequest.serializer.toBytes(
          skir.WatchPublicationRequest(),
        ),
        responseSerializer: skir.PublicationReport.serializer,
        eventSerializer: skir.PublicationReport.serializer,
        snapshot: (response) => response,
        reduce: (_, event) => event,
        delivery: const ProjectionDelivery.ephemeral(),
        reconciliation: const ProjectionReconciliation.latest(),
      );
}

MutationResponseDisposition classifyPublicationResponse(
  skir.PublishAuthoringResponse response,
) => switch (response) {
  skir.PublishAuthoringResponse_resultWrapper(
    value: skir.PublicationResult_blockedWrapper(),
  ) ||
  skir.PublishAuthoringResponse_resultWrapper(
    value: skir.PublicationResult_interruptedWrapper(),
  ) => MutationResponseDisposition.rejected,
  skir.PublishAuthoringResponse_resultWrapper(
    value: skir.PublicationResult_unknown(),
  ) =>
    MutationResponseDisposition.uncertain,
  skir.PublishAuthoringResponse_resultWrapper() =>
    MutationResponseDisposition.confirmed,
  _ => MutationResponseDisposition.uncertain,
};
