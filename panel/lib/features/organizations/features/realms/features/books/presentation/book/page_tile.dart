part of "route.dart";

/// Full page row used by the expanded sidebar.
///
/// It is the interaction boundary for page selection, context actions, page
/// movement, and entry drops. It renders working page metadata and stages edits
/// through the shared workspace.
class _PageTile extends HookConsumerWidget {
  const _PageTile({required this.page, this.expanded = true});
  final bool expanded;
  final Page page;

  skir.ResourceId get pageId => page.pageId;
  String get name => page.name;
  String get chapter => page.chapter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = ref.watch(pageIdProvider.select((e) => e == pageId));
    final authoringScope = ref.watch(selectedAuthoringScopeProvider);
    final operations = authoringScope == null
        ? <SelectionOperation>[]
        : resourceSelectionOperationsFor(ref, authoringScope, [pageId]);
    final scope = ref.watch(selectedAuthoringScopeProvider);
    final issueState = scope == null
        ? null
        : ref.watch(resourceIssuesProvider(scope));
    final issues =
        issueState?.value?.currentFor(pageId) ?? const <ResourceIssue>[];
    final backgroundColor = isSelected
        ? context.theme.colorScheme.primaryContainer
        : Surface.colorOf(context);

    final foregroundColor = isSelected
        ? context.theme.colorScheme.onPrimaryContainer
        : context.theme.colorScheme.onSurface;

    final catalog = ref
        .watch(selectedWorkingAuthoringDocumentProvider)
        .value
        ?.catalog;
    final child = PageNavigationLabel(
      name: name,
      icon: catalog?.selectionDisplay(page.configuration)?.icon,
      expanded: expanded,
      issues: issues,
      checking:
          issueState?.isLoading == true || issueState?.value?.checking == true,
      unavailable:
          issueState?.hasError == true ||
          issueState?.value?.unavailable == true,
    );

    final tile = LayoutBuilder(
      builder: (context, constraints) {
        return DragTarget<PageDrag>(
          onWillAcceptWithDetails: (details) => details.data.pageId != pageId,
          onAcceptWithDetails: (details) async {
            ref
                .readRealmEditing()
                .edit(
                  label: "Move page to chapter",
                  apply: (edit) {
                    final at = authoredFieldLocation(details.data.pageId, [
                      "chapter",
                    ]);
                    final current = edit.expect(at);
                    if (current is! PortablePathValue<skir.DataValue> ||
                        current.value != details.data.expectedChapter) {
                      throw StateError(
                        "The page chapter changed during the drag",
                      );
                    }
                    edit.setPayload(
                      at,
                      skir.DataValue.wrapStringValue(chapter),
                    );
                  },
                )
                .report(context);
          },
          builder: (context, pageCandidateData, rejectedData) {
            final isAccepting = pageCandidateData.isNotEmpty;
            final isRejecting = rejectedData.isNotEmpty;

            return ManagedActionSet(
              shortcuts: [
                for (final operation
                    in operations.whereType<ShortcutableOperation>())
                  operation.shortcut,
              ],
              child: ContextMenuRegion(
                items: [
                  for (final operation in operations) operation.menuItem(ref),
                ],
                child: AnimatedSize(
                  duration: 150.ms,
                  curve: Curves.easeOutCubic,
                  child: Draggable<PageDrag>(
                    data: PageDrag(
                      pageId: pageId,
                      expectedChapter: ref
                          .watch(selectedWorkingAuthoringDocumentProvider)
                          .value
                          ?.resource(pageId)
                          ?.authoredField("chapter"),
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
                      foreground: foregroundColor,
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
    return ResourcePageDropTarget(page: pageId, child: tile);
  }
}
