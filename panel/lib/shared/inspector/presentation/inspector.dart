import "package:typewriter_panel/typewriter_panel.dart";

part "inspector.g.dart";

/// Minimum desktop width and the lower bound used by keyboard resizing.
const double kInspectorMinSize = 200;
const double kInspectorDefaultSize = 400;
const double kInspectorMaxFactor = 3 / 8;

const double kInspectorResizeSmallStep = 10;
const double kInspectorResizeLargeStep = 50;

/// Owns the inspector width used by desktop layout and keyboard resizing.
///
/// The provider clamps requested sizes to [kInspectorMinSize]. It does not own
/// inspector visibility, selection, or the resize gesture itself.
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

/// Places the inspector beside or below [child] according to available width.
///
/// The scaffold does not own selection or focus.
class InspectorScaffold extends HookConsumerWidget {
  const InspectorScaffold({
    required this.child,
    this.margin = const EdgeInsets.only(top: 8, bottom: 8, right: 8),
    this.showInspector = true,
    super.key,
  });

  /// The label assistive technology reads for the inspector pane.
  static const semanticsLabel = "Inspector";

  final EdgeInsets margin;

  final Widget child;

  /// Whether the inspector appears beside [child]. A surface that already
  /// shows its inspector in the main area hides this one.
  final bool showInspector;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!showInspector) return child;
    return LayoutBuilder(
      builder: (context, constraints) =>
          constraints.maxWidth < 3 * kInspectorMinSize
          ? MobileInspector(child: child)
          : DesktopInspector(margin: margin, child: child),
    );
  }
}

/// Renders the inspector as a draggable bottom sheet on narrow layouts.
///
/// Closing the sheet clears selection. Resizing or opening the sheet never
/// changes focus on the underlying selectable surface.
class MobileInspector extends HookConsumerWidget {
  const MobileInspector({required this.child, super.key});
  final Widget child;

  static const _peek = 0.1;
  static const _full = 0.9;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasSelection = ref.watch(hasInspectableSelectionProvider);
    final controller = useDraggableScrollableController();

