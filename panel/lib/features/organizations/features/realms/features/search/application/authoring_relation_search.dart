import "dart:async";

import "package:flutter/foundation.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

const createRelatedResourceCommandId = SearchCommandId(
  "authoring.relation.create",
);
const linkRelatedResourceCommandId = SearchCommandId("authoring.relation.link");

SearchScope relationFieldSearchScope({
  required ValueListenable<AsyncValue<RealmRelationField>> field,
  required ValueListenable<AsyncValue<RealmEditorCatalogState>> catalog,
}) => PredicateSearchScope(
  dependencies: [field, catalog],
  evaluate: (result, query) {
    final selected = field.value.value;
    final snapshot = catalog.value.value?.snapshot;
    if (selected == null || snapshot == null) {
      return const SearchResultVisibility.hidden();
    }
    final root = switch (result.payload) {
      AuthoringCreationOption(:final root) => root,
      AuthoringSearchResultPayload(:final subject) => subject.content.rootType,
      _ => null,
    };
    if (root == null ||
        !selected.accepts(root, TypeRegistry(snapshot.catalog))) {
      return const SearchResultVisibility.hidden();
    }
    if (result.payload case AuthoringSearchResultPayload(:final owner)) {
      if (selected.relation.families.contains("resource.ownership") &&
          owner != null) {
        return const SearchResultVisibility.hidden();
      }
    }
    return const SearchResultVisibility.visible();
  },
);

skir.CreationAttachment relationAttachment(
  skir.ResourceId host,
  RealmRelationField field,
) => skir.CreationAttachment(
  host: host,
  relation: skir.RelationId(value: field.relation.id),
  hostSide: field.endpoint.side == RealmRelationEndpointSide.source
      ? skir.RelationEndpointSide.source
      : skir.RelationEndpointSide.target,
);

