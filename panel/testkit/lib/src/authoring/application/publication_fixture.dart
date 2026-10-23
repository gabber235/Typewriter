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
