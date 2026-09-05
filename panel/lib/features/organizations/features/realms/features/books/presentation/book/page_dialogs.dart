part of "route.dart";

class AddPageDialogue extends HookConsumerWidget {
  const AddPageDialogue({
    this.fixedKind,
    this.autoNavigate = true,
    this.chapter = "",
    super.key,
  });

  final String chapter;
  final PageKindRef? fixedKind;
  final bool autoNavigate;

  Future<String> _addPage(
    WidgetRef ref,
    String name,
    PageKindRef kind,
    String chapter,
    int priority,
  ) async {
    final router = ref.read(appRouterProvider);
    final bookId = ref.read(bookIdProvider);
    if (bookId == null) {
      throw Exception("Book ID not found");
    }
    final pageId = newResourceId(AuthoringResource.page);
    final result = await ref.readAuthoringSession().notifier.createPage(
      skir.Page(
        id: pageId,
        book: bookId,
        name: name,
        kind: kind.toSkir(),
        chapter: chapter,
        priority: priority,
      ),
    );
    result.requireApplied(conflictMessage: "The page already exists");

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
    final definitions = ref
        .watch(realmEditorCatalogProvider)
        .value
        ?.snapshot
        ?.pageCatalog
        .definitions
        .values
        .toList();
    final kind = useState<PageKindRef?>(fixedKind);
    final chapter = useState(this.chapter);
    final priority = useState(0);

    final pageTypeFocus = useFocusNode();
    final chapterFocus = useFocusNode();
    final priorityFocus = useFocusNode();
    useEffect(() {
      final selectedIsAvailable =
          definitions?.any((definition) => definition.kind == kind.value) ??
          false;
      if (fixedKind == null &&
          !selectedIsAvailable &&
          (definitions?.isNotEmpty ?? false)) {
        kind.value = definitions!.first.kind;
      }
      return null;
    }, [definitions]);
    if (definitions == null || definitions.isEmpty) {
      return const AlertDialog(
        title: Text("Add a new page"),
        content: Text("No page kinds are available in the active realm."),
      );
    }
    final selectedKind = kind.value;
    if (selectedKind == null) return const SizedBox.shrink();
    final selectedDefinitions = definitions.where(
      (definition) => definition.kind == selectedKind,
    );
    if (selectedDefinitions.isEmpty) {
      return const AlertDialog(
        title: Text("Add a new page"),
        content: Text("The requested page kind is unavailable."),
      );
    }
    final selectedDefinition = selectedDefinitions.single;

    return AlertDialog(
      title: Text(
        fixedKind != null
            ? "Add a new ${selectedDefinition.name} page"
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
          if (fixedKind == null) ...[
            SizedBox(height: context.spacing.space3),
            Dropdown<PageKindRef>(
              focusNode: pageTypeFocus,
              selected: selectedKind,
              onSelected: (value) {
                if (value != null) kind.value = value;
                Actions.maybeInvoke(context, NextFocusIntent());
              },
              dropdownMenuEntries: [
                for (final definition in definitions)
                  DropdownMenuEntry(
                    value: definition.kind,
                    label: definition.name,
                    leadingIcon: Icones.value(definition.icon),
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
                    selectedKind,
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
