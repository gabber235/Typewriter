/// Organization service management, including registration and live topology.
///
/// The application layer owns canonical service identities, organization scoped
/// mutations, and the topology projection. Presentation consumes those read
/// models to show service, host, Realm, and engine relationships in one graph.
/// Service identity remains distinct from host runtime observation, and runtime
/// entries are navigated through their owning organization routes.
library;

export "application/application.dart";
export "presentation/presentation.dart";
