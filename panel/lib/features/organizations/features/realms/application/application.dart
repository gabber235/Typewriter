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

export "authoring_collections.dart";
export "authoring_element_editor.dart";
export "authoring_element_submission.dart";
export "authoring_placement.dart";
export "authoring_selectable_resource.dart";
export "authoring_session.dart";
export "authoring_subject_role.dart";
export "authoring_subjects.dart";
export "nats_realm_capability_transport.dart";
export "nats_realm_editor_catalog_source.dart";
export "nats_realm_presentation_search_transport.dart";
export "realm.dart";
export "realm_editor_catalog.dart";
export "realm_editor_catalog_cache.dart";
export "realm_editor_catalog_provider.dart";
export "realm_editor_catalog_request.dart";
export "realm_element_catalog.dart";
export "realm_page_catalog.dart";
export "realm_service_address.dart";
export "resource_creation.dart";
export "typed_authoring.dart";
