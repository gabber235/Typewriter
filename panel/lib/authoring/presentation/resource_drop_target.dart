import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "resource_drop_target.freezed.dart";

/// How a hovered drop target looks: whether the drag would land, and what
/// it would do.
@freezed
abstract class ResourceDropHover with _$ResourceDropHover {
  const factory ResourceDropHover({
    @Default(false) bool accepted,
    @Default(false) bool rejected,

    /// The hover hint of the single offer, or a count of the offers.
    String? hint,
  }) = _ResourceDropHover;

  const ResourceDropHover._();

  static const idle = ResourceDropHover();

  /// The hint for [offers]: the offer's own hint, or how many there are.
  static String? hintFor(List<DropOffer>? offers) => switch (offers) {
    null || [] => null,
    [final offer] => offer.hint,
    _ => "${offers.length} options",
  };
}

/// Accepts dragged resources of one authoring scope and runs what they offer
/// at the most specific destination: one offer runs directly, several open
/// the drop chooser at the pointer.
///
/// Candidates come from [dropCandidatesProvider], fetched once when the drag
/// starts, so hovering costs no round trips. Link field and group offers need
/// no candidates and are known at once. While candidates load, a target whose
/// resource destinations might still offer an operation stays neutral and
/// accepts; a target with nothing to offer refuses, so the targets around it
/// receive the drag.
///
/// Flutter delivers a drop only to the target that accepted the hover. A
/// target that turns out to have nothing to offer hands the drop to the
/// nearest enclosing [ResourceDropTarget], before claiming it when its offers
/// are known, or after its candidates arrive otherwise. Acceptance is claimed
/// from the gesture once, before any asynchronous work, and only when some
/// target in that chain may still offer something.
class ResourceDropTarget extends ConsumerStatefulWidget {
  const ResourceDropTarget({
    required this.scope,
    required this.destinations,
    required this.builder,
    this.canMutate,
    super.key,
  });

  /// A target for exactly one destination.
  ResourceDropTarget.at({
    required AuthoringScope scope,
    required DropDestination destination,
    required Widget Function(BuildContext context, ResourceDropHover hover)
    builder,
    bool Function()? canMutate,
    Key? key,
  }) : this(
         scope: scope,
         destinations: (_) => [destination],
         builder: builder,
         canMutate: canMutate,
         key: key,
       );

  final AuthoringScope scope;

  /// Destinations at a global pointer position, most specific first.
  final List<DropDestination> Function(Offset globalPosition) destinations;

  /// Whether the view may edit. Defaults to the Realm editing state.
  final bool Function()? canMutate;
  final Widget Function(BuildContext context, ResourceDropHover hover) builder;

  @override
  ConsumerState<ResourceDropTarget> createState() => _ResourceDropTargetState();
}

class _ResourceDropTargetState extends ConsumerState<ResourceDropTarget> {
  GraphDragPayload<ResourceDrag>? _hovered;

  void _observeHover(GraphDragPayload<ResourceDrag>? value) {
    if (identical(_hovered, value)) return;
    _hovered?.removeListener(_refreshHover);
    _hovered = value;
    value?.addListener(_refreshHover);
  }

  void _refreshHover() {
    if (!mounted) return;
    setState(() {
      final current = _hovered;
      if (current != null && !current.canHover) _observeHover(null);
    });
  }

  @override
  void dispose() {
    _hovered?.removeListener(_refreshHover);
    super.dispose();
  }

  bool _canMutate() =>
      mounted &&
      (widget.canMutate?.call() ??
          ref.read(realmEditingProvider(widget.scope)).state.available);

  bool _eligible(GraphDragPayload<ResourceDrag> offered) =>
      offered.canHover && offered.value.scope == widget.scope && _canMutate();

  /// Offers at the pointer, or null while candidates load and a resource
  /// destination might still offer an operation. Failed candidates still
  /// allow link and group drops, which need no round trip.
  List<DropOffer>? _offers(
    AsyncValue<DropCandidateIndex> candidates,
    AuthoringDocument? document,
    GraphDragPayload<ResourceDrag> offered,
    Offset pointer,
  ) {
    if (document == null) return null;
    final destinations = widget.destinations(pointer);
    return switch (candidates) {
      AsyncValue(:final value?) => value.offersFor(destinations, document),
      AsyncValue(hasError: true) => DropCandidateIndex(
        drag: offered.value,
        byOperation: const {},
      ).offersFor(destinations, document),
      _ => offered.value.pendingOffersFor(destinations, document),
    };
  }

