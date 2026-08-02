import "dart:async";

import "package:auto_route/auto_route.dart";
import "package:collection/collection.dart";
import "package:dotted_border/dotted_border.dart";
import "package:flutter/material.dart" hide Page;
import "package:flutter/rendering.dart";
import "package:flutter/services.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/iconify_flutter_plus.dart";
import "package:iconify_flutter_plus/icons/fa6_solid.dart";
import "package:iconify_flutter_plus/icons/material_symbols.dart";
import "package:iconify_flutter_plus/icons/mingcute.dart";
import "package:iconify_flutter_plus/icons/ph.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "route.g.dart";

@RoutePage()
class BookPage extends HookConsumerWidget {
  const BookPage({
    @PathParam("realmId") required this.realmId,
    @PathParam("bookId") required this.bookId,
    super.key,
  });

  final String realmId;
  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BookScaffold(
      child: AutoRouter(placeholder: (context) => EmptyBookPage()),
    );
  }
}

class EmptyBookPage extends StatelessWidget {
  const EmptyBookPage({super.key});

  Future<String?> _showAddPageDialog(BuildContext context) async =>
      showAdvancedDialog(
        context: context,
        builder: (context) => const AddPageDialogue(),
      );

  @override
  Widget build(BuildContext context) {
    return Pane(
      id: "empty_book_page",
      primary: true,
      borderRadius: context.shapes.largeBorderRadius,
      margin: EdgeInsets.only(
        top: context.spacing.space2,
        left: context.spacing.space2,
        right: context.isMobile ? context.spacing.space2 : 0,
      ),
      child: Section(
        margin: EdgeInsets.zero,
        child: EmptyScreen(
          title: "Select a page to edit or",
          buttonText: "Add Page",
          onPressed: () => _showAddPageDialog(context),
        ),
      ),
    );
  }
}

