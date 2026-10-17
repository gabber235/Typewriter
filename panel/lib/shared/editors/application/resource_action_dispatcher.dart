import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Evaluates resource action expressions in the caller's immutable bindings.
/// Native navigation and prepared edits retain their respective effect owners.
final class ResourceActionDispatcher {
  const ResourceActionDispatcher({
    required this.catalog,
    required this.context,
    required this.isCurrent,
    required this.navigate,
    required this.prepare,
    this.invokeCommand,
    this.reload,
  });

  final CheckedEditorCatalog catalog;
  final PortableInvocationContext context;
  final bool Function() isCurrent;
  final Future<void> Function(
    skir.ResourceId resource,
    skir.ResourceNavigationMode mode,
  )
  navigate;
  final Future<void> Function(
    skir.CapabilityId capability,
    List<skir.ResourceId> targets,
    skir.DataValue? initialInput,
  )
  prepare;

  final Future<void> Function(skir.CapabilityId, skir.DataValue)? invokeCommand;
  final Future<void> Function()? reload;

  skir.DataValue _evaluate(skir.ExpressionNode expression) {
    final evaluated = catalog.evaluateExpression(
      expression,
      bindings: context.bindings,
      budget: skir.EvaluationBudget(maxSteps: 10000, maxCollectionItems: 10000),
      queries: context.queries,
    );
    if (evaluated case PortableExpressionAvailable(:final value)) return value;
    throw StateError(switch (evaluated) {
      PortableExpressionFailed(:final message) => message,
      _ => "The resource action value is unavailable",
    });
  }

  Future<void> dispatch(skir.EditorAction action) async {
    if (!isCurrent()) return;
    switch (action) {
      case skir.EditorAction_navigateWrapper(:final value):
        final identity = _evaluate(value.resource).authoredString;
        if (identity == null || identity.isEmpty) {
          throw StateError("The navigation target is not a resource identity");
        }
        if (!isCurrent()) return;
        await navigate(skir.ResourceId(value: identity), value.mode);
      case skir.EditorAction_authoringWrapper(:final value):
        final items = _evaluate(value.targets).authoredItems;
        if (items == null || items.isEmpty) {
          throw StateError("The authoring action requires resource targets");
        }
        final targets = <skir.ResourceId>[];
        for (final item in items) {
          final identity = item.value.authoredString;
          if (identity == null || identity.isEmpty) {
            throw StateError("The authoring target is not a resource identity");
          }
          final id = skir.ResourceId(value: identity);
          if (!targets.contains(id)) targets.add(id);
        }
        final initial = value.initialInput == null
            ? null
            : _evaluate(value.initialInput!);
        if (!isCurrent()) return;
        await prepare(value.capability, targets, initial);
      case skir.EditorAction_realmWrapper(:final value):
        await executePortableRealmAction(
          value,
          evaluate: _evaluate,
          invokeCommand: invokeCommand,
          reload: reload,
        );
      default:
        throw StateError("A resource operation requires a resource action");
    }
  }
}

/// Shares Realm effect dispatch between presentations and resource operations.
Future<void> executePortableRealmAction(
  skir.RealmEditorAction action, {
  required skir.DataValue Function(skir.ExpressionNode) evaluate,
  Future<void> Function(skir.CapabilityId, skir.DataValue)? invokeCommand,
  Future<void> Function()? reload,
}) async {
  switch (action) {
    case skir.RealmEditorAction_reloadWrapper():
      if (reload == null) throw StateError("Reload is unavailable");
      await reload();
    case skir.RealmEditorAction_commandWrapper(:final value):
      if (invokeCommand == null) {
        throw StateError("Realm commands are unavailable");
      }
      final payload = evaluate(value.payload);
      await invokeCommand(value.capabilityId, payload);
    default:
      throw StateError("This Realm editor action is unavailable");
  }
}

/// Applies the existing Realm command instructions under the invoking lifetime.
Future<void> handleRealmCommandResult(
  skir.CommandResult result, {
  required bool Function() isCurrent,
  required Future<void> Function() reload,
  required FutureOr<void> Function(skir.ResourceId) openResource,
  required FutureOr<void> Function(String) reportStatus,
}) async {
  if (!isCurrent()) return;
  switch (result) {
    case skir.CommandResult_successWrapper(:final value):
      for (final instruction in value.instructions) {
        if (!isCurrent()) return;
        switch (instruction) {
          case skir.PanelInstruction_invalidateResourceWrapper():
            await reload();
          case skir.PanelInstruction_openResourceWrapper(:final value):
            final identity = value.resource.identity.authoredString;
            if (identity == null) {
              await reportStatus(
                "The command returned an invalid resource identity",
              );
            } else {
              await openResource(skir.ResourceId(value: identity));
            }
          case skir.PanelInstruction_notifyWrapper(:final value):
            await reportStatus(value.message);
          default:
            await reportStatus("The command returned an unknown instruction");
        }
      }
    case skir.CommandResult_invalidWrapper(:final value):
    case skir.CommandResult_unavailableWrapper(:final value):
      await reportStatus(
        value.diagnostics.map((item) => item.message).join("\n"),
      );
    case skir.CommandResult_permissionDeniedWrapper(:final value):
      await reportStatus(value.message);
    case skir.CommandResult_staleGenerationWrapper():
      await reload();
      if (isCurrent()) {
        await reportStatus(
          "The editor catalog changed. Review the refreshed form",
        );
      }
    default:
      await reportStatus("The command result is unavailable");
  }
}
