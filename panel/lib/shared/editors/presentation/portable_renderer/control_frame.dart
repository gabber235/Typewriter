part of "../portable_presentation_renderer.dart";

Widget _controlFrame(
  skir.BoundControl control,
  PortablePresentationScope childScope,
  Widget child, {
  skir.InputAppearance? appearance,
  bool renderPrefix = false,
}) {
  final resolvedLabel = _controlString(control.label, childScope);
  final description = _controlString(control.description, childScope);
  final semanticLabel = _controlString(
    control.semanticLabel ?? control.label,
    childScope,
  );
  final content = renderPrefix
      ? _compositeControlContent(control, childScope, child)
      : child;
  final semanticChild = Semantics(label: semanticLabel ?? "", child: content);
  return _PortableControlFrameState(
    scope: childScope,
    child: Builder(
      builder: (context) {
        final states = _PortableControlStateScope.maybeOf(context)!;
        final enclosingTitle = _PortableHeaderTitle.maybeOf(context);
        final label = resolvedLabel?.trim() == enclosingTitle?.trim()
            ? null
            : resolvedLabel;
        return PortableLocationTarget(
          location: childScope.location(control.binding),
          onFocusChange: (focused) =>
              states.update(WidgetState.focused, focused),
          child: PortableDiagnosticFrame(
            scope: childScope,
            appearance: appearance,
            target: childScope.diagnosticTarget(control.binding),
            value: childScope.read(control.binding),
            label: label,
            description: description,
            child: MouseRegion(
              onEnter: (_) => states.update(WidgetState.hovered, true),
              onExit: (_) => states.update(WidgetState.hovered, false),
              child: semanticChild,
            ),
          ),
        );
      },
    ),
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

Widget _compositeControlContent(
  skir.BoundControl control,
  PortablePresentationScope scope,
  Widget child,
) {
  final prefix = control.prefix;
  if (prefix == null) return child;
  return Builder(
    builder: (context) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: context.spacing.space2,
      children: [
        PortablePresentationNodeRenderer(node: prefix, scope: scope),
        Expanded(child: child),
      ],
    ),
  );
}

Widget _controlAssociation(
  skir.BoundControl control,
  PortablePresentationScope scope,
  Widget child,
) {
  final label = _controlString(control.label, scope);
  final description = _controlString(control.description, scope);
  final semanticLabel = _controlString(
    control.semanticLabel ?? control.label,
    scope,
  );
  return PortableLocationTarget(
    location: scope.location(control.binding),
    child: PortableDiagnosticAnchor(
      node: PortableDiagnosticNode(
        kind: PortableDiagnosticNodeKind.header,
        observations: [
          PortableDiagnosticObservation(
            target: scope.diagnosticTarget(control.binding),
            value: scope.read(control.binding),
          ),
        ],
      ),
      builder: (context, summary, owner) {
        final style = _controlStyle(context, scope, null);
        final enclosing = _PortableHeaderTitle.maybeOf(context);
        final effectiveLabel = label?.trim() == enclosing?.trim()
            ? null
            : label;
        return Semantics(
          container: true,
          explicitChildNodes: true,
          label: semanticLabel,
          hint: description,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (effectiveLabel != null || description != null)
                ExcludeSemantics(
                  child: LabeledMessage(
                    label: effectiveLabel,
                    message: description,
                    labelStyle: style.labelStyle,
                    messageStyle: style.descriptionStyle,
                  ),
                ),
              if (effectiveLabel != null || description != null)
                const SizedBox(height: 6),
              _compositeControlContent(control, scope, child),
              PortableDiagnosticMessages(diagnostics: summary.direct),
            ],
          ),
        );
      },
    ),
  );
}

/// Labels one native editor whose decoration contains only display content.
/// Authored actions and other editable controls remain siblings of this child.
Widget _semanticInput(
  skir.BoundControl control,
  PortablePresentationScope scope,
  Widget child,
) {
  final label = _controlString(control.semanticLabel ?? control.label, scope);
  return MergeSemantics(
    child: Semantics(label: label ?? "", child: child),
  );
}