List<SearchCommand> relationFieldCommands({
  required Ref ref,
  required skir.ResourceId host,
  required ValueListenable<AsyncValue<RealmRelationField>> field,
  skir.CreationAttachment? ownershipForNewTarget,
  FutureOr<DataValue?> Function(AuthoringCreationOption option)? initialValue,
  SearchHostEffect? Function(CreatedAuthoringResource resource)? createdEffect,
}) => [
  SearchCommand.single<AuthoringCreationOption>(
    id: createRelatedResourceCommandId,
    presentation: const SearchCommandPresentation(label: "Create"),
    matcher: const SearchResultMatcher(authoringCreationSearchResultType),
    dependencies: [field],
    evaluate: (option, target) {
      final selected = field.value.value;
      if (selected == null) {
        return const SearchCommandState.disabled("Relation is loading");
      }
      if (!selected.relation.families.contains("resource.ownership") &&
          ownershipForNewTarget == null &&
          _nearestOwnership(ref, host, option.root) == null) {
        return const SearchCommandState.disabled(
          "Choose an owner for the new resource",
        );
      }
      return const SearchCommandState.enabled();
    },
    execute: (execution, option, target) async {
      final selected = field.value.value;
      if (selected == null) {
        return const SearchCommandResult.failed(
          message: "The relation is unavailable",
        );
      }
      final snapshot = ref.read(realmEditorCatalogProvider).value?.snapshot;
      if (snapshot == null ||
          !selected.accepts(option.root, TypeRegistry(snapshot.catalog))) {
        return const SearchCommandResult.failed(
          message: "The target type is no longer compatible",
        );
      }
      final ownership = selected.relation.families.contains(
        "resource.ownership",
      );
      final newTargetOwner =
          ownershipForNewTarget ?? _nearestOwnership(ref, host, option.root);
      if (!ownership && newTargetOwner == null) {
        return const SearchCommandResult.failed(
          message: "No compatible owner is available for the new resource",
        );
      }
      final partial = await initialValue?.call(option);
      final created = await execution.prompts.show(
        (context) => ref
            .read(resourceCreationProvider)
            .create(
              context: context,
              request: ResourceCreationRequest(
                definition: option.definition,
                title: "Create ${option.label}",
                concreteRoot: option.root,
                attachment: ownership
                    ? relationAttachment(host, selected)
                    : newTargetOwner,
                links: ownership
                    ? const []
                    : [relationAttachment(host, selected)],
                partial: partial,
                referenceOrigins: [host],
              ),
            ),
      );
      return created == null
          ? const SearchCommandResult.cancelled()
          : SearchCommandResult.completed(
              hostEffects: [?createdEffect?.call(created)],
            );
    },
  ),
  SearchCommand.single<AuthoringSearchResultPayload>(
    id: linkRelatedResourceCommandId,
    presentation: const SearchCommandPresentation(label: "Link"),
    matcher: const SearchResultMatcher(authoringResourceSearchResultType),
    dependencies: [field],
    evaluate: (payload, target) => field.value.value == null
        ? const SearchCommandState.disabled("Relation is loading")
        : const SearchCommandState.enabled(),
    execute: (execution, payload, target) async {
      final selected = field.value.value;
      final snapshot = ref.read(realmEditorCatalogProvider).value?.snapshot;
      if (selected == null ||
          snapshot == null ||
          !selected.accepts(
            payload.subject.content.rootType,
            TypeRegistry(snapshot.catalog),
          )) {
        return const SearchCommandResult.failed(
          message: "The target is no longer compatible",
        );
      }
      if (selected.relation.families.contains("resource.ownership") &&
          payload.owner != null) {
        return const SearchCommandResult.failed(
          message: "The target already has an owner",
        );
      }
      final attachment = relationAttachment(host, selected);
      final source = attachment.hostSide == skir.RelationEndpointSide.source
          ? host
          : payload.id;
      final destination =
          attachment.hostSide == skir.RelationEndpointSide.source
          ? payload.id
          : host;
      try {
        final result = await ref.readAuthoringSession().notifier.applyPreviewed(
          [
            skir.AuthoringOperation.createDeclareRelation(
              relation: attachment.relation,
              source: source,
              target: destination,
              sourceBefore: null,
              targetBefore: null,
            ),
          ],
        );
        result.requireApplied(conflictMessage: "The relation changed");
      } on Object catch (error) {
        return SearchCommandResult.failed(message: error.toString());
      }
      return const SearchCommandResult.completed();
    },
  ),
];

skir.CreationAttachment? _nearestOwnership(
  Ref ref,
  skir.ResourceId host,
  ResolvedTypeRef targetType,
) {
  final catalog = ref.read(realmEditorCatalogProvider).value?.snapshot;
  if (catalog == null) return null;
  final state = ref.readAuthoringSession().state;
  final codec = TypedAuthoringCodec(catalog);
  final ownershipIds = {
    for (final relation in catalog.relations.values)
      if (relation.families.contains("resource.ownership")) relation.id,
  };
  final visited = <skir.ResourceId>{};
  skir.ResourceId? current = host;
  while (current != null && visited.add(current)) {
    final resource = state.resources[current];
    if (resource != null) {
      final root = codec.decodeResource(resource).valueOrNull?.content.rootType;
      if (root != null) {
        final candidates = [
          for (final relation in catalog.relations.values)
            if (relation.families.contains("resource.ownership"))
              if (relation.sourceEndpoint case final endpoint?)
                if (catalog.relationField(root, endpoint.path)
                    case final field?)
                  if (field.relation.id == relation.id &&
                      field.accepts(targetType, codec.registry))
                    relationAttachment(current, field),
        ];
        if (candidates.length == 1) return candidates.single;
        if (candidates.length > 1) return null;
      }
    }
    current = state.edges.values
        .where(
          (edge) =>
              edge.target == current &&
              switch (edge.origin) {
                skir.AuthoringEdgeOrigin_declaredRelationWrapper(
                  :final value,
                ) =>
                  ownershipIds.contains(value.relationId.value),
                _ => false,
              },
        )
        .map((edge) => edge.source)
        .singleOrNull;
  }
  return null;
}
