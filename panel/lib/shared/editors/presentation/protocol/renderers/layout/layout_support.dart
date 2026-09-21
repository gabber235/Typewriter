part of "../../layout_renderer.dart";

extension on List<PresentationNode> {
  List<Widget> renderChildren(PresentationRenderScope scope) => [
    for (final child in this)
      PresentationNodeRenderer(node: child, scope: scope),
  ];
}

extension on List<PresentationAxisChild> {
  List<Widget> renderAxisChildren(
    double spacing,
    PresentationRenderScope scope, {
    bool vertical = false,
  }) => [
    for (final (index, child) in indexed) ...[
      if (index > 0)
        SizedBox(width: vertical ? 0 : spacing, height: vertical ? spacing : 0),
      child.render(scope),
    ],
  ];
}

extension on PresentationAxisChild {
  Widget render(PresentationRenderScope scope) => switch (this) {
    FixedPresentationAxisChild(:final child) => PresentationNodeRenderer(
      node: child,
      scope: scope,
    ),
    FlexiblePresentationAxisChild(:final child, :final flex, :final fit) =>
      Flexible(
        flex: flex,
        fit: fit == PresentationFlexFit.tight ? FlexFit.tight : FlexFit.loose,
        child: PresentationNodeRenderer(node: child, scope: scope),
      ),
  };
}

extension on PresentationMainAxisAlignment {
  MainAxisAlignment get mainAxisAlignment => switch (this) {
    PresentationMainAxisAlignment.start => MainAxisAlignment.start,
    PresentationMainAxisAlignment.center => MainAxisAlignment.center,
    PresentationMainAxisAlignment.end => MainAxisAlignment.end,
    PresentationMainAxisAlignment.spaceBetween =>
      MainAxisAlignment.spaceBetween,
    PresentationMainAxisAlignment.spaceAround => MainAxisAlignment.spaceAround,
    PresentationMainAxisAlignment.spaceEvenly => MainAxisAlignment.spaceEvenly,
  };

  WrapAlignment get wrapAlignment =>
      WrapAlignment.values[mainAxisAlignment.index];
}

extension on PresentationCrossAxisAlignment {
  CrossAxisAlignment get crossAxisAlignment => switch (this) {
    PresentationCrossAxisAlignment.start => CrossAxisAlignment.start,
    PresentationCrossAxisAlignment.center => CrossAxisAlignment.center,
    PresentationCrossAxisAlignment.end => CrossAxisAlignment.end,
    PresentationCrossAxisAlignment.stretch => CrossAxisAlignment.stretch,
  };

  WrapCrossAlignment get wrapCrossAlignment => switch (this) {
    PresentationCrossAxisAlignment.start => WrapCrossAlignment.start,
    PresentationCrossAxisAlignment.center => WrapCrossAlignment.center,
    PresentationCrossAxisAlignment.end ||
    PresentationCrossAxisAlignment.stretch => WrapCrossAlignment.end,
  };
}

extension on TypedExpression? {
  double? resolveLayoutSize(PresentationRenderScope scope) {
    if (this == null) return null;
    final resolved = scope.evaluate(this!).valueOrNull;
    final size = switch (resolved) {
      IntegerValue(:final value) => value.toDouble(),
      FloatValue(:final value) => value,
      DecimalValue(:final value) => double.tryParse(value),
      _ => null,
    };
    return size == null || size < 0 ? null : size;
  }
}
