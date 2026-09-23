/// Shared adapters between panel application code and external protocols.
///
/// Messaging owns NATS transport and Skir request boundaries. Observability
/// owns trace propagation. Generated protocol types remain behind these exports
/// so feature code depends on panel contracts rather than package details.
library;

export "messaging/messaging.dart";
export "observability/observability.dart";
export "protocols/skir/converters.dart";
export "protocols/skir/editor_catalog_codec.dart";
export "protocols/skir/editor_codec.dart";
export "protocols/skir/editor_diagnostic_codec.dart";
export "protocols/skir/skir.dart" show RecordId, ResourceId;
