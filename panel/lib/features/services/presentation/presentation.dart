/// Widgets and deterministic graph layout for the organization services view.
///
/// [ServicesPage] coordinates the routed organization projections. The graph
/// joins canonical service identities with separately observed topology records;
/// [ServicesPackedLayout] turns that projection into the shared graph contract.
/// No widget in this library owns service or topology state.
library;

export "registration_token_input.dart";
export "route.dart";
export "services_graph.dart";
export "services_packed_layout.dart";
export "services_packed_models.dart";
export "services_packed_packer.dart";
