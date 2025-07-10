import "dart:math";

import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:responsive_framework/responsive_framework.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/logic/selectable/selection.dart";
import "package:typewriter_panel/utils/context.dart";
import "package:typewriter_panel/widgets/app/components/inspector/editors.dart";
import "package:typewriter_panel/widgets/app/components/inspector/editors/object_editor.dart";
import "package:typewriter_panel/widgets/generic/components/cursor_controller.dart";
import "package:typewriter_panel/widgets/generic/components/section.dart";

part "inspector.g.dart";

@riverpod
class InspectorSize extends _$InspectorSize {
  @override
  double build() {
    return 400;
  }

  void size(double size) {
    state = max(size, 200);
  }
}

class Inspector extends HookConsumerWidget {
  const Inspector({
    required this.child,
    super.key,
  });
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasSelection = ref.watch(hasSelectionProvider);
    final size = ref.watch(inspectorSizeProvider);
    final controller = useDraggableScrollableController();

    useEffect(
      () {
        if (!controller.isAttached) return null;
        if (hasSelection) {
          controller.animateTo(
            0.1,
            duration: 750.ms,
            curve: ElasticOutCurve(0.8),
          );
        } else {
          controller.animateTo(
            0.0,
            duration: 400.ms,
            curve: Curves.fastEaseInToSlowEaseOut,
          );
        }
        return null;
      },
      [controller, hasSelection, ResponsiveBreakpoints.of(context).screenWidth],
    );

    if (context.isSmalerThan(size * 2)) {
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
                return Section(
                  child: CustomScrollView(
                    controller: scrollController,
                    slivers: [
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _DragHandleDelegate(),
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
                );
              },
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: child),
        _DragHandle(),
        Section(
          margin: EdgeInsets.only(top: 8, right: 8, bottom: 8),
          child: AnimatedSize(
            duration: hasSelection ? 1000.ms : 750.ms,
            curve: hasSelection
                ? ElasticOutCurve(0.9)
                : Curves.fastEaseInToSlowEaseOut,
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: hasSelection ? size : 0,
              height: double.infinity,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: _InspectorContent(),
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
    final selectedHeader = ref.watch(selectedHeaderProvider);
    final selectedDataBlueprint = ref.watch(selectedDataBlueprintProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        if (selectedHeader != null) selectedHeader,
        if (selectedDataBlueprint != null)
          ObjectEditorWidget(
            path: "",
            objectBlueprint: selectedDataBlueprint,
            editorMode: EditorMode.interactiveInspector,
            defaultExpanded: true,
          ),
        const SizedBox(height: 30),
      ],
    );
  }
}

class _DragHandle extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasSelection = ref.watch(hasSelectionProvider);
    if (!hasSelection) return const SizedBox(width: 3);
    final hovering = useState(false);
    final startSize = useState(0.0);
    final startPosition = useState(Offset.zero);

    final showHandle = useMemoized<bool>(() {
      if (startSize.value > 0) return true;
      return hovering.value;
    }, [
      startSize.value,
      hovering.value,
    ]);

    return GestureDetector(
      onHorizontalDragStart: (details) {
        startSize.value = ref.read(inspectorSizeProvider);
        startPosition.value = details.globalPosition;
        ref
            .read(cursorControllerProvider.notifier)
            .cursor(SystemMouseCursors.resizeColumn);
      },
      onHorizontalDragUpdate: (details) {
        final position = details.globalPosition;
        final dx = position.dx - startPosition.value.dx;
        final size = startSize.value - dx;

        final screenWidth = ResponsiveBreakpoints.of(context).screenWidth;
        final maxSize = (screenWidth / 2).floor() - 1.0;

        final newSize = min(maxSize, size);
        ref.read(inspectorSizeProvider.notifier).size(newSize);
      },
      onHorizontalDragEnd: (details) {
        startSize.value = 0.0;
        startPosition.value = Offset.zero;
        ref.read(cursorControllerProvider.notifier).reset();
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeColumn,
        onEnter: (_) => hovering.value = true,
        onExit: (_) => hovering.value = false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(width: 16),
                AnimatedContainer(
                  duration: 200.ms,
                  curve: Curves.easeOut,
                  height:
                      showHandle ? min(constraints.maxHeight * 0.9, 100) : 0,
                  width: showHandle ? 3 : 0,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DragHandleDelegate extends SliverPersistentHeaderDelegate {
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Center(
      child: Container(
        height: 4,
        width: 32,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  @override
  double get maxExtent => 32;

  @override
  double get minExtent => 32;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      false;
}
