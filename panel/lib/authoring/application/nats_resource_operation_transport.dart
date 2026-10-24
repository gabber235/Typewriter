import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Uses the current panel connection and the addressed Realm for operation work.
final class NatsResourceOperationTransport {
  const NatsResourceOperationTransport({
    required this.ref,
    required this.organizationId,
    required this.realmId,
  });

  final Ref ref;
  final skir.RecordId organizationId;
  final skir.RecordId realmId;

  Future<skir.ResolveResourceOperationsResult> resolve(
    skir.ResolveResourceOperationsRequest request,
  ) => ref.requestSkir(
    request.operation(organizationId: organizationId, realmId: realmId),
  );

  Future<skir.ResolveDropCandidatesResult> resolveDropCandidates(
    skir.ResolveDropCandidatesRequest request,
  ) => ref.requestSkir(
    request.operation(organizationId: organizationId, realmId: realmId),
  );

  Future<skir.AuthoringActionResult> prepare(
    skir.PrepareAuthoringActionRequest request,
  ) => ref.requestSkir(
    request.operation(organizationId: organizationId, realmId: realmId),
  );
}
