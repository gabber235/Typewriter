import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "portable_link_choices.freezed.dart";

@freezed
sealed class PortableLinkPlanResult with _$PortableLinkPlanResult {
  const factory PortableLinkPlanResult.ready(List<PortableLinkPlan> plans) =
      PortableLinkPlanReady;
  const factory PortableLinkPlanResult.unavailable(String message) =
      PortableLinkPlanUnavailable;
}

@freezed
abstract class PortableLinkPlan with _$PortableLinkPlan {
  const factory PortableLinkPlan({
    required skir.LinkOccurrence source,
    required skir.RelationContract relation,
    required skir.EndpointDefinition opposite,
    required skir.TypeUse targetType,
    required List<PortableLinkTargetChoice> targets,
  }) = _PortableLinkPlan;
}

@freezed
abstract class PortableLinkTargetChoice with _$PortableLinkTargetChoice {
  const factory PortableLinkTargetChoice({
    required skir.ResourceId resource,
    required bool automaticCounterpart,
    required List<skir.LinkOccurrence> existing,
    required List<PortableNewCounterpartChoice> creatable,
    @Default([]) List<skir.ValueLocation> collections,
    String? disabledReason,
  }) = _PortableLinkTargetChoice;
}

@freezed
abstract class PortableNewCounterpartChoice
    with _$PortableNewCounterpartChoice {
  const factory PortableNewCounterpartChoice({
    required skir.ValueLocation containing,
    required skir.TypeSelection selection,
  }) = _PortableNewCounterpartChoice;
}

@freezed
abstract class ResolvedReference with _$ResolvedReference {
  const factory ResolvedReference({
    required skir.ConnectIntent connection,
    @Default([]) List<ReferenceMaterialization> materializations,
  }) = _ResolvedReference;
}

@freezed
sealed class ReferenceMaterialization with _$ReferenceMaterialization {
  const factory ReferenceMaterialization.value(skir.InsertIntent intent) =
      ReferenceValueInsertion;
  const factory ReferenceMaterialization.preparedItem({
    required skir.ValueLocation at,
    required skir.ItemId? after,
    required skir.ItemId item,
    required skir.ValuePreparationRequest request,
    required skir.PreparedValue prepared,
  }) = PreparedReferenceInsertion;
  const factory ReferenceMaterialization.preparedRecord({
    required skir.ValueLocation at,
    required skir.ValuePreparationRequest request,
    required skir.PreparedValue prepared,
  }) = PreparedReferenceRecord;
}

@freezed
sealed class ReferenceChoice with _$ReferenceChoice {
  const factory ReferenceChoice.existing(ResolvedReference reference) =
      ExistingReference;
  const factory ReferenceChoice.createResource(
    ResourceCreationTemplate template,
  ) = NewResourceReference;
  const factory ReferenceChoice.createCounterpart(
    PortableNewCounterpartChoice slot,
  ) = NewEmbeddedCounterpart;
}

