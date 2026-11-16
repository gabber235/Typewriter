part of "sidebar.dart";

/// Renders the resizable desktop navigation sidebar around [child].
///
/// The sidebar width comes from [sidebarSizeProvider]. Dragging temporarily
/// disables the width animation so the handle tracks the pointer directly.
/// Use [CustomAppBar] on mobile, where this widget is presented in a bottom
/// sheet instead. Its [Pane] joins global directional navigation; the route
/// supplies sidebar content while the shared controller owns resize geometry.
class Sidebar extends HookConsumerWidget {
  const Sidebar({required this.child, super.key});

  /// Navigation content displayed inside the sidebar pane.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = _useSidebarController(context, ref);
    return _SidebarView(controller: controller, child: child);
  }
}

class _SidebarView extends HookWidget {
  const _SidebarView({required this.child, required this.controller});

  final Widget child;
  final _SidebarController controller;

  @override
  Widget build(BuildContext context) {
    final width = controller.effectiveSize;
    final previous = usePrevious(width) ?? width;
    // The direction of the latest change; a rebuild without one keeps it,
    // so a running shrink never takes the grow curve.
    final grows = useRef(true);
    if (width != previous) grows.value = width > previous;
    // Growing overshoots with surfaceIn; shrinking never goes below its
    // target, since panelOut has no overshoot. A drag follows the pointer.
    final timeline = controller.isDragging.value
        ? MotionTimeline.instant
        : motionTimeline(
            context,
            grows.value ? MotionToken.surfaceIn : MotionToken.panelOut,
          );
    return ManagedActionSet(
      shortcuts: controller.shortcuts,
      child: AnimatedContainer(
        duration: timeline.duration,
        curve: timeline.curve,
        width: width,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Pane(
                id: "sidebar",
                margin: EdgeInsets.only(
                  left: context.spacing.space1,
                  top: context.spacing.space1,
                  bottom: context.spacing.space1,
                ),
                borderRadius: context.shapes.mediumBorderRadius,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: context.shapes.mediumBorderRadius,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(context.spacing.space1),
                    child: Surface(
                      color: Theme.of(context).colorScheme.surface,
                      foreground: context.colors.contentPrimary,
                      secondaryForeground: context.colors.contentSecondary,
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
            DragHandle(
              semanticLabel: "Sidebar width",
              axis: Axis.horizontal,
              minSize: kSidebarMinSize,
              maxSize: controller.maxSize,
              getSize: () => controller.effectiveSize,
              onSizeChange: controller.resize,
              onDragStart: controller.startDragging,
              onDragEnd: controller.stopDragging,
              hitThickness: 8,
            ),
          ],
        ),
      ),
    );
  }
}
