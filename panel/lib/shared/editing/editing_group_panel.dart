import "package:typewriter_panel/typewriter_panel.dart";

/// Presents one retained group using the same control as portable bindings.
final class EditingGroupPanel<S, E> extends HookWidget {
  const EditingGroupPanel({
    required this.workspace,
    required this.id,
    this.review,
    super.key,
  });
  final EditingWorkspace<S, E> workspace;
  final EditGroupId id;
  final Widget Function()? review;
  @override
  Widget build(BuildContext context) {
    useListenable(workspace);
    final control = useMemoized(() => workspace.group(id), [workspace, id]);
    useEffect(() => control.dispose, [control]);
    final group = workspace.state.groups[id];
    if (group == null || !control.state.showControls) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(group.label),
        ApplyControls(control: control),
        if (review != null)
          TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(group.label),
                content: SingleChildScrollView(child: review!()),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Close"),
                  ),
                ],
              ),
            ),
            child: const Text("View changes"),
          ),
      ],
    );
  }
}
