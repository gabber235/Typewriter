import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/features/organizations/features/realms/application/authoring_delta.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;

void main() {
  test("applies one commit and invalidates only changed finding evidence", () {
    final changedIdentity = skir.InputIdentity.createSelection(
      value: "changed",
    );
    final absentIdentity = skir.InputIdentity.createSelection(value: "absent");
    final current = _snapshot(
      findings: [
        _finding(changedIdentity, "before"),
        _finding(absentIdentity, "absent"),
      ],
      observations: [_observation(changedIdentity, "before")],
    );
    final resource = _resource("second");
    final change = _change(
      resources: [skir.AuthoringResourceChange.wrapUpsert(resource)],
      changedObservations: [_observation(changedIdentity, "after")],
    );

    final result = applyAuthoringChange(current, change);

    final snapshot = (result as AuthoringDeltaApplied).snapshot;
    expect(snapshot.snapshot, change.snapshot);
    expect(snapshot.resources.single, resource);
    expect(snapshot.findings.first.status, skir.FindingStatus.outdated);
    expect(snapshot.findings.last.status, skir.FindingStatus.current);
  });

  test("rejects ambiguous relation metadata replacement", () {
    final first = _link("first");
    final second = _link("second");
    final current = _snapshot(links: [first, second]);
    final replacement = _link("replacement");
    final change = _change(
      relations: skir.RelationProjectionDelta(
        removals: const [],
        created: const [],
        metadataChanged: [replacement],
      ),
    );

    expect(
      applyAuthoringChange(current, change),
      isA<AuthoringDeltaRecoveryRequired>(),
    );
  });

  test("replaces findings at the same snapshot and ignores its duplicate", () {
    final current = _snapshot();
    final replacement = _finding(
      skir.InputIdentity.createSelection(value: "replacement"),
      "absent",
    );
    final change = _change(
      previousSnapshot: current.snapshot,
      snapshot: current.snapshot,
      findingsToken: "findings:2",
      findings: skir.AuthoringFindingsReplacement(findings: [replacement]),
    );

    final applied = applyAuthoringChange(current, change);
    final snapshot = (applied as AuthoringDeltaApplied).snapshot;
    expect(snapshot.findings, [replacement]);
    expect(snapshot.findingsToken, change.findingsToken);
    expect(
      applyAuthoringChange(snapshot, change),
      isA<AuthoringDeltaDuplicate>(),
    );
  });

  test("keeps the current snapshot when predecessor evidence has a gap", () {
    final current = _snapshot();
    final change = _change(
      previousSnapshot: skir.SnapshotId(value: "realm:missing"),
    );

    expect(
      applyAuthoringChange(current, change),
      isA<AuthoringDeltaRecoveryRequired>(),
    );
  });
}

skir.AuthoringSnapshot _snapshot({
  Iterable<skir.LinkProjection> links = const [],
  Iterable<skir.FindingSet> findings = const [],
  Iterable<skir.InputObservation> observations = const [],
}) => skir.AuthoringSnapshot(
  snapshot: skir.SnapshotId(value: "realm:1"),
  generation: skir.CatalogGeneration(value: "catalog:1"),
  resources: const [],
  links: links,
  findings: findings,
  observations: observations,
  absentInputToken: skir.InputToken(value: "absent"),
  findingsToken: skir.FindingsToken(value: "findings:1"),
);

skir.AuthoringChanged _change({
  skir.SnapshotId? previousSnapshot,
  skir.SnapshotId? snapshot,
  String findingsToken = "findings:1",
  Iterable<skir.AuthoringResourceChange> resources = const [],
  skir.RelationProjectionDelta? relations,
  skir.AuthoringFindingsReplacement? findings,
  Iterable<skir.InputObservation> changedObservations = const [],
}) => skir.AuthoringChanged(
  previousSnapshot: previousSnapshot ?? skir.SnapshotId(value: "realm:1"),
  snapshot: snapshot ?? skir.SnapshotId(value: "realm:2"),
  generation: skir.CatalogGeneration(value: "catalog:1"),
  batch: skir.BatchId(value: "batch:1"),
  resources: resources,
  relations:
      relations ??
      skir.RelationProjectionDelta(
        removals: const [],
        created: const [],
        metadataChanged: const [],
      ),
  previousFindings: skir.FindingsToken(value: "findings:1"),
  findingsToken: skir.FindingsToken(value: findingsToken),
  findings: findings,
  changedObservations: changedObservations,
);

skir.AuthoringResource _resource(String name) => skir.AuthoringResource(
  id: skir.ResourceId(value: name),
  definition: skir.ResourceDefinitionId(value: "definition"),
  content: skir.AuthoringRecord(
    configuration: skir.TypeSelection.unknown,
    fields: const [],
  ),
);

skir.LinkProjection _link(String location) => skir.LinkProjection(
  contract: skir.RelationId(value: "relation"),
  first: skir.ResourceId(value: "first"),
  second: skir.ResourceId(value: "second"),
  firstLocation: skir.ValuePath(
    segments: [skir.PathSegment.createField(name: location)],
  ),
  secondLocation: null,
);

skir.InputObservation _observation(skir.InputIdentity identity, String token) =>
    skir.InputObservation(
      identity: identity,
      token: skir.InputToken(value: token),
    );

skir.FindingSet _finding(skir.InputIdentity identity, String token) =>
    skir.FindingSet(
      ticket: skir.CheckTicket.defaultInstance,
      observations: [_observation(identity, token)],
      outcome: skir.CheckOutcome.unknown,
      findings: const [],
      status: skir.FindingStatus.current,
    );
