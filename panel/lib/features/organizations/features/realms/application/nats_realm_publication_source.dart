import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

abstract interface class RealmPublicationRepository {
  PreparedCommit<skir.PublishAuthoringResponse> preparePublish();

  Future<List<skir.CompiledResourceStatus>> states(
    skir.CompilationStatusSelection selection,
  );

  Stream<skir.PublicationReport> watch();
}

final class NatsRealmPublicationRepository
    implements RealmPublicationRepository {
  NatsRealmPublicationRepository({
    required this.ref,
    required this.organizationId,
    required this.realmId,
  });

  final Ref ref;
  final skir.RecordId organizationId;
  final skir.RecordId realmId;

  @override
  PreparedCommit<skir.PublishAuthoringResponse> preparePublish() =>
      ref.prepareSkir(
        skir.PublishAuthoringRequest().operation(
          organizationId: organizationId,
          realmId: realmId,
        ),
        label: "Publish saved content",
        resources: {
          WorkDriverId(
            domain: "publication",
            scope: AuthoringScope(
              organizationId: organizationId,
              realmId: realmId,
            ),
          ),
        },
        replay: SubmissionReplay.unsupported,
        classify: classifyPublicationResponse,
      );

  @override
  Future<List<skir.CompiledResourceStatus>> states(
    skir.CompilationStatusSelection selection,
  ) async {
    final response = await ref.requestSkir(
      skir.QueryCompiledResourceStatusRequest(selection: selection)
          .operation(organizationId: organizationId, realmId: realmId),
    );
    return switch (response) {
      skir.QueryCompiledResourceStatusResponse_successWrapper(:final value) =>
        List.unmodifiable(value.statuses),
      _ => throw ApiException.internalServerError(),
    };
  }

  @override
  Stream<skir.PublicationReport> watch() =>
      skir.WatchPublicationRequest().watch(
        ref,
        organizationId: organizationId,
        realmId: realmId,
        snapshot: (response) => response,
        reduce: (_, event) => event,
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
