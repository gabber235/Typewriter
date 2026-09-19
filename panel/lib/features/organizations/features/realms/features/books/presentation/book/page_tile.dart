part of "route.dart";

/// Full page row used by the expanded sidebar.
///
/// It is the interaction boundary for page selection, context actions, page
/// movement, and entry drops. It renders projected page metadata but sends all
/// edits through the authoring commands.
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
            final result = await ref.editPage(
              id: pageId,
              chapter: skir.StringChange(expected: chapter, value: newChapter),
            );
            result.requireApplied(conflictMessage: "The page chapter changed");
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
            final result = await ref.editPage(
              id: pageId,
              chapter: skir.StringChange(expected: chapter, value: newChapter),
            );
            result.requireApplied(conflictMessage: "The page chapter changed");
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

    final definition = ref
        .watch(realmEditorCatalogProvider)
        .value
        ?.snapshot
        ?.pageCatalog
        .definitions[page.kind];
    final elementTypes = ref.watch(pageElementTypesProvider(page.kind)).value;

    final backgroundColor = isSelected
        ? context.theme.colorScheme.primaryContainer
        : Surface.colorOf(context);

    final foregroundColor = isSelected
        ? context.theme.colorScheme.onPrimaryContainer
        : context.theme.colorScheme.onSurface;

    final child = Padding(
      padding: EdgeInsets.all(context.spacing.space2),
      child: Row(
        children: [
          SizedBox(width: context.spacing.space1),
          if (definition == null)
            Icon(Icons.warning_rounded, size: 11, color: foregroundColor)
          else
            Icones.value(definition.icon, size: 11, color: foregroundColor),
          SizedBox(width: context.spacing.space2),
          Expanded(
            child: Text(
              page.name.formatted,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: foregroundColor),
            ),
          ),
          SizedBox(width: context.spacing.space2),
          Icon(Icons.chevron_right, size: 16, color: foregroundColor),
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return DragTarget<EntryDragPayload>(
          onWillAcceptWithDetails: (details) {
            return switch (elementTypes) {
              PageElementTypesReady(:final types) => details.data.entries.every(
                (entry) {
                  final elementType = entry.elementType;
                  return elementType != null && types.contains(elementType);
                },
              ),
              _ => false,
            };
          },
          onAcceptWithDetails: (details) async {
            final payload = details.data;
            final sourcePageId = payload.primary.pageId;
            if (sourcePageId == null || sourcePageId == pageId.id) return;
            await ref.withReadyPageElements(sourcePageId, (elements) {
              return elements.moveEntriesToPage(
                payload.entries
                    .map((entry) => entry.id)
                    .toList(growable: false),
                pageId.id,
              );
            });
          },
          builder: (context, entryCandidateData, entryRejectedData) {
            return DragTarget<PageDrag>(
              onWillAcceptWithDetails: (details) =>
                  details.data.pageId != pageId,
              onAcceptWithDetails: (details) async {
                final result = await ref.editPage(
                  id: details.data.pageId,
                  chapter: skir.StringChange(
                    expected: details.data.chapter,
                    value: chapter,
                  ),
                );
                result.requireApplied(
                  conflictMessage: "The page chapter changed",
                );
              },
              builder: (context, pageCandidateData, rejectedData) {
                final isAccepting =
                    entryCandidateData.isNotEmpty ||
                    pageCandidateData.isNotEmpty;
                final isRejecting =
                    entryRejectedData.isNotEmpty || rejectedData.isNotEmpty;

                return ManagedActionSet(
                  shortcuts: _shortcuts(ref),
                  child: ContextMenuRegion(
                    items: _contextMenuItems(ref),
                    child: AnimatedSize(
                      duration: 150.ms,
                      curve: Curves.easeOutCubic,
                      child: Draggable<PageDrag>(
                        data: PageDrag(pageId: pageId, chapter: chapter),
                        feedback: Surface(
                          color: backgroundColor,
                          child: Material(
                            color: backgroundColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: context.shapes.mediumBorderRadius,
                            ),
                            child: ConstrainedBox(
                              constraints: constraints,
                              child: child,
                            ),
                          ),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.5,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: context.spacing.space1,
                            ),
                            child: DottedBorder(
                              options: RoundedRectDottedBorderOptions(
                                radius: context.shapes.mediumRadius,
                                color: isRejecting
                                    ? context.theme.colorScheme.error
                                    : foregroundColor,
                                strokeWidth: 2,
                                dashPattern: [8, 6],
                                padding: EdgeInsets.zero,
                              ),
                              childOnTop: false,
                              child: Surface(
                                color: backgroundColor,
                                child: Material(
                                  color: backgroundColor.withValues(alpha: 0.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        context.shapes.mediumBorderRadius,
                                  ),
                                  child: child,
                                ),
                              ),
                            ),
                          ),
                        ),
                        child: Surface(
                          color: backgroundColor,
                          child: Material(
                            color: backgroundColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: context.shapes.mediumBorderRadius,
                              side: isAccepting || isRejecting
                                  ? BorderSide(
                                      color: isAccepting
                                          ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                          : Theme.of(context).colorScheme.error,
                                      width: 2,
                                    )
                                  : BorderSide.none,
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
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

/// Compact page marker used when the sidebar is collapsed.
///
/// Selection remains read from the route provider, while page kind metadata is
/// resolved from the active realm catalog.
class _SmallPageTile extends HookConsumerWidget {
  const _SmallPageTile({required this.page});

  final Page page;

  skir.RecordId get pageId => page.pageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = ref.watch(pageIdProvider.select((e) => e == pageId));
    final definition = ref
        .watch(realmEditorCatalogProvider)
        .value
        ?.snapshot
        ?.pageCatalog
        .definitions[page.kind];

    return Material(
      color: isSelected
          ? context.colors.selectionContainer
          : Colors.transparent,
      borderRadius: context.shapes.mediumBorderRadius,
      child: Padding(
        padding: EdgeInsets.all(context.spacing.space2),
        child: definition == null
            ? Icon(
                Icons.warning_rounded,
                size: 11,
                color: isSelected
                    ? context.colors.onSelectionContainer
                    : context.colors.contentSecondary,
              )
            : Icones.value(
                definition.icon,
                size: 11,
                color: isSelected
                    ? context.colors.onSelectionContainer
                    : context.colors.contentSecondary,
              ),
      ),
    );
  }
}
