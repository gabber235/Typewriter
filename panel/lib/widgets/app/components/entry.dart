import "package:dotted_border/dotted_border.dart";
import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/logic/pages/entries.dart";
import "package:typewriter_panel/utils/color.dart";

import "package:typewriter_panel/widgets/app/components/graph/graph_drag.dart";
import "package:typewriter_panel/widgets/app/components/selector.dart";
import "package:typewriter_panel/widgets/generic/components/icones.dart";
import "package:typewriter_panel/widgets/generic/components/surface.dart";

class EntryNode extends HookConsumerWidget {
  const EntryNode({required this.entry, super.key});

  final PageEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (entry) {
      DefinitionPageEntry(definition: final definition) => _DefinitionEntryNode(
        definition: definition,
      ),
      ReferencePageEntry(
        id: final id,
        name: final name,
        blueprint: final blueprint,
        pageId: final pageId,
      ) =>
        _ReferenceEntryNode(
          id: id,
          name: name,
          blueprint: blueprint,
          pageId: pageId,
        ),
      NoBlueprintPageEntry(id: final id, name: final name) =>
        _NoBlueprintEntryNode(id: id, name: name),
      _ => const _NonexistentEntryNode(),
    };
  }
}

class _DefinitionEntryNode extends HookConsumerWidget {
  const _DefinitionEntryNode({required this.definition});

  final EntryDefinition definition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusNode = useFocusNode();

    final entryIdentifier = EntryIdentifier(definition.id);
    final isDeprecated = _isEntryDeprecated(definition);

    final graphDrag = GraphDrag.of(context);
    useListenable(graphDrag.draggingInsideGraph);

    return Selector(
      focusNode: focusNode,
      selectableId: entryIdentifier,
      builder: (isSelected, isFocused, isHovered) {
        return Draggable<EntryIdentifier>(
          data: entryIdentifier,
          onDragStarted: () {
            // Because we initially start dragging over itself, we know that we are dragging inside the graph.
            // And want to prevent the feedback from being shown.
            // However the graph doesn't know that we are dragging on it yet.
            graphDrag.draggingInsideGraph.value = true;
          },
          feedback: HookBuilder(
            builder: (context) {
              useListenable(graphDrag.draggingInsideGraph);
              return graphDrag.draggingInsideGraph.value
                  ? SizedBox()
                  : _FeedbackEntryNode(
                      name: definition.name,
                      blueprint: definition.blueprint,
                      isDeprecated: isDeprecated,
                    );
            },
          ),
          childWhenDragging: graphDrag.draggingInsideGraph.value
              ? child(
                  context: context,
                  isDeprecated: isDeprecated,
                  isFocused: isFocused,
                  isSelected: isSelected,
                  isAccepting: false,
                  isRejecting: false,
                )
              : _PlaceholderEntryNode(
                  name: definition.name,
                  blueprint: definition.blueprint,
                  isDeprecated: isDeprecated,
                ),
          child: DragTarget<EntryIdentifier>(
            onWillAcceptWithDetails: (_) {
              // TODO: Evaluate accepting paths for linking on drop.
              return false;
            },
            onAcceptWithDetails: (_) async {
              // TODO: Implement linking flow on drop.
            },
            builder: (context, candidateData, rejectedData) {
              final isAccepting = candidateData.isNotEmpty;
              final isRejecting = rejectedData.isNotEmpty;

              return child(
                context: context,
                isDeprecated: isDeprecated,
                isFocused: isFocused,
                isSelected: isSelected,
                isAccepting: isAccepting,
                isRejecting: isRejecting,
              );
            },
          ),
        );
      },
    );
  }

  Widget child({
    required BuildContext context,
    required bool isDeprecated,
    required bool isFocused,
    required bool isSelected,
    required bool isAccepting,
    required bool isRejecting,
  }) {
    if (isRejecting) {
      return MouseRegion(
        cursor: SystemMouseCursors.forbidden,
        child: Material(
          color: Colors.grey,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.all(7.0),
            child: _InnerEntryNode(
              name: definition.name,
              blueprint: definition.blueprint,
              color: Colors.white,
              isDeprecated: isDeprecated,
            ),
          ),
        ),
      );
    }

    final backgroundColor = isDeprecated
        ? Color.alphaBlend(
            definition.blueprint.color.withValues(alpha: 0.7),
            Surface.colorOf(context),
          )
        : definition.blueprint.color;

    final highlightColor = isFocused
        ? Colors.white
        : backgroundColor.onBrightness(Brightness.dark);

    return AnimatedOpacity(
      duration: 400.ms,
      curve: Curves.easeOutCubic,
      opacity: isAccepting ? 0.5 : 1,
      child: Material(
        borderRadius: BorderRadius.circular(6),
        color: backgroundColor,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCirc,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isSelected ? highlightColor : backgroundColor,
              width: 3,
            ),
          ),
          margin: const EdgeInsets.all(4.0),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCirc,
            alignment: Alignment.topCenter,
            child: _InnerEntryNode(
              name: definition.name,
              blueprint: definition.blueprint,
              color: highlightColor,
              isDeprecated: isDeprecated,
            ),
          ),
        ),
      ),
    );
  }

  bool _isEntryDeprecated(EntryDefinition definition) {
    return definition.blueprint.modifiers.any(
      (modifier) => modifier is DeprecatedModifier,
    );
  }
}

