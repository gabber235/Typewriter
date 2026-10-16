import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Keeps asynchronous hover feedback separate from authoritative drop execution.
/// Pending checks remain neutral; only a checked available target highlights.
class ResourceOperationDropTarget extends ConsumerStatefulWidget {
  const ResourceOperationDropTarget({
    required this.scope,
    required this.operationLocalId,
    required this.suppliedFields,
    required this.canMutate,
    required this.builder,
    super.key,
  });

  final AuthoringScope scope;
  final String operationLocalId;
  final Map<String, skir.DataValue> suppliedFields;
  final bool Function() canMutate;
  final Widget Function(BuildContext context, bool accepted, bool rejected)
  builder;

  @override
  ConsumerState<ResourceOperationDropTarget> createState() =>
      _ResourceOperationDropTargetState();
}

class _ResourceOperationDropTargetState
    extends ConsumerState<ResourceOperationDropTarget> {
  AuthoringResourceDragGroup? _hovered;

  bool _current(AuthoringResourceDragGroup group) =>
      mounted &&
      widget.canMutate() &&
      group.primary.scope == widget.scope &&
      (group.sourceCanMutate?.call() ?? true);

  @override
  Widget build(BuildContext context) {
    final hovered = _hovered;
    AsyncValue<bool>? check;
    if (hovered != null) {
      final document = ref
          .watch(workingAuthoringDocumentProvider(widget.scope))
          .value;
      if (document != null) {
        final invocation = captureResourceOperationInvocation(
          document: document,
          targets: hovered.memberships.keys.map((item) => item.resourceId),
          invocationId: skir.InvocationId(value: "drop-preflight"),
          origin: skir.OperationOrigin(
            container:
                hovered.memberships.values
                        .map((item) => item.source)
                        .toSet()
                        .length ==
                    1
                ? hovered.memberships.values.first.source
                : null,
            occurrences: hovered.memberships.values,
          ),
        );
        check = ref.watch(
          resourceDropAvailableProvider(
            widget.scope,
            invocation,
            widget.operationLocalId,
            skir.DataValue.createRecord(
              fields: [
                for (final field in widget.suppliedFields.entries)
                  skir.FieldValue(name: field.key, value: field.value),
              ],
            ),
          ),
        );
      }
    }
    final known = check is AsyncData<bool> ? check.value : null;
    return DragTarget<AuthoringResourceDragGroup>(
      onWillAcceptWithDetails: (details) {
        if (!_current(details.data)) return false;
        if (_hovered != details.data) {
          setState(() => _hovered = details.data);
          return true;
        }
        return known != false;
      },
      onLeave: (_) {
        if (mounted) setState(() => _hovered = null);
      },
      onAcceptWithDetails: (details) async {
        if (!_current(details.data) || known == false) return;
        final expected = widget;
        try {
          await invokeResourceDropOperation(
            ref: ref,
            scope: widget.scope,
            group: details.data,
            operationLocalId: widget.operationLocalId,
            suppliedFields: widget.suppliedFields,
            isCurrent: () =>
                widget.scope == expected.scope &&
                widget.operationLocalId == expected.operationLocalId &&
                mapEquals(widget.suppliedFields, expected.suppliedFields) &&
                _current(details.data),
          );
        } finally {
          if (mounted) setState(() => _hovered = null);
        }
      },
      builder: (context, accepted, rejected) => widget.builder(
        context,
        accepted.isNotEmpty && known == true,
        rejected.isNotEmpty || accepted.isNotEmpty && known == false,
      ),
    );
  }
}
