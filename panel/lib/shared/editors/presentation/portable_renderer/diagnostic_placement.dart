part of "../portable_presentation_renderer.dart";

@freezed
abstract class PortableDiagnosticSummary with _$PortableDiagnosticSummary {
  const factory PortableDiagnosticSummary({
    @Default([]) List<PortablePresentationDiagnostic> direct,
    @Default([]) List<PortablePresentationDiagnostic> descendants,
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

@freezed
abstract class PortableDiagnosticPlacement with _$PortableDiagnosticPlacement {
  const factory PortableDiagnosticPlacement({
    @Default({}) Map<Object, PortableDiagnosticSummary> summaries,
    @Default([]) List<PortablePresentationDiagnostic> general,
  }) = _PortableDiagnosticPlacement;
  const PortableDiagnosticPlacement._();

  factory PortableDiagnosticPlacement.route({
    required List<PortablePresentationDiagnostic> diagnostics,
    required Iterable<PortableOperationOutcome> outcomes,
    required PortableDiagnosticPresentation presentation,
  }) {
    final direct = <Object, Set<PortablePresentationDiagnostic>>{};
    final descendants = <Object, Set<PortablePresentationDiagnostic>>{};
    final general = <PortablePresentationDiagnostic>{};
    void place(Object id, PortablePresentationDiagnostic diagnostic) {
      (direct[id] ??= {}).add(diagnostic);
      for (final parent in presentation.headerAncestors(id)) {
        (descendants[parent] ??= {}).add(diagnostic);
      }
    }

    final nodes = presentation.nodes;
    for (final entry in nodes.entries) {
      if (entry.value.kind == PortableDiagnosticNodeKind.control) {
        for (final diagnostic in entry.value.diagnostics) {
          for (final parent in presentation.headerAncestors(entry.key)) {
            (descendants[parent] ??= {}).add(diagnostic);
          }
        }
      }
    }
    final global = <PortablePresentationDiagnostic>{...diagnostics};
    for (final node in nodes.values.where(
      (node) => node.kind == PortableDiagnosticNodeKind.source,
    )) {
      global.addAll(node.diagnostics);
    }
    for (final outcome in outcomes) {
      global.addAll(outcome.diagnostics);
    }
    for (final diagnostic in global) {
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
        general.add(diagnostic);
        continue;
      }
      for (final id in destinations) {
        place(id, diagnostic);
      }
      for (final entry in nodes.entries) {
        final anchor = entry.value;
        if (anchor.kind != PortableDiagnosticNodeKind.header ||
            anchor.target == null ||
            destinations.contains(entry.key)) {
          continue;
        }
        if (diagnostic.targets.any(
          (target) => target.isAtOrBelow(anchor.target!),
        )) {
          (descendants[entry.key] ??= {}).add(diagnostic);
        }
      }
    }
    return PortableDiagnosticPlacement(
      general: general.toList(),
      summaries: {
        for (final id in {...direct.keys, ...descendants.keys})
          id: PortableDiagnosticSummary(
            direct: (direct[id] ?? const <PortablePresentationDiagnostic>{})
                .toList(),
            descendants:
                (descendants[id] ?? const <PortablePresentationDiagnostic>{})
                    .difference(
                      direct[id] ?? const <PortablePresentationDiagnostic>{},
                    )
                    .toList(),
          ),
      },
    );
  }

  PortableDiagnosticSummary forAnchor(Object id) =>
      summaries[id] ?? const PortableDiagnosticSummary();
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
