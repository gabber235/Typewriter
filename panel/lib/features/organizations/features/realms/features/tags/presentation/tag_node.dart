import "package:dotted_border/dotted_border.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/graph/presentation/graph_drag.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/presentation/selector.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/tags/application/tag_selectable.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/tags/application/tags.dart";
import "package:typewriter_panel/infrastructure/protocols/protobuf/extensions.dart";
import "package:typewriter_panel/infrastructure/protocols/protobuf/generated/models/book.pb.dart";
import "package:typewriter_panel/shared/ui/components/shimmer.dart";
import "package:typewriter_panel/shared/ui/components/surface.dart";
import "package:typewriter_panel/shared/utilities/color.dart";
import "package:typewriter_panel/shared/utilities/riverpod.dart";
import "package:typewriter_panel/shared/utilities/string.dart";

class TagNode extends HookConsumerWidget {
  const TagNode({required this.tagId, super.key});

  final String tagId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTag = ref.watch(tagProvider(tagId));

    return asyncTag(
      name: "Tag",
      shrink: true,
      builder: (tag) {
        if (tag == null) return const SizedBox.shrink();
        return _TagNode(tag: tag);
      },
      loading: (_) =>
          ShimmerBox.rectangle(width: double.infinity, height: double.infinity),
    );
  }
}

class _TagNode extends HookWidget {
  const _TagNode({required this.tag});

  final Tag tag;

  @override
  Widget build(BuildContext context) {
    final focusNode = useFocusNode();

    final tagColor = tag.color.value != 0
        ? tag.color.value.toFlutterColor()
        : Colors.grey;

    final graphDrag = GraphDrag.maybeOf(context);
    useListenable(graphDrag?.draggingInsideGraph);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Selector(
          selectableId: TagIdentifier(tag.tagId),
          focusNode: focusNode,
          builder: (isSelected, isFocused, isHovered) {
            final content = _TagNodeContent(
              tag: tag,
              tagColor: tagColor,
              isSelected: isSelected,
              isFocused: isFocused,
              isHovered: isHovered,
            );

            return Draggable<TagIdentifier>(
              data: TagIdentifier(tag.tagId),
              onDragStarted: () {
                // Because we initially start dragging over itself, we know that we are dragging inside the graph.
                // And want to prevent the feedback from being shown.
                // However the graph doesn't know that we are dragging on it yet.
                graphDrag?.draggingInsideGraph.value = true;
              },
              feedback: HookBuilder(
                builder: (context) {
                  useListenable(graphDrag?.draggingInsideGraph);
                  return graphDrag?.draggingInsideGraph.value ?? false
                      ? SizedBox()
                      : SizedBox(
                          width: constraints.maxWidth,
                          height: constraints.maxHeight,
                          child: FeedbackTagNode(tag: tag, tagColor: tagColor),
                        );
                },
              ),
              childWhenDragging: graphDrag?.draggingInsideGraph.value ?? false
                  ? content
                  : PlaceholderTagNode(name: tag.name, color: tagColor),
              child: DragTarget<TagIdentifier>(
                onWillAcceptWithDetails: (details) {
                  // TODO: Must check that this will not create a cycle
                  return details.data.id != tag.tagId;
                },
                onAcceptWithDetails: (details) {
                  // TODO: Implement tag linking/grouping when dropped on another tag
                },
                builder: (context, candidateData, rejectedData) {
                  final isDropTarget = candidateData.isNotEmpty;
                  if (isDropTarget) {
                    return _TagNodeContent(
                      tag: tag,
                      tagColor: tagColor,
                      isSelected: true,
                      isFocused: true,
                      isHovered: true,
                    );
                  }
                  return content;
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _TagNodeContent extends StatelessWidget {
  const _TagNodeContent({
    required this.tag,
    required this.tagColor,
    required this.isSelected,
    required this.isFocused,
    required this.isHovered,
  });

  final Tag tag;
  final Color tagColor;
  final bool isSelected;
  final bool isFocused;
  final bool isHovered;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final backgroundColor = Color.alphaBlend(
      tagColor.withValues(
        alpha: switch ((isHovered, isSelected)) {
          (false, false) => 0.2,
          (true, false) => 0.5,
          (false, true) => 1.0,
          (true, true) => 0.7,
        },
      ),
      Surface.colorOf(context),
    );

    final textColor = isHovered
        ? ThemeData.estimateBrightnessForColor(backgroundColor) ==
                  Brightness.dark
              ? Colors.white
              : Colors.black
        : isSelected
        ? backgroundColor.on(context)
        : tagColor;

    return AnimatedContainer(
      duration: 100.ms,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFocused
              ? theme.brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black
              : isSelected
              ? Colors.transparent
              : tagColor,
          width: 2,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Center(
        child: Text(
          tag.name.formatted,
          style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class FeedbackTagNode extends StatelessWidget {
  const FeedbackTagNode({required this.tag, required this.tagColor, super.key});

  final Tag tag;
  final Color tagColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Opacity(
        opacity: 0.8,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: tagColor.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              tag.name.formatted,
              style: TextStyle(
                color:
                    ThemeData.estimateBrightnessForColor(tagColor) ==
                        Brightness.dark
                    ? Colors.white
                    : Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PlaceholderTagNode extends StatelessWidget {
  const PlaceholderTagNode({
    required this.name,
    required this.color,
    super.key,
  });

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final surfaceColor = Theme.of(context).colorScheme.surfaceContainerLowest;

    return Surface(
      color: surfaceColor,
      child: ColoredBox(
        color: surfaceColor,
        child: DottedBorder(
          options: RoundedRectDottedBorderOptions(
            color: color,
            strokeWidth: 2,
            dashPattern: const [5, 5],
            radius: const Radius.circular(12),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Center(
              child: Text(
                name.formatted,
                style: TextStyle(color: color, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
