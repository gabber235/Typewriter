import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// One caller owned publication boundary for one authoring scope.
/// Observation replay is current state. Publish and status queries require scripts.
/// Delivery stays asynchronous so listeners can emit during replay or updates.
class TestPublicationRepository implements RealmPublicationRepository {
  TestPublicationRepository(
    this.scope, {
    required PublicationObservation initial,
  }) : _observations = BehaviorSubject<PublicationObservation>.seeded(initial);

  final AuthoringScope scope;
  final BehaviorSubject<PublicationObservation> _observations;
  final _candidates = <skir.PublicationCandidateId>[];
  PublicationObservation get current => _observations.value;
  List<skir.PublicationCandidateId> get candidates =>
      List.unmodifiable(_candidates);
  Future<SubmissionResult<skir.PublishAuthoringResponse>> Function()? send;
  Future<List<skir.CompiledResourceStatus>> Function(
    skir.CompilationStatusSelection selection,
  )?
  readStates;

  void emit(skir.PublicationStatus status, {String id = "next"}) => observe(
    PublicationObservation.available(
      skir.PublicationView(
        id: skir.PublicationViewId(value: id),
        status: status,
      ),
    ),
  );

  void observe(PublicationObservation value) => _observations.add(value);

  @override
  Stream<PublicationObservation> watch() => _observations.stream;

  @override
  PreparedCommit<skir.PublishAuthoringResponse> preparePublish(
    skir.PublicationCandidateId candidate,
  ) => PreparedCommit(
    id: Object(),
    label: "Publish saved content",
    resources: {WorkDriverId(domain: "publication", scope: scope)},
    replay: SubmissionReplay.unsupported,
    send: () async {
      _candidates.add(candidate);
      final execute = send;
      if (execute == null) {
        throw StateError("No publication reply was scripted");
      }
      return execute();
    },
  );

  @override
  Future<List<skir.CompiledResourceStatus>> states(
    skir.CompilationStatusSelection selection,
  ) async {
    final read = readStates;
    if (read == null) throw StateError("No compiled status reply was scripted");
    return read(selection);
  }

  /// Call after disposing the driver or container that consumes this repository.
  Future<void> close() => _observations.close();
}

/// The publication of [_realm] as the panel sees it over the connection
/// [_connection] returns when it starts watching: like the Realm's hints, its
/// reviews stop once that connection closes, and the repository is rebuilt
/// for the next one.
final class ConnectedPublicationRepository
    implements RealmPublicationRepository {
  ConnectedPublicationRepository(this._realm, this._connection);

  final TestPublicationRepository _realm;
  final Future<NatsClient> Function() _connection;

  @override
  Stream<PublicationObservation> watch() => Stream.fromFuture(_connection())
      .asyncExpand(
        (connection) => _realm.watch().takeUntil(
          connection.connectionStateChanges.where(
            (state) => state is NatsClosed,
          ),
        ),
      );

  @override
  PreparedCommit<skir.PublishAuthoringResponse> preparePublish(
    skir.PublicationCandidateId candidate,
  ) => _realm.preparePublish(candidate);

  @override
  Future<List<skir.CompiledResourceStatus>> states(
    skir.CompilationStatusSelection selection,
  ) => _realm.states(selection);
}

skir.CompilationRoot publicationRoot(String resource) => skir.CompilationRoot(
  projection: skir.CompilationProjectionId(value: "typewriter.resource-graph"),
  resource: skir.ResourceId(value: resource),
);

/// A review ready to release one removal: [resource], which the selected
/// publication released from [published].
skir.PublicationStatus removalPublicationStatus(
  skir.ResourceId resource, {
  required skir.AuthoringRecord published,
}) => skir.PublicationStatus.createReady(
  candidate: skir.PublicationCandidateId(value: "candidate"),
  notices: const [],
  baseline: skir.PublicationBaseline.initial,
  changes: skir.PublicationDelta(
    first: skir.PublicationChange.wrapRootRemoved(
      skir.PublishedRoot(
        root: publicationRoot(resource.value),
        record: published,
      ),
    ),
    additional: const [],
  ),
);

