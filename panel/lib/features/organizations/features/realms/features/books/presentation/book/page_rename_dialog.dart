part of "route.dart";

/// Renames a page through the authoring session.
///
/// The submitted name is checked against the value shown when the dialog
/// opened. A conflict remains visible to the shared dialog error handling. If
/// the renamed page is not the active route, the dialog opens the new route so
/// the selection follows the resource.
class RenamePageDialogue extends HookConsumerWidget {
  const RenamePageDialogue({
    required this.pageId,
    required this.oldName,
    super.key,
  });

  final skir.ResourceId pageId;
  final String oldName;

  Future<void> _renamePage(WidgetRef ref, String newName) async {
    final router = ref.read(appRouterProvider);
    final result = await ref.editPage(
      id: pageId,
      name: newName,
      expectedName: oldName,
    );
    result.requireApplied(
      conflictMessage: "The page name changed while editing",
    );
    if (ref.read(pageIdProvider) == pageId) return;
    unawaited(router.push(RouteRoute(pageId: pageId.id)));
  }

  /// Rejects empty names and a no op rename.
  String? _validateName(String text) {
    if (text.isEmpty) {
      return "Name cannot be empty";
    }

    if (text == oldName) {
      return "Name cannot be the same";
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = useState(oldName);
    final isNameValid = useState(false);
    final buttonController = useLoadingButtonController();

    return AlertDialog(
      title: Text("Rename ${oldName.formatted}"),
      content: ValidatedTextField<String>(
        autofocus: EditorTextFieldAutoFocus.textField,
        value: name.value,
        name: "Page Name",
        icon: Ph.book_fill,
        validator: (value) {
          final validation = _validateName(value);
          isNameValid.value = validation == null;
          return validation;
        },
        inputFormatters: [
          ...identifierInputFormats.toTextInputFormatters(),
          FilteringTextInputFormatter.singleLineFormatter,
        ],
        onChanged: (value) => name.value = value,
        onSubmitted: (_) => buttonController.trigger(),
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
          onPressed: !isNameValid.value
              ? null
              : () async {
                  final navigator = Navigator.of(context);
                  await _renamePage(ref, name.value);
                  navigator.pop(true);
                },
          label: const Text("Rename"),
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
