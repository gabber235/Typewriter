import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/core/trait.dart";
import "package:typewriter_testkit/src/core/world.dart";
import "package:typewriter_testkit/src/authoring/application/publication_fixture.dart";
import "package:typewriter_testkit/src/doubles/realm_library.dart";

/// How the Realm answers when the user publishes.
enum PublishReply {
  /// The Realm activates the publication and reports everything published.
  activated,

  /// The reply is lost, so the panel cannot tell whether it published.
  lost,
}

/// The seeded Realm reports [observation] for its saved content: a review
/// ready to publish, a blocked one, one being published, or none at all.
/// Publishing answers with [reply].
Trait publication(
  PublicationObservation observation, {
  PublishReply reply = PublishReply.activated,
}) => _Publication(observation, reply);

final class _Publication extends Trait {
  const _Publication(this.observation, this.reply);

  final PublicationObservation observation;
  final PublishReply reply;

  @override
  Slot get slot => const Slot("publication");

  @override
  String get description => "publication(${observation.runtimeType}, $reply)";

  @override
  void applyTo(WorldBuilder world) => world.onStart((started) {
    final repository = started.requireRealm.publication..observe(observation);
    repository.send = () async => switch (reply) {
      PublishReply.activated => () {
        final published = skir.PublicationId(value: "published");
        repository.emit(
          skir.PublicationStatus.createCurrent(
            selected: published,
            notices: const [],
          ),
          id: "published",
        );
        return SubmissionResult.confirmed(
          skir.PublishAuthoringResponse.createActivated(publication: published),
        );
      }(),
      PublishReply.lost =>
        SubmissionResult<skir.PublishAuthoringResponse>.uncertain(
          message: "The Realm's answer was lost",
          cause: StateError("No reply"),
          stackTrace: StackTrace.current,
        ),
    };
  });
}

/// The error [id] of kind [code] that a Realm check raises at [location]
/// with [message].
skir.Diagnostic realmDiagnostic(
  String id,
  skir.ValueLocation location, {
  String message = "Text must not be blank",
  String code = "realm.check",
}) => skir.Diagnostic(
  id: skir.DiagnosticId(value: id),
  origin: skir.RuleOrigin.defaultInstance,
  code: code,
  message: message,
  severity: skir.DiagnosticSeverity.error,
  primary: location,
  related: const [],
);

/// A diagnostic as a publication review reports it.
extension DiagnosticInPublication on skir.Diagnostic {
  /// This diagnostic as the details of a publication problem, without
  /// evidence.
  skir.PublicationDiagnosticDetails get publicationDetails =>
      skir.PublicationDiagnosticDetails(
        evidence: null,
        id: id,
        origin: origin,
        code: code,
        message: message,
        primary: primary,
        related: related,
      );
}

/// The publication status blocked by [problems], the first one first.
skir.PublicationStatus blockedPublication(
  List<skir.PublicationDiagnosticDetails> problems,
) => skir.PublicationStatus.createBlocked(
  notices: const [],
  baseline: skir.PublicationBaseline.initial,
  blockers: skir.PublicationBlockers(
    first: skir.PublicationBlocker(details: problems.first),
    additional: [
      for (final problem in problems.skip(1))
        skir.PublicationBlocker(details: problem),
    ],
  ),
  confirmedChanges: const [],
  pendingRoots: const [],
);

/// The publication status blocked by one problem per message on the root
/// of [resource], the problem with the first message first.
skir.PublicationStatus publicationBlockedBy(
  List<String> messages, {
  required String resource,
}) => blockedPublication([
  for (final (index, message) in messages.indexed)
    publicationProblem(
      id: "problem $index",
      message: message,
      resource: resource,
    ),
]);

/// The findings of one run, ending with [outcome], of the check that raised
/// [diagnostic] at its location after reading [facts] and looking up the
/// names in [scopes], in [status] against the seeded Realm's catalog.
skir.FindingSet findingSet(
  skir.Diagnostic diagnostic, {
  skir.FindingStatus status = skir.FindingStatus.current,
  skir.CheckOutcome outcome = skir.CheckOutcome.finished,
  List<skir.EditExpectation> facts = const [],
  List<skir.CheckEvidence_Scope> scopes = const [],
}) => skir.FindingSet(
  ticket: skir.CheckTicket(
    instance: skir.CheckInstanceId(
      rule: skir.RuleId(origin: diagnostic.origin, localIndex: 0),
      location: diagnostic.primary!,
    ),
    catalog: realmDocument().catalog.snapshot.generation,
  ),
  evidence: [
    for (final fact in facts) skir.CheckEvidence.wrapFact(fact),
    for (final scope in scopes) skir.CheckEvidence.wrapScope(scope),
  ],
  outcome: outcome,
  findings: [diagnostic],
  status: status,
);
