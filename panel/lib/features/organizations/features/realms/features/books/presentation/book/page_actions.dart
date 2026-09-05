part of "route.dart";

Future<void> _changePagesChapter(
  WidgetRef ref,
  String chapter,
  String newChapter,
) async {
  final bookId = ref.read(bookIdProvider);
  if (bookId == null) {
    throw Exception("Book ID is null");
  }
  final pages = await ref.read(bookPagesProvider(bookId, "").future);
  final changed = pages
      .where(
        (page) =>
            page.chapter == chapter || page.chapter.startsWith("$chapter."),
      )
      .toList();
  if (changed.isEmpty || !ref.context.mounted) return;
  final result = await ref.readAuthoringSession().notifier.changePagesChapters(
    changed,
    chapter,
    newChapter,
  );
  result.requireApplied(
    conflictMessage: "A page changed while chapters were moving",
  );
}

class _AddPageButton extends HookConsumerWidget {
  const _AddPageButton();

  Future<String?> _showAddPageDialog(BuildContext context) async =>
      showAdvancedDialog(
        context: context,
        builder: (context) => const AddPageDialogue(),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFocused = useState(false);
    final isHovered = useState(false);

    final color = Theme.of(context).colorScheme.onSurface.withValues(
      alpha: isFocused.value || isHovered.value ? 1 : 0.6,
    );

    final animation = useAnimationController(duration: 200.ms);
    useListenable(animation);

    useEffect(() {
      if (isFocused.value || isHovered.value) {
        animation.forward();
      } else {
        animation.reverse();
      }
      return null;
    }, [isFocused.value, isHovered.value]);

    return DottedBorder(
      animation: animation,
      options: CustomPathDottedBorderOptions(
        customPath: (size) {
          return StadiumBorder().getInnerPath(
            Offset(.5, .5) & Size(size.width - 1, size.height - 1),
          );
        },
        color: color,
        strokeWidth: 1,
        dashPattern: [8, 6],
        padding: EdgeInsets.zero,
      ),
      child: TextButton(
        onPressed: () => _showAddPageDialog(context),
        onFocusChange: (focus) => isFocused.value = focus,
        onHover: (hover) => isHovered.value = hover,
        style: TextButton.styleFrom(
          foregroundColor: color,
          animationDuration: 200.ms,
          shape: StadiumBorder(
            side: BorderSide(
              color: isFocused.value || isHovered.value
                  ? color
                  : Colors.transparent,
              width: 1,
            ),
          ),
          textStyle: Theme.of(context).textTheme.bodySmall,
        ),
        child: Row(
          children: [
            SizedBox(width: context.spacing.space2),
            Expanded(child: Text("Add page")),
            SizedBox(width: context.spacing.space2),
            Icon(Icons.add, size: 16),
          ],
        ),
      ),
    );
  }
}

class ChangeChapterDialogue extends HookConsumerWidget {
  const ChangeChapterDialogue({
    required this.title,
    required this.chapter,
    required this.onChapterChanged,
    super.key,
  });

  final String title;
  final String chapter;

  final FutureOr<void> Function(String) onChapterChanged;

  Future<void> _changeChapter(
    WidgetRef ref,
    String newName,
    ValueNotifier<bool> changed,
  ) async {
    if (changed.value) return;
    changed.value = true;

    final navigator = Navigator.of(ref.context);
    await onChapterChanged(newName);
    navigator.pop(true);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chapter = useState(this.chapter);
    final focusNode = useFocusNode();
    final changed = useState(false);
    final controller = useLoadingButtonController();

    return AlertDialog(
      title: Text(title),
      content: EditorTextField(
        focusNode: focusNode,
        autofocus: EditorTextFieldAutoFocus.textField,
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
        onSubmitted: (value) async => controller.trigger(),
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
          controller: controller,
          onPressed: () async => _changeChapter(ref, chapter.value, changed),
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

Future<bool> showPageDeletionDialogue(
  WidgetRef ref,
  skir.RecordId pageId,
  String pageName,
) {
  return showConfirmationDialogue(
    context: ref.context,
    title: "Delete ${pageName.formatted}?",
    content:
        "This will delete the page and all its content.\nTHIS CANNOT BE UNDONE.",
    delayConfirm: 3.seconds,
    confirmText: "Delete",
    confirmIcon: MaterialSymbols.delete_forever,
    onConfirm: () async {
      final router = ref.read(appRouterProvider);
      final result = await ref.readAuthoringSession().notifier.deletePage(
        pageId,
      );
      result.requireApplied(conflictMessage: "The page no longer exists");
      final context = ref.context;
      if (!context.mounted) return;
      final bookId = ref.read(bookIdProvider);
      final realmId = ref.read(realmIdProvider);
      if (bookId != null && realmId != null) {
        unawaited(
          router.push(BookRoute(realmId: realmId.id, bookId: bookId.id)),
        );
      }

      final organizationId = ref.read(organizationIdProvider);
      if (organizationId != null) {
        unawaited(
          router.push(OrganizationRoute(organizationId: organizationId.id)),
        );
      }

      unawaited(router.push(IndexRoute()));
    },
  );
}