class _ReferenceEntryNode extends HookConsumerWidget {
  const _ReferenceEntryNode({
    required this.id,
    required this.name,
    required this.blueprint,
    required this.pageId,
  });

  final String id;
  final String name;
  final EntryBlueprint blueprint;
  final String pageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusNode = useFocusNode();
    // TODO: Change to different type of identifier
    final entryIdentifier = EntryIdentifier(id);
    final isDeprecated = blueprint.modifiers.any(
      (modifier) => modifier is DeprecatedModifier,
    );

    return Selector(
      focusNode: focusNode,
      selectableId: entryIdentifier,
      builder: (isSelected, isFocused, isHovered) {
        final backgroundColor = Color.alphaBlend(
          blueprint.color.withValues(alpha: 0.05),
          Surface.colorOf(context),
        );

        final highlightColor = isFocused ? Colors.white : blueprint.color;

        return LongPressDraggable<EntryIdentifier>(
          data: entryIdentifier,
          feedback: _FeedbackEntryNode(
            name: name,
            blueprint: blueprint,
            isDeprecated: isDeprecated,
            isReference: true,
            pageId: pageId,
          ),
          childWhenDragging: _PlaceholderEntryNode(
            name: name,
            blueprint: blueprint,
            isDeprecated: isDeprecated,
            isReference: true,
          ),
          child: Material(
            animationDuration: 300.ms,
            color: backgroundColor,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: blueprint.color, width: 3),
              borderRadius: BorderRadius.circular(4),
            ),
            child: _InnerEntryNode(
              name: name,
              blueprint: blueprint,
              color: highlightColor,
              isDeprecated: isDeprecated,
              isReference: true,
              // TODO: Resolve page name from pageId if available in providers.
              pageId: pageId,
            ),
          ),
        );
      },
    );
  }
}

