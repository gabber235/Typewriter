import "package:flutter/widgets.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/binding.dart"
    as binding;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/expression.dart"
    as expression;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/presentation.dart"
    as presentation;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/type_catalog.dart"
    as types;
import "package:typewriter_panel/typewriter_panel.dart";

typedef PortableBindingSetter = void Function(
  binding.BindingRef reference,
  types.DataValue value,
);

typedef PortableNamedPayloadBuilder = Widget Function(
  BuildContext context,
  presentation.PresentationNode? customPresentation,
  PortableNamedPayload payload,
);

typedef PortableControlUnavailableBuilder = Widget Function(
  BuildContext context,
  String message,
);

final class PortableNamedPayload {
  const PortableNamedPayload({
    required this.reference,
    required this.actualType,
    required this.value,
    required this.location,
    required this.bindings,
    required this.budget,
    required this.setBinding,
  });

  final binding.BindingRef reference;
  final types.NamedTypeUse actualType;
  final types.DataValue value;
  final types.ValueLocation location;
  final Map<types.ExpressionBindingId, PortableExpressionBinding> bindings;
  final expression.EvaluationBudget budget;
  final PortableBindingSetter setBinding;

  PortableExpressionEvaluator evaluator() =>
      PortableExpressionEvaluator.configuredValue(
        value: value,
        location: location,
        budget: budget,
        additional: bindings,
      );

  void replace(types.DataValue replacement) {
    setBinding(
      reference,
      types.DataValue.createNamed(actualType: actualType, payload: replacement),
    );
  }
}

final class PortableNamedControlHost extends StatelessWidget {
  const PortableNamedControlHost({
    required this.control,
    required this.bindings,
    required this.budget,
    required this.setBinding,
    required this.builder,
    required this.unavailableBuilder,
    super.key,
  });

  final presentation.NamedControl control;
  final Map<types.ExpressionBindingId, PortableExpressionBinding> bindings;
  final expression.EvaluationBudget budget;
  final PortableBindingSetter setBinding;
  final PortableNamedPayloadBuilder builder;
  final PortableControlUnavailableBuilder unavailableBuilder;

  @override
  Widget build(BuildContext context) {
    final reference = control.control.binding;
    final source = bindings[reference.bindingId];
    if (source == null) {
      return unavailableBuilder(context, "The control binding is unavailable");
    }
    final resolved = reference.path.segments.isEmpty
        ? PortablePathValue(source.value)
        : source.value.readAt(reference.path);
    final value = switch (resolved) {
      PortablePathValue(:final value) => value,
      PortablePathUnavailable() => null,
    };
    if (value is! types.DataValue_namedWrapper) {
      return unavailableBuilder(
        context,
        "The control binding is not a named value",
      );
    }
    final baseLocation = source.location;
    if (baseLocation == null) {
      return unavailableBuilder(
        context,
        "The control binding has no authored location",
      );
    }
    final location = types.ValueLocation(
      resource: baseLocation.resource,
      path: types.ValuePath(
        segments: [...baseLocation.path.segments, ...reference.path.segments],
      ),
    );
    return builder(
      context,
      control.payloadPresentation,
      PortableNamedPayload(
        reference: reference,
        actualType: value.value.actualType,
        value: value.value.payload,
        location: location,
        bindings: bindings,
        budget: budget,
        setBinding: setBinding,
      ),
    );
  }
}
