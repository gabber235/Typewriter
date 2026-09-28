import "package:dotted_border/dotted_border.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Resolves and displays one projected tag inside the graph.
///
/// The node watches independently by record ID, allowing local inspector edits
/// and remote session revisions to update one graph node without owning graph
/// state. A missing tag leaves an empty footprint rather than displaying stale
/// content.
class TagNode extends HookConsumerWidget {
  const TagNode({required this.tagId, this.subjects, super.key});

  final skir.ResourceId tagId;
  final AsyncValue<AuthoringSubjectProjection>? subjects;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTag = ref.watch(projectedTagProvider(tagId));
    final organizationId = ref.watch(organizationIdProvider);
    final realmId = ref.watch(realmIdProvider);
    final resolvedSubjects =
        subjects ??
        (organizationId == null || realmId == null
            ? null
            : ref.watch(
                authoringSubjectsProvider(
                  AuthoringSubjectScope(
                    organizationId: organizationId,
                    realmId: realmId,
                    resources: {tagId: referenceResourceTypes.tag},
                  ),
                ),
              ));

    return asyncTag(
      name: "Tag",
      shrink: true,
      builder: (tag) {
        if (tag == null) return const SizedBox.shrink();
        return _TagNode(tag: tag, subjects: resolvedSubjects);
      },
      loading: (_) =>
          ShimmerBox.rectangle(width: double.infinity, height: double.infinity),
    );
  }
}

/// Adds selection, drag feedback, and inheritance drop behavior to a tag.
class _TagNode extends HookConsumerWidget {
  const _TagNode({required this.tag, required this.subjects});

  final Tag tag;
  final AsyncValue<AuthoringSubjectProjection>? subjects;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusNode = useFocusNode();

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
              subjects: subjects,
              isSelected: isSelected,
              isFocused: isFocused,
              isHovered: isHovered,
            );
            final identifier = TagIdentifier(tag.tagId);

            return Draggable<TagIdentifier>(
              data: identifier,
              onDragStarted: () => graphDrag?.beginDrag(identifier),
              onDragEnd: (_) => graphDrag?.endDrag(),
              feedback: HookBuilder(
                builder: (context) {
                  useListenable(graphDrag?.draggingInsideGraph);
                  return graphDrag?.draggingInsideGraph.value ?? false
                      ? SizedBox()
                      : SizedBox(
                          width: constraints.maxWidth,
                          height: constraints.maxHeight,
                          child: FeedbackTagNode(tag: tag, subjects: subjects),
                        );
                },
              ),
              childWhenDragging: graphDrag?.draggingInsideGraph.value ?? false
                  ? content
                  : const PlaceholderTagNode(),
              child: GraphDragTargetRegion(
                targetId: identifier.graphId,
                child: DragTarget<TagIdentifier>(
                  onWillAcceptWithDetails: (details) =>
                      tagParentDropAction(
                        ref.read(projectedTagsProvider).value ?? const [],
                        childId: tag.tagId,
                        parentId: details.data.tagId,
                      ) !=
                      null,
                  onAcceptWithDetails: (details) => ref
                      .read(canonicalTagsProvider.notifier)
                      .toggleTagParent(
                        ref.read(projectedTagsProvider).value ?? const [],
                        tag.tagId,
                        details.data.tagId,
                      ),
                  builder: (context, candidateData, rejectedData) {
                    final isDropTarget = candidateData.isNotEmpty;
                    final isRejected = rejectedData.isNotEmpty;
                    if (isRejected) {
                      return RejectedTagDropTarget(tag: tag);
                    }
                    if (isDropTarget) {
                      return _TagNodeContent(
                        tag: tag,
                        subjects: subjects,
                        isSelected: true,
                        isFocused: true,
                        isHovered: true,
                      );
                    }
                    return content;
                  },
                ),
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
    required this.subjects,
    required this.isSelected,
    required this.isFocused,
    required this.isHovered,
  });

  final Tag tag;
  final AsyncValue<AuthoringSubjectProjection>? subjects;
  final bool isSelected;
  final bool isFocused;
  final bool isHovered;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final backgroundColor = Color.alphaBlend(
      theme.colorScheme.primary.withValues(
        alpha: switch ((isHovered, isSelected)) {
          (false, false) => 0.2,
          (true, false) => 0.5,
          (false, true) => 1.0,
          (true, true) => 0.7,
        },
      ),
      Surface.colorOf(context),
    );

    return AnimatedContainer(
      duration: 100.ms,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: context.shapes.largeBorderRadius,
        border: Border.all(
          color: isFocused
              ? theme.brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black
              : isSelected
              ? Colors.transparent
              : theme.colorScheme.outline,
          width: 2,
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.space3,
        vertical: context.spacing.space2,
      ),
      child: Center(
        child: _TagRoleNode(tagId: tag.tagId, subjects: subjects),
      ),
    );
  }
}

