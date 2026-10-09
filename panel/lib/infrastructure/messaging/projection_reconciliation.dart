import "package:typewriter_panel/typewriter_panel.dart";

part "projection_reconciliation.freezed.dart";

/// Chooses how projection events reach the panel transport.
@freezed
sealed class ProjectionDelivery with _$ProjectionDelivery {
  /// Uses a core NATS subscription for current observations.
  const factory ProjectionDelivery.ephemeral() = ProjectionDeliveryEphemeral;

  /// Uses an ordered consumer from the named persisted stream.
  const factory ProjectionDelivery.ordered({required String stream}) =
      ProjectionDeliveryOrdered;
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
