import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

final class NatsAuthoredCapabilityTransport {
  NatsAuthoredCapabilityTransport({
    required this.ref,
    required skir.RecordId organizationId,
    required skir.RecordId realmId,
  }) : _address = RealmServiceAddress(
         organizationId: organizationId,
         realmId: realmId,
       );

  final Ref ref;
  final RealmServiceAddress _address;

  Future<skir.CommandResult> command({
    required skir.CatalogGeneration generation,
    required skir.CapabilityId capabilityId,
    required skir.DataValue payload,
  }) async {
    final invocation = skir.InvocationId(value: const Uuid().v4());
    final result = await ref.requestSkir(
      _address.request("editor.capability.command.invoke"),
      skir.CapabilityInvocationRequest.serializer.toBytes(
        skir.CapabilityInvocationRequest(
          invocationId: invocation,
          generation: generation,
          capabilityId: capabilityId,
          payload: payload,
          expectedResultType: null,
        ),
      ),
      skir.CommandResult.serializer,
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
    final result = await ref.requestSkir(
      _address.request("editor.capability.computation.invoke"),
      skir.CapabilityInvocationRequest.serializer.toBytes(
        skir.CapabilityInvocationRequest(
          invocationId: invocation,
          generation: generation,
          capabilityId: capabilityId,
          payload: payload,
          expectedResultType: expectedResultType,
        ),
      ),
      skir.ComputationResult.serializer,
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
