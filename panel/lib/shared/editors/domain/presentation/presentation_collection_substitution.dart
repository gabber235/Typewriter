part of "presentation_substitution.dart";

PresentationElement _substituteCollectionElement(
  PresentationElement element,
  Map<String, TypeExpression> substitutions,
) => switch (element) {
  CollectionLookupElement() => CollectionLookupElement(
    sourceId: element.sourceId,
    key: element.key,
    found: element.found._substituteTypes(substitutions),
    missing: element.missing._substituteTypes(substitutions),
    loading: element.loading._substituteTypes(substitutions),
  ),
  CollectionGraphElement() => CollectionGraphElement(
    sourceId: element.sourceId,
    roots: element.roots,
    relation: element.relation,
    direction: element.direction,
    rootRows: element.rootRows._substituteTypes(substitutions),
    reachedRows: element.reachedRows._substituteTypes(substitutions),
    paths: element.paths._substituteTypes(substitutions),
    pathBindingId: element.pathBindingId,
    maximumDepth: element.maximumDepth,
    deduplicate: element.deduplicate,
  ),
  _ => element,
};
