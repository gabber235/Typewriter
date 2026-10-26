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

skir.CompilationRoot publicationRoot(String resource) => skir.CompilationRoot(
  projection: skir.CompilationProjectionId(value: "typewriter.resource-graph"),
  resource: skir.ResourceId(value: resource),
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

skir.PublicationDiagnosticDetails publicationProblem({
  String id = "problem",
  String message = "A required Page value is missing",
  String resource = "page",
}) => skir.PublicationDiagnosticDetails(
  evidence: null,
  id: skir.DiagnosticId(value: id),
  origin: skir.RuleOrigin.defaultInstance,
  code: "required",
  message: message,
  related: const [],
  primary: skir.ValueLocation(
    resource: skir.ResourceId(value: resource),
    path: skir.ValuePath(segments: const []),
  ),
);

skir.PublicationStatus blockedPublicationStatus() =>
    skir.PublicationStatus.createBlocked(
      notices: const [],
      baseline: skir.PublicationBaseline.initial,
      blockers: skir.PublicationBlockers(
        first: skir.PublicationBlocker(details: publicationProblem()),
        additional: const [],
      ),
      confirmedChanges: const [],
      pendingRoots: const [],
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