void replacePortableLinkCollection({
  required PortableAuthoringEdit draft,
  required CheckedEditorCatalog catalog,
  required skir.ResourceId resource,
  required String field,
  required List<skir.ResourceId> expected,
  required List<skir.ResourceId> proposed,
}) {
  final containing = skir.ValuePath(
    segments: [skir.PathSegment.createField(name: field)],
  );
  final record = draft.resource(resource);
  final items = record?.authoredField(field)?.authoredItems?.toList();
  if (record == null || items == null) {
    throw StateError("The $field link collection is unavailable");
  }
  final current = [
    for (final item in items)
      if (item.value.authoredLink case final link?) link.target.resource,
  ];
  if (!_sameResources(current, expected)) {
    throw StateError("The $field link collection changed");
  }
  final remaining = List<skir.ResourceId>.of(proposed);
  for (final item in items) {
    final link = item.value.authoredLink;
    if (link == null) continue;
    final retained = remaining.indexOf(link.target.resource);
    if (retained >= 0) {
      remaining.removeAt(retained);
      continue;
    }
    draft.disconnect(
      skir.LinkOccurrence(
        id: skir.LinkOccurrenceId(
          endpoint: link.endpoint,
          location: skir.ValueLocation(
            resource: resource,
            path: skir.ValuePath(
              segments: [
                ...containing.segments,
                skir.PathSegment.createItem(id: item.id),
              ],
            ),
          ),
        ),
        source: resource,
        target: link.target,
      ),
    );
  }
  var index = 0;
  for (final target in remaining) {
    late skir.ItemId item;
    late skir.ValueLocation source;
    do {
      item = skir.ItemId(value: "panel:link:${draft.operationCount}:$index");
      index++;
      source = skir.ValueLocation(
        resource: resource,
        path: skir.ValuePath(
          segments: [
            ...containing.segments,
            skir.PathSegment.createItem(id: item),
          ],
        ),
      );
    } while (record.readAt(source.path) is PortablePathValue<skir.DataValue>);
    final plans = draft.linkPlans(catalog: catalog, source: source);
    final choices = switch (plans) {
      PortableLinkPlanReady(:final plans) => [
        for (final plan in plans)
          for (final choice in plan.targets)
            if (choice.resource == target && choice.automaticCounterpart) plan,
      ],
      PortableLinkPlanUnavailable() => const <PortableLinkPlan>[],
    };
    if (choices.length != 1) {
      throw StateError("The $field link target requires an explicit choice");
    }
    final plan = choices.single;
    final choice = plan.targets.singleWhere(
      (choice) => choice.resource == target,
    );
    draft.applyResolvedReference(
      draft.resolveReference(catalog: catalog, plan: plan, target: choice),
    );
  }
}

bool _sameResources(List<skir.ResourceId> first, List<skir.ResourceId> second) {
  if (first.length != second.length) return false;
  for (var index = 0; index < first.length; index++) {
    if (first[index] != second[index]) return false;
  }
  return true;
}

