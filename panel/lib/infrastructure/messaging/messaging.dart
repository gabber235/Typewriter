/// Panel boundaries for authenticated NATS transport and typed Skir messaging.
///
/// The transport layer owns connection lifetime and failure translation. The
/// protocol layer owns serialization, ordered projection recovery, and mutation
/// submission identity.
library;

export "api_exception.dart";
export "nats.dart";
export "nats_client.dart";
export "nats_core_client.dart";
export "nats_provider.dart";
export "skir_mutation.dart";
export "skir_nats.dart";
