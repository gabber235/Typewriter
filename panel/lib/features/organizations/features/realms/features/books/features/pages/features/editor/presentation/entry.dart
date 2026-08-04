import "package:dotted_border/dotted_border.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

// Entry nodes use white as their established focus treatment so focus remains
// legible against every data-driven blueprint color.
const _entryFocusColor = Colors.white;

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

    final graphDrag = GraphDrag.maybeOf(context);
    useListenable(graphDrag?.draggingInsideGraph);

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
            graphDrag?.draggingInsideGraph.value = true;
          },
          feedback: HookBuilder(
            builder: (context) {
              useListenable(graphDrag?.draggingInsideGraph);
              return graphDrag?.draggingInsideGraph.value ?? false
                  ? SizedBox()
                  : _FeedbackEntryNode(
                      name: definition.name,
                      blueprint: definition.blueprint,
                      isDeprecated: isDeprecated,
                    );
            },
          ),
          childWhenDragging: graphDrag?.draggingInsideGraph.value ?? false
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
          color: context.colors.surfaceEmphasized,
          borderRadius: context.shapes.smallBorderRadius,
          child: Padding(
            padding: const EdgeInsets.all(7.0),
            child: InnerElementNode(
              name: definition.name,
              blueprint: definition.blueprint,
              color: context.colors.contentPrimary,
              isDeprecated: isDeprecated,
            ),
          ),
        ),
      );
    }

    return HookBuilder(
      builder: (context) {
        final backgroundColor = isDeprecated
            ? Color.alphaBlend(
                definition.blueprint.color.withValues(alpha: 0.7),
                Surface.colorOf(context),
              )
            : definition.blueprint.color;

        final adaptedBackgroundColor = useMemoized(
          () => backgroundColor.onBrightness(Brightness.dark),
          [backgroundColor],
        );

        final highlightColor = isFocused
            ? _entryFocusColor
            : adaptedBackgroundColor;

        return AnimatedOpacity(
          duration: 400.ms,
          curve: Curves.easeOutCubic,
          opacity: isAccepting ? 0.5 : 1,
          child: Material(
            borderRadius: context.shapes.mediumBorderRadius,
            color: backgroundColor,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCirc,
              decoration: BoxDecoration(
                borderRadius: context.shapes.smallBorderRadius,
                border: Border.all(
                  color: isSelected ? highlightColor : backgroundColor,
                  width: 3,
                ),
              ),
              margin: EdgeInsets.all(context.spacing.space1),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCirc,
                alignment: Alignment.topCenter,
                child: InnerElementNode(
                  name: definition.name,
                  blueprint: definition.blueprint,
                  color: highlightColor,
                  isDeprecated: isDeprecated,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  bool _isEntryDeprecated(EntryDefinition definition) {
    return definition.blueprint.hasModifier<DeprecatedModifier>();
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
  final ElementBlueprint blueprint;
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

        final highlightColor = isFocused ? _entryFocusColor : blueprint.color;

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
              borderRadius: context.shapes.smallBorderRadius,
            ),
            child: InnerElementNode(
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
      color: context.colors.danger,
      borderRadius: context.shapes.smallBorderRadius,
      child: AdaptiveElementLayout(
        padding: EdgeInsets.symmetric(
          horizontal: context.spacing.space3,
          vertical: context.spacing.space2,
        ),
        compactPadding: EdgeInsets.all(context.spacing.space1),
        leading: Icon(Icons.error, color: context.colors.onDanger, size: 18),
        center: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: Text(
                "Non-existent entry",
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: context.colors.onDanger,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Flexible(
              child: Text(
                "Entry reference is not an entry",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.colors.onDanger.withValues(alpha: 0.7),
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
            ? _entryFocusColor
            : backgroundColor.onBrightness(Brightness.dark);

        return Material(
          borderRadius: context.shapes.mediumBorderRadius,
          color: backgroundColor,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCirc,
            decoration: BoxDecoration(
              borderRadius: context.shapes.smallBorderRadius,
              border: Border.all(
                color: isSelected ? highlightColor : backgroundColor,
                width: 3,
              ),
            ),
            margin: EdgeInsets.all(context.spacing.space1),
            padding: EdgeInsets.all(context.spacing.space1),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCirc,
              alignment: Alignment.topCenter,
              child: AdaptiveElementLayout(
                padding: EdgeInsets.symmetric(
                  horizontal: context.spacing.space2,
                  vertical: context.spacing.space1,
                ),
                compactPadding: EdgeInsets.all(context.spacing.space1),
                leading: Icon(Icons.error, color: highlightColor, size: 18),
                center: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: highlightColor,
                          fontSize: 13,
                        ),
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

class _FeedbackEntryNode extends StatelessWidget {
  const _FeedbackEntryNode({
    required this.name,
    required this.blueprint,
    required this.isDeprecated,
    this.isReference = false,
    this.pageId,
  });

  final String name;
  final ElementBlueprint blueprint;
  final bool isDeprecated;
  final bool isReference;
  final String? pageId;

  @override
  Widget build(BuildContext context) {
    final foreground = blueprint.color.on(context);
    final secondaryForeground = foreground.withValues(alpha: 0.7);
    return Material(
      borderRadius: context.shapes.smallBorderRadius,
      color: blueprint.color,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.spacing.space3,
          vertical: context.spacing.space1,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icones(blueprint.icon, color: foreground, size: 18),
            SizedBox(width: context.spacing.space2),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: foreground,
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
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: secondaryForeground,
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
  final ElementBlueprint blueprint;
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
            child: InnerElementNode(
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
