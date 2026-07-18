import "dart:math";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/app/presentation/shell/panes.dart";
import "package:typewriter_panel/app/presentation/shortcuts/action_shortcuts.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/domain/selection.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/inspector/presentation/editors.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/inspector/presentation/editors/object_editor.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/inspector/presentation/operations.dart";
import "package:typewriter_panel/shared/hooks/timer.dart";
import "package:typewriter_panel/shared/ui/components/drag_handle.dart";
import "package:typewriter_panel/shared/ui/components/draggable_sheet_handle.dart";
import "package:typewriter_panel/shared/ui/components/section.dart";
import "package:typewriter_panel/shared/ui/components/section_title.dart";
import "package:typewriter_panel/shared/ui/components/surface.dart";
import "package:typewriter_panel/shared/utilities/context.dart";

part "inspector.g.dart";

const double kInspectorMinSize = 200;
const double kInspectorDefaultSize = 400;
const double kInspectorMaxFactor = 3 / 8;

const double kInspectorResizeSmallStep = 10;
const double kInspectorResizeLargeStep = 50;

@riverpod
class InspectorSize extends _$InspectorSize {
  @override
  double build() {
    return kInspectorDefaultSize;
  }

  void size(double size) {
    state = max(size, kInspectorMinSize);
  }
}

class Inspector extends HookConsumerWidget {
  const Inspector({
    required this.child,
    this.margin = const EdgeInsets.only(top: 8, bottom: 8, right: 8),
    super.key,
  });

  final EdgeInsets margin;

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (context.isSmallerThan(3 * kInspectorMinSize)) {
      return MobileInspector(child: child);
    }

    return DesktopInspector(margin: margin, child: child);
  }
}

class MobileInspector extends HookConsumerWidget {
  const MobileInspector({required this.child, super.key});
  final Widget child;

