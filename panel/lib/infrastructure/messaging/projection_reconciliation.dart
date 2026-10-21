import "package:typewriter_panel/typewriter_panel.dart";

part "projection_reconciliation.freezed.dart";

/// Chooses how projection events reach the panel transport.
@freezed
sealed class ProjectionDelivery with _$ProjectionDelivery {
  /// Uses a core NATS subscription for current observations.
  const factory ProjectionDelivery.ephemeral() = ProjectionDeliveryEphemeral;

  /// Uses one exact named consumer from the persisted stream.
  const factory ProjectionDelivery.persistent({
    required String stream,
    required String consumer,
  }) = ProjectionDeliveryPersistent;
}

/// One persistent projection a generated watch route reads through a named
/// consumer.
///
/// The consumer name identifies the connection: its actor, its organization
/// when [organizationScoped], its session and the projection [id]. The backend
/// grants the same name, so a connection only reads its own consumer.
final class PersistentProjectionRoute {
  const PersistentProjectionRoute({
    required this.id,
    required this.organizationScoped,
  });

  final String id;
  final bool organizationScoped;

  /// Names the consumer of [client]. Throws a [StateError] when the
  /// projection is organization scoped and the client admitted none.
  String consumerName(NatsClient client) {
    final organization = client.organizationId;
    if (organizationScoped && organization == null) {
      throw StateError(
        "Persistent organization projection requires an admitted organization",
      );
    }
    return persistentConsumerName(
      actor: client.actorId.transportIdentity,
      organization: organizationScoped ? organization?.transportIdentity : null,
      session: client.connectionSession.transportSession,
      projection: id,
    );
  }
}

/// Chooses how a snapshot and later events reconcile into one projection.
@freezed
sealed class ProjectionReconciliation<TData, TResponse, TEvent>
    with _$ProjectionReconciliation<TData, TResponse, TEvent> {
  /// Applies every event to the latest delivered projection value.
  const factory ProjectionReconciliation.latest() =
      ProjectionLatest<TData, TResponse, TEvent>;

  /// Reconciles ordered events through feature owned sequence progress.
  const factory ProjectionReconciliation.sequenced({
    required int Function(TResponse) snapshotSequence,
    required int Function(TEvent) eventSequence,
    required SequencedCollection<TData> sequenceState,
  }) = ProjectionSequenced<TData, TResponse, TEvent>;
}

extension SequencedProjectionProgress<TData, TResponse, TEvent>
    on ProjectionSequenced<TData, TResponse, TEvent> {
  void installSnapshot(TResponse response, TData value) {
    final sequence = snapshotSequence(response);
    final current = sequenceState.snapshot;
    if (current != null && sequence < current.sequence) return;
    sequenceState.snapshot = SequencedSnapshot(
      sequence: sequence,
      value: value,
    );
  }

  SequencedEventResult applyEvent(
    TEvent event,
    TData Function(TData, TEvent) reduce,
  ) => sequenceState.apply(
    sequence: eventSequence(event),
    reduce: (current) => reduce(current, event),
  );

  TData get current => sequenceState.value;
}
