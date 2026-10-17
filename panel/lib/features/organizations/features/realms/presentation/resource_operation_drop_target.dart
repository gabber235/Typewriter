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
  GraphDragPayload<AuthoringResourceDragGroup>? _hovered;

  void _observeHover(GraphDragPayload<AuthoringResourceDragGroup>? value) {
    if (identical(_hovered, value)) return;
    _hovered?.removeListener(_refreshHover);
    _hovered = value;
    value?.addListener(_refreshHover);
  }

  void _refreshHover() {
    if (!mounted) return;
    setState(() {
      final current = _hovered;
      if (current != null && !current.canHover) _observeHover(null);
    });
  }

  @override
  void dispose() {
    _hovered?.removeListener(_refreshHover);
    super.dispose();
  }

  bool _domainCurrent(AuthoringResourceDragGroup group) =>
      mounted &&
      widget.canMutate() &&
      group.primary.scope == widget.scope &&
      (group.sourceCanMutate?.call() ?? true);

  @override
  Widget build(BuildContext context) {
    final evaluated = _hovered;
    AsyncValue<bool>? check;
    if (evaluated != null &&
        evaluated.canHover &&
        _domainCurrent(evaluated.value)) {
      final hovered = evaluated.value;
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
    bool? knownFor(GraphDragPayload<AuthoringResourceDragGroup> offered) =>
        identical(evaluated, offered) ? known : null;

    bool eligible(GraphDragPayload<AuthoringResourceDragGroup> offered) =>
        offered.canHover && _domainCurrent(offered.value);

    return DragTarget<GraphDragPayload<AuthoringResourceDragGroup>>(
      onWillAcceptWithDetails: (details) {
        final offered = details.data;
        if (!eligible(offered)) return false;
        if (!identical(_hovered, offered)) {
          setState(() => _observeHover(offered));
        }
        return knownFor(offered) != false;
      },
      onLeave: (offered) {
        if (mounted && identical(_hovered, offered)) {
          setState(() => _observeHover(null));
        }
      },
      onAcceptWithDetails: (details) async {
        final offered = details.data;
        if (!eligible(offered) ||
            knownFor(offered) == false ||
            !offered.claim()) {
          return;
        }
        // Claim is the handoff. Do not check hover phase after an await.
        final group = offered.value;
        final expected = widget;
        try {
          await invokeResourceDropOperation(
            ref: ref,
            scope: widget.scope,
            group: group,
            operationLocalId: widget.operationLocalId,
            suppliedFields: widget.suppliedFields,
            isCurrent: () =>
                mounted &&
                widget.scope == expected.scope &&
                widget.operationLocalId == expected.operationLocalId &&
                mapEquals(widget.suppliedFields, expected.suppliedFields) &&
                _domainCurrent(group),
          );
        } finally {
          if (mounted && identical(_hovered, offered)) {
            setState(() => _observeHover(null));
          }
        }
      },
      builder: (context, accepted, rejected) => HookBuilder(
        builder: (context) {
          useListenable(
            Listenable.merge([
              ...accepted.nonNulls,
              ...rejected
                  .whereType<GraphDragPayload<AuthoringResourceDragGroup>>(),
            ]),
          );
          return widget.builder(
            context,
            accepted.nonNulls.any(
              (offered) =>
                  eligible(offered) &&
                  identical(_hovered, offered) &&
                  knownFor(offered) == true,
            ),
            rejected
                    .whereType<GraphDragPayload<AuthoringResourceDragGroup>>()
                    .any((offered) => offered.canHover) ||
                accepted.nonNulls.any(
                  (offered) =>
                      eligible(offered) &&
                      identical(_hovered, offered) &&
                      knownFor(offered) == false,
                ),
          );
        },
      ),
    );
  }
}
