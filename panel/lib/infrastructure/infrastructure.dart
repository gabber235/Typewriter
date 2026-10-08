/// Shared adapters between panel application code and external protocols.
///
/// Messaging owns NATS transport and Skir request boundaries. Observability
/// owns trace propagation. This facade exports handwritten panel adapters.
/// Protocol declarations and serializers belong to the separate Skir library.
library;

export "messaging/messaging.dart";
export "observability/observability.dart";
export "protocols/skir/converters.dart";
export "protocols/skir/realm_search_query_codec.dart";
