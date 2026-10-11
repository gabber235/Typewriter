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

// Owns mounted presentation membership, not operation or document state.
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
    super.key,
  });
  final List<PortablePresentationDiagnostic> diagnostics;
  final List<PortableDiagnosticObservation> observations;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PortableDiagnosticAnchor(
      node: PortableDiagnosticNode(
        kind: PortableDiagnosticNodeKind.source,
        diagnostics: diagnostics,
        observations: observations,
      ),
      builder: (context, summary, owner) => child,
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
    super.key,
  });

  final PortableOperationResults operations;
  final List<PortableDiagnosticObservation> observations;
  final List<PortablePresentationDiagnostic> diagnostics;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tree = useMemoized(PortableDiagnosticTree.new, [operations]);
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
        outcomes: operations.value.outcomes.values.where(
          (outcome) => !obsolete.contains(outcome.request),
        ),
        presentation: presentation,
      ),
      [diagnostics, operations.value, presentation, obsolete],
    );
    return PortableDiagnosticScope(
      tree: tree,
      placement: placement,
      child: child,
    );
  }
}
