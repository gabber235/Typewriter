part of "../portable_presentation_renderer.dart";

enum PortableDiagnosticNodeKind { control, header, source }

@freezed
abstract class PortableDiagnosticObservation
    with _$PortableDiagnosticObservation {
  const factory PortableDiagnosticObservation({
    required PortableDiagnosticTarget target,
    required skir.DataValue? value,
  }) = _PortableDiagnosticObservation;
  const PortableDiagnosticObservation._();

  PortableDiagnosticObservation? resolve(PortableDiagnosticTarget descendant) {
    if (!descendant.isAtOrBelow(target)) return null;
    return PortableDiagnosticObservation(
      target: descendant,
      value: value?.editorValueAt(
        skir.ValuePath(
          segments: descendant.path.segments.skip(target.path.segments.length),
        ),
      ),
    );
  }
}

@freezed
abstract class PortableDiagnosticNode with _$PortableDiagnosticNode {
  const factory PortableDiagnosticNode({
    required PortableDiagnosticNodeKind kind,
    Object? parent,
    @Default([]) List<PortableDiagnosticObservation> observations,
    @Default([]) List<PortablePresentationDiagnostic> diagnostics,
    @Default(PortableDiagnosticFallback.presentation)
    PortableDiagnosticFallback diagnosticFallback,
  }) = _PortableDiagnosticNode;
  const PortableDiagnosticNode._();

  PortableDiagnosticTarget? get target => observations.firstOrNull?.target;
}

@freezed
abstract class PortableDiagnosticPresentation
    with _$PortableDiagnosticPresentation {
  const factory PortableDiagnosticPresentation({
    @Default({}) Map<Object, PortableDiagnosticNode> nodes,
  }) = _PortableDiagnosticPresentation;
  const PortableDiagnosticPresentation._();

  Iterable<Object> headerAncestors(Object id) sync* {
    var parent = nodes[id]?.parent;
    while (parent != null) {
      final node = nodes[parent];
      if (node == null) return;
      if (node.kind == PortableDiagnosticNodeKind.header) yield parent;
      parent = node.parent;
    }
  }

  PortableDiagnosticObservation? resolve(PortableDiagnosticTarget target) {
    final sources = [
      for (final node in nodes.values)
        if (node.kind == PortableDiagnosticNodeKind.source)
          ...node.observations,
    ];
    final controls = [
      for (final node in nodes.values)
        if (node.kind != PortableDiagnosticNodeKind.source)
          ...node.observations,
    ];
    return sources.resolveDiagnosticTarget(target) ??
        controls.resolveDiagnosticTarget(target);
  }
}

extension _PortableDiagnosticObservationLookup
    on List<PortableDiagnosticObservation> {
  PortableDiagnosticObservation? resolveDiagnosticTarget(
    PortableDiagnosticTarget target,
  ) {
    final candidates = where((item) => target.isAtOrBelow(item.target)).toList()
      ..sort(
        (a, b) => b.target.path.segments.length.compareTo(
          a.target.path.segments.length,
        ),
      );
    return candidates.firstOrNull?.resolve(target);
  }
}

extension _PortableDocumentDiagnosticObservations
    on PortablePresentationDocument {
  List<PortableDiagnosticObservation> get diagnosticObservations => [
    for (final entry in bindings.entries)
      PortableDiagnosticObservation(
        target: entry.value.location == null
            ? PortableDiagnosticTarget.binding(
                skir.BindingRef(bindingId: entry.key, path: editorRootPath),
              )
            : PortableDiagnosticTarget.value(entry.value.location!),
        value: entry.value.value,
      ),
  ];
}

/// Owns mounted diagnostic membership. Updates are visible in [snapshot]
/// immediately, while listener notifications coalesce after the current frame.
/// Operation and document state remain with their existing owners.
class PortableDiagnosticTree extends ChangeNotifier {
  final _nodes = <Object, PortableDiagnosticNode>{};
  bool _scheduled = false;
  bool _closed = false;
  PortableDiagnosticPresentation get snapshot =>
      PortableDiagnosticPresentation(nodes: Map.unmodifiable(_nodes));

  void update(Object id, PortableDiagnosticNode node) {
    if (_closed || _nodes[id] == node) return;
    _nodes[id] = node;
    _schedule();
  }

  void remove(Object id) {
    if (_closed || _nodes.remove(id) == null) return;
    _schedule();
  }

  void _schedule() {
    if (_closed || _scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (!_closed) notifyListeners();
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  void dispose() {
    _closed = true;
    _nodes.clear();
    super.dispose();
  }
}

class PortableDiagnosticScope extends InheritedWidget {
  const PortableDiagnosticScope({
    required this.tree,
    required this.placement,
    required super.child,
    super.key,
  });
  final PortableDiagnosticTree tree;
  final PortableDiagnosticPlacement placement;
  static PortableDiagnosticScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PortableDiagnosticScope>();

  static PortableDiagnosticScope of(BuildContext context) => maybeOf(context)!;
  @override
  bool updateShouldNotify(PortableDiagnosticScope old) =>
      !identical(tree, old.tree) || placement != old.placement;
}

class PortableDiagnosticSource extends StatelessWidget {
  const PortableDiagnosticSource({
    required this.diagnostics,
    required this.observations,
    required this.child,
    this.diagnosticFallback = PortableDiagnosticFallback.presentation,
    super.key,
  });
  final List<PortablePresentationDiagnostic> diagnostics;
  final PortableDiagnosticFallback diagnosticFallback;
  final List<PortableDiagnosticObservation> observations;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PortableDiagnosticAnchor(
      node: PortableDiagnosticNode(
        kind: PortableDiagnosticNodeKind.source,
        diagnostics: diagnostics,
        diagnosticFallback: diagnosticFallback,
        observations: observations,
      ),
      builder: (context, summary, owner) => child,
    );
  }
}

/// Owns diagnostic anchors for a passive copy rendered outside its editor.
/// Observes existing operation results without retiring or disposing them.
class PortableDiagnosticPreview extends HookWidget {
  const PortableDiagnosticPreview({
    required this.operations,
    required this.child,
    super.key,
  });

