import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;

sealed class AuthoringDeltaApplication {
  const AuthoringDeltaApplication();
}

final class AuthoringDeltaApplied extends AuthoringDeltaApplication {
  const AuthoringDeltaApplied(this.snapshot);

  final skir.AuthoringSnapshot snapshot;
}

final class AuthoringDeltaDuplicate extends AuthoringDeltaApplication {
  const AuthoringDeltaDuplicate();
}

final class AuthoringDeltaRecoveryRequired extends AuthoringDeltaApplication {
  const AuthoringDeltaRecoveryRequired();
}

/// Applies one verified transfer only when its predecessor evidence matches.
///
/// A recovery result means the caller must keep its current snapshot and fetch
/// one complete snapshot. No partial resource, relation, observation, or
/// finding update escapes this function.
AuthoringDeltaApplication applyAuthoringChange(
  skir.AuthoringSnapshot current,
  skir.AuthoringChanged change,
) {
  if (change.generation != current.generation) {
    return const AuthoringDeltaRecoveryRequired();
  }
  if (change.snapshot == current.snapshot &&
      change.findingsToken == current.findingsToken) {
    return const AuthoringDeltaDuplicate();
  }
  if (change.previousSnapshot != current.snapshot ||
      change.previousFindings != current.findingsToken) {
    return const AuthoringDeltaRecoveryRequired();
  }

  final resources = <skir.ResourceId, skir.AuthoringResource>{
    for (final resource in current.resources) resource.id: resource,
  };
  for (final resource in change.resources) {
    switch (resource) {
      case skir.AuthoringResourceChange_upsertWrapper(:final value):
        resources[value.id] = value;
      case skir.AuthoringResourceChange_removeWrapper(:final value):
        if (resources.remove(value) == null) {
          return const AuthoringDeltaRecoveryRequired();
        }
      case skir.AuthoringResourceChange_unknown():
        return const AuthoringDeltaRecoveryRequired();
    }
  }

  final links = current.links.toList();
  for (final removal in change.relations.removals) {
    if (!links.remove(removal)) {
      return const AuthoringDeltaRecoveryRequired();
    }
  }
  for (final replacement in change.relations.metadataChanged) {
    final candidates = <int>[
      for (var index = 0; index < links.length; index++)
        if (_sameRelationEndpoints(links[index], replacement)) index,
    ];
    if (candidates.length != 1) {
      return const AuthoringDeltaRecoveryRequired();
    }
    links[candidates.single] = replacement;
  }
  for (final creation in change.relations.created) {
    if (links.contains(creation)) {
      return const AuthoringDeltaRecoveryRequired();
    }
    links.add(creation);
  }

  final observations = <skir.InputIdentity, skir.InputObservation>{
    for (final observation in current.observations)
      observation.identity: observation,
  };
  for (final observation in change.changedObservations) {
    observations[observation.identity] = observation;
  }

  final findings =
      change.findings?.findings.toList() ??
      current.findings.map((finding) {
        if (finding.status == skir.FindingStatus.outdated ||
            !finding.observations.any(
              (observed) =>
                  (observations[observed.identity]?.token ??
                      current.absentInputToken) !=
                  observed.token,
            )) {
          return finding;
        }
        return skir.FindingSet(
          ticket: finding.ticket,
          observations: finding.observations,
          outcome: finding.outcome,
          findings: finding.findings,
          status: skir.FindingStatus.outdated,
        );
      }).toList();

  return AuthoringDeltaApplied(
    skir.AuthoringSnapshot(
      snapshot: change.snapshot,
      generation: change.generation,
      resources: resources.values,
      links: links,
      findings: findings,
      observations: observations.values,
      absentInputToken: current.absentInputToken,
      findingsToken: change.findingsToken,
    ),
  );
}

bool _sameRelationEndpoints(
  skir.LinkProjection first,
  skir.LinkProjection second,
) =>
    first.contract == second.contract &&
    first.first == second.first &&
    first.second == second.second;
