part of "../portable_presentation_renderer.dart";

@freezed
abstract class PortableDiagnosticSummary with _$PortableDiagnosticSummary {
  const factory PortableDiagnosticSummary({
    @Default([]) List<PortablePresentationDiagnostic> direct,
    @Default([]) List<PortablePresentationDiagnostic> descendants,

    /// Whether the direct diagnostics just cleared, so the anchor says Fixed
    /// for the `doneShow` timing.
    @Default(false) bool fixed,
  }) = _PortableDiagnosticSummary;
  const PortableDiagnosticSummary._();

  int get descendantCount => descendants.length;
  bool get isEmpty => direct.isEmpty && descendants.isEmpty;
  skir.DiagnosticSeverity? get highestSeverity {
    skir.DiagnosticSeverity? highest;
    for (final diagnostic in [...direct, ...descendants]) {
      if (highest == null || diagnostic.severity.rank > highest.rank) {
        highest = diagnostic.severity;
      }
    }
    return highest;
  }
}

extension _PortableDiagnosticSeverityPresentation on skir.DiagnosticSeverity {
  int get rank => switch (kind) {
    skir.DiagnosticSeverity_kind.informationConst => 1,
    skir.DiagnosticSeverity_kind.warningConst => 2,
    _ => 3,
  };

  Color color(BuildContext context) => switch (kind) {
    skir.DiagnosticSeverity_kind.informationConst => context.colors.info,
    skir.DiagnosticSeverity_kind.warningConst => context.colors.warning,
    _ => context.colors.danger,
  };
}

/// Routes each target to exact mounted controls, otherwise the deepest matching
/// headers. Header ancestors summarize descendants without duplicating their
/// direct messages. Unmatched diagnostics retain their declared fallback, so
/// resource feedback is not silently promoted into general presentation feedback.
@freezed
abstract class PortableDiagnosticPlacement with _$PortableDiagnosticPlacement {
  const factory PortableDiagnosticPlacement({
    @Default({}) Map<Object, PortableDiagnosticSummary> summaries,
    @Default([]) List<PortablePresentationDiagnostic> general,
    @Default([]) List<PortablePresentationDiagnostic> unplaced,

    /// Whether the general diagnostics just cleared, so the presentation
    /// says Fixed for the `doneShow` timing.
    @Default(false) bool generalFixed,
  }) = _PortableDiagnosticPlacement;
  const PortableDiagnosticPlacement._();

  factory PortableDiagnosticPlacement.route({
    required List<PortablePresentationDiagnostic> diagnostics,
    required Iterable<PortableOperationOutcome> outcomes,
    required PortableDiagnosticPresentation presentation,
    PortableDiagnosticFallback diagnosticFallback =
        PortableDiagnosticFallback.presentation,
  }) {
    final direct = <Object, Set<PortablePresentationDiagnostic>>{};
    final general = <PortablePresentationDiagnostic>{};
    final unplaced = <PortablePresentationDiagnostic>{};

    final nodes = presentation.nodes;
    // A control's own findings, such as text it cannot parse, stay on it.
    for (final entry in nodes.entries) {
      if (entry.value.kind == PortableDiagnosticNodeKind.control) {
        for (final diagnostic in entry.value.diagnostics) {
          (direct[entry.key] ??= {}).add(diagnostic);
        }
      }
    }
    final fallbacks =
        <PortablePresentationDiagnostic, PortableDiagnosticFallback>{};
    void include(
      Iterable<PortablePresentationDiagnostic> values,
      PortableDiagnosticFallback fallback,
    ) {
      for (final diagnostic in values) {
        if (fallbacks[diagnostic] != PortableDiagnosticFallback.presentation) {
          fallbacks[diagnostic] = fallback;
        }
      }
    }

    include(diagnostics, diagnosticFallback);
    for (final node in nodes.values.where(
      (node) => node.kind == PortableDiagnosticNodeKind.source,
    )) {
      include(node.diagnostics, node.diagnosticFallback);
    }
    for (final outcome in outcomes) {
      include(outcome.diagnostics, PortableDiagnosticFallback.presentation);
    }
    for (final entry in fallbacks.entries) {
      final diagnostic = entry.key;
      final destinations = <Object>{};
      for (final target in diagnostic.targets) {
        final controls = nodes.entries.where(
          (entry) =>
              entry.value.kind == PortableDiagnosticNodeKind.control &&
              entry.value.target == target,
        );
        if (controls.isNotEmpty) {
          destinations.addAll(controls.map((entry) => entry.key));
          continue;
        }
        final headers = nodes.entries
            .where(
              (entry) =>
                  entry.value.kind == PortableDiagnosticNodeKind.header &&
                  entry.value.target != null &&
                  target.isAtOrBelow(entry.value.target!),
            )
            .toList();
        if (headers.isEmpty) continue;
        final depth = headers
            .map((entry) => entry.value.target!.path.segments.length)
            .reduce((a, b) => a > b ? a : b);
        destinations.addAll(
          headers
              .where(
                (entry) => entry.value.target!.path.segments.length == depth,
              )
              .map((entry) => entry.key),
        );
      }
      if (destinations.isEmpty) {
        switch (entry.value) {
          case PortableDiagnosticFallback.presentation:
            general.add(diagnostic);
          case PortableDiagnosticFallback.resource:
            unplaced.add(diagnostic);
        }
        continue;
      }
      for (final id in destinations) {
        (direct[id] ??= {}).add(diagnostic);
      }
    }
    return PortableDiagnosticPlacement.summarize(
      direct: direct,
      general: general.toList(),
      unplaced: unplaced.toList(),
      presentation: presentation,
    );
  }

