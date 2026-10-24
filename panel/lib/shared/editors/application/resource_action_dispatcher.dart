import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Evaluates resource action expressions in the caller's immutable bindings.
/// Native navigation, creation and prepared edits retain their respective
/// effect owners.
final class ResourceActionDispatcher {
  const ResourceActionDispatcher({
    required this.catalog,
    required this.context,
    required this.isCurrent,
    required this.navigate,
    required this.prepare,
    this.create,
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

  /// Creates a resource of the requested type that joins the link field at
  /// the owner location, with evaluated preset fields.
  final Future<void> Function(
    skir.TypeDefinitionId type,
    skir.ValueLocation? owner,
    List<skir.FieldValue> supplied,
  )?
  create;

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

  skir.DataValue? _evaluateOptional(skir.ExpressionNode expression) =>
      switch (catalog.evaluateExpression(
        expression,
        bindings: context.bindings,
        budget: skir.EvaluationBudget(
          maxSteps: 10000,
          maxCollectionItems: 10000,
        ),
        queries: context.queries,
      )) {
        PortableExpressionAvailable(:final value) => value,
        PortableExpressionUnavailable() => null,
        PortableExpressionFailed(:final message) => throw StateError(message),
      };

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
      case skir.EditorAction_createWrapper(:final value):
        final create = this.create;
        if (create == null) throw StateError("Creation is unavailable here");
        final owner = switch (value.owner) {
          final reference? => context.location(
            reference,
            catalog.snapshot.generation,
          ),
          null => null,
        };
        if (value.owner != null && owner == null) {
          throw StateError("The creation owner is unavailable");
        }
        final presets = <(skir.ValuePath, skir.DataValue)>[];
        for (final preset in value.fields) {
          // A preset that evaluates to missing leaves the field at its default.
          if (_evaluateOptional(preset.value) case final evaluated?) {
            presets.add((preset.path, evaluated));
          }
        }
        if (!isCurrent()) return;
        await create(value.type, owner, presetFields(presets));
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

/// Initial field values from presets addressed by field paths, nesting partial
/// records for deeper paths. A later preset for the same path wins.
List<skir.FieldValue> presetFields(
  Iterable<(skir.ValuePath, skir.DataValue)> presets,
) {
  final values = <String, Object>{};
  for (final (path, value) in presets) {
    final names = [
      for (final segment in path.segments)
        switch (segment) {
          skir.PathSegment_fieldWrapper(:final value) => value.name,
          _ => throw StateError("A creation preset must address a field"),
        },
    ];
    if (names.isEmpty) {
      throw StateError("A creation preset must address a field");
    }
    var level = values;
    for (final name in names.take(names.length - 1)) {
      final nested = level[name];
      level = nested is Map<String, Object>
          ? nested
          : level[name] = <String, Object>{};
    }
    level[names.last] = value;
  }
  List<skir.FieldValue> fields(Map<String, Object> level) => [
    for (final entry in level.entries)
      skir.FieldValue(
        name: entry.key,
        value: switch (entry.value) {
          final skir.DataValue value => value,
          final Map<String, Object> nested => skir.DataValue.createRecord(
            fields: fields(nested),
          ),
          _ => throw StateError("Unexpected preset value"),
        },
      ),
  ];
  return fields(values);
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
    case skir.CommandResult_invalidErrorWrapper(:final value):
    case skir.CommandResult_unavailableErrorWrapper(:final value):
      await reportStatus(
        value.diagnostics.map((item) => item.message).join("\n"),
      );
    case skir.CommandResult_permissionDeniedErrorWrapper(:final value):
      await reportStatus(value.message);
    case skir.CommandResult_staleGenerationErrorWrapper():
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
