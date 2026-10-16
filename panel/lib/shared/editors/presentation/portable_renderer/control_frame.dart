part of "../portable_presentation_renderer.dart";

Widget _controlFrame(
  skir.BoundControl control,
  PortablePresentationScope childScope,
  Widget child, {
  skir.InputAppearance? appearance,
  bool renderPrefix = false,
}) {
  final association = childScope.associationFor(control);
  final resolvedLabel = association.label;
  final description = association.description;
  final semanticLabel = association.semanticLabel;
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
  final association = childScope.associationFor(control);
  final prefix = association.prefix;
  if (prefix == null) return null;
  final rendered = prefix.render(childScope);
  final semanticLabel = association.semanticLabel;
  return semanticLabel == null || semanticLabel.isEmpty
      ? rendered
      : ExcludeSemantics(child: rendered);
}

Widget _compositeControlContent(
  skir.BoundControl control,
  PortablePresentationScope scope,
  Widget child,
) {
  final prefix = scope.associationFor(control).prefix;
  if (prefix == null) return child;
  return Builder(
    builder: (context) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: context.spacing.space2,
      children: [
        prefix.render(scope),
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
  final association = scope.associationFor(control);
  final label = association.label;
  final description = association.description;
  final semanticLabel = association.semanticLabel;
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
        final effectiveLabel =
            label == null || label.isEmpty || label.trim() == enclosing?.trim()
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
  final label = scope.associationFor(control).semanticLabel;
  return MergeSemantics(
    child: Semantics(label: label ?? "", child: child),
  );
}

Widget? _fieldLabel(
  skir.BoundControl control,
  PortablePresentationScope scope,
) {
  final label = scope.associationFor(control).label;
  return label == null || label.isEmpty ? null : Text(label);
}
