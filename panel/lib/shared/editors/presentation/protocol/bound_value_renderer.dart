import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "renderers/data/default_presentation_renderer.dart";

class ProtocolBoundValueEditor extends StatelessWidget {
  const ProtocolBoundValueEditor({
    required this.control,
    required this.scope,
    super.key,
  });

  final BoundControl control;
  final PresentationRenderScope scope;

  @override
  Widget build(BuildContext context) {
    final result = scope.resolve(control.binding);
    if (result case TypeFailure(:final diagnostics)) {
      return presentationDiagnostic(context, diagnostics);
    }
    final binding = result.valueOrNull!;
    return LabeledControl(
      control: control,
      scope: scope,
      child: binding.renderDefaultPresentation(
        scope,
        nodeId: "bound.${control.binding.bindingId.value}",
      ),
    );
  }
}

extension ResolvedBindingDefaultPresentationRendering on ResolvedBinding {
  Widget renderDefaultPresentation(
    PresentationRenderScope scope, {
    required String nodeId,
    bool root = false,
    String? label,
  }) => PresentationNodeRenderer(
    node: type.generateDefaultPresentation(
      binding: reference,
      nodeId: nodeId,
      root: root,
      label: label,
    ),
    scope: scope,
  );
}

class LabeledControl extends StatelessWidget {
  const LabeledControl({
    required this.control,
    required this.scope,
    required this.child,
    super.key,
  });

  final BoundControl control;
  final PresentationRenderScope scope;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final label = control.label == null
        ? null
        : scope.expressionText(control.label!);
    final description = control.description == null
        ? null
        : scope.expressionText(control.description!);
    final semanticLabel = resolveControlSemanticLabel(control, scope);
    final semanticChild = semanticLabel == null || semanticLabel.isEmpty
        ? child
        : MergeSemantics(
            child: Semantics(label: semanticLabel, child: child),
          );
    if ((label == null || label.isEmpty) &&
        (description == null || description.isEmpty)) {
      return semanticChild;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LabeledMessage(
          label: label,
          message: description,
          labelStyle: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 6),
        semanticChild,
      ],
    );
  }
}

String? resolveControlSemanticLabel(
  BoundControl control,
  PresentationRenderScope scope,
) {
  final expression = control.semanticLabel ?? control.label;
  return expression == null ? null : scope.expressionText(expression);
}

Widget? renderControlPrefix(
  BuildContext context,
  BoundControl control,
  PresentationRenderScope scope,
) {
  final prefix = control.prefix;
  if (prefix == null) return null;
  Widget child = PresentationNodeRenderer(node: prefix, scope: scope);
  if (resolveControlSemanticLabel(control, scope) case final label?
      when label.isNotEmpty) {
    child = ExcludeSemantics(child: child);
  }
  return Padding(
    padding: EdgeInsets.all(context.spacing.space2),
    child: DefaultTextStyle.merge(
      style: Theme.of(
        context,
      ).textTheme.labelLarge?.copyWith(color: context.colors.contentSecondary),
      child: IconTheme.merge(
        data: IconThemeData(color: context.colors.contentSecondary, size: 18),
        child: child,
      ),
    ),
  );
}
