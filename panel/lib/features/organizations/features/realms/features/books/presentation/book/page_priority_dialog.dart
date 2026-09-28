part of "route.dart";

/// Changes a page priority through an optimistic, conflict checked mutation.
///
/// The dialog keeps submission single shot while the request is pending. A
/// failed request re enables submission and leaves the dialog open so the
/// caller can correct or retry the value.
class ChangePagePriorityDialogue extends HookConsumerWidget {
  const ChangePagePriorityDialogue({
    required this.pageId,
    required this.pageName,
    required this.priority,
    super.key,
  });

  final skir.ResourceId pageId;
  final String pageName;
  final int priority;

  Future<void> _changePriority(
    WidgetRef ref,
    int newPriority,
    ValueNotifier<bool> changed,
  ) async {
    if (changed.value) return;
    changed.value = true;

    final navigator = Navigator.of(ref.context);
    try {
      final result = await ref.editPage(
        id: pageId,
        priority: newPriority,
        expectedPriority: priority,
      );
      result.requireApplied(
        conflictMessage: "The page priority changed while editing",
      );
    } on Object {
      if (ref.context.mounted) changed.value = false;
      rethrow;
    }
    if (ref.context.mounted) navigator.pop(true);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController();
    final focusNode = useFocusNode();
    final changed = useState(false);
    final buttonController = useLoadingButtonController();

    return AlertDialog(
      title: Text("Change priority of $pageName"),
      content: EditorTextField(
        controller: controller,
        focusNode: focusNode,
        autofocus: EditorTextFieldAutoFocus.textField,
        text: priority.toString(),
        hintText: "Priority",
        prefix: Icones(MaterialSymbols.priority_high_rounded),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r"^-?\d*"))],
        onSubmitted: (value) async => buttonController.trigger(),
      ),
      actions: [
        TextButton.icon(
          icon: const Icones(Fa6Solid.xmark),
          label: const Text("Cancel"),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).textTheme.bodySmall?.color,
          ),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        LoadingButton.filledIcon(
          controller: buttonController,
          onPressed: () async =>
              _changePriority(ref, int.parse(controller.text), changed),
          label: const Text("Change"),
          icon: const Icones(Mingcute.pencil_fill),
          style: FilledButton.styleFrom(
            foregroundColor: context.colors.onWarning,
            backgroundColor: context.colors.warning,
          ),
        ),
      ],
    );
  }
}
