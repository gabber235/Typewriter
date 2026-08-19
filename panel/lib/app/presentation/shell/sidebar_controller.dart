part of "sidebar.dart";

class _SidebarController {
  const _SidebarController({
    required this.effectiveSize,
    required this.minSize,
    required this.maxSize,
    required this.isDragging,
    required this.shortcuts,
    required this.resize,
    required this.startDragging,
    required this.stopDragging,
  });

  final double effectiveSize;
  final double minSize;
  final double maxSize;
  final ValueNotifier<bool> isDragging;
  final List<ActionShortcut> shortcuts;
  final ValueChanged<double> resize;
  final VoidCallback startDragging;
  final VoidCallback stopDragging;
}

_SidebarController _useSidebarController(BuildContext context, WidgetRef ref) {
  final size = ref.watch(sidebarSizeProvider);
  final screenSize = MediaQuery.of(context).size;
  final maxSize = (screenSize.width * kSidebarMaxFactor).floorToDouble() - 1.0;
  final minSize = min(kSidebarMinSize, maxSize);
  final effectiveSize = size.clamp(max<double>(0.0, minSize), maxSize);
  final isDragging = useState(false);

  void resizeFromDrag(double value) {
    ref.read(sidebarSizeProvider.notifier).size(value.clamp(minSize, maxSize));
  }

  void resizeBy(double delta) {
    final newSize = (effectiveSize + delta).clamp(
      max<double>(0.0, minSize),
      maxSize,
    );
    ref.read(sidebarSizeProvider.notifier).size(newSize);
  }

  final shortcuts = [
    ActionShortcut(
      id: "sidebar-shrink",
      label: "Shrink Sidebar",
      description: "Shrink the sidebar size",
      activators: [
        const SingleActivator(LogicalKeyboardKey.less),
        const SingleActivator(LogicalKeyboardKey.less, shift: true),
        const SingleActivator(LogicalKeyboardKey.comma),
        const SingleActivator(LogicalKeyboardKey.comma, shift: true),
      ],
      priority: -1,
      onInvoke: (_) => resizeBy(
        HardwareKeyboard.instance.isShiftPressed
            ? -kSidebarResizeLargeStep
            : -kSidebarResizeSmallStep,
      ),
      show: false,
    ),
    ActionShortcut(
      id: "sidebar-expand",
      label: "Expand Sidebar",
      description: "Expand the sidebar size",
      activators: [
        const SingleActivator(LogicalKeyboardKey.greater),
        const SingleActivator(LogicalKeyboardKey.greater, shift: true),
        const SingleActivator(LogicalKeyboardKey.period),
        const SingleActivator(LogicalKeyboardKey.period, shift: true),
      ],
      priority: -1,
      onInvoke: (_) => resizeBy(
        HardwareKeyboard.instance.isShiftPressed
            ? kSidebarResizeLargeStep
            : kSidebarResizeSmallStep,
      ),
      show: false,
    ),
    ActionShortcut(
      id: "sidebar-resize",
      label: "Resize Sidebar",
      description: "Resize the sidebar size",
      activators: [
        const SingleActivator(LogicalKeyboardKey.period),
        const SingleActivator(LogicalKeyboardKey.comma),
        const SingleActivator(LogicalKeyboardKey.greater),
        const SingleActivator(LogicalKeyboardKey.less),
      ],
      priority: -1,
    ),
  ];

  return _SidebarController(
    effectiveSize: effectiveSize,
    minSize: minSize,
    maxSize: maxSize,
    isDragging: isDragging,
    shortcuts: shortcuts,
    resize: resizeFromDrag,
    startDragging: () => isDragging.value = true,
    stopDragging: () => isDragging.value = false,
  );
}
