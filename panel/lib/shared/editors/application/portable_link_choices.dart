import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

sealed class PortableLinkPlanResult {
  const PortableLinkPlanResult();
}

final class PortableLinkPlanReady extends PortableLinkPlanResult {
  const PortableLinkPlanReady(this.plans);

  final List<PortableLinkPlan> plans;
}

final class PortableLinkPlanUnavailable extends PortableLinkPlanResult {
  const PortableLinkPlanUnavailable(this.message);

  final String message;
}

final class PortableLinkPlan {
  const PortableLinkPlan({
    required this.source,
    required this.relation,
    required this.opposite,
    required this.targets,
  });

  final skir.LinkOccurrence source;
  final skir.RelationContract relation;
  final skir.EndpointDefinition opposite;
  final List<PortableLinkTargetChoice> targets;
}

final class PortableLinkTargetChoice {
  const PortableLinkTargetChoice({
    required this.resource,
    required this.automaticCounterpart,
    required this.existing,
    required this.creatable,
  });

  final skir.ResourceId resource;
  final bool automaticCounterpart;
  final List<skir.LinkOccurrence> existing;
  final List<PortableNewCounterpartChoice> creatable;
}

final class PortableNewCounterpartChoice {
  const PortableNewCounterpartChoice({
    required this.containing,
    required this.selection,
  });

  final skir.ValueLocation containing;
  final skir.TypeSelection selection;
}

void replacePortableLinkCollection({
  required PortableAuthoringDocument draft,
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
    final plans = portableLinkPlans(
      draft: draft,
      catalog: catalog,
      source: source,
    );
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
    draft.connect(choices.single.source, target);
  }
}

bool _sameResources(List<skir.ResourceId> first, List<skir.ResourceId> second) {
  if (first.length != second.length) return false;
  for (var index = 0; index < first.length; index++) {
    if (first[index] != second[index]) return false;
  }
  return true;
}

PortableLinkPlanResult portableLinkPlans({
  required PortableAuthoringDocument draft,
  required CheckedEditorCatalog catalog,
  required skir.ValueLocation source,
}) {
  final sourceRecord = draft.resource(source.resource);
  if (sourceRecord == null) {
    return const PortableLinkPlanUnavailable("The source resource is absent");
  }
  final current = switch (sourceRecord.readAt(source.path)) {
    PortablePathValue(value: final value) => value.authoredLink,
    PortablePathUnavailable() => null,
  };
  final bindings = current == null
      ? catalog.endpointBindingsAt(sourceRecord.configuration, source.path)
      : catalog
            .endpointBindingsAt(sourceRecord.configuration, source.path)
            .where((binding) => binding.template.endpoint == current.endpoint)
            .toList(growable: false);
  if (bindings.isEmpty) {
    return const PortableLinkPlanUnavailable(
      "The link endpoint is unavailable at this location",
    );
  }
  final plans = <PortableLinkPlan>[];
  for (final binding in bindings) {
    final relation = catalog.snapshot.relations
        .where(
          (candidate) =>
              candidate.first.id == binding.template.endpoint ||
              candidate.second.id == binding.template.endpoint,
        )
        .firstOrNull;
    if (relation == null) continue;
    final opposite = relation.first.id == binding.template.endpoint
        ? relation.second
        : relation.first;
    final sourceOccurrence = skir.LinkOccurrence(
      id: skir.LinkOccurrenceId(
        endpoint: binding.template.endpoint,
        location: source,
      ),
      source: source.resource,
      target:
          current?.target ??
          skir.LinkTarget(
            resource: skir.ResourceId.defaultInstance,
            opposite: null,
          ),
    );
    final targets = <PortableLinkTargetChoice>[];
    for (final entry in draft.resources.entries) {
      if (!_resourceMatches(
        catalog,
        entry.value.configuration,
        binding.target,
      )) {
        continue;
      }
      final oppositeBindings = catalog
          .endpointBindings(entry.value.configuration)
          .where((candidate) => candidate.template.endpoint == opposite.id)
          .toList(growable: false);
      final direct =
          oppositeBindings.length == 1 &&
          catalog
              .nominalDefinitions(entry.value.configuration)
              .contains(oppositeBindings.single.template.valueOwner);
      final existing = <skir.LinkOccurrence>[];
      final creatable = <PortableNewCounterpartChoice>[];
      for (final oppositeBinding in oppositeBindings) {
        for (final path in expandAuthoredPattern(
          entry.value,
          oppositeBinding.template.relativePath,
        )) {
          existing.add(
            skir.LinkOccurrence(
              id: skir.LinkOccurrenceId(
                endpoint: opposite.id,
                location: skir.ValueLocation(resource: entry.key, path: path),
              ),
              source: entry.key,
              target: skir.LinkTarget(
                resource: source.resource,
                opposite: source.path,
              ),
            ),
          );
        }
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
      targets.add(
        PortableLinkTargetChoice(
          resource: entry.key,
          automaticCounterpart: oppositeBindings.isEmpty || direct,
          existing: List.unmodifiable(existing),
          creatable: List.unmodifiable(_distinctNewChoices(creatable)),
        ),
      );
    }
    plans.add(
      PortableLinkPlan(
        source: sourceOccurrence,
        relation: relation,
        opposite: opposite,
        targets: List.unmodifiable(targets),
      ),
    );
  }
  if (plans.isEmpty) {
    return const PortableLinkPlanUnavailable(
      "The link relation is unavailable",
    );
  }
  return PortableLinkPlanReady(List.unmodifiable(plans));
}

bool _resourceMatches(
  CheckedEditorCatalog catalog,
  skir.TypeSelection selection,
  skir.TypeUse? expected,
) {
  if (expected == null) return false;
  final actual = switch (selection) {
    skir.TypeSelection_completeWrapper(:final value) => skir.TypeUse.wrapNamed(
      value,
    ),
    _ => null,
  };
  return actual != null && catalog.isReadableAs(actual, expected);
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
