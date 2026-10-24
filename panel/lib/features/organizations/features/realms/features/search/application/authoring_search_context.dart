import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "authoring_search_context.freezed.dart";

const authoringTypeSelectorId = "type";

/// Narrows creation to types whose name matches, such as `type:Dialogue`.
const authoringTypeSelector = KeyValueSelectorDefinition(
  id: authoringTypeSelectorId,
  key: "type:",
  multiplicity: QueryMultiplicity.single,
);

/// One scope keyword for creating a type, such as `book:` for a page element:
/// the owner type's search key and the route from the created type up to it.
@freezed
abstract class ScopeSelector with _$ScopeSelector {
  const factory ScopeSelector({
    required String key,
    required OwnerRoute route,
  }) = _ScopeSelector;
}

extension CreationScopes on CheckedEditorCatalog {
  /// One selector per owner type above [configuration], nearest first. The
  /// realm root and its sections get none, since every resource is inside
  /// them. When two routes reach owners with one key, the nearer one wins.
  Iterable<ScopeSelector> scopeSelectors(
    skir.TypeSelection configuration,
  ) sync* {
    final keys = <String>{};
    for (final route in ownerRoutes(configuration)) {
      final owner = beginSelection(route.ownerRoot);
      if (isRealmRoot(owner) || isRealmSection(owner)) continue;
      final key = published(route.ownerRoot)?.searchKey;
      if (key == null || key == authoringTypeSelectorId || !keys.add(key)) {
        continue;
      }
      yield ScopeSelector(key: key, route: route);
    }
  }

  /// The query syntax of creation search: every scope keyword a creatable
  /// type offers, then `type:`.
  List<QuerySelectorDefinition> get creationSelectors => [
    for (final key in {
      for (final type in creatableTypes)
        for (final selector in scopeSelectors(beginSelection(type)))
          selector.key,
    })
      KeyValueSelectorDefinition(
        id: key,
        key: "$key:",
        multiplicity: QueryMultiplicity.single,
      ),
    authoringTypeSelector,
  ];
}

/// How one scope selector value of a creation query resolved, matching
/// resources of the owner type by their appearance label.
@freezed
sealed class ScopeResolution with _$ScopeResolution {
  const ScopeResolution._();

  /// Exactly one resource has the name, such as the one Book "Main story".
  const factory ScopeResolution.matched({
    required ScopeSelector selector,
    required String text,
    required skir.ResourceId target,
  }) = ScopeMatched;

  /// Several resources have the name, such as two Books named "Intro".
  /// Creation asks which one, offering only these.
  const factory ScopeResolution.ambiguous({
    required ScopeSelector selector,
    required String text,
    required Set<skir.ResourceId> candidates,
  }) = ScopeAmbiguous;

  /// No resource of the owner type has the name.
  const factory ScopeResolution.unmatched({
    required ScopeSelector selector,
    required String text,
  }) = ScopeUnmatched;

  /// The constraint this resolution puts on the created resource, or null
  /// when nothing matched.
  CreationReferenceConstraint? get constraint => switch (this) {
    ScopeMatched(:final selector, :final target) => CreationReferenceConstraint(
      route: selector.route.endpoints,
      targets: {target},
    ),
    ScopeAmbiguous(:final selector, :final candidates) =>
      CreationReferenceConstraint(
        route: selector.route.endpoints,
        targets: candidates,
      ),
    ScopeUnmatched() => null,
  };
}

/// The creation context a query asks for, or the scope values it cannot meet.
@freezed
sealed class CreationQueryOutcome with _$CreationQueryOutcome {
  /// Every scope value names at least one resource. Ambiguous values leave a
  /// choice among their candidates to the creation.
  const factory CreationQueryOutcome.scoped(CreationContext context) =
      CreationScoped;

  /// Scope values that name no resource, such as `book:Missing`.
  const factory CreationQueryOutcome.unmatched(List<ScopeUnmatched> scopes) =
      CreationScopeUnmatched;
}

