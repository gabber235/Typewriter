import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/features/organizations/features/realms/application/realm_service_address.dart";
import "package:typewriter_panel/infrastructure/messaging/api_exception.dart";
import "package:typewriter_panel/infrastructure/messaging/skir_nats.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/capability.dart"
    as capability;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/type_catalog.dart"
    as types;
import "package:uuid/uuid.dart";

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

  Future<capability.CommandResult> command({
    required types.CatalogGeneration generation,
    required types.CapabilityId capabilityId,
    required types.DataValue payload,
  }) async {
    final invocation = capability.InvocationId(value: const Uuid().v4());
    final result = await ref.requestSkir(
      _address.request("editor.capability.command.invoke"),
      capability.CapabilityInvocationRequest.serializer.toBytes(
        capability.CapabilityInvocationRequest(
          invocationId: invocation,
          generation: generation,
          capabilityId: capabilityId,
          payload: payload,
          expectedResultType: null,
        ),
      ),
      capability.CommandResult.serializer,
    );
    if (_commandInvocation(result) != invocation) {
      throw ApiException.internalServerError();
    }
    return result;
  }

  Future<capability.ComputationResult> computation({
    required types.CatalogGeneration generation,
    required types.CapabilityId capabilityId,
    required types.DataValue payload,
    required types.TypeTemplate expectedResultType,
  }) async {
    final invocation = capability.InvocationId(value: const Uuid().v4());
    final result = await ref.requestSkir(
      _address.request("editor.capability.computation.invoke"),
      capability.CapabilityInvocationRequest.serializer.toBytes(
        capability.CapabilityInvocationRequest(
          invocationId: invocation,
          generation: generation,
          capabilityId: capabilityId,
          payload: payload,
          expectedResultType: expectedResultType,
        ),
      ),
      capability.ComputationResult.serializer,
    );
    if (_computationInvocation(result) != invocation) {
      throw ApiException.internalServerError();
    }
    return result;
  }
}

capability.InvocationId? _commandInvocation(
  capability.CommandResult result,
) => switch (result) {
  capability.CommandResult_successWrapper(:final value) => value.invocationId,
  capability.CommandResult_invalidWrapper(:final value) => value.invocationId,
  capability.CommandResult_unavailableWrapper(:final value) =>
    value.invocationId,
  capability.CommandResult_permissionDeniedWrapper(:final value) =>
    value.invocationId,
  capability.CommandResult_staleGenerationWrapper(:final value) =>
    value.invocationId,
  capability.CommandResult_unknown() => null,
};

capability.InvocationId? _computationInvocation(
  capability.ComputationResult result,
) => switch (result) {
  capability.ComputationResult_successWrapper(:final value) =>
    value.invocationId,
  capability.ComputationResult_invalidWrapper(:final value) =>
    value.invocationId,
  capability.ComputationResult_unavailableWrapper(:final value) =>
    value.invocationId,
  capability.ComputationResult_permissionDeniedWrapper(:final value) =>
    value.invocationId,
  capability.ComputationResult_staleGenerationWrapper(:final value) =>
    value.invocationId,
  capability.ComputationResult_unknown() => null,
};
