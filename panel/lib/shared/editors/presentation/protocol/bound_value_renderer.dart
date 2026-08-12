import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";

extension DefaultPresentationElementRendering on DefaultPresentationElement {
  Widget render(BuildContext context, PresentationRenderScope scope) {
    final element = this;
    if (element.presentationId case final presentationId?
        when scope.activePresentations.contains(presentationId)) {
      return presentationDiagnostic(context, [
        const TypeDiagnostic(
          code: TypeDiagnosticCode.invalidValue,
          message: "Presentation delegation is recursive",
        ),
      ]);
    }
    final resolved = scope.resolve(element.binding);
    if (resolved case TypeFailure(:final diagnostics)) {
      return presentationDiagnostic(context, diagnostics);
    }
    final binding = resolved.valueOrNull!;
    final selected = scope.resolvePresentation(
      binding.type,
      element.presentationId,
    );
    if (selected == null) {
      final generated = binding.type.generateDefaultPresentation(
        binding: element.binding,
        nodeId: "default.${element.binding.bindingId.value}",
      );
      return PresentationNodeRenderer(node: generated, scope: scope);
    }
    if (scope.activePresentations.contains(selected.id)) {
      return presentationDiagnostic(context, [
        const TypeDiagnostic(
          code: TypeDiagnosticCode.invalidValue,
          message: "Presentation delegation is recursive",
        ),
      ]);
    }
    final childScope = scope
        .withAlias(
          const BindingId(0),
          scope.canonical(element.binding),
          BindingSnapshot(
            type: binding.type,
            value: binding.value,
            revision: binding.revision,
            writable: binding.writable,
          ),
        )
        .copyWith(
          activePresentations: {...scope.activePresentations, selected.id},
        );
    return PresentationNodeRenderer(node: selected.root, scope: childScope);
  }
}

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
  }) => PresentationNodeRenderer(
    node: type.generateDefaultPresentation(
      binding: reference,
      nodeId: nodeId,
      root: false,
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
