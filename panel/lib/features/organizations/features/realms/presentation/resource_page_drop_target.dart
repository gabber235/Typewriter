import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Transfers an owned node group onto a page without changing page dragging.
class ResourcePageDropTarget extends ConsumerStatefulWidget {
  const ResourcePageDropTarget({
    required this.page,
    required this.child,
    this.enabled = true,
    this.workspace,
    this.authoringScope,
    super.key,
  });

  final skir.ResourceId page;
  final Widget child;
  final bool enabled;
  final RealmEditing? workspace;
  final AuthoringScope? authoringScope;

  @override
  ConsumerState<ResourcePageDropTarget> createState() =>
      _ResourcePageDropTargetState();
}

class _ResourcePageDropTargetState
    extends ConsumerState<ResourcePageDropTarget> {
  bool get canMutate {
    if (!mounted || !widget.enabled) return false;
    if (widget.workspace case final workspace?) {
      return workspace.state.available;
    }
    final scope = ref.read(selectedAuthoringScopeProvider);
    return scope != null &&
        ref.read(realmEditingProvider(scope)).state.available;
  }

  @override
  Widget build(BuildContext context) {
    final scope =
        widget.authoringScope ?? ref.watch(selectedAuthoringScopeProvider);
    if (scope == null) return widget.child;
    final workspace =
        widget.workspace ?? ref.watch(realmEditingProvider(scope));
    if (workspace == null) return widget.child;
    bool current() {
      if (!canMutate) return false;
      final currentScope =
          widget.authoringScope ?? ref.read(selectedAuthoringScopeProvider);
      if (currentScope != scope) return false;
      final currentWorkspace =
          widget.workspace ?? ref.read(realmEditingProvider(scope));
      return identical(currentWorkspace, workspace);
    }

    return ResourceOperationDropTarget(
      scope: scope,
      operationLocalId: "moveToPage",
      suppliedFields: {
        "destination": skir.DataValue.wrapStringValue(widget.page.value),
      },
      canMutate: current,
      builder: (context, accepted, rejected) => Semantics(
        label: accepted ? "Move entries to this page" : null,
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            border: accepted || rejected
                ? Border.all(
                    width: 2,
                    color: accepted
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.error,
                  )
                : null,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