class _NonexistentEntryNode extends StatelessWidget {
  const _NonexistentEntryNode();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.redAccent,
      borderRadius: BorderRadius.circular(4),
      child: _AdaptiveEntryLayout(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        compactPadding: const EdgeInsets.all(4),
        leading: const Icon(Icons.error, color: Colors.white, size: 18),
        center: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Flexible(
              child: Text(
                "Non-existent entry",
                style: TextStyle(color: Colors.white, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Flexible(
              child: Text(
                "Entry reference is not an entry",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                  fontStyle: FontStyle.italic,
                  fontSize: 11,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoBlueprintEntryNode extends HookConsumerWidget {
  const _NoBlueprintEntryNode({required this.id, required this.name});

  final String id;
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusNode = useFocusNode();
    // TODO: Change to different type of identifier
    final entryIdentifier = EntryIdentifier(id);

    return Selector(
      focusNode: focusNode,
      selectableId: entryIdentifier,
      builder: (isSelected, isFocused, isHovered) {
        final backgroundColor = Theme.of(context).colorScheme.error;

        final highlightColor = isFocused
            ? Colors.white
            : backgroundColor.onBrightness(Brightness.dark);

        return Material(
          borderRadius: BorderRadius.circular(6),
          color: backgroundColor,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCirc,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isSelected ? highlightColor : backgroundColor,
                width: 3,
              ),
            ),
            margin: const EdgeInsets.all(4),
            padding: const EdgeInsets.all(4),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCirc,
              alignment: Alignment.topCenter,
              child: _AdaptiveEntryLayout(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                compactPadding: const EdgeInsets.all(4),
                leading: Icon(Icons.error, color: highlightColor, size: 18),
                center: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: TextStyle(color: highlightColor, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        "Blueprint for this entry does not exist",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: highlightColor,
                          fontStyle: FontStyle.italic,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _InnerEntryNode extends StatelessWidget {
  const _InnerEntryNode({
    required this.name,
    required this.blueprint,
    required this.color,
    required this.isDeprecated,
    this.isReference = false,
    this.pageId,
  });

  final String name;
  final EntryBlueprint blueprint;
  final Color color;
  final bool isDeprecated;
  final bool isReference;
  final String? pageId;

  @override
  Widget build(BuildContext context) {
    final centerContent = isReference && pageId != null
        ? Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Text(
                  name,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    decoration: isDeprecated
                        ? TextDecoration.lineThrough
                        : null,
                    decorationThickness: 2.8,
                    decorationColor: color,
                    decorationStyle: TextDecorationStyle.wavy,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                "Page: $pageId",
                style: TextStyle(
                  color: color.withValues(alpha: 0.7),
                  fontSize: 11,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          )
        : Text(
            name,
            style: TextStyle(
              color: color,
              fontSize: 13,
              decoration: isDeprecated ? TextDecoration.lineThrough : null,
              decorationThickness: 2.8,
              decorationColor: color,
              decorationStyle: TextDecorationStyle.wavy,
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          );

    return _AdaptiveEntryLayout(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      compactPadding: const EdgeInsets.all(4),
      leading: Icones(blueprint.icon, size: 18, color: color),
      center: centerContent,
      suffix: isReference
          ? Icon(Icons.open_in_new, color: color, size: 18)
          : null,
    );
  }
}

enum _EntrySlot { leading, center, suffix }

class _AdaptiveEntryLayout
    extends SlottedMultiChildRenderObjectWidget<_EntrySlot, RenderBox> {
  const _AdaptiveEntryLayout({
    required this.leading,
    this.center,
    this.suffix,
    this.padding = EdgeInsets.zero,
    this.compactPadding,
    // ignore: unused_element_parameter
    this.minCenterWidth = 30.0,
  });

  final Widget leading;
  final Widget? center;
  final Widget? suffix;
  final EdgeInsets padding;
  final EdgeInsets? compactPadding;
  final double minCenterWidth;

  @override
  Iterable<_EntrySlot> get slots => _EntrySlot.values;

  @override
  Widget? childForSlot(_EntrySlot slot) {
    return switch (slot) {
      _EntrySlot.leading => leading,
      _EntrySlot.center => center,
      _EntrySlot.suffix => suffix,
    };
  }

  @override
  SlottedContainerRenderObjectMixin<_EntrySlot, RenderBox> createRenderObject(
    BuildContext context,
  ) {
    return _RenderAdaptiveEntryLayout(
      padding: padding,
      compactPadding: compactPadding ?? padding,
      minCenterWidth: minCenterWidth,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderAdaptiveEntryLayout renderObject,
  ) {
    renderObject
      ..padding = padding
      ..compactPadding = compactPadding ?? padding
      ..minCenterWidth = minCenterWidth;
  }
}

class _RenderAdaptiveEntryLayout extends RenderBox
    with SlottedContainerRenderObjectMixin<_EntrySlot, RenderBox> {
  _RenderAdaptiveEntryLayout({
    required EdgeInsets padding,
    required EdgeInsets compactPadding,
    required double minCenterWidth,
  }) : _padding = padding,
       _compactPadding = compactPadding,
       _minCenterWidth = minCenterWidth;

  EdgeInsets _padding;
  EdgeInsets get padding => _padding;
  set padding(EdgeInsets value) {
    if (_padding == value) return;
    _padding = value;
    markNeedsLayout();
  }

  EdgeInsets _compactPadding;
  EdgeInsets get compactPadding => _compactPadding;
  set compactPadding(EdgeInsets value) {
    if (_compactPadding == value) return;
    _compactPadding = value;
    markNeedsLayout();
  }

  double _minCenterWidth;
  double get minCenterWidth => _minCenterWidth;
  set minCenterWidth(double value) {
    if (_minCenterWidth == value) return;
    _minCenterWidth = value;
    markNeedsLayout();
  }

  static const double _spacing = 8.0;

  bool _showCenter = false;
  bool _showSuffix = false;

  @override
  void performLayout() {
    final leadingChild = childForSlot(_EntrySlot.leading);
    final centerChild = childForSlot(_EntrySlot.center);
    final suffixChild = childForSlot(_EntrySlot.suffix);

    final looseConstraints = BoxConstraints.loose(
      Size(constraints.maxWidth, constraints.maxHeight),
    );

    final leadingSize = leadingChild != null
        ? (leadingChild..layout(looseConstraints, parentUsesSize: true)).size
        : Size.zero;

    final centerSize = centerChild != null
        ? (centerChild..layout(looseConstraints, parentUsesSize: true)).size
        : Size.zero;

    final suffixSize = suffixChild != null
        ? (suffixChild..layout(looseConstraints, parentUsesSize: true)).size
        : Size.zero;

    final availableWidth = constraints.maxWidth;

    final minWidthForAllThree =
        _padding.horizontal +
        leadingSize.width +
        (centerChild != null ? _spacing + _minCenterWidth : 0) +
        (suffixChild != null ? _spacing + suffixSize.width : 0);

    final minWidthForLeadingCenter =
        _padding.horizontal +
        leadingSize.width +
        (centerChild != null ? _spacing + _minCenterWidth : 0);

    _showCenter = false;
    _showSuffix = false;
    EdgeInsets activePadding;

    if (suffixChild != null &&
        centerChild != null &&
        minWidthForAllThree <= availableWidth) {
      _showCenter = true;
      _showSuffix = true;
      activePadding = _padding;
    } else if (centerChild != null &&
        minWidthForLeadingCenter <= availableWidth) {
      _showCenter = true;
      activePadding = _padding;
    } else {
      activePadding = _compactPadding;
    }

    size = constraints.constrain(Size(availableWidth, constraints.maxHeight));

    final contentWidth = size.width - activePadding.horizontal;
    final verticalCenter = size.height / 2;

    if (_showCenter && _showSuffix) {
      final leadingX = activePadding.left;
      final suffixX = size.width - activePadding.right - suffixSize.width;
      final centerStartX = leadingX + leadingSize.width + _spacing;
      final centerEndX = suffixX - _spacing;
      final centerAvailableWidth = centerEndX - centerStartX;

      if (centerChild != null) {
        if (centerAvailableWidth < centerSize.width) {
          centerChild.layout(
            BoxConstraints(
              maxWidth: centerAvailableWidth,
              maxHeight: constraints.maxHeight,
            ),
            parentUsesSize: true,
          );
        }
      }

      final actualCenterWidth = centerChild?.size.width ?? 0;
      final centerX =
          centerStartX + (centerAvailableWidth - actualCenterWidth) / 2;

      if (leadingChild != null) {
        (leadingChild.parentData! as BoxParentData).offset = Offset(
          leadingX,
          verticalCenter - leadingSize.height / 2,
        );
      }

      if (centerChild != null) {
        (centerChild.parentData! as BoxParentData).offset = Offset(
          centerX,
          verticalCenter - centerChild.size.height / 2,
        );
      }

      if (suffixChild != null) {
        (suffixChild.parentData! as BoxParentData).offset = Offset(
          suffixX,
          verticalCenter - suffixSize.height / 2,
        );
      }
    } else if (_showCenter) {
      final leadingX = activePadding.left;
      final centerStartX = leadingX + leadingSize.width + _spacing;
      final centerEndX = size.width - activePadding.right;
      final centerAvailableWidth = centerEndX - centerStartX;

      if (centerChild != null) {
        if (centerAvailableWidth < centerSize.width) {
          centerChild.layout(
            BoxConstraints(
              maxWidth: centerAvailableWidth,
              maxHeight: constraints.maxHeight,
            ),
            parentUsesSize: true,
          );
        }
      }

      final actualCenterWidth = centerChild?.size.width ?? 0;
      final centerX =
          centerStartX + (centerAvailableWidth - actualCenterWidth) / 2;

      if (leadingChild != null) {
        (leadingChild.parentData! as BoxParentData).offset = Offset(
          leadingX,
          verticalCenter - leadingSize.height / 2,
        );
      }

      if (centerChild != null) {
        (centerChild.parentData! as BoxParentData).offset = Offset(
          centerX,
          verticalCenter - centerChild.size.height / 2,
        );
      }
    } else {
      final leadingX =
          activePadding.left + (contentWidth - leadingSize.width) / 2;

      if (leadingChild != null) {
        (leadingChild.parentData! as BoxParentData).offset = Offset(
          leadingX,
          verticalCenter - leadingSize.height / 2,
        );
      }
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final leadingChild = childForSlot(_EntrySlot.leading);
    final centerChild = childForSlot(_EntrySlot.center);
    final suffixChild = childForSlot(_EntrySlot.suffix);

    if (leadingChild != null) {
      final childParentData = leadingChild.parentData! as BoxParentData;
      context.paintChild(leadingChild, childParentData.offset + offset);
    }

    if (_showCenter && centerChild != null) {
      final childParentData = centerChild.parentData! as BoxParentData;
      context.paintChild(centerChild, childParentData.offset + offset);
    }

    if (_showSuffix && suffixChild != null) {
      final childParentData = suffixChild.parentData! as BoxParentData;
      context.paintChild(suffixChild, childParentData.offset + offset);
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final leadingChild = childForSlot(_EntrySlot.leading);
    final centerChild = childForSlot(_EntrySlot.center);
    final suffixChild = childForSlot(_EntrySlot.suffix);

    for (final child in [
      if (_showSuffix && suffixChild != null) suffixChild,
      if (_showCenter && centerChild != null) centerChild,
      ?leadingChild,
    ]) {
      final childParentData = child.parentData! as BoxParentData;
      final isHit = result.addWithPaintOffset(
        offset: childParentData.offset,
        position: position,
        hitTest: (result, transformed) {
          return child.hitTest(result, position: transformed);
        },
      );
      if (isHit) return true;
    }

    return false;
  }
}

class _FeedbackEntryNode extends StatelessWidget {
  const _FeedbackEntryNode({
    required this.name,
    required this.blueprint,
    required this.isDeprecated,
    this.isReference = false,
    this.pageId,
  });

  final String name;
  final EntryBlueprint blueprint;
  final bool isDeprecated;
  final bool isReference;
  final String? pageId;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(4),
      color: blueprint.color,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icones(blueprint.icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      decoration: isDeprecated
                          ? TextDecoration.lineThrough
                          : null,
                      decorationThickness: 2.8,
                      decorationColor: Theme.of(
                        context,
                      ).scaffoldBackgroundColor,
                      decorationStyle: TextDecorationStyle.wavy,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    blueprint.name,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      decoration: isDeprecated
                          ? TextDecoration.lineThrough
                          : null,
                      decorationThickness: 2.5,
                      decorationColor: Theme.of(
                        context,
                      ).scaffoldBackgroundColor,
                      decorationStyle: TextDecorationStyle.wavy,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderEntryNode extends StatelessWidget {
  const _PlaceholderEntryNode({
    required this.name,
    required this.blueprint,
    required this.isDeprecated,
    this.isReference = false,
  });

  final String name;
  final EntryBlueprint blueprint;
  final bool isDeprecated;
  final bool isReference;

  @override
  Widget build(BuildContext context) {
    final color = Surface.colorOf(context);

    return Surface(
      color: color,
      child: ColoredBox(
        color: color,
        child: DottedBorder(
          options: RoundedRectDottedBorderOptions(
            color: blueprint.color,
            strokeWidth: 2,
            dashPattern: const [5, 5],
            radius: const Radius.circular(6),
          ),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: _InnerEntryNode(
              name: name,
              blueprint: blueprint,
              color: blueprint.color,
              isDeprecated: isDeprecated,
              isReference: isReference,
            ),
          ),
        ),
      ),
    );
  }
}
