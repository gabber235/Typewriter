/// Realm application state and boundary adapters for the organization panel.
///
/// This library connects route selected realms to their authoritative catalogs,
/// authoring projections, editor resources, capability invocation, and
/// presentation search. Riverpod providers construct the graph only when an
/// organization and an online realm exist. NATS adapters translate between
/// those application contracts and the realm service wire protocols.
///
/// Canonical authoring data belongs to [AuthoringSession]. Catalog snapshots
/// belong to [RealmEditorCatalogCache]. Editor drafts remain owned by the
/// shared editor and mutation layers. The realm service remains authoritative
/// for durable content and catalog generation.
library;

export "authored_capability_transport.dart";
export "authored_draft.dart";
export "authored_draft_presentation_host.dart";
export "authored_findings.dart";
export "authored_library_values.dart";
export "authored_local_rules.dart";
export "authoring_changed_transfer_assembler.dart";
export "authoring_delta.dart";
export "authoring_placement.dart";
export "authoring_resource_mutation.dart";
export "authoring_selectable_resource.dart";
export "authoring_session.dart";
export "authoring_session_access.dart";
export "authoring_snapshot_transfer_assembler.dart";
export "authoring_subject_role.dart";
export "core_resource_definitions.dart";
export "nats_realm_editor_catalog_source.dart";
export "nats_realm_presentation_search_transport.dart";
export "nats_realm_publication_source.dart";
export "realm.dart";
export "realm_editor_catalog_route.dart";
export "realm_publication.dart";
export "realm_service_address.dart";
export "resource_creation.dart";