    // After layout the sheet's controller is attached. Reads the selection
    // when it fires: closing clears the selection.
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        final open = ref.read(hasInspectableSelectionProvider);
        controller.settleTo(context, open ? _peek : 0);
      });
      return null;
    }, [controller, hasSelection, MediaQuery.sizeOf(context).width]);

    final pad = motionTimeline(
      context,
      hasSelection ? MotionToken.surfaceIn : MotionToken.panelOut,
    );
    return Stack(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            return AnimatedPadding(
              duration: pad.duration,
              curve: pad.curve,
              padding: EdgeInsets.only(
                bottom: hasSelection ? constraints.maxHeight * _peek : 0,
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
          child: NotificationListener<ScrollEndNotification>(
            // A released drag settles with the same tokens, not the
            // framework's snap curve.
            onNotification: (_) {
              controller.settleNearest(context, const [0.0, _peek, _full]);
              return false;
            },
            child: DraggableScrollableSheet(
              initialChildSize: 0.0,
              minChildSize: 0.0,
              maxChildSize: _full,
              shouldCloseOnMinExtent: true,
              controller: controller,
              builder: (context, scrollController) {
                final surfaceColor = Theme.of(context).colorScheme.surface;

                return Semantics(
                  label: InspectorScaffold.semanticsLabel,
                  container: true,
                  explicitChildNodes: true,
                  child: Surface(
                    color: surfaceColor,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: context.shapes.mediumBorderRadius,
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
                                padding: EdgeInsets.only(
                                  left: context.spacing.space3,
                                  right: context.spacing.space3,
                                  bottom: context.spacing.space3,
                                ),
                                child: _InspectorContent(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// Renders the inspector as a resizable pane on wide layouts.
///
/// The pane is visible only when the inspector has a selection. Its size is
/// retained in [InspectorSize] and clamped to the current layout constraints.
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
    final hasSelection = ref.watch(hasInspectableSelectionProvider);
    final previousSelection = usePrevious(hasSelection);
    final size = ref.watch(inspectorSizeProvider);
    final isDragging = useState(false);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxSize = max<double>(
          0,
          (constraints.maxWidth * kInspectorMaxFactor).floorToDouble() - 1,
        );
        final minSize = min(kInspectorMinSize, maxSize);
        final effectiveSize = size.clamp(minSize, maxSize);
        // Arrival is surfaceIn, leave is panelOut; a drag still jumps.
        final arrive = motionTimeline(context, MotionToken.surfaceIn);
        final leave = motionTimeline(context, MotionToken.panelOut);
        final move = hasSelection ? arrive : leave;

        return Row(
          children: [
            Expanded(child: child),
            if (hasSelection)
              DragHandle(
                semanticLabel: "Inspector width",
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
                duration: leave.duration,
                curve: leave.curve,
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
                    const SingleActivator(
                      LogicalKeyboardKey.greater,
                      shift: true,
                    ),
                    const SingleActivator(LogicalKeyboardKey.period),
                    const SingleActivator(
                      LogicalKeyboardKey.period,
                      shift: true,
                    ),
                  ],
                  priority: -1,
                  run: ActionRun.press((ref) {
                    final step = HardwareKeyboard.instance.isShiftPressed
                        ? kInspectorResizeLargeStep
                        : kInspectorResizeSmallStep;
                    final newSize = (effectiveSize - step).clamp(
                      max<double>(0.0, minSize),
                      maxSize,
                    );
                    ref.read(inspectorSizeProvider.notifier).size(newSize);
                  }),
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
                    const SingleActivator(
                      LogicalKeyboardKey.comma,
                      shift: true,
                    ),
                  ],
                  priority: -1,
                  run: ActionRun.press((ref) {
                    final step = HardwareKeyboard.instance.isShiftPressed
                        ? kInspectorResizeLargeStep
                        : kInspectorResizeSmallStep;
                    final newSize = (effectiveSize + step).clamp(
                      max<double>(0.0, minSize),
                      maxSize,
                    );
                    ref.read(inspectorSizeProvider.notifier).size(newSize);
                  }),
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
                padding: EdgeInsets.only(
                  top: margin.top,
                  bottom: margin.bottom,
                ),
                child: AnimatedPadding(
                  duration: move.duration,
                  curve: move.curve,
                  padding: hasSelection
                      ? EdgeInsets.only(left: margin.left, right: margin.right)
                      : EdgeInsets.zero,
                  child: Semantics(
                    label: InspectorScaffold.semanticsLabel,
                    container: true,
                    explicitChildNodes: true,
                    child: Pane(
                      id: "inspector",
                      borderRadius: context.shapes.largeBorderRadius,
                      enabled: hasSelection,
                      margin: null,
                      child: Section(
                        margin: EdgeInsets.zero,
                        child: AnimatedContainer(
                          duration: isDragging.value
                              ? Duration.zero
                              : move.duration,
                          curve: move.curve,
                          width: hasSelection ? effectiveSize : 0,
                          height: double.infinity,
                          child: ClipRect(
                            child: OverflowBox(
                              alignment: Alignment.centerLeft,
                              minWidth: effectiveSize,
                              maxWidth: effectiveSize,
                              child: SingleChildScrollView(
                                child: Padding(
                                  padding: EdgeInsets.all(
                                    context.spacing.space3,
                                  ),
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
            ),
          ],
        );
      },
    );
  }
}

class _InspectorContent extends HookConsumerWidget {
  const _InspectorContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Add shimmer when loading.
    final session = ref.watch(inspectionSessionProvider);

    final selection = ref.watch(selectionProvider);
    return PresentationEnvironment(
      host: HostContext(selectionCount: selection.length)
          .within(PresentationEnvironment.hostOf(context)),
      child: ListenableBuilder(
        listenable: session,
        builder: (context, _) {
          final hosts = session.hosts;
          final body = session.body;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: context.spacing.space3,
            children: [
              ?body,
              for (var index = 0; index < hosts.length; index++)
                PortablePresentationRenderer(
                  key: ValueKey((selection, index)),
                  host: hosts[index],
                ),
              const SizedBox(height: 5),
              InspectorOperations(),
              const SizedBox(height: 30),
            ],
          );
        },
      ),
    );
  }
}

/// Shows operations available for every currently inspected selectable.
///
/// Operations use the inspected selection, not the focused selectable. An
/// operation is omitted unless its capability contract accepts the full
/// selection.
class InspectorOperations extends HookConsumerWidget {
  const InspectorOperations({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(inspectedSelectionProvider).value ?? [];
    final operations = selected.isEmpty
        ? const <SelectionOperation>[]
        : SelectionOperationsRoot.of(context)
              .operationsFor(ref, selected)
              .where((operation) => operation.showInInspector)
              .toList();

    if (operations.isEmpty) return const SizedBox.shrink();

    // The sections and order of the context menu; the pane keeps one filled
    // button at most.
    final sections = operations.sections;
    final emphases = sections.flattened.shownEmphases;
    var index = 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: context.spacing.space3,
      children: [
        const SectionTitle(title: "Operations"),
        for (final (number, section) in sections.indexed) ...[
          if (number > 0) const Separator(),
          for (final operation in section)
            operation.inspectorButton(selected, emphasis: emphases[index++]),
        ],
      ],
    );
  }
}