  final PortableOperationResults operations;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tree = useMemoized(PortableDiagnosticTree.new);
    useEffect(() => tree.dispose, [tree]);
    useListenable(tree);
    useListenable(operations);
    final presentation = tree.snapshot;
    return PortableDiagnosticScope(
      tree: tree,
      placement: _useRevealedPlacement(
        PortableDiagnosticPlacement.route(
          diagnostics: const [],
          outcomes: operations.value.outcomes.values,
          presentation: presentation,
        ),
        presentation,
      ),
      child: child,
    );
  }
}

/// Owns presentation membership for either public renderer entry point.
/// Operation results stay with the caller and are never recreated by scope copies.
class _PortableDiagnosticBoundary extends HookWidget {
  const _PortableDiagnosticBoundary({
    required this.operations,
    required this.observations,
    required this.child,
    this.diagnostics = const [],
    this.diagnosticFallback = PortableDiagnosticFallback.presentation,
    super.key,
  });

  final PortableOperationResults operations;
  final List<PortableDiagnosticObservation> observations;
  final List<PortablePresentationDiagnostic> diagnostics;
  final PortableDiagnosticFallback diagnosticFallback;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tree = useMemoized(PortableDiagnosticTree.new);
    useEffect(() => tree.dispose, [tree]);
    useListenable(operations);
    useListenable(tree);
    final presentation = tree.snapshot;
    final obsolete = useMemoized(
      () => operations.value.obsoleteRequests(
        (target) =>
            observations.resolveDiagnosticTarget(target) ??
            presentation.resolve(target),
      ),
      [observations, operations.value, presentation],
    );
    useEffect(() {
      var active = true;
      if (obsolete.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (active) operations.retire(obsolete);
        });
      }
      return () {
        active = false;
      };
    }, [operations, obsolete]);
    final placement = useMemoized(
      () => PortableDiagnosticPlacement.route(
        diagnostics: diagnostics,
        diagnosticFallback: diagnosticFallback,
        outcomes: operations.value.outcomes.values.where(
          (outcome) => !obsolete.contains(outcome.request),
        ),
        presentation: presentation,
      ),
      [
        diagnostics,
        diagnosticFallback,
        operations.value,
        presentation,
        obsolete,
      ],
    );
    return PortableDiagnosticScope(
      tree: tree,
      placement: _useRevealedPlacement(placement, presentation),
      child: child,
    );
  }
}

/// What every reader of one diagnostic tree over [presentation] shows of
/// the [routed] placement: one [PortableDiagnosticReveal] on one clock, so a
/// field, its messages and the headers above it change together.
PortableDiagnosticPlacement _useRevealedPlacement(
  PortableDiagnosticPlacement routed,
  PortableDiagnosticPresentation presentation,
) {
  final timing = useContext().timing;
  // Controllers rather than timers, so a settling test steps through them.
  final wait = useAnimationController(duration: timing.problemWait);
  final linger = useAnimationController(duration: timing.doneShow);
  final reveal = useRef<PortableDiagnosticReveal?>(null);
  final changes = useState(0);
  useEffect(() {
    void waited(AnimationStatus status) {
      if (status != AnimationStatus.completed) return;
      reveal.value = reveal.value?.settle();
      changes.value++;
    }

    void lingered(AnimationStatus status) {
      if (status != AnimationStatus.completed) return;
      reveal.value = reveal.value?.expire();
      changes.value++;
    }

    wait.addStatusListener(waited);
    linger.addStatusListener(lingered);
    return () {
      wait.removeStatusListener(waited);
      linger.removeStatusListener(lingered);
    };
  }, [wait, linger]);

  final mounted = presentation.nodes.keys.toSet();
  final current = reveal.value;
  if (current == null) {
    reveal.value = PortableDiagnosticReveal.start(routed, mounted);
  } else if (current.routed != routed || !setEquals(current.mounted, mounted)) {
    final (reveal: next, :waits, :fixes) = current.observe(routed, mounted);
    reveal.value = next;
    // A wait of no length settles here: a controller would finish during
    // this build and its listener may not rebuild then.
    if (waits && timing.problemWait == Duration.zero) {
      reveal.value = reveal.value!.settle();
    } else if (waits) {
      wait.forward(from: 0);
    }
    if (fixes && timing.doneShow == Duration.zero) {
      reveal.value = reveal.value!.expire();
    } else if (fixes) {
      linger.forward(from: 0);
    }
  }
  return reveal.value!.placement(presentation);
}
