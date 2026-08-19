part of "route.dart";

class AddPageDialogue extends HookConsumerWidget {
  const AddPageDialogue({
    this.fixedType,
    this.autoNavigate = true,
    this.chapter = "",
    super.key,
  });

  final String chapter;
  final PageType? fixedType;
  final bool autoNavigate;

  Future<String> _addPage(
    WidgetRef ref,
    String name,
    PageType type,
    String chapter,
    int priority,
  ) async {
    final router = ref.read(appRouterProvider);
    final bookId = ref.read(bookIdProvider);
    if (bookId == null) {
      throw Exception("Book ID not found");
    }
    final pageId = await ref
        .read(booksProvider.notifier)
        .createPage(bookId, name, type.toSkir(), chapter, priority);

    if (!autoNavigate) return pageId.id;
    unawaited(router.push(RouteRoute(pageId: pageId.id)));
    return pageId.id;
  }

  /// Validates the proposed name for a page.
  /// A name is invalid if it is empty.
  String? _validateName(String text) {
    if (text.isEmpty) {
      return "Name cannot be empty";
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = useState("");
    final isNameValid = useState(false);
    final type = useState(fixedType ?? PageType.sequence);
    final chapter = useState(this.chapter);
    final priority = useState(0);

    final pageTypeFocus = useFocusNode();
    final chapterFocus = useFocusNode();
    final priorityFocus = useFocusNode();

    return AlertDialog(
      title: Text(
        fixedType != null
            ? "Add a new ${fixedType!.displayName} page"
            : "Add a new page",
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ValidatedTextField<String>(
            autofocus: EditorTextFieldAutoFocus.textField,
            keepErrorVisibleWhenUnfocused: true,
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
            onSubmitted: (_) => Actions.maybeInvoke(context, NextFocusIntent()),
          ),
          if (fixedType == null) ...[
            SizedBox(height: context.spacing.space3),
            Dropdown<PageType>(
              focusNode: pageTypeFocus,
              selected: type.value,
              onSelected: (value) {
                if (value != null) type.value = value;
                Actions.maybeInvoke(context, NextFocusIntent());
              },
              dropdownMenuEntries: [
                for (final type in PageType.values)
                  DropdownMenuEntry(
                    value: type,
                    label: type.displayName.formatted,
                    leadingIcon: Icones(type.icon),
                  ),
              ],
            ),
          ],
          SizedBox(height: context.spacing.space3),
          ExpansionTile(
            title: const Text("Advanced"),
            shape: const RoundedRectangleBorder(),
            children: [
              SizedBox(height: context.spacing.space3),
              EditorTextField(
                focusNode: chapterFocus,
                text: chapter.value,
                hintText: "Chapter Name",
                prefix: Icones(Ph.book_bookmark_fill),
                inputFormatters: [
                  TextInputFormatter.withFunction(
                    (oldValue, newValue) => newValue.copyWith(
                      text: newValue.text
                          .toLowerCase()
                          .replaceAll(" ", ".")
                          .replaceAll("_", ".")
                          .replaceAll("-", "."),
                    ),
                  ),
                  FilteringTextInputFormatter.singleLineFormatter,
                  FilteringTextInputFormatter.allow(RegExp("[a-z0-9.]")),
                ],
                onChanged: (value) => chapter.value = value,
                onSubmitted: (value) =>
                    Actions.maybeInvoke(context, NextFocusIntent()),
              ),
              SizedBox(height: context.spacing.space3),
              EditorTextField(
                focusNode: priorityFocus,
                text: priority.value.toString(),
                hintText: "Priority",
                prefix: Icones(MaterialSymbols.priority_high_rounded),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r"^-?\d*")),
                ],
                onChanged: (value) => priority.value = int.parse(value),
                onSubmitted: (value) =>
                    Actions.maybeInvoke(context, NextFocusIntent()),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton.icon(
          icon: const Icones(Fa6Solid.xmark),
          label: const Text("Cancel"),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).textTheme.bodySmall?.color,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        LoadingButton.filledIcon(
          onPressed: !isNameValid.value
              ? null
              : () async {
                  final navigator = Navigator.of(context);
                  final pageId = await _addPage(
                    ref,
                    name.value,
                    type.value,
                    chapter.value,
                    priority.value,
                  );
                  navigator.pop(pageId);
                },
          label: const Text("Add"),
          icon: const Icones(Fa6Solid.plus),
        ),
      ],
    );
  }
}

class RenamePageDialogue extends HookConsumerWidget {
  const RenamePageDialogue({
    required this.pageId,
    required this.oldName,
    super.key,
  });

  final skir.RecordId pageId;
  final String oldName;

  Future<void> _renamePage(WidgetRef ref, String newName) async {
    final router = ref.read(appRouterProvider);
    await ref.read(pagesProvider(pageId).notifier).updatePage(name: newName);
    if (ref.read(pageIdProvider) == pageId) return;
    unawaited(router.push(RouteRoute(pageId: pageId.id)));
  }

  /// Validates the proposed name for a page.
  /// A name is invalid if it is empty or if it already exists.
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
