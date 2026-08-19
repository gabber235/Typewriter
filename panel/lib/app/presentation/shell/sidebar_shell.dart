part of "sidebar.dart";

class Sidebar extends HookConsumerWidget {
  const Sidebar({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = _useSidebarController(context, ref);
    return _SidebarView(controller: controller, child: child);
  }
}

class _SidebarView extends StatelessWidget {
  const _SidebarView({required this.child, required this.controller});

  final Widget child;
  final _SidebarController controller;

  @override
  Widget build(BuildContext context) {
    return ManagedActionSet(
      shortcuts: controller.shortcuts,
      child: AnimatedContainer(
        duration: controller.isDragging.value ? 0.ms : 1000.ms,
        curve: ElasticOutCurve(0.9),
        width: controller.effectiveSize,
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
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
            DragHandle(
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
