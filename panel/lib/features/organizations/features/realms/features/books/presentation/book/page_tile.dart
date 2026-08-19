part of "route.dart";

class _PageTile extends HookConsumerWidget {
  const _PageTile({required this.page});
  final Page page;

  skir.RecordId get pageId => page.pageId;
  String get name => page.name;
  String get chapter => page.chapter;

  List<MenuItem> _contextMenuItems(WidgetRef ref) => [
    MenuItem(
      label: "Rename",
      icon: Icones(Mingcute.pencil_fill),
      onPressed: () => showAdvancedDialog(
        context: ref.context,
        builder: (_) => RenamePageDialogue(pageId: pageId, oldName: name),
      ),
    ),
    MenuItem(
      label: "Change Chapter",
      icon: Icones(Ph.book_bookmark_fill),
      onPressed: () => showAdvancedDialog(
        context: ref.context,
        builder: (_) => ChangeChapterDialogue(
          title: "Change chapter of $name",
          chapter: chapter,
          onChapterChanged: (newChapter) async {
            await ref
                .read(pagesProvider(pageId).notifier)
                .updatePage(chapter: newChapter);
          },
        ),
      ),
    ),
    MenuItem(
      label: "Change Priority",
      icon: Icones(MaterialSymbols.priority_high_rounded),
      onPressed: () => showAdvancedDialog(
        context: ref.context,
        builder: (_) => ChangePagePriorityDialogue(
          pageId: pageId,
          pageName: name,
          priority: page.priority,
        ),
      ),
    ),
    MenuItem.divider(),
    MenuItem(
      label: "Delete",
      icon: Icones(MaterialSymbols.delete_forever_rounded),
      color: ref.context.colors.danger,
      onPressed: () => showPageDeletionDialogue(ref, pageId, name),
    ),
  ];

  List<ActionShortcut> _shortcuts(WidgetRef ref) => [
    ActionShortcut(
      id: "book_sidebar_page_rename",
      label: "Rename",
      description: "Rename the page",
      activators: [SingleActivator(LogicalKeyboardKey.keyR)],
      priority: 1,
      onInvoke: (_) => showAdvancedDialog(
        context: ref.context,
        builder: (_) => RenamePageDialogue(pageId: pageId, oldName: name),
      ),
    ),
    ActionShortcut(
      id: "book_sidebar_page_change_chapter",
      label: "Change Chapter",
      description: "Change the chapter of the page",
      activators: [SingleActivator(LogicalKeyboardKey.keyC)],
      priority: 1,
      onInvoke: (_) => showAdvancedDialog(
        context: ref.context,
        builder: (_) => ChangeChapterDialogue(
          title: "Change chapter of $name",
          chapter: chapter,
          onChapterChanged: (newChapter) async {
            await ref
                .read(pagesProvider(pageId).notifier)
                .updatePage(chapter: newChapter);
          },
        ),
      ),
    ),
    ActionShortcut(
      id: "book_sidebar_page_change_priority",
      label: "Change Priority",
      description: "Change the priority of the page",
      activators: [SingleActivator(LogicalKeyboardKey.keyP)],
      priority: 1,
      onInvoke: (_) => showAdvancedDialog(
        context: ref.context,
        builder: (_) => ChangePagePriorityDialogue(
          pageId: pageId,
          pageName: name,
          priority: page.priority,
        ),
      ),
    ),
    ActionShortcut(
      id: "book_sidebar_page_delete",
      label: "Delete",
      description: "Delete the page",
      activators: shortcutsFor(DeleteIntent),
      priority: 1,
      onInvoke: (_) => showPageDeletionDialogue(ref, pageId, name),
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = ref.watch(pageIdProvider.select((e) => e == pageId));
    final elementTypes = ref.watch(pageElementTypesProvider(page.type)).value;

    final color = Theme.of(context).colorScheme.onSurface;

    final child = Padding(
      padding: EdgeInsets.all(context.spacing.space2),
      child: Row(
        children: [
          SizedBox(width: context.spacing.space1),
          Icones(page.type.icon, size: 11, color: color),
          SizedBox(width: context.spacing.space2),
          Expanded(
            child: Text(
              page.name.formatted,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: color),
            ),
          ),
          SizedBox(width: context.spacing.space2),
          Icon(Icons.chevron_right, size: 16, color: color),
        ],
      ),
    );

    return DragTarget<EntryIdentifier>(
      onWillAcceptWithDetails: (details) {
        final entryId = details.data.id;
        final definition = ref.read(entryProvider(entryId)).value;
        if (definition == null) return false;

        return switch (elementTypes) {
          PageElementTypesReady(:final types) => types.contains(
            definition.elementDefinition.rootType,
          ),
          _ => false,
        };
      },
      onAcceptWithDetails: (details) {
        final entryId = details.data.id;
        ref.read(entryProvider(entryId).notifier).moveToPage(pageId.id);
      },
      builder: (context, entryCandidateData, entryRejectedData) {
        return DragTarget<PageDrag>(
          onWillAcceptWithDetails: (details) => true,
          onAcceptWithDetails: (details) {
            final pageId = details.data.pageId;
            ref
                .read(pagesProvider(pageId).notifier)
                .updatePage(chapter: chapter);
          },
          builder: (context, pageCandidateData, rejectedData) {
            final isAccepting =
                entryCandidateData.isNotEmpty || pageCandidateData.isNotEmpty;
            final isRejecting =
                entryRejectedData.isNotEmpty || rejectedData.isNotEmpty;
            return Surface(
              color: isSelected ? Surface.colorOf(context) : Colors.transparent,
              child: Material(
                color: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: context.shapes.mediumBorderRadius,
                  side: isAccepting || isRejecting
                      ? BorderSide(
                          color: isAccepting
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.error,
                          width: 2,
                        )
                      : BorderSide.none,
                ),
                child: ManagedActionSet(
                  shortcuts: _shortcuts(ref),
                  child: ContextMenuRegion(
                    items: _contextMenuItems(ref),
                    child: Draggable<PageDrag>(
                      data: PageDrag(pageId: pageId),
                      feedback: Surface(
                        color: Surface.colorOf(context),
                        child: Material(
                          color: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: context.shapes.mediumBorderRadius,
                          ),
                          child: child,
                        ),
                      ),
                      child: InkWell(
                        onTap: () {
                          if (isSelected) return;
                          ref
                              .read(appRouterProvider)
                              .push(RouteRoute(pageId: pageId.id));
                        },
                        borderRadius: context.shapes.mediumBorderRadius,
                        child: child,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _SmallPageTile extends HookConsumerWidget {
  const _SmallPageTile({required this.page});

  final Page page;

  skir.RecordId get pageId => page.pageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = ref.watch(pageIdProvider.select((e) => e == pageId));

    return Material(
      color: isSelected
          ? context.colors.selectionContainer
          : Colors.transparent,
      borderRadius: context.shapes.mediumBorderRadius,
      child: Padding(
        padding: EdgeInsets.all(context.spacing.space2),
        child: Icones(
          page.type.icon,
          size: 11,
          color: isSelected
              ? context.colors.onSelectionContainer
              : context.colors.contentSecondary,
        ),
      ),
    );
  }
}

// A button for adding a new page.
// Button has a outline.
