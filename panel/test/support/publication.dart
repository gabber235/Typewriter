import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

skir.CompilationRoot publicationRoot(String resource) => skir.CompilationRoot(
  projection: skir.CompilationProjectionId(value: "typewriter.page"),
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

/// Replays its current observation on each watch, as the transport snapshot does.
class TestPublicationRepository implements RealmPublicationRepository {
  TestPublicationRepository(this.scope);
  final AuthoringScope scope;
  final observations = StreamController<PublicationObservation>.broadcast(
    sync: true,
  );
  PublicationObservation current = PublicationObservation.available(
    skir.PublicationView(
      id: skir.PublicationViewId(value: "first"),
      status: readyPublicationStatus(),
    ),
  );
  final candidates = <skir.PublicationCandidateId>[];
  Future<SubmissionResult<skir.PublishAuthoringResponse>> Function()? send;
  void emit(skir.PublicationStatus status, {String id = "next"}) => observe(
    PublicationObservation.available(
      skir.PublicationView(
        id: skir.PublicationViewId(value: id),
        status: status,
      ),
    ),
  );
  void observe(PublicationObservation value) {
    current = value;
    observations.add(value);
  }

  @override
  Stream<PublicationObservation> watch() async* {
    yield current;
    yield* observations.stream;
  }

  @override
  PreparedCommit<skir.PublishAuthoringResponse> preparePublish(
    skir.PublicationCandidateId candidate,
  ) => PreparedCommit(
    id: Object(),
    label: "Publish saved content",
    resources: {WorkDriverId(domain: "publication", scope: scope)},
    replay: SubmissionReplay.unsupported,
    send: () async {
      candidates.add(candidate);
      return await send?.call() ??
          SubmissionConfirmed(
            skir.PublishAuthoringResponse.wrapResult(
              skir.PublicationResult.noChanges,
            ),
          );
    },
  );
  @override
  Future<List<skir.CompiledResourceStatus>> states(
    skir.CompilationStatusSelection selection,
  ) async => [];
  Future<void> close() => observations.close();
}

Future<void> waitForPublication(bool Function() predicate) async {
  for (var index = 0; index < 100 && !predicate(); index++) {
    await Future<void>.delayed(Duration.zero);
  }
  if (!predicate()) {
    throw StateError("Publication did not reach its expected state");
  }
}
