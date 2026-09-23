import "dart:async";

import "package:dotted_border/dotted_border.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

// Focus uses white because node colors come from the element catalog and can
// vary per definition. A stable focus color keeps selection legible.
const _entryFocusColor = Colors.white;

/// Renders the page entry union as a local node, a cross page reference, or a
/// visible degraded state when the target or its catalog definition is gone.
///
/// Interaction state is delegated to selection and graph drag infrastructure.
/// This widget only chooses the visual variant and passes its state to the
/// variant renderer.
class EntryNode extends HookConsumerWidget {
  const EntryNode({
    required this.pageId,
    required this.entry,
    this.subjects,
    super.key,
  });

  /// Page coordinator that owns mutations for a local entry definition.
  final String pageId;
  final PageEntry entry;
  final AsyncValue<AuthoringSubjectProjection>? subjects;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (entry) {
      DefinitionPageEntry(definition: final definition) => _DefinitionEntryNode(
        pageId: pageId,
        definition: definition,
        subjects: subjects,
      ),
      ReferencePageEntry(
        id: final id,
        name: final name,
        elementDefinition: final elementDefinition,
        pageId: final pageId,
      ) =>
        _ReferenceEntryNode(
          id: id,
          name: name,
          elementDefinition: elementDefinition,
          pageId: pageId,
          subjects: subjects,
        ),
      MissingElementDefinitionPageEntry(id: final id, name: final name) =>
        _MissingElementDefinitionEntryNode(id: id, name: name),
      UnavailableReferencePageEntry(id: final id, name: final name) =>
        _MissingElementDefinitionEntryNode(id: id, name: name),
      _ => const _NonexistentEntryNode(),
    };
  }
}

class _DefinitionEntryNode extends HookConsumerWidget {
  const _DefinitionEntryNode({
    required this.pageId,
    required this.definition,
    required this.subjects,
  });

  final String pageId;
  final EntryDefinition definition;
  final AsyncValue<AuthoringSubjectProjection>? subjects;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusNode = useFocusNode();

    final entryIdentifier = EntryIdentifier(
      definition.id,
      pageId: pageId,
      elementType: definition.elementDefinition.rootType,
    );
    final isDeprecated = _isEntryDeprecated(definition);

    final graphDrag = GraphDrag.maybeOf(context);
    useListenable(graphDrag?.draggingInsideGraph);
    final catalog = ref.watch(realmEditorCatalogProvider).value?.snapshot;
    final registry = catalog == null ? null : TypeRegistry(catalog.catalog);
    final organizationId = ref.watch(organizationIdProvider);
    final realmId = ref.watch(realmIdProvider);
    final entryIndex = organizationId == null || realmId == null
        ? null
        : ref.watch(realmEntryIndexProvider(organizationId, realmId)).value;

