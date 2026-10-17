import "package:typewriter_panel/typewriter_panel.dart";

/// Renders the visual grip used to indicate a draggable sheet.
///
/// This widget is decorative and does not implement dragging. Attach gesture
/// ownership to the surrounding sheet or sliver.
class DraggableSheetHandle extends StatelessWidget {
  const DraggableSheetHandle({
    this.width = 32,
    this.height = 4,
    this.color,
    this.borderRadius,
    super.key,
  });

  final double width;
  final double height;
  final Color? color;
  final BorderRadiusGeometry? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color:
              color ??
              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          borderRadius: borderRadius ?? BorderRadius.circular(height / 2),
        ),
      ),
    );
  }
}

/// Keeps a [DraggableSheetHandle] visible as a fixed extent sliver header.
///
/// The delegate owns header layout configuration only. Sheet drag behavior
/// remains with the scrollable or sheet controller.
class DraggableSheetHandleDelegate extends SliverPersistentHeaderDelegate {
  const DraggableSheetHandleDelegate({
    this.extent = 32,
    this.width = 32,
    this.height = 4,
    this.color,
    this.backgroundColor,
    this.borderRadius,
  });

  final double extent;
  final double width;
  final double height;
  final Color? color;
  final Color? backgroundColor;
  final BorderRadiusGeometry? borderRadius;

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final handle = DraggableSheetHandle(
      width: width,
      height: height,
      color: color,
      borderRadius: borderRadius,
    );

    final background = backgroundColor;
    if (background == null) {
      return handle;
    }

    return ColoredBox(color: background, child: handle);
  }

  @override
  bool shouldRebuild(covariant DraggableSheetHandleDelegate oldDelegate) {
    return extent != oldDelegate.extent ||
        width != oldDelegate.width ||
        height != oldDelegate.height ||
        color != oldDelegate.color ||
        backgroundColor != oldDelegate.backgroundColor ||
        borderRadius != oldDelegate.borderRadius;
  }
}
