/// NATS transport and typed messaging boundaries used by the panel.
///
/// [NatsClient] owns connection and subscription lifecycle. Skir adapters own
/// serialization and ordered projection recovery, while mutation helpers hand
/// submission identity and consistency decisions to the shared work owner.
library;

export "nats_authorization.dart";
export "nats_client.dart";
export "nats_connection.dart";
export "nats_core_client.dart";
export "nats_provider.dart";
export "skir_mutation.dart";
export "skir_nats.dart";
