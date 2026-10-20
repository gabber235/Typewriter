/// Panel boundaries for authenticated NATS transport and typed Skir messaging.
///
/// The transport layer owns connection lifetime and failure translation. The
/// protocol layer owns serialization and ordered projection recovery. Mutation
/// adapters transfer captured submissions to the shared local work owner.
library;

export "api_exception.dart";
export "bounded_transfer_assembler.dart";
export "generated/generated.dart";
export "generation_checked_transfer_assembler.dart";
export "nats.dart";
export "nats_client.dart";
export "nats_core_client.dart";
export "nats_provider.dart";
export "projection_reconciliation.dart";
export "skir_mutation.dart";
export "skir_nats.dart";