  List<DropOffer>? _readOffers(
    GraphDragPayload<ResourceDrag> offered,
    Offset pointer,
  ) => _offers(
    ref.read(dropCandidatesProvider(offered.value)),
    ref.read(workingAuthoringDocumentProvider(widget.scope)).value,
    offered,
    pointer,
  );

  _ResourceDropTargetState? get _enclosing => context
      .getInheritedWidgetOfExactType<_EnclosingResourceDropTarget>()
      ?.target;

  /// Accepts a drop Flutter delivered to this target, or hands it to the
  /// enclosing target when this one has nothing to offer. Claims the gesture
  /// only while an offer is known or may still arrive, and returns whether
  /// this target claimed it.
  bool _accept(GraphDragPayload<ResourceDrag> offered, Offset pointer) {
    final offers = _eligible(offered)
        ? _readOffers(offered, pointer)
        : const <DropOffer>[];
    if (offers != null && offers.isEmpty) {
      _enclosing?._accept(offered, pointer);
      return false;
    }
    if (!offered.claim()) return false;
    // Claim is the handoff. Do not check hover phase after an await.
    unawaited(_dropClaimed(offered, pointer));
    return true;
  }

  Future<void> _dropClaimed(
    GraphDragPayload<ResourceDrag> offered,
    Offset pointer,
  ) async {
    try {
      if (!await _drop(offered.value, pointer)) {
        await _enclosing?._dropFallback(offered.value, pointer);
      }
    } finally {
      if (mounted && identical(_hovered, offered)) {
        setState(() => _observeHover(null));
      }
    }
  }

  /// Runs what this target offers for a drop an inner target claimed but
  /// could not use, or hands it further out.
  Future<void> _dropFallback(ResourceDrag drag, Offset pointer) async {
    if (!mounted) return;
    if (drag.scope == widget.scope && _canMutate()) {
      if (await _drop(drag, pointer)) return;
    }
    if (mounted) await _enclosing?._dropFallback(drag, pointer);
  }

  /// Runs what [drag] offers at [pointer] once its candidates are known.
  /// Returns false when this target offers nothing.
  Future<bool> _drop(ResourceDrag drag, Offset pointer) async {
    final destinations = widget.destinations(pointer);
    final candidates = ref.listenManual(
      dropCandidatesProvider(drag),
      (_, _) {},
    );
    try {
      DropCandidateIndex index;
      try {
        index = await ref.read(dropCandidatesProvider(drag).future);
      } on Object {
        index = DropCandidateIndex(drag: drag, byOperation: const {});
      }
      if (!mounted) return true;
      final document = ref
          .read(workingAuthoringDocumentProvider(widget.scope))
          .value;
      if (document == null || !_canMutate()) return true;
      final offers = index.offersFor(destinations, document);
      if (offers.isEmpty) return false;
      final chosen = switch (offers) {
        [final offer] => offer,
        _ => await showDropChooser(context, pointer, offers),
      };
      if (chosen == null || !mounted) return true;
      await chosen.run(ref, drag, canMutate: _canMutate);
      return true;
    } finally {
      candidates.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hovered = _hovered;
    List<DropOffer>? offers;
    if (hovered != null && _eligible(hovered)) {
      offers = _offers(
        ref.watch(dropCandidatesProvider(hovered.value)),
        ref.watch(workingAuthoringDocumentProvider(widget.scope)).value,
        hovered,
        hovered.pointer ?? Offset.zero,
      );
    }

    return _EnclosingResourceDropTarget(
      target: this,
      child: _buildTarget(offers),
    );
  }

  Widget _buildTarget(List<DropOffer>? offers) =>
      DragTarget<GraphDragPayload<ResourceDrag>>(
        onWillAcceptWithDetails: (details) {
          final offered = details.data;
          if (!_eligible(offered)) return false;
          if (!identical(_hovered, offered)) {
            setState(() => _observeHover(offered));
          }
          final known = _readOffers(offered, offered.pointer ?? details.offset);
          return known == null || known.isNotEmpty;
        },
        onLeave: (offered) {
          if (mounted && identical(_hovered, offered)) {
            setState(() => _observeHover(null));
          }
        },
        onAcceptWithDetails: (details) {
          final offered = details.data;
          if (!_accept(offered, offered.pointer ?? details.offset) &&
              identical(_hovered, offered)) {
            setState(() => _observeHover(null));
          }
        },
        builder: (context, accepted, rejected) => HookBuilder(
          builder: (context) {
            useListenable(
              Listenable.merge([
                ...accepted.nonNulls,
                ...rejected.whereType<GraphDragPayload<ResourceDrag>>(),
              ]),
            );
            final accepting = accepted.nonNulls.any(
              (offered) => identical(_hovered, offered) && _eligible(offered),
            );
            return widget.builder(
              context,
              ResourceDropHover(
                accepted: accepting && offers != null && offers.isNotEmpty,
                rejected:
                    rejected.whereType<GraphDragPayload<ResourceDrag>>().any(
                      (offered) => offered.canHover,
                    ) ||
                    accepting && offers != null && offers.isEmpty,
                hint: accepting ? ResourceDropHover.hintFor(offers) : null,
              ),
            );
          },
        ),
      );
}

/// Lets a nested [ResourceDropTarget] hand drops it cannot use to the target
/// around it.
class _EnclosingResourceDropTarget extends InheritedWidget {
  const _EnclosingResourceDropTarget({
    required this.target,
    required super.child,
  });

