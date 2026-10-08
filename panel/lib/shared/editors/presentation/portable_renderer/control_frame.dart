part of "../portable_presentation_renderer.dart";

Widget _controlFrame(
  skir.BoundControl control,
  PortablePresentationScope childScope,
  Widget child,
) {
  final resolvedLabel = _controlString(control.label, childScope);
  final description = _controlString(control.description, childScope);
  final semanticLabel = _controlString(
    control.semanticLabel ?? control.label,
    childScope,
  );
  final semanticChild = semanticLabel == null || semanticLabel.isEmpty
      ? child
      : MergeSemantics(
          child: Semantics(label: semanticLabel, child: child),
        );
  return Builder(
    builder: (context) {
      final enclosingTitle = _PortableHeaderTitle.maybeOf(context);
      final label = resolvedLabel?.trim() == enclosingTitle?.trim()
          ? null
          : resolvedLabel;
      final hasMessage =
          (label != null && label.isNotEmpty) ||
          (description != null && description.isNotEmpty);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          LabeledMessage(label: label, message: description),
          if (hasMessage) const SizedBox(height: 6),
          semanticChild,
        ],
      );
    },
  );
}

Widget? _controlPrefix(
  skir.BoundControl control,
  PortablePresentationScope childScope,
) {
  final prefix = control.prefix;
  if (prefix == null) return null;
  final rendered = PortablePresentationNodeRenderer(
    node: prefix,
    scope: childScope,
  );
  final semanticLabel = _controlString(
    control.semanticLabel ?? control.label,
    childScope,
  );
  return semanticLabel == null || semanticLabel.isEmpty
      ? rendered
      : ExcludeSemantics(child: rendered);
}

Widget? _paddedControlPrefix(
  skir.BoundControl control,
  PortablePresentationScope childScope,
) {
  final prefix = _controlPrefix(control, childScope);
  return prefix == null
      ? null
      : Builder(
          builder: (context) => Padding(
            padding: EdgeInsets.all(context.spacing.space2),
            child: prefix,
          ),
        );
}

Widget _withControlPrefix(
  skir.BoundControl control,
  PortablePresentationScope childScope,
  Widget child,
) {
  final prefix = _controlPrefix(control, childScope);
  if (prefix == null) return child;
  return Builder(
    builder: (context) => Row(
      children: [
        Padding(padding: EdgeInsets.all(context.spacing.space2), child: prefix),
        const SizedBox(width: 6),
        Expanded(child: child),
      ],
    ),
  );
}
