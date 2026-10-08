part of "route.dart";

/// Full page row used by the expanded sidebar.
///
/// It is the interaction boundary for page selection, context actions, page
/// movement, and entry drops. It renders projected page metadata but sends all
/// edits through the authoring commands.
class _PageTile extends HookConsumerWidget {
  const _PageTile({required this.page});
  final Page page;

  skir.ResourceId get pageId => page.pageId;
  String get name => page.name;
  String get chapter => page.chapter;

  List<MenuItem> _contextMenuItems(WidgetRef ref) => [
    MenuItem(
      label: "Edit",
      icon: Icones(Mingcute.pencil_fill),
      onPressed: () => ref.inspectPage(pageId),
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
    ActionShortcut.intent(
      id: "book_sidebar_page_edit",
      label: "Edit",
      description: "Edit the page in the inspector",
      intent: PrimaryActionIntent,
      priority: 1,
      onInvoke: (_) => ref.inspectPage(pageId),
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
          Expanded(child: _PageRoleTile(pageId: pageId)),
          SizedBox(width: context.spacing.space2),
          Icon(Icons.chevron_right, size: 16, color: foregroundColor),
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return DragTarget<PageDrag>(
          onWillAcceptWithDetails: (details) => details.data.pageId != pageId,
          onAcceptWithDetails: (details) async {
            await ref.movePageChapter(
              id: details.data.pageId,
              chapter: chapter,
              expectedChapter: details.data.expectedChapter,
            );
          },
          builder: (context, pageCandidateData, rejectedData) {
            final isAccepting = pageCandidateData.isNotEmpty;
            final isRejecting = rejectedData.isNotEmpty;

            return ManagedActionSet(
              shortcuts: _shortcuts(ref),
              child: ContextMenuRegion(
                items: _contextMenuItems(ref),
                child: AnimatedSize(
                  duration: 150.ms,
                  curve: Curves.easeOutCubic,
                  child: Draggable<PageDrag>(
                    data: PageDrag(
                      pageId: pageId,
                      expectedChapter: page.authoredRecord.authoredField(
                        "chapter",
                      ),
                    ),
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
                                borderRadius: context.shapes.mediumBorderRadius,
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
                                      ? Theme.of(context).colorScheme.primary
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
  }
}

/// Compact page marker used when the sidebar is collapsed.
///
/// Selection remains read from the route provider, while page kind metadata is
/// resolved from the active realm catalog.
class _SmallPageTile extends HookConsumerWidget {
  const _SmallPageTile({required this.page});

  final Page page;

  skir.ResourceId get pageId => page.pageId;

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
        child: SizedBox.square(
          dimension: 20,
          child: ClipRect(child: _PageRoleTile(pageId: pageId)),
        ),
      ),
    );
  }
}

class _PageRoleTile extends StatelessWidget {
  const _PageRoleTile({required this.pageId});

  final skir.ResourceId pageId;

  @override
  Widget build(BuildContext context) => AuthoringSubjectRole(
    resourceId: pageId,
    role: skir.PresentationRole.pageTile,
  );
}