extension ReferencePlanning on PortableAuthoringView {
  PortableLinkPlanResult linkPlans({
    required CheckedEditorCatalog catalog,
    required skir.ValueLocation source,
  }) {
    final sourceRecord = resource(source.resource);
    if (sourceRecord == null) {
      return const PortableLinkPlanUnavailable("The source resource is absent");
    }
    final current = switch (sourceRecord.readAt(source.path)) {
      PortablePathValue(value: final value) => value.authoredLink,
      PortablePathUnavailable() => null,
    };
    final reference = catalog.referenceTypeAt(sourceRecord, source.path);
    if (reference == null ||
        current != null && current.endpoint != reference.endpoint) {
      return const PortableLinkPlanUnavailable(
        "The link endpoint is unavailable at this location",
      );
    }
    final relation = catalog.snapshot.relations
        .where(
          (candidate) =>
              candidate.first.id == reference.endpoint ||
              candidate.second.id == reference.endpoint,
        )
        .singleOrNull;
    if (relation == null) {
      return const PortableLinkPlanUnavailable(
        "The link relation is unavailable",
      );
    }
    final sourceEndpoint = relation.first.id == reference.endpoint
        ? relation.first
        : relation.second;
    final sourceType = catalog.applyTemplate(
      skir.TypeTemplate.wrapNamed(sourceEndpoint.resource),
      sourceRecord.configuration,
    );
    if (!catalog.selectionMatches(sourceRecord.configuration, sourceType)) {
      return const PortableLinkPlanUnavailable(
        "The relation endpoint does not accept this resource type",
      );
    }
    final opposite = relation.first.id == reference.endpoint
        ? relation.second
        : relation.first;
    final sourceOccurrence = skir.LinkOccurrence(
      id: skir.LinkOccurrenceId(endpoint: reference.endpoint, location: source),
      source: source.resource,
      target:
          current?.target ??
          skir.LinkTarget(
            resource: skir.ResourceId.defaultInstance,
            opposite: null,
          ),
    );
    final targets = <PortableLinkTargetChoice>[];
    for (final entry in resources.entries) {
      if (!catalog.selectionMatches(
        entry.value.configuration,
        reference.target,
      )) {
        continue;
      }
      final oppositeBindings = catalog
          .endpointBindings(entry.value.configuration)
          .where((candidate) => candidate.template.endpoint == opposite.id)
          .toList(growable: false);
      final compatibleBindings = oppositeBindings
          .where(
            (candidate) =>
                candidate.isAvailable &&
                catalog.selectionMatches(
                  sourceRecord.configuration,
                  candidate.target,
                ),
          )
          .toList(growable: false);
      final direct =
          compatibleBindings.length == 1 &&
          catalog
              .nominalDefinitions(entry.value.configuration)
              .contains(compatibleBindings.single.template.valueOwner);
      final existing = <skir.LinkOccurrence>[];
      final creatable = <PortableNewCounterpartChoice>[];
      final locations = catalog
          .referenceLocations(entry.value)
          .where((location) => location.endpoint == opposite.id)
          .toList();
      final collections = catalog
          .referenceCollections(entry.value)
          .where((location) => location.endpoint == opposite.id)
          .toList();
      final compatibleLocations = locations.where(
        (location) => catalog.selectionMatches(
          sourceRecord.configuration,
          location.target,
        ),
      );
      final compatibleCollections = collections.where(
        (location) => catalog.selectionMatches(
          sourceRecord.configuration,
          location.target,
        ),
      );
      for (final location in compatibleLocations) {
        final previous = switch (entry.value.readAt(location.path)) {
          PortablePathValue(value: final value) => value.authoredLink?.target,
          PortablePathUnavailable() => null,
        };
        existing.add(
          skir.LinkOccurrence(
            id: skir.LinkOccurrenceId(
              endpoint: opposite.id,
              location: skir.ValueLocation(
                resource: entry.key,
                path: location.path,
              ),
            ),
            source: entry.key,
            target:
                previous ??
                skir.LinkTarget(
                  resource: source.resource,
                  opposite: source.path,
                ),
          ),
        );
      }
      for (final oppositeBinding in compatibleBindings) {
        if (!direct) {
          creatable.addAll(
            _newCounterpartChoices(
              catalog: catalog,
              resource: entry.key,
              record: entry.value,
              binding: oppositeBinding,
            ),
          );
        }
      }
      final unfinishedForms = catalog
          .unselectedReferenceForms(entry.value, opposite.id)
          .toList();
      targets.add(
        PortableLinkTargetChoice(
          resource: entry.key,
          automaticCounterpart:
              (oppositeBindings.isEmpty &&
                  locations.isEmpty &&
                  collections.isEmpty &&
                  unfinishedForms.isEmpty) ||
              direct,
          collections: [
            for (final location in compatibleCollections)
              skir.ValueLocation(resource: entry.key, path: location.path),
          ],
          disabledReason:
              unfinishedForms.isNotEmpty &&
                  existing.isEmpty &&
                  compatibleCollections.isEmpty &&
                  creatable.isEmpty
              ? "Select a form at ${unfinishedForms.first.segments.map((segment) => segment is skir.PathSegment_fieldWrapper ? segment.value.name : "item").join(" / ")} to expose its counterpart"
              : (oppositeBindings.isNotEmpty ||
                        locations.isNotEmpty ||
                        collections.isNotEmpty) &&
                    compatibleBindings.isEmpty &&
                    compatibleLocations.isEmpty &&
                    compatibleCollections.isEmpty
              ? (oppositeBindings.any((binding) => !binding.isAvailable)
                    ? "The opposite endpoint type is unavailable"
                    : "The opposite endpoint does not accept this resource type")
              : null,
          existing: List.unmodifiable(existing),
          creatable: List.unmodifiable(_distinctNewChoices(creatable)),
        ),
      );
    }
    return PortableLinkPlanReady([
      PortableLinkPlan(
        source: sourceOccurrence,
        relation: relation,
        opposite: opposite,
        targetType: reference.target,
        targets: List.unmodifiable(targets),
      ),
    ]);
  }

