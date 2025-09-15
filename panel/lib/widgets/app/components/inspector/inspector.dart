import "dart:math";

import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/hooks/timer.dart";
import "package:typewriter_panel/logic/selectable/selection.dart";
import "package:typewriter_panel/utils/context.dart";
import "package:typewriter_panel/widgets/app/components/inspector/editors.dart";
import "package:typewriter_panel/widgets/app/components/inspector/editors/object_editor.dart";
import "package:typewriter_panel/widgets/app/components/inspector/operations.dart";
import "package:typewriter_panel/widgets/app/components/panes.dart";
import "package:typewriter_panel/widgets/generic/components/drag_handle.dart";
import "package:typewriter_panel/widgets/generic/components/section.dart";
import "package:typewriter_panel/widgets/generic/components/section_title.dart";

part "inspector.g.dart";

const double kInspectorMinSize = 200;
const double kInspectorDefaultSize = 400;
const double kInspectorMaxFactor = 3 / 8;

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
    final size = ref.watch(inspectorSizeProvider);

    if (context.isSmallerThan(size / kInspectorMaxFactor)) {
      return MobileInspector(child: child);
    }

    return DesktopInspector(
      margin: margin,
      child: child,
    );
  }
}

class MobileInspector extends HookConsumerWidget {
  const MobileInspector({
    required this.child,
    super.key,
  });
  final Widget child;

  void _runAnimation(
    bool hasSelection,
    DraggableScrollableController controller,
  ) {
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
              return DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Section(
                  child: CustomScrollView(
                    controller: scrollController,
                    slivers: [
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _MobileDragHandleDelegate(),
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
    final minSize = maxSize > kInspectorMinSize ? maxSize : kInspectorMinSize;

    return Row(
      children: [
        Expanded(child: child),
        if (hasSelection)
          DragHandle(
            axis: Axis.horizontal,
            minSize: minSize,
            maxSize: maxSize,
            getSize: () => ref.read(inspectorSizeProvider),
            onSizeChange: (v) =>
                ref.read(inspectorSizeProvider.notifier).size(v),
            sizeResolver: (s, d) => s - d,
          )
        else
          TweenAnimationBuilder<double>(
            tween: Tween<double>(
              begin: previousSelection != null ? 16 : 3,
              end: 3,
            ),
            duration: 750.ms,
            curve: Curves.fastEaseInToSlowEaseOut,
            builder: (context, width, _) => SizedBox(width: width),
          ),
        Padding(
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
                  duration: hasSelection ? 1000.ms : 750.ms,
                  curve: hasSelection
                      ? ElasticOutCurve(0.9)
                      : Curves.fastEaseInToSlowEaseOut,
                  width: hasSelection ? size : 0,
                  height: double.infinity,
                  child: ClipRect(
                    child: OverflowBox(
                      alignment: Alignment.centerLeft,
                      minWidth: size,
                      maxWidth: size,
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
      ],
    );
  }
}

class _MobileDragHandleDelegate extends SliverPersistentHeaderDelegate {
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
