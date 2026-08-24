import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/editor_codec_support.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/capability.dart"
    as wire;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/type_catalog.dart"
    as wire_type;
import "package:typewriter_panel/typewriter_panel.dart";

final class NatsRealmCapabilityTransport {
  NatsRealmCapabilityTransport({
    required this.ref,
    required this.organizationId,
    required this.realmId,
    required this.generation,
    required this.registry,
    required this.reload,
  });

  final Ref ref;
  final skir.RecordId organizationId;
  final skir.RecordId realmId;
  final CatalogGeneration generation;
  final TypeRegistry registry;
  final Future<void> Function() reload;
  var _sequence = 0;

  RealmServiceAddress get _address =>
      RealmServiceAddress(organizationId: organizationId, realmId: realmId);

  Future<RealmCommandResult> execute(
    RealmAction action,
    DataValue? payload,
  ) async {
    if (action is ReloadRealmAction) {
      await reload();
      return const RealmCommandResult.success([]);
    }
    final command = action as InvokeRealmCommandAction;
    if (payload == null) {
      return RealmCommandResult.invalid([
        const TypeDiagnostic(
          code: TypeDiagnosticCode.invalidValue,
          message: "Realm command payload is missing",
        ),
      ]);
    }
    final editor = SkirEditorCodec(registry);
    final encoded = editor.encodeValue(payload);
    if (encoded case TypeFailure(:final diagnostics)) {
      return RealmCommandResult.invalid(diagnostics);
    }
    final invocationId =
        "${DateTime.now().microsecondsSinceEpoch}:${_sequence++}";
    final response = await ref.requestSkir(
      _address.request("editor.capability.command.invoke"),
      wire.CapabilityInvocationRequest.serializer.toBytes(
        wire.CapabilityInvocationRequest(
          invocationId: wire.InvocationId(value: invocationId),
          generation: wire_type.CatalogGeneration(value: generation.value),
          capabilityId: wire_type.CapabilityId(
            value: command.capabilityId.value,
          ),
          payload: encoded.valueOrNull!,
          expectedResultType: null,
        ),
      ),
      wire.CommandResult.serializer,
    );
    return _decode(response, editor, invocationId);
  }

  Future<RealmComputationResult> compute({
    required CapabilityId capabilityId,
    required DataValue payload,
    required TypeExpression resultType,
  }) async {
    final editor = SkirEditorCodec(registry);
    final encodedPayload = editor.encodeValue(payload);
    final encodedResult = editor.typeCodec.encodeExpression(resultType);
    final diagnostics = [
      ...encodedPayload.diagnostics,
      ...encodedResult.diagnostics,
    ];
    if (diagnostics.isNotEmpty) {
      return RealmComputationResult.invalid(diagnostics);
    }
    final invocationId =
        "${DateTime.now().microsecondsSinceEpoch}:${_sequence++}";
    final response = await ref.requestSkir(
      _address.request("editor.capability.computation.invoke"),
      wire.CapabilityInvocationRequest.serializer.toBytes(
        wire.CapabilityInvocationRequest(
          invocationId: wire.InvocationId(value: invocationId),
          generation: wire_type.CatalogGeneration(value: generation.value),
          capabilityId: wire_type.CapabilityId(value: capabilityId.value),
          payload: encodedPayload.valueOrNull!,
          expectedResultType: encodedResult.valueOrNull,
        ),
      ),
      wire.ComputationResult.serializer,
    );
    return _decodeComputation(response, editor, invocationId);
  }
}

RealmComputationResult _decodeComputation(
  wire.ComputationResult result,
  SkirEditorCodec editor,
  String invocationId,
) {
  final correlated = switch (result) {
    wire.ComputationResult_successWrapper(:final value) =>
      value.invocationId.value,
    wire.ComputationResult_invalidWrapper(:final value) =>
      value.invocationId.value,
    wire.ComputationResult_unavailableWrapper(:final value) =>
      value.invocationId.value,
    wire.ComputationResult_permissionDeniedWrapper(:final value) =>
      value.invocationId.value,
    wire.ComputationResult_staleGenerationWrapper(:final value) =>
      value.invocationId.value,
    wire.ComputationResult_unknown() => invocationId,
  };
  if (correlated != invocationId) {
    return RealmComputationResult.unavailable([
      const TypeDiagnostic(
        code: TypeDiagnosticCode.invalidValue,
        message: "Realm computation response used a different invocation ID",
      ),
    ]);
  }
  return switch (result) {
    wire.ComputationResult_successWrapper(:final value) => switch (editor
        .decodeValue(value.value)) {
      TypeSuccess(:final value) => RealmComputationResult.success(value),
      TypeFailure(:final diagnostics) => RealmComputationResult.invalid(
        diagnostics,
      ),
    },
    wire.ComputationResult_invalidWrapper(:final value) =>
      RealmComputationResult.invalid(
        value.diagnostics
            .map((item) => item.decodeWire(editor.pathCodec))
            .toList(),
      ),
    wire.ComputationResult_unavailableWrapper(:final value) =>
      RealmComputationResult.unavailable(
        value.diagnostics
            .map((item) => item.decodeWire(editor.pathCodec))
            .toList(),
      ),
    wire.ComputationResult_permissionDeniedWrapper(:final value) =>
      RealmComputationResult.permissionDenied(value.message),
    wire.ComputationResult_staleGenerationWrapper(:final value) =>
      RealmComputationResult.staleGeneration(
        CatalogGeneration(value.actualGeneration.value),
      ),
    wire.ComputationResult_unknown() => RealmComputationResult.unavailable([
      const TypeDiagnostic(
        code: TypeDiagnosticCode.invalidValue,
        message: "Realm returned an unknown computation result",
      ),
    ]),
  };
}