class BookScaffold extends HookConsumerWidget {
  const BookScaffold({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final organizationId = ref.watch(organizationIdProvider);
    final realmId = ref.watch(realmIdProvider);
    return SimpleScaffold(
      appBar: CustomAppBar(
        row: [
          if (organizationId != null) ...[
            const OrganizationSelector(),
            if (realmId != null) ...[
              Iconify(
                MaterialSymbols.chevron_right,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const RealmSelector(),
            ],
          ],
          const Spacer(),
          if (!context.isMobile) const ModeDisplayWidget(),
        ],
        sidebar: const BookSidebarContent(),
      ),
      child: Row(
        children: [
          if (!context.isMobile) const Sidebar(child: BookSidebarContent()),
          Expanded(
            child: Column(
              children: [
                Expanded(child: child),
                ActionRow(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

@riverpod
class _PageSearch extends _$PageSearch {
  @override
  String build() => "";

  // ignore: use_setters_to_change_properties
  void search(String value) {
    state = value;
  }
}

@riverpod
Future<List<Page>> _viewingPages(Ref ref) async {
  final bookId = ref.watch(bookIdProvider);
  if (bookId == null) throw Exception("Not visiting a book (sub)route");

  final search = ref.watch(_pageSearchProvider);

  await ref.debounce(300.ms);

  return await ref.watch(bookPagesProvider(bookId, search).future);
}

class BookSidebarContent extends HookConsumerWidget {
  const BookSidebarContent({this.expanded = true, super.key});

  final bool expanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchController = useTextEditingController();
    final focusNode = useFocusNode();

    final bookId = ref.watch(bookIdProvider);
    if (bookId == null) return const SizedBox.shrink();

    final pages = ref.watch(_viewingPagesProvider);

    return AnimatedSize(
      duration: expanded ? 750.ms : 200.ms,
      curve: expanded ? ElasticOutCurve(0.9) : Curves.easeInOut,
      alignment: Alignment.centerLeft,
      child: ManagedActionSet(
        shortcuts: [
          ActionShortcut(
            id: "book_sidebar_search",
            label: "Search",
            description: "Search pages",
            activators: [
              SingleActivator(LogicalKeyboardKey.keyS),
              SingleActivator(LogicalKeyboardKey.slash),
            ],
            priority: 0,
            onInvoke: (_) => focusNode.requestFocus(),
          ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SidebarHeader(text: "Pages"),
            DecoratedTextField(
              focusNode: focusNode,
              controller: searchController,
              onChanged: (value) =>
                  ref.read(_pageSearchProvider.notifier).search(value),
              decoration: InputDecoration(
                hintText: "Search pages...",
                hintStyle: Theme.of(
                  context,
                ).textTheme.bodyMedium!.copyWith(fontSize: 12),
              ),
            ),
            SizedBox(height: context.spacing.space3),
            pages(
              name: "pages",
              shrink: true,
              builder: (data) {
                return Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _PagesTree(pages: data, expanded: expanded),
                        SizedBox(height: context.spacing.space3),
                        if (expanded) const _AddPageButton(),
                      ],
                    ),
                  ),
                );
              },
              loading: (_) => Expanded(child: const LoadingPagesSidebar()),
            ),
            const FooterSidebarLinks(),
          ],
        ),
      ),
    );
  }
}

class LoadingPagesSidebar extends StatelessWidget {
  const LoadingPagesSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: context.spacing.space2,
      children: [
        for (var i = 0; i < 10; i++)
          ShimmerBox.rectangle(height: 35, width: double.infinity),
      ],
    );
  }
}

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

  Future<void> _changeChapter(
    WidgetRef ref,
    String chapter,
    String newChapter,
  ) async {
    final bookId = ref.read(bookIdProvider);
    if (bookId == null) {
      throw Exception("Book ID is null");
    }
    await ref
        .read(booksProvider.notifier)
        .changePagesChapters(bookId, chapter, newChapter);
  }

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
                        _changeChapter(ref, chapter, newChapter),
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
                        _changeChapter(ref, chapter, newChapter),
                  ),
                ),
              ),
            ],
            child: DragTarget<ChapterDrag>(
              onWillAcceptWithDetails: (details) {
                return !chapter.startsWith(details.data.chapter);
              },
              onAcceptWithDetails: (details) =>
                  _changeChapter(ref, chapter, details.data.chapter),
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
          if (expanded) const SizedBox(width: 4),
          Padding(
            padding: EdgeInsets.symmetric(vertical: expanded ? 4 : 0),
            child: Icones(
              isExpanded ? Fa6Solid.chevron_down : Fa6Solid.chevron_right,
              size: 11,
              color: color,
            ),
          ),
          if (expanded) ...[
            const SizedBox(width: 8),
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

        final entryPageType = definition.blueprint.pageType;
        return entryPageType == page.type;
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

class _TreeBarLayout extends SingleChildRenderObjectWidget {
  const _TreeBarLayout({
    required this.barWidth,
    required this.barMargin,
    required this.barColor,
    required this.borderRadius,
    required super.child,
  });

  final double barWidth;
  final EdgeInsets barMargin;
  final Color barColor;
  final Radius borderRadius;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderTreeBarLayout(
      barWidth: barWidth,
      barMargin: barMargin,
      barColor: barColor,
      borderRadius: borderRadius,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderTreeBarLayout renderObject,
  ) {
    renderObject
      ..barWidth = barWidth
      ..barMargin = barMargin
      ..barColor = barColor
      ..borderRadius = borderRadius;
  }
}

class _RenderTreeBarLayout extends RenderBox
    with RenderObjectWithChildMixin<RenderBox> {
  _RenderTreeBarLayout({
    required double barWidth,
    required EdgeInsets barMargin,
    required Color barColor,
    required Radius borderRadius,
  }) : _barWidth = barWidth,
       _barMargin = barMargin,
       _barColor = barColor,
       _borderRadius = borderRadius;

  double _barWidth;
  double get barWidth => _barWidth;
  set barWidth(double value) {
    if (_barWidth == value) return;
    _barWidth = value;
    markNeedsLayout();
  }

  EdgeInsets _barMargin;
  EdgeInsets get barMargin => _barMargin;
  set barMargin(EdgeInsets value) {
    if (_barMargin == value) return;
    _barMargin = value;
    markNeedsLayout();
  }

  Color _barColor;
  Color get barColor => _barColor;
  set barColor(Color value) {
    if (_barColor == value) return;
    _barColor = value;
    markNeedsPaint();
  }

  Radius _borderRadius;
  Radius get borderRadius => _borderRadius;
  set borderRadius(Radius value) {
    if (_borderRadius == value) return;
    _borderRadius = value;
    markNeedsPaint();
  }

  @override
  void performLayout() {
    if (child == null) {
      size = Size(constraints.maxWidth, constraints.minHeight);
      return;
    }

    final barSpaceWidth = barMargin.horizontal + barWidth;
    final availableWidth = constraints.maxWidth - barSpaceWidth;

    child!.layout(
      BoxConstraints(
        minWidth: 0,
        maxWidth: availableWidth > 0 ? availableWidth : 0,
        minHeight: constraints.minHeight,
        maxHeight: constraints.maxHeight,
      ),
      parentUsesSize: true,
    );

    (child!.parentData! as BoxParentData).offset = Offset(
      barSpaceWidth,
      barMargin.top,
    );

    size = Size(constraints.maxWidth, child!.size.height);
    size = constraints.constrain(size);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) {
      return;
    }
    final paint = Paint()
      ..color = barColor
      ..style = PaintingStyle.fill;

    final barRect = Rect.fromLTWH(
      offset.dx + barMargin.left,
      offset.dy + barMargin.top,
      barWidth,
      size.height - barMargin.vertical,
    );

    final rrect = RRect.fromRectAndRadius(barRect, borderRadius);

    context.canvas.drawRRect(rrect, paint);

    final childParentData = child!.parentData! as BoxParentData;
    context.paintChild(child!, childParentData.offset + offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    if (child != null) {
      final childParentData = child!.parentData! as BoxParentData;
      return result.addWithPaintOffset(
        offset: childParentData.offset,
        position: position,
        hitTest: (result, transformed) {
          return child!.hitTest(result, position: transformed);
        },
      );
    }
    return false;
  }
}

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
            autofocus: DecoratedTextFieldAutoFocus.textField,
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
              SnakeCaseInputFormatter(),
              FilteringTextInputFormatter.singleLineFormatter,
              FilteringTextInputFormatter.allow(RegExp("[a-z0-9_]")),
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
              FormattedTextField(
                focusNode: chapterFocus,
                text: chapter.value,
                hintText: "Chapter Name",
                icon: Ph.book_bookmark_fill,
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
              FormattedTextField(
                focusNode: priorityFocus,
                text: priority.value.toString(),
                hintText: "Priority",
                icon: MaterialSymbols.priority_high_rounded,
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
        autofocus: DecoratedTextFieldAutoFocus.textField,
        value: name.value,
        name: "Page Name",
        icon: Ph.book_fill,
        validator: (value) {
          final validation = _validateName(value);
          isNameValid.value = validation == null;
          return validation;
        },
        inputFormatters: [
          SnakeCaseInputFormatter(),
          FilteringTextInputFormatter.singleLineFormatter,
          FilteringTextInputFormatter.allow(RegExp("[a-z0-9_]")),
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
      content: FormattedTextField(
        focusNode: focusNode,
        autofocus: DecoratedTextFieldAutoFocus.textField,
        text: chapter.value,
        hintText: "Chapter Name",
        icon: Ph.book_bookmark_fill,
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

class ChangePagePriorityDialogue extends HookConsumerWidget {
  const ChangePagePriorityDialogue({
    required this.pageId,
    required this.pageName,
    required this.priority,
    super.key,
  });

  final skir.RecordId pageId;
  final String pageName;
  final int priority;

  Future<void> _changePriority(
    WidgetRef ref,
    int newPriority,
    ValueNotifier<bool> changed,
  ) async {
    if (changed.value) return;
    changed.value = true;

    final navigator = Navigator.of(ref.context);
    await ref
        .read(pagesProvider(pageId).notifier)
        .updatePage(priority: newPriority);
    navigator.pop(true);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController();
    final focusNode = useFocusNode();
    final changed = useState(false);
    final buttonController = useLoadingButtonController();

    return AlertDialog(
      title: Text("Change priority of $pageName"),
      content: FormattedTextField(
        controller: controller,
        focusNode: focusNode,
        autofocus: DecoratedTextFieldAutoFocus.textField,
        text: priority.toString(),
        hintText: "Priority",
        icon: MaterialSymbols.priority_high_rounded,
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r"^-?\d*"))],
        onSubmitted: (value) async => buttonController.trigger(),
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
          controller: buttonController,
          onPressed: () async =>
              _changePriority(ref, int.parse(controller.text), changed),
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
      await ref.read(booksProvider.notifier).deletePage(pageId);
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

class PageDrag {
  const PageDrag({required this.pageId});

  final skir.RecordId pageId;
}

class ChapterDrag {
  const ChapterDrag({required this.chapter});

  final String chapter;
}
