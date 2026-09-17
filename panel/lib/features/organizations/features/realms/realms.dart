// Realm is the organization workspace boundary for selecting a running realm,
// loading its versioned editor catalog, and exposing realm scoped authoring and
// editor features. Application providers own selection, connection, catalog,
// and session lifecycles. Presentation routes and barriers consume those
// projections without owning transport or durable authoring state.
library;

export "application/application.dart";
export "features/features.dart";
export "presentation/presentation.dart";