  /// Resolves an automatic or explicitly selected inverse to stable locations.
  ResolvedReference resolveReference({
    required CheckedEditorCatalog catalog,
    required PortableLinkPlan plan,
    required PortableLinkTargetChoice target,
    skir.CounterpartChoice? counterpart,
    skir.ValueLocation? collection,
  }) {
    if (target.disabledReason case final reason?) throw StateError(reason);
    final materializations = <ReferenceMaterialization>[];
    var resolved = counterpart;
    if (resolved case skir.CounterpartChoice_newWrapper(:final value)) {
      final targetRecord = resource(target.resource);
      final sourceRecord = resource(plan.source.source);
      if (targetRecord == null ||
          sourceRecord == null ||
          value.containing.resource != target.resource) {
        throw StateError("The counterpart resources are unavailable");
      }
      final prepared = value.prepared;
      final selection = prepared.recordContent.configuration;
      final request = skir.ValuePreparationRequest(
        catalog: generation,
        target: skir.PreparationTarget.wrapRecord(selection),
        suppliedValue: skir.DataValue.createRecord(fields: const []),
      );
      var embedded = value.containing;
      final current = switch (read(value.containing)) {
        PortablePathValue(value: final value) => value,
        PortablePathUnavailable() => null,
      };
      final items = current?.authoredItems?.toList();
      if (items != null) {
        final item = skir.ItemId(value: "panel:reference:${const Uuid().v4()}");
        materializations.add(
          ReferenceMaterialization.preparedItem(
            at: value.containing,
            after: items.lastOrNull?.id,
            item: item,
            request: request,
            prepared: prepared,
          ),
        );
        embedded = skir.ValueLocation(
          resource: target.resource,
          path: skir.ValuePath(
            segments: [
              ...value.containing.path.segments,
              skir.PathSegment.createItem(id: item),
            ],
          ),
        );
      } else {
        materializations.add(
          ReferenceMaterialization.preparedRecord(
            at: value.containing,
            request: request,
            prepared: prepared,
          ),
        );
      }
      final paths = <skir.ValuePath>{
        for (final reference in catalog.referenceLocations(
          prepared.recordContent,
        ))
          if (reference.endpoint == plan.opposite.id &&
              catalog.selectionMatches(
                sourceRecord.configuration,
                reference.target,
              ))
            skir.ValuePath(
              segments: [...embedded.path.segments, ...reference.path.segments],
            ),
      };
      if (paths.length != 1) {
        throw StateError(
          "The prepared counterpart requires an exact link location",
        );
      }
      resolved = skir.CounterpartChoice.wrapExisting(
        skir.LinkOccurrence(
          id: skir.LinkOccurrenceId(
            endpoint: plan.opposite.id,
            location: skir.ValueLocation(
              resource: target.resource,
              path: paths.single,
            ),
          ),
          source: target.resource,
          target: skir.LinkTarget(
            resource: plan.source.source,
            opposite: plan.source.id.location.path,
          ),
        ),
      );
    }
    if (resolved == null) {
      final record = resource(target.resource);
      if (record == null) {
        throw StateError("The counterpart resource is unavailable");
      }
      final selectedCollection =
          collection ??
          (target.automaticCounterpart && target.collections.length == 1
              ? target.collections.single
              : null);
      if (selectedCollection != null) {
        if (!target.collections.contains(selectedCollection)) {
          throw StateError("The counterpart collection is unavailable");
        }
        final matches = target.existing
            .where(
              (occurrence) =>
                  occurrence.id.location.path.segments.length ==
                      selectedCollection.path.segments.length + 1 &&
                  skir.ValuePath(
                        segments: occurrence.id.location.path.segments.take(
                          selectedCollection.path.segments.length,
                        ),
                      ) ==
                      selectedCollection.path &&
                  occurrence.target.resource == plan.source.source &&
                  occurrence.target.opposite == plan.source.id.location.path,
            )
            .toList(growable: false);
        if (matches.length > 1) {
          throw StateError("Choose the exact existing counterpart occurrence");
        }
        if (matches.length == 1) {
          resolved = skir.CounterpartChoice.wrapExisting(matches.single);
        } else {
          final items = switch (read(selectedCollection)) {
            PortablePathValue(value: final value) =>
              value.authoredItems?.toList() ??
                  (value.authoredPayload == skir.DataValue.unfilled
                      ? <skir.ListItem>[]
                      : null),
            PortablePathUnavailable() => null,
          };
          if (items == null) {
            throw StateError("The counterpart collection is unavailable");
          }
          final item = skir.ItemId(
            value: "panel:reference:${const Uuid().v4()}",
          );
          materializations.add(
            ReferenceMaterialization.value(
              skir.InsertIntent(
                at: selectedCollection,
                after: items.lastOrNull?.id,
                item: skir.ListItem(id: item, value: skir.DataValue.unfilled),
              ),
            ),
          );
          resolved = skir.CounterpartChoice.wrapExisting(
            skir.LinkOccurrence(
              id: skir.LinkOccurrenceId(
                endpoint: plan.opposite.id,
                location: skir.ValueLocation(
                  resource: target.resource,
                  path: skir.ValuePath(
                    segments: [
                      ...selectedCollection.path.segments,
                      skir.PathSegment.createItem(id: item),
                    ],
                  ),
                ),
              ),
              source: target.resource,
              target: skir.LinkTarget(
                resource: plan.source.source,
                opposite: plan.source.id.location.path,
              ),
            ),
          );
        }
      } else if (target.automaticCounterpart && target.existing.length == 1) {
        final candidate = target.existing.single;
        final previous = switch (read(candidate.id.location)) {
          PortablePathValue(value: final value) => value.authoredLink?.target,
          PortablePathUnavailable() => null,
        };
        if (previous != null &&
            (previous.resource != plan.source.source ||
                previous.opposite != null &&
                    previous.opposite != plan.source.id.location.path)) {
          throw StateError(
            "The counterpart is already linked. Choose its location explicitly",
          );
        }
        resolved = skir.CounterpartChoice.wrapExisting(candidate);
      } else if (!target.automaticCounterpart ||
          target.existing.isNotEmpty ||
          target.collections.isNotEmpty) {
        throw StateError("Choose the counterpart location explicitly");
      }
    }
    return ResolvedReference(
      connection: skir.ConnectIntent(
        source: plan.source,
        target: target.resource,
        counterpart: resolved,
      ),
      materializations: materializations,
    );
  }
}

