/// Realm application state and boundary adapters for the organization panel.
///
/// This library connects route selected realms to their authoritative catalogs,
/// authoring projections, editor resources, capability invocation, and
/// presentation search. Riverpod providers construct the graph only when an
/// organization and an online realm exist. NATS adapters translate between
/// those application contracts and the realm service wire protocols.
///
/// Confirmed observations belong to [AuthoringSession]. Catalog snapshots
/// belong to [RealmEditorCatalogCache]. [AuthoringWorkspace] owns working
/// values, grouped operations, and save lifecycle across all Realm views.
/// The realm service remains authoritative for durable content.

library;

export "authored_capability_transport.dart";
export "authored_findings.dart";
export "authored_library_values.dart";
export "authored_local_rules.dart";
export "authored_presentation_host.dart";
export "authored_resource_commands.dart";
export "authoring_placement.dart";
export "authoring_resource_mutation.dart";
export "authoring_selectable_resource.dart";
export "authoring_session.dart";
export "authoring_state_transfer_assembler.dart";
export "authoring_subject_role.dart";
export "authoring_workspace.dart";
export "catalog_transfer_assembler.dart";
export "core_resource_definitions.dart";
export "nats_realm_editor_catalog_source.dart";
export "nats_realm_presentation_search_transport.dart";
export "nats_realm_publication_source.dart";
export "realm.dart";
export "realm_editor_catalog_request.dart";
export "realm_editor_catalog_route.dart";
export "realm_publication.dart";
export "realm_service_address.dart";
export "resource_creation.dart";
