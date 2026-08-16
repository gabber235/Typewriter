part of "../../simple_input_renderer.dart";

bool _bindingLocked(ResolvedBinding binding, PresentationRenderScope scope) =>
    scope.readOnly || !scope.enabled || !binding.writable;

Widget _inputDiagnostic(String message) => Builder(
  builder: (context) => presentationDiagnostic(context, [
    TypeDiagnostic(code: TypeDiagnosticCode.invalidValue, message: message),
  ]),
);

Widget _renderParsedTextValue({
  required ResolvedBinding binding,
  required PresentationRenderScope scope,
  required String? text,
  required DataValue? Function(String) parse,
  required String diagnostic,
}) {
  if (text == null) return _inputDiagnostic(diagnostic);
  return DecoratedTextField(
    key: ValueKey((binding.reference, binding.value)),
    text: text,
    enabled: !_bindingLocked(binding, scope),
    onChanged: (next) {
      final parsed = parse(next);
      if (parsed != null && parsed.validateAgainst(binding.type).isEmpty) {
        scope.update(binding.reference, parsed);
      }
    },
  );
}

Widget _renderNamedInput({
  required BoundControl control,
  required BuildContext context,
  required PresentationRenderScope scope,
}) {
  final result = scope.resolve(control.binding);
  if (result case TypeFailure(:final diagnostics)) {
    return presentationDiagnostic(context, diagnostics);
  }
  final binding = result.valueOrNull!;
  if (binding.type is! NamedType) {
    return _inputDiagnostic("Named control requires a nominal binding");
  }
  final namedType = binding.type as NamedType;
  final resolved = scope.registry.resolve(namedType);
  if (resolved case TypeFailure(:final diagnostics)) {
    return presentationDiagnostic(context, diagnostics);
  }
  final nominal = resolved.valueOrNull!;
  if (!nominal.isConcrete) {
    return _inputDiagnostic("Abstract values require a polymorphic control");
  }
  const payloadId = BindingId(2147483646);
  const payloadReference = BindingReference(bindingId: payloadId);
  final childScope = scope.withVirtualBinding(
    payloadId,
    BindingSnapshot(
      type: nominal.representation,
      value: binding.value,
      revision: binding.revision,
      writable: binding.writable,
    ),
    (next) => scope.update(binding.reference, next),
    interactionTarget: scope.canonical(binding.reference),
  );
  final child =
      ResolvedBinding(
        reference: payloadReference,
        type: nominal.representation,
        value: binding.value,
        revision: binding.revision,
        writable: binding.writable,
      ).renderDefaultPresentation(
        childScope,
        nodeId: "named.${namedType.reference.id}",
      );
  return LabeledControl(control: control, scope: scope, child: child);
}