Iterable<PortableNewCounterpartChoice> _newCounterpartChoices({
  required CheckedEditorCatalog catalog,
  required skir.ResourceId resource,
  required skir.AuthoringRecord record,
  required AppliedEndpointBinding binding,
}) sync* {
  final segments = binding.template.relativePath.segments.toList(
    growable: false,
  );

  Iterable<PortableNewCounterpartChoice> visit(
    skir.ValuePath path,
    skir.TypeSelection selection,
    int index,
  ) sync* {
    if (index >= segments.length) return;
    final segment = segments[index];
    switch (segment) {
      case skir.FieldPatternSegment_fieldWrapper(:final value):
        final field = catalog
            .fields(selection)
            .where((candidate) => candidate.template.key == value.name)
            .firstOrNull;
        if (field == null || field.type == null) return;
        if (field.template.owner.definition == binding.template.valueOwner &&
            path.segments.isNotEmpty) {
          final current = record.readAt(path);
          final empty = switch (current) {
            PortablePathValue(value: final value) =>
              value == skir.DataValue.unfilled || value == skir.DataValue.null_,
            PortablePathUnavailable() => true,
          };
          if (empty) {
            if (catalog.selected(selection)?.definition.id ==
                binding.template.valueOwner) {
              yield PortableNewCounterpartChoice(
                containing: skir.ValueLocation(resource: resource, path: path),
                selection: selection,
              );
            }
          }
        }
        final next = skir.ValuePath(
          segments: [
            ...path.segments,
            skir.PathSegment.createField(name: value.name),
          ],
        );
        final named = catalog.namedUse(field.type);
        if (named == null) return;
        yield* visit(next, skir.TypeSelection.wrapComplete(named), index + 1);
      case final value when value == skir.FieldPatternSegment.items:
        final collectionType = path.segments.isEmpty
            ? null
            : catalog.valueTypeAt(record.configuration, path);
        final itemType = catalog.collectionItemType(collectionType);
        final named = catalog.namedUse(itemType);
        if (named == null) return;
        if (named.definition == binding.template.valueOwner) {
          yield PortableNewCounterpartChoice(
            containing: skir.ValueLocation(resource: resource, path: path),
            selection: skir.TypeSelection.wrapComplete(named),
          );
        }
        final items = switch (record.readAt(path)) {
          PortablePathValue(value: final value) => value.authoredItems,
          PortablePathUnavailable() => null,
        };
        for (final item in items ?? const <skir.ListItem>[]) {
          yield* visit(
            skir.ValuePath(
              segments: [
                ...path.segments,
                skir.PathSegment.createItem(id: item.id),
              ],
            ),
            skir.TypeSelection.wrapComplete(named),
            index + 1,
          );
        }
      default:
    }
  }

  yield* visit(skir.ValuePath(segments: const []), record.configuration, 0);
}