  final _ResourceDropTargetState target;

  @override
  bool updateShouldNotify(_EnclosingResourceDropTarget oldWidget) =>
      target != oldWidget.target;
}

/// Outlines a drop target that is not a resource item, and shows the hint of
/// what a drop would do.
class ResourceDropHighlight extends StatelessWidget {
  const ResourceDropHighlight({
    required this.hover,
    required this.child,
    super.key,
  });

  final ResourceDropHover hover;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: hover.hint,
      child: Stack(
        fit: StackFit.passthrough,
        clipBehavior: Clip.none,
        children: [
          DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              borderRadius: context.shapes.mediumBorderRadius,
              border: hover.accepted || hover.rejected
                  ? Border.all(
                      width: 2,
                      color: hover.accepted ? scheme.primary : scheme.error,
                    )
                  : null,
            ),
            child: child,
          ),
          if (hover.hint case final hint? when hover.accepted)
            PositionedDirectional(
              top: context.spacing.space1,
              end: context.spacing.space1,
              child: IgnorePointer(child: DropHintChip(hint: hint)),
            ),
        ],
      ),
    );
  }
}

/// Says what releasing a dragged resource here would do.
class DropHintChip extends StatelessWidget {
  const DropHintChip({required this.hint, super.key});

  final String hint;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.inverseSurface,
      borderRadius: context.shapes.smallBorderRadius,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.spacing.space2,
          vertical: context.spacing.space1,
        ),
        child: Text(
          hint,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: scheme.onInverseSurface),
        ),
      ),
    );
  }
}

/// Lets a person pick one of several drop offers. Arrow keys move between
/// offers, Enter runs one and Escape cancels.
class DropChooser extends StatelessWidget {
  const DropChooser({required this.offers, required this.onChoose, super.key});

  final List<DropOffer> offers;

  /// Receives the chosen offer, or null to cancel.
  final ValueChanged<DropOffer?> onChoose;

  @override
  Widget build(BuildContext context) => Shortcuts(
    // Web platform defaults map arrow keys to scrolling, so the chooser binds
    // them to focus traversal itself.
    shortcuts: const {
      SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
      SingleActivator(LogicalKeyboardKey.arrowDown): DirectionalFocusIntent(
        TraversalDirection.down,
      ),
      SingleActivator(LogicalKeyboardKey.arrowUp): DirectionalFocusIntent(
        TraversalDirection.up,
      ),
    },
    child: Actions(
      actions: {
        DismissIntent: CallbackAction<DismissIntent>(
          onInvoke: (_) {
            onChoose(null);
            return null;
          },
        ),
      },
      child: FocusTraversalGroup(
        child: Material(
          elevation: 8,
          borderRadius: context.shapes.mediumBorderRadius,
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 200, maxWidth: 320),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    context.spacing.space3,
                    context.spacing.space2,
                    context.spacing.space3,
                    context.spacing.space1,
                  ),
                  child: Text(
                    "Drop to",
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(color: context.colors.contentDisabled),
                  ),
                ),
                for (final (index, offer) in offers.indexed)
                  MenuItemButton(
                    autofocus: index == 0,
                    leadingIcon: offer.icon.isEmpty
                        ? null
                        : Icones(offer.icon, size: 18),
                    onPressed: () => onChoose(offer),
                    child: Text(offer.label),
                  ),
                SizedBox(height: context.spacing.space1),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Shows the [DropChooser] at the global [position] and returns the chosen
/// offer, or null when dismissed.
Future<DropOffer?> showDropChooser(
  BuildContext context,
  Offset position,
  List<DropOffer> offers,
) => showGeneralDialog<DropOffer>(
  context: context,
  barrierDismissible: true,
  barrierLabel: "Cancel drop",
  barrierColor: Colors.transparent,
  pageBuilder: (dialogContext, _, _) => CustomSingleChildLayout(
    delegate: _DropChooserLayout(position),
    child: DropChooser(
      offers: offers,
      onChoose: (offer) => Navigator.of(dialogContext).pop(offer),
    ),
  ),
);

/// Places the chooser at the pointer, kept inside the screen.
class _DropChooserLayout extends SingleChildLayoutDelegate {
  const _DropChooserLayout(this.position);

  final Offset position;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) => Offset(
    position.dx.clamp(0, max(0, size.width - childSize.width)),
    position.dy.clamp(0, max(0, size.height - childSize.height)),
  );

  @override
  bool shouldRelayout(_DropChooserLayout oldDelegate) =>
      position != oldDelegate.position;
}

/// The avatar of a dragged resource outside a graph: its name, and how many
/// resources the drag carries.
class ResourceDragFeedback extends StatelessWidget {
  const ResourceDragFeedback({
    required this.label,
    required this.count,
    this.icon,
    this.accent,
    super.key,
  });

