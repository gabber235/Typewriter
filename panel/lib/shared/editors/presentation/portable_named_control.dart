import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "portable_named_control.freezed.dart";

typedef PortableBindingSetter =
    FutureOr<PortablePresentationWriteResult> Function(
      skir.BindingRef reference,
      skir.DataValue value,
    );

typedef PortableNamedPayloadBuilder = Widget Function(
  BuildContext context,
  skir.PresentationNode? customPresentation,
  PortableNamedPayload payload,
);

typedef PortableControlUnavailableBuilder = Widget Function(
  BuildContext context,
  String message,
);

@freezed
abstract class PortableNamedPayload with _$PortableNamedPayload {
  const factory PortableNamedPayload({
    required skir.BindingRef reference,
    required skir.NamedTypeUse actualType,
    required skir.DataValue value,
    required skir.ValueLocation location,
    required Map<skir.ExpressionBindingId, PortableExpressionBinding> bindings,
    required skir.EvaluationBudget budget,
    required PortableBindingSetter setBinding,
  }) = _PortableNamedPayload;
  const PortableNamedPayload._();

  PortableExpressionEvaluator evaluator() =>
      PortableExpressionEvaluator.configuredValue(
        value: value,
        location: location,
        budget: budget,
        additional: bindings,
      );

  FutureOr<PortablePresentationWriteResult> replace(
    skir.DataValue replacement,
  ) => setBinding(
    reference,
    skir.DataValue.createNamed(actualType: actualType, payload: replacement),
  );
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

  final skir.NamedControl control;
  final Map<skir.ExpressionBindingId, PortableExpressionBinding> bindings;
  final skir.EvaluationBudget budget;
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
    if (value is! skir.DataValue_namedWrapper) {
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
    final location = skir.ValueLocation(
      resource: baseLocation.resource,
      path: skir.ValuePath(
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