Iterable<PortableNewCounterpartChoice> _distinctNewChoices(
  Iterable<PortableNewCounterpartChoice> choices,
) sync* {
  final seen = <skir.ValueLocation>{};
  for (final choice in choices) {
    if (seen.add(choice.containing)) yield choice;
  }
}

extension ResolvedReferenceEditing on PortableAuthoringEdit {
  void applyReferenceMaterialization(ReferenceMaterialization materialization) {
    final result = switch (materialization) {
      ReferenceValueInsertion(:final intent) => insert(
        intent.at,
        intent.after,
        intent.item,
      ),
      PreparedReferenceInsertion(
        :final at,
        :final after,
        :final item,
        :final request,
        :final prepared,
      ) =>
        insertPrepared(at, after, item, request, prepared),
      PreparedReferenceRecord(:final at, :final request, :final prepared) =>
        applyPreparedRecord(at, request, prepared),
    };
    if (result case PortablePathUnavailable(:final message)) {
      throw EditPreparationFailure(message);
    }
  }

  void applyResolvedReference(ResolvedReference reference) {
    for (final materialization in reference.materializations) {
      applyReferenceMaterialization(materialization);
    }
    final connection = reference.connection;
    connect(
      connection.source,
      connection.target,
      counterpart: connection.counterpart,
    );
  }
}

/// Resolves the counterpart request shared by field and resource link commands.
Future<skir.CounterpartChoice?> preparePortableLinkCounterpart({
  required skir.CatalogGeneration generation,
  required PortableLinkCounterpartRequest counterpart,
  required Future<skir.PreparedValue> Function(skir.ValuePreparationRequest)?
  prepareValue,
}) async => switch (counterpart) {
  PortableExistingCounterpart(:final occurrence) =>
    skir.CounterpartChoice.wrapExisting(occurrence),
  PortableCreatedCounterpart(:final slot) => skir.CounterpartChoice.createNew(
    containing: slot.containing,
    prepared:
        await (prepareValue ??
            (throw StateError("Creation preparation is unavailable")))(
          skir.ValuePreparationRequest(
            catalog: generation,
            target: skir.PreparationTarget.wrapRecord(slot.selection),
            suppliedValue: skir.DataValue.createRecord(fields: const []),
          ),
        ),
  ),
  _ => null,
};