    return Selector(
      focusNode: focusNode,
      selectableId: entryIdentifier,
      builder: (isSelected, isFocused, isHovered) {
        final dragPayload = ref.entryDragPayload(entryIdentifier);
        return Draggable<EntryDragPayload>(
          data: dragPayload,
          onDragStarted: () => graphDrag?.beginDrag(entryIdentifier),
          onDragEnd: (_) => graphDrag?.endDrag(),
          feedback: HookBuilder(
            builder: (context) {
              useListenable(graphDrag?.draggingInsideGraph);
              return graphDrag?.draggingInsideGraph.value ?? false
                  ? SizedBox()
                  : _FeedbackEntryNode(
                      name: definition.name,
                      elementDefinition: definition.elementDefinition,
                      isDeprecated: isDeprecated,
                      body: subjects == null
                          ? null
                          : _EntryRoleNode(
                              entryId: entryIdentifier.referenceId,
                              subjects: subjects,
                            ),
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
                  subjects: subjects,
                )
              : _PlaceholderEntryNode(
                  name: definition.name,
                  elementDefinition: definition.elementDefinition,
                  isDeprecated: isDeprecated,
                ),
          child: GraphDragTargetRegion(
            targetId: entryIdentifier.graphId,
            child: DragTarget<Object>(
              onWillAcceptWithDetails: (details) =>
                  details.data is EntryDragPayload &&
                  registry != null &&
                  entryIndex != null &&
                  (details.data as EntryDragPayload).entries.every(
                    (source) => _referenceDropValues(
                      entryIndex,
                      source,
                      definition,
                      registry,
                    ).isNotEmpty,
                  ),
              onAcceptWithDetails: (details) {
                final source = details.data;
                if (source is! EntryDragPayload || entryIndex == null) return;
                unawaited(
                  _acceptReferenceDrop(
                    context,
                    ref,
                    entryIndex,
                    source.entries,
                    definition.id,
                    registry!,
                  ),
                );
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
                  subjects: subjects,
                );
              },
            ),
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
    required AsyncValue<AuthoringSubjectProjection>? subjects,
  }) {
    if (isRejecting) {
      return MouseRegion(
        cursor: SystemMouseCursors.forbidden,
        child: Material(
          color: context.colors.surfaceEmphasized,
          borderRadius: context.shapes.smallBorderRadius,
          child: Padding(
            padding: const EdgeInsets.all(7.0),
            child: subjects == null
                ? InnerElementNode(
                    name: definition.name,
                    elementDefinition: definition.elementDefinition,
                    color: context.colors.contentPrimary,
                    isDeprecated: isDeprecated,
                  )
                : _EntryRoleNode(
                    entryId: EntryIdentifier(definition.id).referenceId,
                    subjects: subjects,
                  ),
          ),
        ),
      );
    }

    return HookBuilder(
      builder: (context) {
        final backgroundColor = isDeprecated
            ? Color.alphaBlend(
                definition.elementDefinition.color.withValues(alpha: 0.7),
                Surface.colorOf(context),
              )
            : definition.elementDefinition.color;

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
                child: subjects == null
                    ? InnerElementNode(
                        name: definition.name,
                        elementDefinition: definition.elementDefinition,
                        color: highlightColor,
                        isDeprecated: isDeprecated,
                      )
                    : _EntryRoleNode(
                        entryId: EntryIdentifier(definition.id).referenceId,
                        subjects: subjects,
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  bool _isEntryDeprecated(EntryDefinition definition) {
    return definition.elementDefinition.isDeprecated;
  }
}

class _EntryRoleNode extends StatelessWidget {
  const _EntryRoleNode({required this.entryId, required this.subjects});

  final skir.ResourceId entryId;
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
          message: "Entry presentation is unavailable",
          child: Icon(Icons.warning_rounded, size: 14),
        );
      }
      return ShimmerBox.rectangle(width: double.infinity, height: 20);
    }
    final subject = projection.subjects[entryId];
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
            id: "entry.graph.node.diagnostic",
            element: DiagnosticElement(
              diagnostics.isEmpty
                  ? const [
                      TypeDiagnostic(
                        code: TypeDiagnosticCode.invalidPresentation,
                        message: "Entry presentation subject is unavailable",
                        pathPresent: false,
                      ),
                    ]
                  : diagnostics,
            ),
          ),
          diagnostics: diagnostics,
        );
    return IgnorePointer(child: ComposedEditor(model: model, readOnly: true));
  }
}

Future<void> _acceptReferenceDrop(
  BuildContext context,
  WidgetRef ref,
  Map<String, CachedPageEntry> entryIndex,
  List<EntryIdentifier> sourceIdentifiers,
  String targetId,
  TypeRegistry registry,
) async {
  final target = entryIndex[targetId];
  final sources = sourceIdentifiers
      .map((identifier) => entryIndex[identifier.id])
      .nonNulls
      .toList(growable: false);
  if (sources.length != sourceIdentifiers.length ||
      target == null ||
      sourceIdentifiers.any((source) => source.id == targetId)) {
    return;
  }
  final candidateMaps = [
    for (final source in sources)
      source.definition.referenceDropValues(
        _referenceIdentity(target.definition),
        registry,
      ),
  ];
  final commonPaths = candidateMaps
      .map((values) => values.keys.toSet())
      .reduce((left, right) => left.intersection(right));
  final candidates = {
    for (final path in commonPaths) path: candidateMaps.first[path]!,
  };
  if (candidates.isEmpty) return;
  final selected = candidates.length == 1
      ? candidates.entries.single
      : await showAdvancedDialog<MapEntry<DataPath, DataValue>>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Choose reference field"),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final candidate in candidates.entries)
                    ListTile(
                      dense: true,
                      title: Text(candidate.key.toString()),
                      onTap: () => Navigator.of(context).pop(candidate),
                    ),
                ],
              ),
            ),
          ),
        );
  if (selected == null || !context.mounted) return;
  await ref
      .withReadyPageElements(sources.first.pageId, (elements) {
        final organizationId = ref.read(organizationIdProvider);
        final realmId = ref.read(realmIdProvider);
        if (organizationId == null) throw ApiException.noOrganization();
        if (realmId == null) {
          throw ApiException.badRequest("No realm selected");
        }

        final currentIndex = ref
            .read(realmEntryIndexProvider(organizationId, realmId))
            .requireValue;
        final currentTarget = currentIndex[targetId];
        final currentSources = sourceIdentifiers
            .map((identifier) => currentIndex[identifier.id])
            .nonNulls
            .toList(growable: false);
        if (currentSources.length != sourceIdentifiers.length ||
            currentTarget == null) {
          throw ApiException.notFound("Entry");
        }
        if (currentSources.any(
          (source) => source.pageId != sources.first.pageId,
        )) {
          throw ApiException.conflict("The entry moved to another page");
        }
        final currentValues = {
          for (final source in currentSources)
            source.definition.id: source.definition.referenceDropValues(
              _referenceIdentity(currentTarget.definition),
              registry,
            )[selected.key],
        };
        if (currentValues.values.any((value) => value == null)) {
          throw ApiException.conflict("The reference field changed");
        }
        return elements.updateEntryFieldValues({
          for (final source in currentSources)
            source.definition.id: (
              path: selected.key,
              value: currentValues[source.definition.id]!,
            ),
        });
      })
      .catchApiExceptionsAndDisplay(context);
}

