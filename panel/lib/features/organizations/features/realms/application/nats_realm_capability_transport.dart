import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/editor_codec_support.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Invokes realm owned command and computation capabilities over NATS.
///
/// The active catalog provider supplies the registry and generation used to
/// encode payloads and correlate the request with the catalog that described
/// it. This adapter translates wire outcomes, diagnostics, and panel
/// instructions into editor results. It does not evaluate expressions, check
/// command payload types, or own catalog refresh; the runtime and provider do
/// those jobs.
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

  /// Executes a command or handles the local realm reload action.
  ///
  /// Payload encoding failures are returned as invalid results. Remote stale
  /// generation, permission, unavailable, and malformed responses remain
  /// distinct so the caller can choose reload, correction, or retry.
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
      skir.CapabilityInvocationRequest.serializer.toBytes(
        skir.CapabilityInvocationRequest(
          invocationId: skir.InvocationId(value: invocationId),
          generation: skir.CatalogGeneration(value: generation.value),
          capabilityId: skir.CapabilityId(value: command.capabilityId.value),
          payload: encoded.valueOrNull!,
          expectedResultType: null,
        ),
      ),
      skir.CommandResult.serializer,
    );
    return _decode(response, editor, invocationId);
  }

  /// Evaluates a realm computation with the active catalog generation.
  ///
  /// Both payload and result type must encode before a request is sent. The
  /// decoded result is validated by the wire codec and protocol failures are
  /// returned as explicit computation outcomes.
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
      skir.CapabilityInvocationRequest.serializer.toBytes(
        skir.CapabilityInvocationRequest(
          invocationId: skir.InvocationId(value: invocationId),
          generation: skir.CatalogGeneration(value: generation.value),
          capabilityId: skir.CapabilityId(value: capabilityId.value),
          payload: encodedPayload.valueOrNull!,
          expectedResultType: encodedResult.valueOrNull,
        ),
      ),
      skir.ComputationResult.serializer,
    );
    return _decodeComputation(response, editor, invocationId);
  }
}

RealmComputationResult _decodeComputation(
  skir.ComputationResult result,
  SkirEditorCodec editor,
  String invocationId,
) {
  final correlated = switch (result) {
    skir.ComputationResult_successWrapper(:final value) =>
      value.invocationId.value,
    skir.ComputationResult_invalidWrapper(:final value) =>
      value.invocationId.value,
    skir.ComputationResult_unavailableWrapper(:final value) =>
      value.invocationId.value,
    skir.ComputationResult_permissionDeniedWrapper(:final value) =>
      value.invocationId.value,
    skir.ComputationResult_staleGenerationWrapper(:final value) =>
      value.invocationId.value,
    skir.ComputationResult_unknown() => invocationId,
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
    skir.ComputationResult_successWrapper(:final value) => switch (editor
        .decodeValue(value.value)) {
      TypeSuccess(:final value) => RealmComputationResult.success(value),
      TypeFailure(:final diagnostics) => RealmComputationResult.invalid(
        diagnostics,
      ),
    },
    skir.ComputationResult_invalidWrapper(:final value) =>
      RealmComputationResult.invalid(
        value.diagnostics
            .map((item) => item.decodeWire(editor.pathCodec))
            .toList(),
      ),
    skir.ComputationResult_unavailableWrapper(:final value) =>
      RealmComputationResult.unavailable(
        value.diagnostics
            .map((item) => item.decodeWire(editor.pathCodec))
            .toList(),
      ),
    skir.ComputationResult_permissionDeniedWrapper(:final value) =>
      RealmComputationResult.permissionDenied(value.message),
    skir.ComputationResult_staleGenerationWrapper(:final value) =>
      RealmComputationResult.staleGeneration(
        CatalogGeneration(value.actualGeneration.value),
      ),
    skir.ComputationResult_unknown() => RealmComputationResult.unavailable([
      const TypeDiagnostic(
        code: TypeDiagnosticCode.invalidValue,
        message: "Realm returned an unknown computation result",
      ),
    ]),
  };
}

RealmCommandResult _decode(
  skir.CommandResult result,
  SkirEditorCodec editor,
  String invocationId,
) {
  final correlated = switch (result) {
    skir.CommandResult_successWrapper(:final value) => value.invocationId.value,
    skir.CommandResult_invalidWrapper(:final value) => value.invocationId.value,
    skir.CommandResult_unavailableWrapper(:final value) =>
      value.invocationId.value,
    skir.CommandResult_permissionDeniedWrapper(:final value) =>
      value.invocationId.value,
    skir.CommandResult_staleGenerationWrapper(:final value) =>
      value.invocationId.value,
    skir.CommandResult_unknown() => invocationId,
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
    skir.CommandResult_successWrapper(:final value) => _decodeInstructions(
      value.instructions.toList(),
      editor,
    ),
    skir.CommandResult_invalidWrapper(:final value) =>
      RealmCommandResult.invalid(
        value.diagnostics
            .map((item) => item.decodeWire(editor.pathCodec))
            .toList(),
      ),
    skir.CommandResult_unavailableWrapper(:final value) =>
      RealmCommandResult.unavailable(
        value.diagnostics
            .map((item) => item.decodeWire(editor.pathCodec))
            .toList(),
      ),
    skir.CommandResult_permissionDeniedWrapper(:final value) =>
      RealmCommandResult.permissionDenied(value.message),
    skir.CommandResult_staleGenerationWrapper(:final value) =>
      RealmCommandResult.staleGeneration(
        CatalogGeneration(value.actualGeneration.value),
      ),
    skir.CommandResult_unknown() => RealmCommandResult.unavailable([
      const TypeDiagnostic(
        code: TypeDiagnosticCode.invalidValue,
        message: "Realm returned an unknown command result",
      ),
    ]),
  };
}

RealmCommandResult _decodeInstructions(
  List<skir.PanelInstruction> values,
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
  skir.PanelInstruction value,
  SkirEditorCodec editor,
) => switch (value) {
  skir.PanelInstruction_invalidateResourceWrapper(:final value) =>
    _decodeResource(
      value.resource,
      editor,
    ).mapValue(PanelInstruction.invalidateResource),
  skir.PanelInstruction_openResourceWrapper(:final value) => _decodeResource(
    value.resource,
    editor,
  ).mapValue(PanelInstruction.openResource),
  skir.PanelInstruction_notifyWrapper(:final value) => TypeResult.success(
    PanelInstruction.notify(switch (value.severity) {
      skir.NotificationSeverity.info => NotificationSeverity.info,
      skir.NotificationSeverity.success => NotificationSeverity.success,
      skir.NotificationSeverity.warning => NotificationSeverity.warning,
      skir.NotificationSeverity.error => NotificationSeverity.error,
      skir.NotificationSeverity_unknown() => NotificationSeverity.error,
    }, value.message),
  ),
  skir.PanelInstruction_unknown() => invalidWire("Unknown panel instruction"),
};

TypeResult<ResourceAddress> _decodeResource(
  skir.ResourceAddress value,
  SkirEditorCodec editor,
) => combineResults(
  editor.typeCodec.decodeReference(value.resourceType),
  editor.decodeValue(value.identity),
  (type, identity) => ResourceAddress(type: type, identity: identity),
);
