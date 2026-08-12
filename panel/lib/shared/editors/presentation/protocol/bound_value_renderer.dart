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
  }) => PresentationNodeRenderer(
    node: type.generateDefaultPresentation(
      binding: reference,
      nodeId: nodeId,
      root: root,
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
    if ((label == null || label.isEmpty) &&
        (description == null || description.isEmpty)) {
      return child;
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
        child,
      ],
    );
  }
}