extension CreationContexts on AuthoringDocument {
  /// Resolves the scope selectors of [configuration] that [query] sets, keyed
  /// by search key. A value narrows to resources inside the resources that
  /// the other values name, so `book:"Main story" page:Intro` picks the Intro
  /// of that Book.
  List<ScopeResolution> resolveScopes(
    skir.TypeSelection configuration,
    Map<String, String> query,
  ) {
    final selectors = [
      for (final selector in catalog.scopeSelectors(configuration))
        if (query.containsKey(selector.key)) selector,
    ];
    final candidates = {
      for (final selector in selectors)
        selector: _named(selector.route.ownerRoot, query[selector.key]!),
    };
    // Outer owners narrow first, so each value narrows by already narrowed
    // owners above it.
    final outermostFirst = selectors.sortedBy<num>(
      (selector) => -selector.route.endpoints.length,
    );
    for (final inner in outermostFirst) {
      for (final outer in selectors) {
        final remainder = _routeBeyond(
          inner.route.endpoints,
          outer.route.endpoints,
        );
        final targets = candidates[outer]!;
        if (remainder == null || targets.isEmpty) continue;
        candidates[inner] = {
          for (final candidate in candidates[inner]!)
            if (_reaches(this, catalog, candidate, remainder, targets))
              candidate,
        };
      }
    }
    return [
      for (final selector in selectors)
        switch (candidates[selector]!) {
          final matches when matches.isEmpty => ScopeResolution.unmatched(
            selector: selector,
            text: query[selector.key]!,
          ),
          final matches when matches.length == 1 => ScopeResolution.matched(
            selector: selector,
            text: query[selector.key]!,
            target: matches.single,
          ),
          final matches => ScopeResolution.ambiguous(
            selector: selector,
            text: query[selector.key]!,
            candidates: matches,
          ),
        },
    ];
  }

  /// The context for creating [configuration] scoped by [query], preferring
  /// [preferredResources] wherever the query leaves a destination open.
  CreationQueryOutcome creationContext(
    skir.TypeSelection configuration,
    Map<String, String> query, {
    List<skir.ResourceId> preferredResources = const [],
  }) {
    final resolutions = resolveScopes(configuration, query);
    final unmatched = resolutions.whereType<ScopeUnmatched>().toList();
    if (unmatched.isNotEmpty) return CreationQueryOutcome.unmatched(unmatched);
    return CreationQueryOutcome.scoped(
      CreationContext(
        preferredResources: preferredResources,
        constraints: resolutions
            .map((resolution) => resolution.constraint!)
            .toList(),
      ),
    );
  }

  /// Resources of [type] whose appearance label is [text], ignoring case.
  Set<skir.ResourceId> _named(skir.TypeDefinitionId type, String text) {
    final name = text.toLowerCase();
    return {
      for (final entry in entries.values)
        if (catalog
                .nominalDefinitions(entry.content.configuration)
                .contains(type) &&
            catalog.appearanceOf(entry.content).label.toLowerCase() == name)
          entry.id,
    };
  }
}

/// The endpoints [outer] follows after [inner], when [outer] continues past
/// [inner]'s owner, such as the page to Book step after an element's page.
List<skir.EndpointId>? _routeBeyond(
  List<skir.EndpointId> inner,
  List<skir.EndpointId> outer,
) {
  if (outer.length <= inner.length) return null;
  for (var index = 0; index < inner.length; index++) {
    if (inner[index] != outer[index]) return null;
  }
  return outer.sublist(inner.length);
}

/// A path from the requested resource through [route] to one of [targets].
/// Several targets leave the choice among them to the creation.
@freezed
abstract class CreationReferenceConstraint with _$CreationReferenceConstraint {
  const factory CreationReferenceConstraint({
    required List<skir.EndpointId> route,
    required Set<skir.ResourceId> targets,
  }) = _CreationReferenceConstraint;
}

