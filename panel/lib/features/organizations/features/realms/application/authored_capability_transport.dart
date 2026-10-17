import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

final class NatsAuthoredCapabilityTransport {
  NatsAuthoredCapabilityTransport({
    required this.ref,
    required this.organizationId,
    required this.realmId,
  });

  final Ref ref;
  final skir.RecordId organizationId;
  final skir.RecordId realmId;

  Future<skir.CommandResult> command({
    required skir.CatalogGeneration generation,
    required skir.CapabilityId capabilityId,
    required skir.DataValue payload,
  }) async {
    final invocation = skir.InvocationId(value: const Uuid().v4());
    final request = skir.CapabilityInvocationRequest(
      invocationId: invocation,
      generation: generation,
      capabilityId: capabilityId,
      payload: payload,
      expectedResultType: null,
    );
    final result = await ref.requestSkir(
      EditorCapabilityCommandInvokeRouteNats(request)
          .commandOperation(organizationId: organizationId, realmId: realmId),
    );
    if (_commandInvocation(result) != invocation) {
      throw ApiException.internalServerError();
    }
    return result;
  }

  Future<skir.ComputationResult> computation({
    required skir.CatalogGeneration generation,
    required skir.CapabilityId capabilityId,
    required skir.DataValue payload,
    required skir.TypeTemplate expectedResultType,
  }) async {
    final invocation = skir.InvocationId(value: const Uuid().v4());
    final request = skir.CapabilityInvocationRequest(
      invocationId: invocation,
      generation: generation,
      capabilityId: capabilityId,
      payload: payload,
      expectedResultType: expectedResultType,
    );
    final result = await ref.requestSkir(
      EditorCapabilityComputationInvokeRouteNats(
        request,
      ).computationOperation(organizationId: organizationId, realmId: realmId),
    );
    if (_computationInvocation(result) != invocation) {
      throw ApiException.internalServerError();
    }
    return result;
  }
}

skir.InvocationId? _commandInvocation(skir.CommandResult result) =>
    switch (result) {
      skir.CommandResult_successWrapper(:final value) => value.invocationId,
      skir.CommandResult_invalidWrapper(:final value) => value.invocationId,
      skir.CommandResult_unavailableWrapper(:final value) => value.invocationId,
      skir.CommandResult_permissionDeniedWrapper(:final value) =>
        value.invocationId,
      skir.CommandResult_staleGenerationWrapper(:final value) =>
        value.invocationId,
      skir.CommandResult_unknown() => null,
    };

skir.InvocationId? _computationInvocation(skir.ComputationResult result) =>
    switch (result) {
      skir.ComputationResult_successWrapper(:final value) => value.invocationId,
      skir.ComputationResult_invalidWrapper(:final value) => value.invocationId,
      skir.ComputationResult_unavailableWrapper(:final value) =>
        value.invocationId,
      skir.ComputationResult_permissionDeniedWrapper(:final value) =>
        value.invocationId,
      skir.ComputationResult_staleGenerationWrapper(:final value) =>
        value.invocationId,
      skir.ComputationResult_unknown() => null,
    };