  /// Summarizes diagnostics already placed [direct] on anchors: each header
  /// ancestor of an anchor, and each header whose target covers a
  /// diagnostic's target, counts it among its descendants. Anchors in
  /// [fixed] say Fixed, and [generalFixed] makes [general] say it.
  factory PortableDiagnosticPlacement.summarize({
    required Map<Object, Iterable<PortablePresentationDiagnostic>> direct,
    required PortableDiagnosticPresentation presentation,
    List<PortablePresentationDiagnostic> general = const [],
    List<PortablePresentationDiagnostic> unplaced = const [],
    Set<Object> fixed = const {},
    bool generalFixed = false,
  }) {
    final descendants = <Object, Set<PortablePresentationDiagnostic>>{};
    final placed = <PortablePresentationDiagnostic>{};
    for (final entry in direct.entries) {
      placed.addAll(entry.value);
      for (final parent in presentation.headerAncestors(entry.key)) {
        (descendants[parent] ??= {}).addAll(entry.value);
      }
    }
    for (final diagnostic in placed) {
      for (final entry in presentation.nodes.entries) {
        final anchor = entry.value;
        if (anchor.kind == PortableDiagnosticNodeKind.header &&
            anchor.target != null &&
            diagnostic.targets.any(
              (target) => target.isAtOrBelow(anchor.target!),
            )) {
          (descendants[entry.key] ??= {}).add(diagnostic);
        }
      }
    }
    final ids = {
      for (final entry in direct.entries)
        if (entry.value.isNotEmpty) entry.key,
      ...descendants.keys,
      ...fixed,
    };
    return PortableDiagnosticPlacement(
      general: general,
      unplaced: unplaced,
      generalFixed: generalFixed,
      summaries: {
        for (final id in ids)
          id: PortableDiagnosticSummary(
            direct: [...?direct[id]],
            descendants:
                (descendants[id] ?? const <PortablePresentationDiagnostic>{})
                    .difference({...?direct[id]})
                    .toList(),
            fixed: fixed.contains(id),
          ),
      },
    );
  }

  PortableDiagnosticSummary forAnchor(Object id) =>
      summaries[id] ?? const PortableDiagnosticSummary();
}

/// What a diagnostic tree shows of the diagnostics routed to it, so every
/// reader (a field, its messages, the headers above it) sees the same
/// problems and the same Fixed from one clock.
///
/// Diagnostics new or changed on a mounted anchor wait for the
/// `problemWait` timing before they show, so typing never flashes a problem
/// at every letter; [observe] reports the wait and [settle] ends it. An
/// anchor whose diagnostics are gone shows nothing at once and says Fixed
/// until [expire]. A newly mounted anchor shows its diagnostics at once.
final class PortableDiagnosticReveal {
  PortableDiagnosticReveal.start(this.routed, this.mounted)
    : shown = _shownOf(routed),
      fixed = const {};

  const PortableDiagnosticReveal._({
    required this.routed,
    required this.mounted,
    required this.shown,
    required this.fixed,
  });

  /// Stands for the general diagnostics among the anchors.
  static const _general = #general;

  /// The latest routing, which [settle] shows.
  final PortableDiagnosticPlacement routed;

  /// The anchors mounted at the latest routing.
  final Set<Object> mounted;

  /// The diagnostics shown on each anchor, and on [_general].
  final Map<Object, List<PortablePresentationDiagnostic>> shown;

