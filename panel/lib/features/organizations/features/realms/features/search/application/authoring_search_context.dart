import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "authoring_search_context.freezed.dart";

const authoringBookSelectorId = "book";
const authoringPageSelectorId = "page";
const authoringTagSelectorId = "tag";
const authoringTypeSelectorId = "type";

const authoringCreationSelectors = [
  KeyValueSelectorDefinition(
    id: authoringBookSelectorId,
    key: "book:",
    multiplicity: QueryMultiplicity.single,
  ),
  KeyValueSelectorDefinition(
    id: authoringPageSelectorId,
    key: "page:",
    multiplicity: QueryMultiplicity.single,
  ),
  KeyValueSelectorDefinition(
    id: authoringTypeSelectorId,
    key: "type:",
    multiplicity: QueryMultiplicity.single,
  ),
];

final libraryPageBookEndpoint = skir.EndpointId(
  value: "4fbbe0dcedd84ccb8b7ce8c6a6105551:second",
);
final libraryElementPageEndpoint = skir.EndpointId(
  value: "349b4d11c4464d13ad4ca063ead60c62:second",
);

/// A path from the requested resource, scoped to one chain of references.
@freezed
abstract class CreationReferenceConstraint with _$CreationReferenceConstraint {
  const factory CreationReferenceConstraint({
    required List<skir.EndpointId> route,
    required skir.ResourceId target,
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

  skir.ResourceId? requiredTarget(skir.EndpointId endpoint) {
    final targets = constraints
        .where(
          (constraint) =>
              constraint.route.length == 1 &&
              constraint.route.single == endpoint,
        )
        .map((constraint) => constraint.target)
        .toSet();
    if (targets.length > 1) {
      throw StateError("The reference has conflicting destinations");
    }
    return targets.singleOrNull;
  }

  bool accepts(
    skir.ResourceId resource,
    PortableAuthoringView view,
    CheckedEditorCatalog catalog,
  ) => constraints.every(
    (constraint) =>
        _reaches(resource, constraint.route, constraint.target, view, catalog),
  );

  bool _reaches(
    skir.ResourceId source,
    List<skir.EndpointId> route,
    skir.ResourceId target,
    PortableAuthoringView view,
    CheckedEditorCatalog catalog,
  ) {
    if (route.isEmpty) return source == target;
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
            first ? link.second : link.first,
            route.skip(1).toList(),
            target,
            view,
            catalog,
          ),
        );
  }
}

extension AuthoringQueryOperations on SearchQueryContext {
  bool hasSelector(String selectorId) =>
      selectors.any((selector) => selector.selectorId == selectorId);

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

  CreationContext creationContext({
    required AuthoringDocument document,
    required skir.TypeSelection configuration,
    required List<skir.ResourceId> preferredResources,
  }) {
    final book = resolveBook(document);
    final page = resolvePage(document);
    if (hasSelector(authoringBookSelectorId) && book == null) {
      throw StateError("The Book selector must identify one existing Book");
    }
    if (hasSelector(authoringPageSelectorId) && page == null) {
      throw StateError(
        "The Page selector must identify one existing page in the selected Book",
      );
    }
    final endpoints = document.catalog
        .endpointBindings(configuration)
        .map((binding) => binding.template.endpoint)
        .toSet();
    final pageRoute = endpoints.contains(libraryElementPageEndpoint)
        ? [libraryElementPageEndpoint]
        : <skir.EndpointId>[];
    final bookRoute = pageRoute.isNotEmpty
        ? [...pageRoute, libraryPageBookEndpoint]
        : endpoints.contains(libraryPageBookEndpoint)
        ? [libraryPageBookEndpoint]
        : <skir.EndpointId>[];
    if (page != null && pageRoute.isEmpty ||
        book != null && bookRoute.isEmpty) {
      throw StateError(
        "The selected resource does not support this destination selector",
      );
    }
    return CreationContext(
      preferredResources: preferredResources,
      constraints: [
        if (page != null)
          CreationReferenceConstraint(route: pageRoute, target: page),
        if (book != null)
          CreationReferenceConstraint(route: bookRoute, target: book),
      ],
    );
  }

  /// The one Book whose label matches the Book selector.
  skir.ResourceId? resolveBook(AuthoringDocument document) {
    final value = _singleSelectorValue(authoringBookSelectorId);
    if (value == null) return null;
    return _resourcesAt(document, libraryPageBookEndpoint, opposite: true)
        .where(
          (book) =>
              document.catalog
                  .appearanceOf(document.resource(book)!)
                  .label
                  .toLowerCase() ==
              value.toLowerCase(),
        )
        .singleOrNull;
  }

  /// The one page whose label matches the Page selector, inside the selected
  /// Book when the Book selector is present.
  skir.ResourceId? resolvePage(AuthoringDocument document) {
    final value = _singleSelectorValue(authoringPageSelectorId);
    if (value == null) return null;
    final book = resolveBook(document);
    if (hasSelector(authoringBookSelectorId) && book == null) return null;
    final ownership = document.relations;
    return _resourcesAt(document, libraryPageBookEndpoint)
        .where(
          (page) =>
              document.catalog
                      .appearanceOf(document.resource(page)!)
                      .label
                      .toLowerCase() ==
                  value.toLowerCase() &&
              (book == null || ownership.parents[page]?.contains(book) == true),
        )
        .singleOrNull;
  }

  String? _singleSelectorValue(String selectorId) => selectors
      .where((selector) => selector.selectorId == selectorId)
      .map((selector) => selector.value)
      .nonNulls
      .toSet()
      .singleOrNull;
}

/// Resources of the type at [endpoint], or at its [opposite] end: pages and
/// Books for the endpoint through which a page links to its Book.
Iterable<skir.ResourceId> _resourcesAt(
  AuthoringDocument document,
  skir.EndpointId endpoint, {
  bool opposite = false,
}) {
  final relation = document.catalog.snapshot.relations.firstWhereOrNull(
    (relation) =>
        relation.first.id == endpoint || relation.second.id == endpoint,
  );
  if (relation == null) return const [];
  final first = (relation.first.id == endpoint) != opposite;
  final resource = first ? relation.first.resource : relation.second.resource;
  return document.entries.values
      .where(
        (entry) => document.catalog
            .nominalDefinitions(entry.content.configuration)
            .contains(resource.definition),
      )
      .map((entry) => entry.id);
}