Map<DataPath, DataValue> _referenceDropValues(
  Map<String, CachedPageEntry> entryIndex,
  EntryIdentifier source,
  EntryDefinition target,
  TypeRegistry registry,
) {
  if (source.id == target.id) return const {};
  return entryIndex[source.id]?.definition.referenceDropValues(
        _referenceIdentity(target),
        registry,
      ) ??
      const {};
}

EntryIdentifier _referenceIdentity(EntryDefinition definition) =>
    EntryIdentifier(
      definition.id,
      elementType: definition.elementDefinition.rootType,
    );

class _ReferenceEntryNode extends HookConsumerWidget {
  const _ReferenceEntryNode({
    required this.id,
    required this.name,
    required this.elementDefinition,
    required this.pageId,
    required this.subjects,
  });

  final String id;
  final String name;
  final ElementDefinition elementDefinition;
  final String pageId;
  final AsyncValue<AuthoringSubjectProjection>? subjects;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusNode = useFocusNode();
    // TODO: Change to different type of identifier
    final entryIdentifier = EntryIdentifier(id);
    final isDeprecated = elementDefinition.isDeprecated;

    return Selector(
      focusNode: focusNode,
      selectableId: entryIdentifier,
      builder: (isSelected, isFocused, isHovered) {
        final backgroundColor = Color.alphaBlend(
          elementDefinition.color.withValues(alpha: 0.05),
          Surface.colorOf(context),
        );
        final frameColor = isFocused
            ? _entryFocusColor
            : isSelected
            ? elementDefinition.color
            : elementDefinition.color.withValues(alpha: 0);

        return LongPressDraggable<EntryIdentifier>(
          data: entryIdentifier,
          feedback: _FeedbackEntryNode(
            name: name,
            elementDefinition: elementDefinition,
            isDeprecated: isDeprecated,
            isReference: true,
            pageId: pageId,
          ),
          childWhenDragging: _PlaceholderEntryNode(
            name: name,
            elementDefinition: elementDefinition,
            isDeprecated: isDeprecated,
            isReference: true,
          ),
          child: AnimatedContainer(
            duration: 100.ms,
            decoration: BoxDecoration(
              color: backgroundColor,
              border: Border.all(color: frameColor, width: 3),
              borderRadius: context.shapes.smallBorderRadius,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final showNavigation = constraints.maxWidth >= 96;
                return Row(
                  children: [
                    Expanded(
                      child: _EntryRoleNode(
                        entryId: entryIdentifier.referenceId,
                        subjects: subjects,
                      ),
                    ),
                    if (showNavigation)
                      IconButton(
                        tooltip: "Open referenced entry",
                        onPressed: () => unawaited(
                          ref
                              .read(appRouterProvider)
                              .push(RouteRoute(pageId: pageId)),
                        ),
                        icon: const Icon(Icons.open_in_new, size: 18),
                      ),
                  ],
                );
              },
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
      child: AdaptiveLeadingLayout(
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
                style: Theme.of(context).textTheme.bodyMedium!
                    .copyWith(color: context.colors.onDanger, fontSize: 13),
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

class _MissingElementDefinitionEntryNode extends HookConsumerWidget {
  const _MissingElementDefinitionEntryNode({
    required this.id,
    required this.name,
  });

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
              child: AdaptiveLeadingLayout(
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
                        style: Theme.of(context).textTheme.bodyMedium!
                            .copyWith(color: highlightColor, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        "The element definition for this entry does not exist",
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
    required this.elementDefinition,
    required this.isDeprecated,
    this.body,
    this.isReference = false,
    this.pageId,
  });

  final String name;
  final ElementDefinition elementDefinition;
  final bool isDeprecated;
  final Widget? body;
  final bool isReference;
  final String? pageId;

  @override
  Widget build(BuildContext context) {
    final foreground = elementDefinition.color.on(context);
    final secondaryForeground = foreground.withValues(alpha: 0.7);
    return Material(
      borderRadius: context.shapes.smallBorderRadius,
      color: elementDefinition.color,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.spacing.space3,
          vertical: context.spacing.space1,
        ),
        child:
            body ??
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icones.value(
                  elementDefinition.icon,
                  color: foreground,
                  size: 18,
                ),
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
                          decorationColor: Theme.of(context)
                              .scaffoldBackgroundColor,
                          decorationStyle: TextDecorationStyle.wavy,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        elementDefinition.name,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: secondaryForeground,
                          fontSize: 11,
                          decoration: isDeprecated
                              ? TextDecoration.lineThrough
                              : null,
                          decorationThickness: 2.5,
                          decorationColor: Theme.of(context)
                              .scaffoldBackgroundColor,
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
    required this.elementDefinition,
    required this.isDeprecated,
    this.isReference = false,
  });

  final String name;
  final ElementDefinition elementDefinition;
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
            color: elementDefinition.color,
            strokeWidth: 2,
            dashPattern: const [5, 5],
            radius: const Radius.circular(6),
          ),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: InnerElementNode(
              name: name,
              elementDefinition: elementDefinition,
              color: elementDefinition.color,
              isDeprecated: isDeprecated,
              isReference: isReference,
            ),
          ),
        ),
      ),
    );
  }
}
