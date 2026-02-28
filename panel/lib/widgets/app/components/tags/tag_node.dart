import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/generated/models/book.pb.dart";
import "package:typewriter_panel/logic/tags/tag_selectable.dart";
import "package:typewriter_panel/logic/tags/tags.dart";
import "package:typewriter_panel/utils/color.dart";
import "package:typewriter_panel/utils/string.dart";
import "package:typewriter_panel/widgets/app/components/graph/graph_drag.dart";
import "package:typewriter_panel/widgets/app/components/selector.dart";

class TagNode extends HookConsumerWidget {
  const TagNode({required this.tagId, super.key});

  final String tagId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tag = ref.watch(tagProvider(tagId));
    final focusNode = useFocusNode();

    if (tag == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final tagColor = tag.color.value != 0
        ? Color(tag.color.value)
        : Colors.grey;

    final graphDrag = GraphDrag.maybeOf(context);

    return Selector(
      selectableId: TagIdentifier(tagId),
      focusNode: focusNode,
      builder: (isSelected, isFocused, isHovered) {
        final content = _TagNodeContent(
          tag: tag,
          tagColor: tagColor,
          colorScheme: colorScheme,
          theme: theme,
          isSelected: isSelected,
          isFocused: isFocused,
          isHovered: isHovered,
        );

        return Draggable<TagIdentifier>(
          data: TagIdentifier(tagId),
          feedback: FeedbackTagNode(tag: tag, tagColor: tagColor),
          childWhenDragging: PlaceholderTagNode(tagColor: tagColor),
          onDragStarted: () {
            graphDrag?.draggingInsideGraph.value = true;
          },
          onDragEnd: (_) {
            graphDrag?.draggingInsideGraph.value = false;
          },
          child: DragTarget<TagIdentifier>(
            onWillAcceptWithDetails: (details) {
              return details.data.id != tagId;
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
                  colorScheme: colorScheme,
                  theme: theme,
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
  }
}

class _TagNodeContent extends StatelessWidget {
  const _TagNodeContent({
    required this.tag,
    required this.tagColor,
    required this.colorScheme,
    required this.theme,
    required this.isSelected,
    required this.isFocused,
    required this.isHovered,
  });

  final Tag tag;
  final Color tagColor;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final bool isSelected;
  final bool isFocused;
  final bool isHovered;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Color.alphaBlend(
      tagColor.withValues(
        alpha: switch ((isHovered, isSelected)) {
          (false, false) => 0.2,
          (true, false) => 0.5,
          (false, true) => 1.0,
          (true, true) => 0.7,
        },
      ),
      colorScheme.surface,
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
    );
  }
}

class PlaceholderTagNode extends StatelessWidget {
  const PlaceholderTagNode({required this.tagColor, super.key});

  final Color tagColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tagColor.withValues(alpha: 0.5),
          width: 2,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
    );
  }
}
