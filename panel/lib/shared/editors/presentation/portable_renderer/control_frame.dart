part of "../portable_presentation_renderer.dart";

Widget _controlFrame(
  skir.BoundControl control,
  PortablePresentationScope childScope,
  Widget child, {
  skir.InputAppearance? appearance,
  bool renderPrefix = false,
  bool labelsInput = false,
}) {
  final association = childScope.associationFor(control);
  final resolvedLabel = association.label;
  final description = association.description;
  final semanticLabel = association.semanticLabel;
  final content = renderPrefix
      ? _compositeControlContent(control, childScope, child)
      : child;
  return _PortableControlFrameState(
    scope: childScope,
    child: Builder(
      builder: (context) {
        final states = _PortableControlStateScope.maybeOf(context)!;
        final enclosingTitle = _PortableHeaderTitle.maybeOf(context);
        final label = resolvedLabel?.trim() == enclosingTitle?.trim()
            ? null
            : resolvedLabel;
        // The visible label stays out of the semantics tree, so the field is
        // announced once: by its native input when [labelsInput] (see
        // [_inputSemanticLabel]), otherwise by this frame unless the
        // enclosing header already reads the same title.
        final frameLabel = semanticLabel?.trim() == enclosingTitle?.trim()
            ? null
            : semanticLabel;
        final semanticChild = labelsInput
            ? content
            : Semantics(
                label: frameLabel ?? "",
                hint: description,
                child: content,
              );
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

/// The name assistive technology reads for the native input of [control]:
/// its own semantic label, or else the title of the enclosing header that
/// visibly names it.
String? _inputSemanticLabel(
  BuildContext context,
  skir.BoundControl control,
  PortablePresentationScope scope,
) =>
    scope.associationFor(control).semanticLabel ??
    _PortableHeaderTitle.maybeOf(context);

/// Labels one native editor whose decoration contains only display content.
/// Authored actions and other editable controls remain siblings of this child.
Widget _semanticInput(
  skir.BoundControl control,
  PortablePresentationScope scope,
  Widget child,
) => Builder(
  builder: (context) => MergeSemantics(
    child: Semantics(
      label: _inputSemanticLabel(context, control, scope) ?? "",
      hint: scope.associationFor(control).description,
      child: child,
    ),
  ),
);

Widget? _fieldLabel(
  skir.BoundControl control,
  PortablePresentationScope scope,
) {
  final label = scope.associationFor(control).label;
  return label == null || label.isEmpty ? null : Text(label);
}