  final String label;
  final int count;
  final skir.Icon? icon;
  final Color? accent;

  @override
  Widget build(BuildContext context) => Material(
    elevation: 6,
    borderRadius: context.shapes.mediumBorderRadius,
    child: Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.space3,
        vertical: context.spacing.space2,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: context.spacing.space2,
        children: [
          ResourceIcon(
            icon: icon,
            color: accent ?? context.colors.contentDisabled,
            size: 18,
          ),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          if (count > 1) Badge(label: Text("$count"), backgroundColor: accent),
        ],
      ),
    ),
  );
}

/// Makes [child] draggable as [drag], and keeps the drag's candidates
/// fetched from drag start to drag end. Inside a graph the graph shows the
/// moving node; elsewhere [feedback], or a [ResourceDragFeedback], follows
/// the pointer.
class ResourceDragSource extends HookConsumerWidget {
  const ResourceDragSource({
    required this.drag,
    required this.enabled,
    required this.child,
    this.feedback,
    super.key,
  });

  final ResourceDrag drag;
  final bool enabled;
  final Widget child;
  final WidgetBuilder? feedback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dragSource = useGraphDragSource(context, drag);
    final offered = dragSource.payload;
    useListenable(dragSource.state);
    useListenable(offered);
    final candidates = useRef<ProviderSubscription<Object?>?>(null);
    useEffect(
      () =>
          () => candidates.value?.close(),
      const [],
    );
    // A drag cannot outlive the source's mutation access.
    useEffect(() {
      if (enabled || !offered.isDragging) return null;
      // Ending notifies the graph, which must not rebuild during this build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (offered.isDragging) dragSource.end(offered);
      });
      return null;
    }, [enabled]);
    if (!enabled) return child;
    final themes = InheritedTheme.capture(
      from: context,
      to: Overlay.of(context, rootOverlay: true).context,
    );
    final providers = ProviderScope.containerOf(context);
    return Draggable<GraphDragPayload<ResourceDrag>>(
      data: offered,
      key: ObjectKey(offered),
      maxSimultaneousDrags: 1,
      dragAnchorStrategy: (widget, context, position) =>
          dragSource.anchor(offered, widget, context, position),
      rootOverlay: true,
      onDragStarted: () {
        candidates.value?.close();
        candidates.value = ref.listenManual(
          dropCandidatesProvider(offered.value),
          (_, _) {},
        );
        dragSource.begin(offered);
      },
      onDragUpdate: (details) => dragSource.update(offered, details),
      onDragEnd: (_) {
        dragSource.end(offered);
        candidates.value?.close();
        candidates.value = null;
      },
      feedback: HookBuilder(
        builder: (context) {
          useListenable(dragSource.state);
          useListenable(offered);
          if (!dragSource.showFeedback(offered)) {
            return const SizedBox.shrink();
          }
          return themes.wrap(
            UncontrolledProviderScope(
              container: providers,
              child: ExcludeFocus(
                child:
                    feedback?.call(context) ??
                    Consumer(
                      builder: (context, ref, _) {
                        final appearance = ref.watch(
                          resourceAppearanceProvider(
                            drag.scope,
                            drag.primary.resourceId,
                          ),
                        );
                        return ResourceDragFeedback(
                          label: appearance?.label ?? "Resource",
                          icon: appearance?.icon,
                          accent: appearance?.accentColor,
                          count: drag.subjects.length,
                        );
                      },
                    ),
              ),
            ),
          );
        },
      ),
      childWhenDragging: Opacity(opacity: .45, child: child),
      child: child,
    );
  }
}
