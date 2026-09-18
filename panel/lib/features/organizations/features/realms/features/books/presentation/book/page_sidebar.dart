part of "route.dart";

/// Search text local to the current book sidebar.
///
/// It is intentionally separate from canonical page state. The derived page
/// provider combines this query with canonical pages and local editor work.
@riverpod
class _PageSearch extends _$PageSearch {
  @override
  String build() => "";

  // ignore: use_setters_to_change_properties
  void search(String value) {
    state = value;
  }
}

/// Supplies the sidebar projection, preserving local edits while searching.
///
/// A projected result is used immediately when available. Otherwise the
/// canonical provider is awaited once, then the projection is read again so
/// the sidebar does not display stale canonical values over an active draft.
@riverpod
Future<List<Page>> _viewingPages(Ref ref) async {
  final bookId = ref.watch(bookIdProvider);
  if (bookId == null) throw Exception("Not visiting a book (sub)route");

  final search = ref.watch(_pageSearchProvider);

  await ref.debounce(300.ms);

  final projected = ref.watch(projectedBookPagesProvider(bookId, search));
  if (projected.hasValue) return projected.requireValue;
  await ref.watch(canonicalBookPagesProvider(bookId).future);
  return ref.read(projectedBookPagesProvider(bookId, search)).requireValue;
}

/// Sidebar for searching, selecting, and organizing pages in the active book.
///
/// Page data is read through the projected provider. Mutations are delegated to
/// dialogs and drag handlers, which use expected values to surface conflicts.
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
            EditorTextField(
              focusNode: focusNode,
              controller: searchController,
              onChanged: (value) =>
                  ref.read(_pageSearchProvider.notifier).search(value),
              decoration: InputDecoration(
                hintText: "Search pages...",
                hintStyle: Theme.of(context).textTheme.bodyMedium!
                    .copyWith(fontSize: 12),
              ),
            ),
            SizedBox(height: context.spacing.space3),
            pages(
              name: "pages",
              shrink: true,
              builder: (data) {
                return Expanded(
                  child: ClipPath(
                    clipper: VerticalClipper(additionalWidth: 10),
                    child: SingleChildScrollView(
                      clipBehavior: .none,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _PagesTree(pages: data, expanded: expanded),
                          SizedBox(height: context.spacing.space3),
                          if (expanded) const _AddPageButton(),
                        ],
                      ),
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

/// Skeleton sidebar shown while the book's page projection is loading.
class LoadingPagesSidebar extends StatelessWidget {
  const LoadingPagesSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: 10,
      itemBuilder: (_, _) =>
          ShimmerBox.rectangle(height: 35, width: double.infinity),
      separatorBuilder: (_, _) => SizedBox(height: context.spacing.space2),
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
    required this._barWidth,
    required this._barMargin,
    required this._barColor,
    required this._borderRadius,
  });

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
