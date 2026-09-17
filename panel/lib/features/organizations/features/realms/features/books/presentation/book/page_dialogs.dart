part of "route.dart";

/// Collects the metadata required to create a page.
///
/// Page kinds come from the active realm catalog. Submission returns a
/// [PageCreationInput] to the caller without mutating authoring state. A missing
/// catalog is presented as an unavailable capability rather than retried.
class AddPageDialogue extends HookConsumerWidget {
  const AddPageDialogue({this.fixedKind, this.chapter = "", super.key});

  final String chapter;
  final PageKindRef? fixedKind;

  /// Rejects an empty page name before authoring is attempted.
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

    final pageKindFocus = useFocusNode();
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
              focusNode: pageKindFocus,
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
              : () => Navigator.of(context).pop(
                  PageCreationInput(
                    name: name.value,
                    kind: selectedKind,
                    chapter: chapter.value,
                    priority: priority.value,
                  ),
                ),
          label: const Text("Add"),
          icon: const Icones(Fa6Solid.plus),
        ),
      ],
    );
  }
}

/// Prompts for page metadata using the panel dialog integration.
Future<PageCreationInput?> promptPageCreation({
  required BuildContext context,
  PageKindRef? fixedKind,
  String chapter = "",
}) => showAdvancedDialog<PageCreationInput>(
  context: context,
  builder: (_) => AddPageDialogue(fixedKind: fixedKind, chapter: chapter),
);

/// Prompts, creates, and optionally opens a page for ordinary book controls.
Future<Page?> promptAndCreatePage({
  required BuildContext context,
  required WidgetRef ref,
  PageKindRef? fixedKind,
  String chapter = "",
  bool navigate = true,
}) async {
  final input = await promptPageCreation(
    context: context,
    fixedKind: fixedKind,
    chapter: chapter,
  );
  if (input == null || !context.mounted) return null;

  final bookId = ref.read(bookIdProvider);
  if (bookId == null) throw ApiException.badRequest("No book selected");
  final page = await ref.readAuthoringSession().notifier.createPageFromInput(
    bookId,
    input,
  );
  if (navigate && context.mounted) {
    unawaited(
      ref.read(appRouterProvider).push(RouteRoute(pageId: page.pageId.id)),
    );
  }
  return page;
}
