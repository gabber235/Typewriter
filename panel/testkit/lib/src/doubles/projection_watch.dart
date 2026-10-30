import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/core/world.dart";

/// The scope a test projection is watched from, as a feature provider would.
final _watchScope = Provider<Ref>((ref) => ref);

/// The bytes of a counter projection reply or event carrying [value].
Uint8List counterBytes(int value) =>
    skir.Duration.serializer.toBytes(skir.Duration(milliseconds: value));

/// Watching a projection of one counter through the panel's real watch
/// adapter over [World.nats].
///
/// The snapshot reply on [subject] and every event on [eventSubject] carry
/// one counter value, written with [counterBytes]. A test registers the reply
/// with `world.nats.registerHandler` and emits events on the connection; it
/// states only what its case changes.
extension CounterProjection on World {
  /// Watches the counter projection.
  ///
  /// By default the snapshot installs its value and each event replaces it.
  /// [snapshot] and [reduce] change how a reply and an event become the
  /// projection. A [sequence] reconciles in order: the counter value is the
  /// sequence, so a value that skips ahead reloads the snapshot. [persistent]
  /// reads events through a named consumer instead of a core subscription.
  /// [confirmed] facts reduce through [reduceConfirmed], starting at
  /// [initialValue]; [reconcileSnapshot] merges a later snapshot with them.
  ///
  /// The panel must be connected to NATS first, so a signed in world awaits
  /// `initialized()` before it watches.
  Stream<int> watchCounter({
    String subject = "watch",
    String eventSubject = "events",
    bool persistent = false,
    SequencedCollection<int>? sequence,
    int Function(int value)? snapshot,
    int Function(int current, int event)? reduce,
    Stream<int>? confirmed,
    int Function(int current, int fact)? reduceConfirmed,
    int Function(int current, int snapshot)? reconcileSnapshot,
    int? initialValue,
  }) {
    final reduceEvent = reduce ?? (_, event) => event;
    final reduceFact = reduceConfirmed;
    return container
        .read(_watchScope)
        .watchProjection<int, skir.Duration, skir.Duration>(
          subject: subject,
          eventSubject: eventSubject,
          requestBytes: Uint8List(0),
          responseSerializer: skir.Duration.serializer,
          eventSerializer: skir.Duration.serializer,
          snapshot: (response) =>
              (snapshot ?? (value) => value)(response.milliseconds),
          reduce: (current, event) => reduceEvent(current, event.milliseconds),
          reduceConfirmed: reduceFact == null
              ? null
              : (current, fact) => reduceFact(current, fact.milliseconds),
          confirmedEvents: confirmed?.map(
            (fact) => skir.Duration(milliseconds: fact),
          ),
          reconcileSnapshot: reconcileSnapshot,
          initialValue: initialValue,
          delivery: persistent
              ? const ProjectionDelivery.persistent(
                  stream: "TYPEWRITER_FIXTURE",
                  route: PersistentProjectionRoute(
                    id: "counter",
                    organizationScoped: false,
                  ),
                )
              : const ProjectionDelivery.ephemeral(),
          reconciliation: sequence == null
              ? const ProjectionReconciliation.latest()
              : ProjectionReconciliation.sequenced(
                  snapshotSequence: (response) => response.milliseconds,
                  eventSequence: (event) => event.milliseconds,
                  sequenceState: sequence,
                ),
        );
  }
}
