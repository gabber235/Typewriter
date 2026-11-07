import "package:typewriter_panel/typewriter_panel.dart";

/// A row that grows into a surface with surfaceIn and shrinks with
/// panelOut. Esc anywhere inside a grown card shrinks it and puts focus
/// back on its header.
class GrowingCard extends HookWidget {
  const GrowingCard({
    required this.controller,
    required this.header,
    required this.body,
    this.maintainState = false,
    super.key,
  });

  final ExpansibleController controller;

  /// The row; [Animation] runs from 0 at row size to 1 grown, for a turning
  /// chevron.
  final Widget Function(BuildContext context, Animation<double> animation)
  header;
  final WidgetBuilder body;

  /// Keeps the body built while the card is a row.
  final bool maintainState;

  @override
  Widget build(BuildContext context) {
    useListenable(controller);
    // A plain node, not a scope: Tab still travels from the header into
    // the body.
    final headerGroup = useFocusNode(
      debugLabel: "Growing card header",
      skipTraversal: true,
      canRequestFocus: false,
    );
    final style = motionTimeline(
      context,
      MotionToken.surfaceIn,
    ).styleWith(motionTimeline(context, MotionToken.panelOut));

    void shrink() {
      controller.collapse();
      headerGroup.traversalDescendants.firstOrNull?.requestFocus();
    }

    return Actions(
      actions: {
        // Only while grown, so a row lets Esc reach what is around it.
        if (controller.isExpanded)
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) {
              shrink();
              return null;
            },
          ),
      },
      child: Expansible(
        controller: controller,
        animationStyle: style,
        maintainState: maintainState,
        headerBuilder: (context, animation) =>
            Focus(focusNode: headerGroup, child: header(context, animation)),
        bodyBuilder: (context, _) => ExcludeFocus(
          excluding: !controller.isExpanded,
          child: body(context),
        ),
        expansibleBuilder: (context, header, body, _) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [header, body],
        ),
      ),
    );
  }
}