/// Explicit requirements take precedence over compatible ambient resources.
@freezed
abstract class CreationContext with _$CreationContext {
  const factory CreationContext({
    @Default([]) List<CreationReferenceConstraint> constraints,
    @Default([]) List<skir.ResourceId> preferredResources,
  }) = _CreationContext;

  const CreationContext._();

  CreationContext through(skir.EndpointId endpoint) => copyWith(
    constraints: [
      for (final constraint in constraints)
        if (constraint.route.firstOrNull == endpoint &&
            constraint.route.length > 1)
          constraint.copyWith(route: constraint.route.skip(1).toList()),
    ],
  );

  /// The destinations every constraint ending at [endpoint] allows, or null
  /// when no constraint ends there.
  Set<skir.ResourceId>? allowedTargets(skir.EndpointId endpoint) {
    Set<skir.ResourceId>? allowed;
    for (final constraint in constraints) {
      if (constraint.route.length != 1 || constraint.route.single != endpoint) {
        continue;
      }
      allowed = allowed == null
          ? constraint.targets
          : allowed.intersection(constraint.targets);
    }
    return allowed;
  }

  bool accepts(
    skir.ResourceId resource,
    PortableAuthoringView view,
    CheckedEditorCatalog catalog,
  ) => constraints.every(
    (constraint) =>
        _reaches(view, catalog, resource, constraint.route, constraint.targets),
  );
}

/// Whether following [route] from [source] through the links in [view] ends
/// at one of [targets]. Each endpoint is the side [source] links through.
bool _reaches(
  PortableAuthoringView view,
  CheckedEditorCatalog catalog,
  skir.ResourceId source,
  List<skir.EndpointId> route,
  Set<skir.ResourceId> targets,
) {
  if (route.isEmpty) return targets.contains(source);
  final relation = catalog.snapshot.relations
      .where(
        (relation) =>
            relation.first.id == route.first ||
            relation.second.id == route.first,
      )
      .singleOrNull;
  if (relation == null) return false;
  final first = relation.first.id == route.first;
  return view.links
      .where(
        (link) =>
            link.contract == relation.id &&
            (first ? link.first : link.second) == source,
      )
      .any(
        (link) => _reaches(
          view,
          catalog,
          first ? link.second : link.first,
          route.skip(1).toList(),
          targets,
        ),
      );
}

extension AuthoringQueryOperations on SearchQueryContext {
  bool hasSelector(String selectorId) =>
      selectors.any((selector) => selector.selectorId == selectorId);

  /// The one value of each selector set in this query, by selector id.
  /// Selectors given conflicting values are left out.
  Map<String, String> get selectorValues => {
    for (final id in selectors.map((selector) => selector.selectorId).toSet())
      id: ?_singleSelectorValue(id),
  };

  bool matchesCreationType(
    CheckedEditorCatalog catalog,
    skir.TypeSelection configuration,
  ) {
    final requested = _singleSelectorValue(authoringTypeSelectorId)
        ?.toLowerCase();
    if (requested == null) return !hasSelector(authoringTypeSelectorId);
    return catalog
        .nominalDefinitions(configuration)
        .any(
          (definition) =>
              catalog
                  .typeSelectionName(catalog.beginSelection(definition))
                  .toLowerCase() ==
              requested,
        );
  }

  /// Whether [configuration] offers a scope selector for every scope keyword
  /// in this query, so `book:` hides types that never live in a Book.
  bool matchesCreationScopes(
    CheckedEditorCatalog catalog,
    skir.TypeSelection configuration,
  ) {
    final offered = {
      for (final selector in catalog.scopeSelectors(configuration))
        selector.key,
    };
    return selectors.every(
      (selector) =>
          selector.selectorId == authoringTypeSelectorId ||
          offered.contains(selector.selectorId),
    );
  }

  String? _singleSelectorValue(String selectorId) => selectors
      .where((selector) => selector.selectorId == selectorId)
      .map((selector) => selector.value)
      .nonNulls
      .toSet()
      .singleOrNull;
}
