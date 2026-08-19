part of "route.dart";

class _PagesTree extends HookConsumerWidget {
  const _PagesTree({required this.expanded, required this.pages});

  final bool expanded;
  final List<Page> pages;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tree = useMemoized(() => createTreeNode(pages, (p) => p.chapter), [
      pages,
    ]);
    return _TreeChildren(children: tree.children, expanded: expanded);
  }
}

class _TreeChildren extends HookWidget {
  const _TreeChildren({required this.children, required this.expanded});

  final List<TreeNode<Page>> children;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final sorted = useMemoized(
      () => children.sorted((a, b) {
        if (a is LeafTreeNode<Page> && b is LeafTreeNode<Page>) {
          return a.value.name.compareTo(b.value.name);
        } else if (a is InnerTreeNode<Page> && b is InnerTreeNode<Page>) {
          return a.name.compareTo(b.name);
        } else if (a is LeafTreeNode<Page>) {
          return 1;
        } else if (b is LeafTreeNode<Page>) {
          return -1;
        } else {
          return 0;
        }
      }),
      children,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final child in sorted) _TreeItem(node: child, expanded: expanded),
      ],
    );
  }
}

class _TreeItem extends HookWidget {
  const _TreeItem({required this.node, required this.expanded});

  final TreeNode<Page> node;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return switch (node) {
      LeafTreeNode<Page>(:final value) when expanded => _PageTile(page: value),
      LeafTreeNode<Page>(:final value) => _SmallPageTile(page: value),
      InnerTreeNode<Page>() => _TreeCategory(
        node: node as InnerTreeNode<Page>,
        expanded: expanded,
      ),
      _ => throw UnimplementedError(),
    };
  }
}

class _TreeCategory extends HookConsumerWidget {
  const _TreeCategory({required this.node, required this.expanded});

  final InnerTreeNode<Page> node;
  final bool expanded;

  String get chapter => node.path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpanded = useState(false);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ManagedActionSet(
          shortcuts: [
            ActionShortcut(
              id: "book_sidebar_chapter_toggle",
              label: isExpanded.value ? "Collapse" : "Expand",
              description: isExpanded.value
                  ? "Collapse chapter"
                  : "Expand chapter",
              activators: shortcutsFor(ActivateIntent),
              priority: 1,
              onInvoke: (_) {
                isExpanded.value = !isExpanded.value;
              },
            ),
            ActionShortcut(
              id: "book_sidebar_chapter_new_page",
              label: "New Page",
              description: "Create a new page",
              activators: [SingleActivator(LogicalKeyboardKey.keyN)],
              priority: 2,
              onInvoke: (_) {
                showAdvancedDialog(
                  context: context,
                  builder: (_) => AddPageDialogue(chapter: chapter),
                );
              },
            ),
            ActionShortcut(
              id: "book_sidebar_chapter_rename",
              label: "Rename",
              description: "Rename the chapter",
              activators: [SingleActivator(LogicalKeyboardKey.keyR)],
              priority: 3,
              onInvoke: (_) {
                showAdvancedDialog(
                  context: context,
                  builder: (_) => ChangeChapterDialogue(
                    title: "Rename chapter",
                    chapter: chapter,
                    onChapterChanged: (newChapter) =>
                        _changePagesChapter(ref, chapter, newChapter),
                  ),
                );
              },
            ),
          ],
          child: ContextMenuRegion(
            items: [
              MenuItem(
                label: "New Page",
                icon: Icones(Fa6Solid.plus),
                onPressed: () => showAdvancedDialog(
                  context: context,
                  builder: (_) => AddPageDialogue(chapter: chapter),
                ),
              ),
              MenuItem(
                label: "Rename Chapter",
                icon: Icones(Fa6Solid.pencil),
                onPressed: () => showAdvancedDialog(
                  context: context,
                  builder: (_) => ChangeChapterDialogue(
                    title: "Rename chapter",
                    chapter: chapter,
                    onChapterChanged: (newChapter) =>
                        _changePagesChapter(ref, chapter, newChapter),
                  ),
                ),
              ),
            ],
            child: DragTarget<ChapterDrag>(
              onWillAcceptWithDetails: (details) {
                return !chapter.startsWith(details.data.chapter);
              },
              onAcceptWithDetails: (details) =>
                  _changePagesChapter(ref, chapter, details.data.chapter),
              builder: (context, chapterCandidates, chapterRejected) {
                return DragTarget<PageDrag>(
                  onWillAcceptWithDetails: (details) => true,
                  onAcceptWithDetails: (details) {
                    final pageId = details.data.pageId;
                    ref
                        .read(pagesProvider(pageId).notifier)
                        .updatePage(chapter: node.path);
                  },
                  builder: (context, pageCandidates, pageRejected) {
                    final isAccepting =
                        chapterCandidates.isNotEmpty ||
                        pageCandidates.isNotEmpty;
                    final isRejecting =
                        chapterRejected.isNotEmpty || pageRejected.isNotEmpty;
                    return Material(
                      color: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        side: isAccepting || isRejecting
                            ? BorderSide(
                                color: isAccepting
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.error,
                                width: 2,
                              )
                            : BorderSide.none,
                        borderRadius: context.shapes.mediumBorderRadius,
                      ),
                      child: Draggable<ChapterDrag>(
                        data: ChapterDrag(chapter: chapter),
                        feedback: Surface(
                          color: Surface.colorOf(context),
                          child: Material(
                            color: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: context.shapes.mediumBorderRadius,
                            ),
                            child: _buildHeader(
                              context,
                              expand: false,
                              isExpanded: isExpanded.value,
                            ),
                          ),
                        ),
                        child: InkWell(
                          onTap: () => isExpanded.value = !isExpanded.value,
                          borderRadius: context.shapes.mediumBorderRadius,
                          child: _buildHeader(
                            context,
                            expand: true,
                            isExpanded: isExpanded.value,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
        AnimatedSize(
          duration: 200.ms,
          curve: Curves.easeInOut,
          alignment: Alignment.topLeft,
          child: isExpanded.value
              ? _TreeBarLayout(
                  barWidth: 3,
                  barMargin: EdgeInsets.only(left: expanded ? 14 : 10),
                  barColor: Surface.colorOf(context).withValues(alpha: 0.2),
                  borderRadius: Radius.circular(2),
                  child: _TreeChildren(
                    children: node.children,
                    expanded: expanded,
                  ),
                )
              : const SizedBox(height: 0),
        ),
      ],
    );
  }

  Widget _buildHeader(
    BuildContext context, {
    required bool expand,
    required bool isExpanded,
  }) {
    final color = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: EdgeInsets.all(context.spacing.space2),
      child: Row(
        children: [
          if (expanded) SizedBox(width: context.spacing.space1),
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: expanded ? context.spacing.space1 : 0,
            ),
            child: Icones(
              isExpanded ? Fa6Solid.chevron_down : Fa6Solid.chevron_right,
              size: 11,
              color: color,
            ),
          ),
          if (expanded) ...[
            SizedBox(width: context.spacing.space2),
            if (expand)
              Expanded(
                child: Text(
                  node.name.formatted,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: color),
                ),
              )
            else
              Text(
                node.name.formatted,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: color),
              ),
          ],
        ],
      ),
    );
  }
}