  void _runAnimation(
    bool hasSelection,
    DraggableScrollableController controller,
  ) {
    if (hasSelection) {
      controller.animateTo(0.1, duration: 750.ms, curve: ElasticOutCurve(0.8));
    } else {
      controller.animateTo(
        0.0,
        duration: 400.ms,
        curve: Curves.fastEaseInToSlowEaseOut,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasSelection = ref.watch(hasSelectionProvider);
    final controller = useDraggableScrollableController();

    // Ensure that after a resize the modal will show up.
    useTimer(
      200.ms,
      (timer) => _runAnimation(hasSelection, controller),
      repeat: false,
    );

    useEffect(
      () {
        if (!controller.isAttached) {
          return null;
        } else {
          _runAnimation(hasSelection, controller);
        }
        return null;
      },
      [
        controller,
        controller.isAttached,
        hasSelection,
        MediaQuery.of(context).size.width,
      ],
    );

    return Stack(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            return AnimatedPadding(
              duration: hasSelection ? 750.ms : 400.ms,
              curve: hasSelection
                  ? ElasticOutCurve(0.8)
                  : Curves.fastEaseInToSlowEaseOut,
              padding: EdgeInsets.only(
                bottom: hasSelection ? constraints.maxHeight * 0.1 : 0,
              ),
              child: child,
            );
          },
        ),
        NotificationListener<DraggableScrollableNotification>(
          onNotification: (notification) {
            if (notification.extent <= notification.minExtent &&
                notification.shouldCloseOnMinExtent) {
              ref.read(selectionProvider.notifier).clear();
            }
            return false;
          },
          child: DraggableScrollableSheet(
            initialChildSize: 0.0,
            minChildSize: 0.0,
            maxChildSize: 0.9,
            shouldCloseOnMinExtent: true,
            snapSizes: [0.1, 0.9],
            snap: true,
            controller: controller,
            snapAnimationDuration: 200.ms,
            builder: (context, scrollController) {
              final surfaceColor = Theme.of(context).colorScheme.surface;

              return Surface(
                color: surfaceColor,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Section(
                    child: CustomScrollView(
                      controller: scrollController,
                      slivers: [
                        const SliverPersistentHeader(
                          pinned: true,
                          delegate: DraggableSheetHandleDelegate(),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.only(
                              left: 12,
                              right: 12,
                              bottom: 12,
                            ),
                            child: _InspectorContent(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class DesktopInspector extends HookConsumerWidget {
  const DesktopInspector({
    required this.child,
    this.margin = const EdgeInsets.only(top: 8, right: 8, bottom: 8),
    super.key,
  });

  final EdgeInsets margin;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasSelection = ref.watch(hasSelectionProvider);
    final previousSelection = usePrevious(hasSelection);
    final size = ref.watch(inspectorSizeProvider);

    final screenWidth = MediaQuery.of(context).size.width;
    final maxSize = (screenWidth * kInspectorMaxFactor).floorToDouble() - 1.0;
    final minSize = min(kInspectorMinSize, maxSize);

    final effectiveSize = size.clamp(max<double>(0.0, minSize), maxSize);

    final isDragging = useState(false);

    return Row(
      children: [
        Expanded(child: child),
        if (hasSelection)
          DragHandle(
            axis: Axis.horizontal,
            minSize: minSize,
            maxSize: maxSize,
            getSize: () => effectiveSize,
            onSizeChange: (v) {
              ref
                  .read(inspectorSizeProvider.notifier)
                  .size(v.clamp(minSize, maxSize));
            },
            sizeResolver: (s, d) => s - d,
            onDragStart: () => isDragging.value = true,
            onDragEnd: () => isDragging.value = false,
            hitThickness: 8,
          )
        else
          TweenAnimationBuilder<double>(
            tween: Tween<double>(
              begin: previousSelection != null ? 8 : 3,
              end: 3,
            ),
            duration: 750.ms,
            curve: Curves.fastEaseInToSlowEaseOut,
            builder: (context, width, _) => SizedBox(width: width),
          ),
        ManagedActionSet(
          shortcuts: [
            ActionShortcut(
              id: "inspector-shrink",
              label: "Shrink Inspector",
              description: "Shrink the inspector size",
              activators: [
                const SingleActivator(LogicalKeyboardKey.greater),
                const SingleActivator(LogicalKeyboardKey.greater, shift: true),
                const SingleActivator(LogicalKeyboardKey.period),
                const SingleActivator(LogicalKeyboardKey.period, shift: true),
              ],
              priority: -1,
              onInvoke: (ref) {
                final step = HardwareKeyboard.instance.isShiftPressed
                    ? kInspectorResizeLargeStep
                    : kInspectorResizeSmallStep;
                final newSize = (effectiveSize - step).clamp(
                  max<double>(0.0, minSize),
                  maxSize,
                );
                ref.read(inspectorSizeProvider.notifier).size(newSize);
              },
              show: false,
            ),
            ActionShortcut(
              id: "inspector-expand",
              label: "Expand Inspector",
              description: "Expand the inspector size",
              activators: [
                const SingleActivator(LogicalKeyboardKey.less),
                const SingleActivator(LogicalKeyboardKey.less, shift: true),
                const SingleActivator(LogicalKeyboardKey.comma),
                const SingleActivator(LogicalKeyboardKey.comma, shift: true),
              ],
              priority: -1,
              onInvoke: (ref) {
                final step = HardwareKeyboard.instance.isShiftPressed
                    ? kInspectorResizeLargeStep
                    : kInspectorResizeSmallStep;
                final newSize = (effectiveSize + step).clamp(
                  max<double>(0.0, minSize),
                  maxSize,
                );
                ref.read(inspectorSizeProvider.notifier).size(newSize);
              },
              show: false,
            ),
            ActionShortcut(
              id: "inspector-resize",
              label: "Resize Inspector",
              description: "Resize the inspector size",
              activators: [
                const SingleActivator(LogicalKeyboardKey.period),
                const SingleActivator(LogicalKeyboardKey.comma),
                const SingleActivator(LogicalKeyboardKey.greater),
                const SingleActivator(LogicalKeyboardKey.less),
              ],
              priority: -1,
            ),
          ],
          child: Padding(
            padding: EdgeInsets.only(top: margin.top, bottom: margin.bottom),
            child: AnimatedPadding(
              duration: hasSelection ? 1000.ms : 750.ms,
              curve: hasSelection
                  ? ElasticOutCurve(0.9)
                  : Curves.fastEaseInToSlowEaseOut,
              padding: hasSelection
                  ? EdgeInsets.only(left: margin.left, right: margin.right)
                  : EdgeInsets.zero,
              child: Pane(
                id: "inspector",
                borderRadius: BorderRadius.circular(12),
                enabled: hasSelection,
                margin: null,
                child: Section(
                  margin: EdgeInsets.zero,
                  child: AnimatedContainer(
                    duration: isDragging.value
                        ? 0.ms
                        : hasSelection
                        ? 1000.ms
                        : 750.ms,
                    curve: hasSelection
                        ? ElasticOutCurve(0.9)
                        : Curves.fastEaseInToSlowEaseOut,
                    width: hasSelection ? effectiveSize : 0,
                    height: double.infinity,
                    child: ClipRect(
                      child: OverflowBox(
                        alignment: Alignment.centerLeft,
                        minWidth: effectiveSize,
                        maxWidth: effectiveSize,
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: _InspectorContent(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InspectorContent extends HookConsumerWidget {
  const _InspectorContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Add shimmer when loading.
    final selectedHeader = ref.watch(selectedHeaderProvider);
    final selectedDataBlueprint = ref.watch(selectedDataBlueprintProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        ?selectedHeader,
        if (selectedDataBlueprint != null)
          ObjectEditorWidget(
            path: "",
            objectBlueprint: selectedDataBlueprint,
            editorMode: EditorMode.interactiveInspector,
            defaultExpanded: true,
          ),
        const SizedBox(height: 5),
        Operations(),
        const SizedBox(height: 30),
      ],
    );
  }
}

class Operations extends HookConsumerWidget {
  const Operations({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedProvider).value ?? [];
    final operations = ref.watch(availableOperationsProvider);

    if (operations.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 12,
      children: [
        const SectionTitle(title: "Operations"),
        for (final operation in operations) operation.inspectorButton(selected),
      ],
    );
  }
}
