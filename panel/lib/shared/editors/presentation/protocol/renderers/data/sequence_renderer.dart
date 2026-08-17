part of "../../data_renderer.dart";

Widget renderSequence({
  required BuildContext context,
  required SequencePresentation presentation,
  required PresentationRenderScope scope,
  required List<PresentationRenderScope> itemScopes,
}) {
  if (itemScopes.isEmpty) {
    final empty = presentation.empty;
    if (empty == null) return const SizedBox.shrink();
    return _renderSequenceNode(empty, scope);
  }
  final children = <Widget>[];
  final separator = presentation.separator;
  final hierarchy = presentation.layout is PresentationHierarchySequenceLayout;
  for (final (index, itemScope) in itemScopes.indexed) {
    if (index > 0 && separator != null && !hierarchy) {
      children.add(
        KeyedSubtree(
          key: ValueKey("separator.$index"),
          child: _renderSequenceNode(separator, scope),
        ),
      );
    }
    children.add(
      KeyedSubtree(
        key: ValueKey("item.$index"),
        child: _renderSequenceNode(presentation.item, itemScope),
      ),
    );
  }
  final sequence = presentation.layout.renderSequence(
    context,
    children: children,
    scope: scope,
    itemScopes: itemScopes,
  );
  if (!hierarchy || separator == null) return sequence;
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      presentationDiagnostic(context, [
        const TypeDiagnostic(
          code: TypeDiagnosticCode.invalidPresentation,
          message: "Hierarchy sequences do not support separators",
        ),
      ]),
      sequence,
    ],
  );
}

Widget _renderSequenceNode(
  PresentationNode node,
  PresentationRenderScope scope,
) => PresentationNodeRenderer(
  node: node.localizeFailures(
    scope.expressions,
    registry: scope.registry,
    budget: scope.budget,
  ),
  scope: scope,
);