RealmCommandResult _decode(
  wire.CommandResult result,
  SkirEditorCodec editor,
  String invocationId,
) {
  final correlated = switch (result) {
    wire.CommandResult_successWrapper(:final value) => value.invocationId.value,
    wire.CommandResult_invalidWrapper(:final value) => value.invocationId.value,
    wire.CommandResult_unavailableWrapper(:final value) =>
      value.invocationId.value,
    wire.CommandResult_permissionDeniedWrapper(:final value) =>
      value.invocationId.value,
    wire.CommandResult_staleGenerationWrapper(:final value) =>
      value.invocationId.value,
    wire.CommandResult_unknown() => invocationId,
  };
  if (correlated != invocationId) {
    return RealmCommandResult.unavailable([
      const TypeDiagnostic(
        code: TypeDiagnosticCode.invalidValue,
        message: "Realm command response used a different invocation ID",
      ),
    ]);
  }
  return switch (result) {
    wire.CommandResult_successWrapper(:final value) => _decodeInstructions(
      value.instructions.toList(),
      editor,
    ),
    wire.CommandResult_invalidWrapper(:final value) =>
      RealmCommandResult.invalid(
        value.diagnostics
            .map((item) => item.decodeWire(editor.pathCodec))
            .toList(),
      ),
    wire.CommandResult_unavailableWrapper(:final value) =>
      RealmCommandResult.unavailable(
        value.diagnostics
            .map((item) => item.decodeWire(editor.pathCodec))
            .toList(),
      ),
    wire.CommandResult_permissionDeniedWrapper(:final value) =>
      RealmCommandResult.permissionDenied(value.message),
    wire.CommandResult_staleGenerationWrapper(:final value) =>
      RealmCommandResult.staleGeneration(
        CatalogGeneration(value.actualGeneration.value),
      ),
    wire.CommandResult_unknown() => RealmCommandResult.unavailable([
      const TypeDiagnostic(
        code: TypeDiagnosticCode.invalidValue,
        message: "Realm returned an unknown command result",
      ),
    ]),
  };
}

RealmCommandResult _decodeInstructions(
  List<wire.PanelInstruction> values,
  SkirEditorCodec editor,
) {
  final instructions = <PanelInstruction>[];
  final diagnostics = <TypeDiagnostic>[];
  for (final value in values) {
    final decoded = _decodeInstruction(value, editor);
    diagnostics.addAll(decoded.diagnostics);
    if (decoded.valueOrNull case final instruction?) {
      instructions.add(instruction);
    }
  }
  return diagnostics.isEmpty
      ? RealmCommandResult.success(instructions)
      : RealmCommandResult.invalid(diagnostics);
}

TypeResult<PanelInstruction> _decodeInstruction(
  wire.PanelInstruction value,
  SkirEditorCodec editor,
) => switch (value) {
  wire.PanelInstruction_invalidateResourceWrapper(:final value) =>
    _decodeResource(
      value.resource,
      editor,
    ).mapValue(PanelInstruction.invalidateResource),
  wire.PanelInstruction_openResourceWrapper(:final value) => _decodeResource(
    value.resource,
    editor,
  ).mapValue(PanelInstruction.openResource),
  wire.PanelInstruction_notifyWrapper(:final value) => TypeResult.success(
    PanelInstruction.notify(switch (value.severity) {
      wire.NotificationSeverity.info => NotificationSeverity.info,
      wire.NotificationSeverity.success => NotificationSeverity.success,
      wire.NotificationSeverity.warning => NotificationSeverity.warning,
      wire.NotificationSeverity.error => NotificationSeverity.error,
      wire.NotificationSeverity_unknown() => NotificationSeverity.error,
    }, value.message),
  ),
  wire.PanelInstruction_unknown() => invalidWire("Unknown panel instruction"),
};

TypeResult<ResourceAddress> _decodeResource(
  wire.ResourceAddress value,
  SkirEditorCodec editor,
) => combineResults(
  editor.typeCodec.decodeReference(value.resourceType),
  editor.decodeValue(value.identity),
  (type, identity) => ResourceAddress(type: type, identity: identity),
);
