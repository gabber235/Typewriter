/// Authoring of realm content, keyed by an explicit [AuthoringScope].
///
/// Authoring owns the observed documents, the edit session, resource
/// operations, and the presentation hosts that shared editors render. Realm
/// routes, shared editors, selectables, and the inspector use it; it does not
/// belong to any single route.
library;

export "application/application.dart";
export "presentation/presentation.dart";
export "search/search.dart";