  /// The anchors, and [_general], that say Fixed.
  final Set<Object> fixed;

  static Map<Object, List<PortablePresentationDiagnostic>> _shownOf(
    PortableDiagnosticPlacement placement,
  ) => {
    for (final entry in placement.summaries.entries)
      if (entry.value.direct.isNotEmpty) entry.key: entry.value.direct,
    if (placement.general.isNotEmpty) _general: placement.general,
  };

  /// Takes a new [routed] placement over the [mounted] anchors. Says
  /// whether shown diagnostics must wait for the `problemWait` timing and
  /// whether an anchor started to say Fixed.
  ({PortableDiagnosticReveal reveal, bool waits, bool fixes}) observe(
    PortableDiagnosticPlacement routed,
    Set<Object> mounted,
  ) {
    final latest = _shownOf(routed);
    final present = {
      for (final diagnostics in latest.values) ...diagnostics,
      ...routed.unplaced,
    };
    final shown = {...this.shown};
    final fixed = {...this.fixed};
    var waits = false;
    var fixes = false;
    for (final key in {...latest.keys, ...this.shown.keys}) {
      final next = latest[key] ?? const <PortablePresentationDiagnostic>[];
      final current = this.shown[key] ?? const [];
      if (setEquals(next.toSet(), current.toSet())) continue;
      if (key != _general && !this.mounted.contains(key)) {
        shown[key] = next;
      } else if (next.isEmpty) {
        shown.remove(key);
        // A diagnostic that only moved to another anchor was not fixed.
        if (current.any((diagnostic) => !present.contains(diagnostic))) {
          fixed.add(key);
          fixes = true;
        }
      } else {
        fixed.remove(key);
        waits = true;
      }
    }
    bool kept(Object key) => key == _general || mounted.contains(key);
    shown.removeWhere((key, diagnostics) => !kept(key) || diagnostics.isEmpty);
    fixed.removeWhere((key) => !kept(key));
    return (
      reveal: PortableDiagnosticReveal._(
        routed: routed,
        mounted: mounted,
        shown: shown,
        fixed: fixed,
      ),
      waits: waits,
      fixes: fixes,
    );
  }

  /// Shows the latest routing once its diagnostics have rested.
  PortableDiagnosticReveal settle() {
    final shown = _shownOf(routed);
    return PortableDiagnosticReveal._(
      routed: routed,
      mounted: mounted,
      shown: shown,
      fixed: {...fixed}..removeAll(shown.keys),
    );
  }

  /// Ends every Fixed once the `doneShow` timing has passed.
  PortableDiagnosticReveal expire() => PortableDiagnosticReveal._(
    routed: routed,
    mounted: mounted,
    shown: shown,
    fixed: const {},
  );

  /// The placement every reader of the tree over [presentation] shows.
  PortableDiagnosticPlacement placement(
    PortableDiagnosticPresentation presentation,
  ) => PortableDiagnosticPlacement.summarize(
    direct: {
      for (final entry in shown.entries)
        if (entry.key != _general) entry.key: entry.value,
    },
    general: shown[_general] ?? const [],
    unplaced: routed.unplaced,
    fixed: {...fixed}..remove(_general),
    generalFixed: fixed.contains(_general),
    presentation: presentation,
  );
}

typedef PortableDiagnosticAnchorBuilder = Widget Function(
  BuildContext context,
  PortableDiagnosticSummary summary,
  Object owner,
);

class PortableDiagnosticAnchor extends HookWidget {
  const PortableDiagnosticAnchor({
    required this.node,
    required this.builder,
    super.key,
  });
  final PortableDiagnosticNode node;
  final PortableDiagnosticAnchorBuilder builder;

  @override
  Widget build(BuildContext context) {
    final owner = useMemoized(Object.new);
    final diagnostics = PortableDiagnosticScope.of(context);
    final parent = _PortableDiagnosticParent.maybeOf(context);
    final tree = diagnostics.tree;
    useEffect(
      () =>
          () => tree.remove(owner),
      [tree, owner],
    );
    tree.update(owner, node.copyWith(parent: parent));
    return _PortableDiagnosticParent(
      id: owner,
      child: builder(context, diagnostics.placement.forAnchor(owner), owner),
    );
  }
}

class _PortableDiagnosticParent extends InheritedWidget {
  const _PortableDiagnosticParent({required this.id, required super.child});
  final Object id;
  static Object? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_PortableDiagnosticParent>()
      ?.id;
  @override
  bool updateShouldNotify(_PortableDiagnosticParent old) =>
      !identical(id, old.id);
}
