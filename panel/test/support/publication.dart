import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

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

Future<void> waitForPublication(bool Function() predicate) async {
  for (var index = 0; index < 100 && !predicate(); index++) {
    await Future<void>.delayed(Duration.zero);
  }
  if (!predicate()) {
    throw StateError("Publication did not reach its expected state");
  }
}
