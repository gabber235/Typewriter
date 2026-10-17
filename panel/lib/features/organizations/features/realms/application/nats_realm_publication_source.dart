import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

abstract interface class RealmPublicationRepository {
  PreparedCommit<skir.PublishAuthoringResponse> preparePublish(
    skir.PublicationCandidateId candidate,
  );

  Future<List<skir.CompiledResourceStatus>> states(
    skir.CompilationStatusSelection selection,
  );

  Stream<PublicationObservation> watch();
}

/// Reconciles publication hints into complete, identity checked review transfers.
///
/// Each newer hint cancels the previous fetch and fences late completion. A view
/// changed response follows the new identity; stream cancellation stops transfer
/// and hint observation. Prepared publication requests use the submission owner
/// and declare automatic replay unsupported because the original outcome may be unknown.
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
  PreparedCommit<skir.PublishAuthoringResponse> preparePublish(
    skir.PublicationCandidateId candidate,
  ) => ref.prepareSkir(
    skir.PublishAuthoringRequest(candidate: candidate)
        .operation(organizationId: organizationId, realmId: realmId),
    label: "Publish saved content",
    resources: {
      WorkDriverId(
        domain: "publication",
        scope: AuthoringScope(organizationId: organizationId, realmId: realmId),
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
  Stream<PublicationObservation> watch() => Stream.multi((output) {
    var generation = 0;
    Completer<void>? cancelled;
    Future<void> fetch(
      skir.PublicationViewId expected,
      int requestGeneration,
    ) async {
      final stop = Completer<void>();
      cancelled = stop;
      final transferId = uuid.v4();
      try {
        final transport = SkirMutationClient(
          () => ref.read(natsProvider),
          () => ref.read(panelTelemetryProvider.future),
        );
        final responses = skir.QueryPublicationViewRequest(
          expected: expected,
          transferId: transferId,
        ).watch(transport, organizationId: organizationId, realmId: realmId);
        final bytes = await BoundedTransferAssembler().assemble(
          responses.map((response) {
            if (response case skir.QueryPublicationViewResponse_changedWrapper(
              :final value,
            )) {
              throw PublicationViewChanged(value.current);
            }
            if (response case skir.QueryPublicationViewResponse_chunkWrapper(
              :final value,
            )) {
              if (value.view != expected ||
                  value.transfer.transferId != transferId) {
                throw const BoundedTransferRejected(
                  "Publication transfer identity changed",
                );
              }
              final chunk = value.transfer;
              return BoundedTransferPart(
                transferId: chunk.transferId,
                index: chunk.index,
                chunkCount: chunk.chunkCount,
                encodedSize: chunk.encodedSize,
                sha256: chunk.sha256,
                payload: chunk.payload.asUnmodifiableList,
              );
            }
            throw StateError("Publication review is unavailable");
          }),
          cancelled: stop.future,
        );
        final view = skir.PublicationView.serializer.fromBytes(bytes);
        if (view.id != expected) {
          throw StateError("Publication review does not match its transfer");
        }
        if (requestGeneration == generation) {
          output.add(PublicationObservation.available(view));
        }
      } on PublicationViewChanged catch (changed) {
        if (requestGeneration == generation) {
          output.add(PublicationObservation.fetching(changed.current));
          unawaited(fetch(changed.current, requestGeneration));
        }
      } on Object catch (error) {
        if (requestGeneration == generation && !stop.isCompleted) {
          output.add(PublicationObservation.unavailable(error.toString()));
        }
      }
    }

    final hints = skir.WatchPublicationRequest()
        .watch(
          ref,
          organizationId: organizationId,
          realmId: realmId,
          snapshot: (response) => response,
          reduce: (_, event) => event,
          reconciliation: const ProjectionReconciliation.latest(),
        )
        .listen(
          (hint) {
            final requestGeneration = ++generation;
            if (cancelled != null && !cancelled!.isCompleted) {
              cancelled!.complete();
            }
            cancelled = null;
            output.add(PublicationObservation.fetching(hint.current));
            unawaited(fetch(hint.current, requestGeneration));
          },
          onError: (Object error) {
            generation++;
            if (cancelled != null && !cancelled!.isCompleted) {
              cancelled!.complete();
            }
            cancelled = null;
            output.add(PublicationObservation.unavailable(error.toString()));
          },
        );
    output.onCancel = () async {
      generation++;
      if (cancelled != null && !cancelled!.isCompleted) cancelled!.complete();
      await hints.cancel();
    };
  });
}

MutationResponseDisposition classifyPublicationResponse(
  skir.PublishAuthoringResponse response,
) => switch (response) {
  skir.PublishAuthoringResponse_resultWrapper(
    value: skir.PublicationResult_blockedWrapper(),
  ) ||
  skir.PublishAuthoringResponse_resultWrapper(
    value: skir.PublicationResult_interruptedWrapper(),
  ) ||
  skir.PublishAuthoringResponse_resultWrapper(
    value: skir.PublicationResult_candidateChangedWrapper(),
  ) => MutationResponseDisposition.rejected,
  skir.PublishAuthoringResponse_resultWrapper(
    value: skir.PublicationResult_unknown(),
  ) =>
    MutationResponseDisposition.uncertain,
  skir.PublishAuthoringResponse_resultWrapper() =>
    MutationResponseDisposition.confirmed,
  _ => MutationResponseDisposition.uncertain,
};

final class PublicationViewChanged implements Exception {
  const PublicationViewChanged(this.current);
  final skir.PublicationViewId current;
}