skir.PublicationStatus readyPublicationStatus({
  String candidate = "candidate",
  String resource = "page",
}) => skir.PublicationStatus.createReady(
  candidate: skir.PublicationCandidateId(value: candidate),
  notices: const [],
  baseline: skir.PublicationBaseline.initial,
  changes: skir.PublicationDelta(
    first: skir.PublicationChange.wrapRootAdded(publicationRoot(resource)),
    additional: const [],
  ),
);

/// A publication problem [id] of kind [code] at [primary], or at the root of
/// [resource] when no location is given, raised by the rule [origin] and
/// backed by [evidence] when given.
skir.PublicationDiagnosticDetails publicationProblem({
  String id = "problem",
  String code = "required",
  String message = "A required Page value is missing",
  String resource = "page",
  skir.ValueLocation? primary,
  skir.RuleOrigin? origin,
  skir.DiagnosticEvidence? evidence,
}) => skir.PublicationDiagnosticDetails(
  evidence: evidence,
  id: skir.DiagnosticId(value: id),
  origin: origin ?? skir.RuleOrigin.defaultInstance,
  code: code,
  message: message,
  related: const [],
  primary:
      primary ??
      skir.ValueLocation(
        resource: skir.ResourceId(value: resource),
        path: skir.ValuePath(segments: const []),
      ),
);

/// A review that blocks publishing on [problem], or on the default
/// [publicationProblem].
skir.PublicationStatus_Blocked blockedPublicationReview({
  skir.PublicationDiagnosticDetails? problem,
}) => skir.PublicationStatus_Blocked(
  notices: const [],
  baseline: skir.PublicationBaseline.initial,
  blockers: skir.PublicationBlockers(
    first: skir.PublicationBlocker(details: problem ?? publicationProblem()),
    additional: const [],
  ),
  confirmedChanges: const [],
  pendingRoots: const [],
);

/// The publication view blocked on the problem "original": the value at
/// [at] is unfinished, raised by the rule [origin] and backed by [evidence]
/// when given.
RealmPublicationView unfinishedValueBlocking(
  skir.ValueLocation at, {
  required skir.RuleOrigin origin,
  skir.DiagnosticEvidence? evidence,
}) => RealmPublicationView.blocked(
  blockedPublicationReview(
    problem: publicationProblem(
      id: "original",
      code: "unfinished_value",
      message: "A required value is unfinished.",
      primary: at,
      origin: origin,
      evidence: evidence,
    ),
  ),
);

/// The publication status of a [blockedPublicationReview] on [problem].
skir.PublicationStatus blockedPublicationStatus({
  skir.PublicationDiagnosticDetails? problem,
}) => skir.PublicationStatus.wrapBlocked(
  blockedPublicationReview(problem: problem),
);

PublicationObservation publicationObservation(
  skir.PublicationStatus status, {
  String id = "first",
}) => PublicationObservation.available(
  skir.PublicationView(
    id: skir.PublicationViewId(value: id),
    status: status,
  ),
);

/// A publication of [resource] that is activating, with nothing left to
/// review after it.
skir.PublicationStatus publishingPublicationStatus({
  String publication = "active",
  String resource = "page",
}) => skir.PublicationStatus.createPublishing(
  publication: skir.PublicationId(value: publication),
  phase: skir.PublicationActivationPhase.activating,
  releasing: skir.PublicationDelta(
    first: skir.PublicationChange.wrapRootAdded(publicationRoot(resource)),
    additional: const [],
  ),
  next: skir.PublicationPendingReview(
    findings: const [],
    confirmedChanges: const [],
    pendingRoots: const [],
    blockers: const [],
    notices: const [],
  ),
);
