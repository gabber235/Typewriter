import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/core/trait.dart";
import "package:typewriter_testkit/src/core/world.dart";
import "package:typewriter_testkit/src/doubles/realm.dart";

/// The Realm lets dragged resources land on [destinations] through [via],
/// answering each drag after [delay]; without this trait nothing accepts a
/// drop.
Trait dropsOnto(
  List<skir.ResourceId> destinations, {
  RealmOperation via = const RealmOperation.moveTo(),
  Duration delay = Duration.zero,
}) => _DropsOnto(destinations, via, delay);

final class _DropsOnto extends Trait {
  const _DropsOnto(this.destinations, this.via, this.delay);

  final List<skir.ResourceId> destinations;
  final RealmOperation via;
  final Duration delay;

  @override
  Slot get slot => const Slot("drop candidates");

  @override
  String get description =>
      "dropsOnto(${destinations.map((it) => it.value).join(", ")}, "
      "via: $via, delay: $delay)";

  @override
  void applyTo(WorldBuilder world) => world.onStart(
    (started) => started.requireRealm.answerDropCandidates = (_) async {
      await Future<void>.delayed(delay);
      return skir.ResolveDropCandidatesResult.wrapResolved([
        skir.DropCandidates(
          operation: via.definition.id,
          destinations: destinations,
          complete: true,
        ),
      ]);
    },
  );
}

/// The Realm cannot read its saved document again: every refresh fails, as
/// when the Realm is unreachable after the panel opened it.
const Trait savedDocumentUnreadable = _SavedDocumentUnreadable();

final class _SavedDocumentUnreadable extends Trait {
  const _SavedDocumentUnreadable();

  @override
  Slot get slot => const Slot("refresh");

  @override
  String get description => "savedDocumentUnreadable";

  @override
  void applyTo(WorldBuilder world) => world.onStart(
    (started) => started.requireRealm.refreshFailure = StateError(
      "The Realm cannot read its saved document",
    ),
  );
}

/// Someone else saves each of [changes] to the Realm in turn, the first
/// [every] after the panel opened and each next one [every] later, such as a
/// rename that is renamed again while the panel reviews it.
Trait remoteChanges(
  List<void Function(AuthoringEdit edit)> changes, {
  Duration every = const Duration(milliseconds: 300),
}) => _RemoteChanges(changes, every);

final class _RemoteChanges extends Trait {
  const _RemoteChanges(this.changes, this.every);

  final List<void Function(AuthoringEdit edit)> changes;
  final Duration every;

  @override
  Slot get slot => const Slot("remote change");

  @override
  String get description =>
      "remoteChanges(${changes.length} changes, every: $every)";

  @override
  void applyTo(WorldBuilder world) => world.onStart((started) {
    for (final (index, change) in changes.indexed) {
      started.schedule(
        every * (index + 1),
        () => started.requireRealm.remoteChange(change),
      );
    }
  });
}

/// The Realm answers each preparation step only once [until] completes, and
/// adds [findings] to every value it prepares, such as a creation whose
/// preparation is still running or reports a finding.
Trait heldPreparations(
  Future<void> until, {
  List<skir.InitializationDiagnostic> findings = const [],
}) => _HeldPreparations(until, findings);

final class _HeldPreparations extends Trait {
  const _HeldPreparations(this.until, this.findings);

  final Future<void> until;
  final List<skir.InitializationDiagnostic> findings;

  @override
  Slot get slot => const Slot("preparation");

  @override
  String get description => "heldPreparations(${findings.length} findings)";

  @override
  void applyTo(WorldBuilder world) => world.onStart((started) {
    final realm = started.requireRealm;
    realm.answerPrepareStep = (step) async {
      await until;
      return switch (realm.document.prepareStep(step)) {
        skir.PrepareValueResult_readyWrapper(:final value) =>
          skir.PrepareValueResult.wrapReady(
            skir.PreparedValue(
              content: value.content,
              findings: [...value.findings, ...findings],
            ),
          ),
        final other => other,
      };
    };
  });
}
