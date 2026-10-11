import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "authoring_relation_index.freezed.dart";

@freezed
abstract class AuthoringOwnershipPath with _$AuthoringOwnershipPath {
  const factory AuthoringOwnershipPath({
    required List<skir.ResourceId> owners,
    String? problem,
  }) = _AuthoringOwnershipPath;
}

@freezed
abstract class AuthoringRelationIndex with _$AuthoringRelationIndex {
  const factory AuthoringRelationIndex({
    required Map<skir.ResourceId, List<skir.ResourceId>> parents,
    required Map<skir.ResourceId, List<skir.ResourceId>> children,
    required Set<skir.TypeDefinitionId> ownedDefinitions,
    required List<String> problems,
    required Map<skir.ResourceId, List<String>> resourceProblems,
  }) = _AuthoringRelationIndex;

  const AuthoringRelationIndex._();

  factory AuthoringRelationIndex.fromDocument(AuthoringDocument document) {
    final childSlots = <skir.RelationId, skir.EndpointSlot>{};
    final definitions = <skir.TypeDefinitionId>{};
    final problems = <String>[];
    final malformed = <skir.RelationId>{};
    final resourceProblems = <skir.ResourceId, List<String>>{};

    void flag(skir.ResourceId resource, String problem) {
      resourceProblems.putIfAbsent(resource, () => []).add(problem);
    }

    for (final relation in document.catalog.snapshot.relations) {
      if (!relation.families.any(
        (family) => family.value == "resource.ownership",
      )) {
        continue;
      }
      final firstOwns =
          relation.first.cardinality == skir.EndpointCardinality.one &&
          relation.second.cardinality == skir.EndpointCardinality.many;
      final secondOwns =
          relation.second.cardinality == skir.EndpointCardinality.one &&
          relation.first.cardinality == skir.EndpointCardinality.many;
      if (!firstOwns && !secondOwns) {
        malformed.add(relation.id);
        problems.add(
          "Ownership ${relation.id.value} has no unique owner endpoint",
        );
        continue;
      }
      childSlots[relation.id] = firstOwns
          ? skir.EndpointSlot.second
          : skir.EndpointSlot.first;
      definitions.add(
        firstOwns
            ? relation.second.resource.definition
            : relation.first.resource.definition,
      );
    }

    final parents = <skir.ResourceId, Set<skir.ResourceId>>{};
    final children = <skir.ResourceId, Set<skir.ResourceId>>{};
    for (final link in document.links) {
      if (malformed.contains(link.contract)) {
        final problem =
            "Ownership ${link.contract.value} has no unique owner endpoint";
        flag(link.first, problem);
        flag(link.second, problem);
        continue;
      }
      final childSlot = childSlots[link.contract];
      if (childSlot == null) continue;
      final child = childSlot == skir.EndpointSlot.second
          ? link.second
          : link.first;
      final owner = childSlot == skir.EndpointSlot.second
          ? link.first
          : link.second;
      if (document.entry(owner) == null || document.entry(child) == null) {
        final problem =
            "Ownership ${link.contract.value} references an absent resource";
        problems.add(problem);
        flag(owner, problem);
        flag(child, problem);
        continue;
      }
      parents.putIfAbsent(child, () => {}).add(owner);
      children.putIfAbsent(owner, () => {}).add(child);
    }

    return AuthoringRelationIndex(
      parents: {
        for (final entry in parents.entries)
          entry.key: List.unmodifiable(entry.value),
      },
      children: {
        for (final entry in children.entries)
          entry.key: List.unmodifiable(entry.value),
      },
      ownedDefinitions: definitions,
      problems: problems,
      resourceProblems: {
        for (final entry in resourceProblems.entries)
          entry.key: List.unmodifiable(entry.value),
      },
    );
  }

  List<skir.ResourceId> ownedBy(skir.ResourceId owner) =>
      children[owner] ?? const [];

  AuthoringOwnershipPath ownerPath(skir.ResourceId resource) {
    final path = <skir.ResourceId>[];
    final visited = <skir.ResourceId>{resource};
    var current = resource;
    while (true) {
      final localProblems = resourceProblems[current] ?? const <String>[];
      if (localProblems.isNotEmpty) {
        return AuthoringOwnershipPath(
          owners: path,
          problem: localProblems.join("\n"),
        );
      }
      final owners = parents[current] ?? const <skir.ResourceId>[];
      if (owners.isEmpty) return AuthoringOwnershipPath(owners: path);
      if (owners.length != 1) {
        return AuthoringOwnershipPath(
          owners: path,
          problem: "Resource has multiple owners",
        );
      }
      current = owners.single;
      if (!visited.add(current)) {
        return AuthoringOwnershipPath(
          owners: path,
          problem: "Ownership contains a cycle",
        );
      }
      path.add(current);
    }
  }
}
