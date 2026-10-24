// Realm is the organization workspace route for selecting a running realm,
// connecting to it, and hosting its authoring surfaces. Application providers
// own selection, connection, and inbox lifecycles. Presentation routes and
// barriers consume those projections without owning transport or durable
// authoring state, which belongs to the authoring module.
library;

export "application/application.dart";
export "presentation/presentation.dart";
export "search/search.dart";