class _TagRoleNode extends StatelessWidget {
  const _TagRoleNode({required this.tagId, required this.subjects});

  final skir.ResourceId tagId;
  final AsyncValue<AuthoringSubjectProjection>? subjects;

  @override
  Widget build(BuildContext context) {
    final projection = switch (subjects) {
      AsyncData(:final value) => value,
      _ => null,
    };
    if (projection == null) {
      if (subjects?.hasError ?? subjects == null) {
        return const Tooltip(
          message: "Tag presentation is unavailable",
          child: Icon(Icons.warning_rounded, size: 14),
        );
      }
      return ShimmerBox.rectangle(width: double.infinity, height: 20);
    }
    final subject = projection.subjects[tagId];
    final result = subject == null
        ? null
        : TypedAuthoringCodec(projection.catalog).subjectPresentation(
            subject,
            PresentationRole.graphNode,
            collections: projection.collections,
          );
    final diagnostics = result?.diagnostics ?? projection.diagnostics;
    final model =
        result?.valueOrNull?.model ??
        PresentationModel(
          catalog: projection.catalog.catalog,
          inputs: const {},
          root: PresentationNode(
            id: "tag.graph.node.diagnostic",
            element: DiagnosticElement(
              diagnostics.isEmpty
                  ? const [
                      TypeDiagnostic(
                        code: TypeDiagnosticCode.invalidPresentation,
                        message: "Tag presentation subject is unavailable",
                        pathPresent: false,
                      ),
                    ]
                  : diagnostics,
            ),
          ),
          diagnostics: diagnostics,
        );
    return ComposedEditor(model: model, readOnly: true);
  }
}

/// Visual representation shown while a tag is dragged outside the graph.
class FeedbackTagNode extends StatelessWidget {
  const FeedbackTagNode({required this.tag, required this.subjects, super.key});

  final Tag tag;
  final AsyncValue<AuthoringSubjectProjection>? subjects;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Opacity(
        opacity: 0.8,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.spacing.space3,
            vertical: context.spacing.space2,
          ),
          decoration: BoxDecoration(
            color: Surface.colorOf(context),
            borderRadius: context.shapes.largeBorderRadius,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: _TagRoleNode(tagId: tag.tagId, subjects: subjects),
          ),
        ),
      ),
    );
  }
}

/// Preserves the graph node footprint while its source is being dragged.
class PlaceholderTagNode extends StatelessWidget {
  const PlaceholderTagNode({super.key});

  @override
  Widget build(BuildContext context) {
    final surfaceColor = Theme.of(context).colorScheme.surfaceContainerLowest;

    return Surface(
      color: surfaceColor,
      child: ColoredBox(
        color: surfaceColor,
        child: DottedBorder(
          options: RoundedRectDottedBorderOptions(
            color: Theme.of(context).colorScheme.outline,
            strokeWidth: 2,
            dashPattern: const [5, 5],
            radius: const Radius.circular(12),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: context.shapes.largeBorderRadius,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: context.spacing.space3,
              vertical: context.spacing.space2,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}
