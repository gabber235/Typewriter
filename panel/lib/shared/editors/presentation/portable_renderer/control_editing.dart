part of "../portable_presentation_renderer.dart";

skir.DataValue _payloadReplacement(
  PortablePresentationScope scope,
  skir.BindingRef reference,
  skir.DataValue payload,
) {
  final current = scope.read(reference);
  final expected = scope.expectedType(reference).withoutNullableWrappers;
  return current is skir.DataValue_namedWrapper
      ? current.preservingNamedIdentity(payload)
      : expected is skir.TypeUse_namedWrapper
      ? skir.DataValue.createNamed(actualType: expected.value, payload: payload)
      : payload;
}

PortableExpressionResult _evaluateMapping(
  PortablePresentationScope scope,
  skir.ExpressionMapping mapping,
  skir.DataValue candidate, {
  skir.TypeUse? candidateType,
}) => scope
    .copyWith(
      bindings: {
        ...scope.bindings,
        mapping.inputBinding: PortableExpressionBinding(
          value: candidate,
          schema: candidateType == null
              ? null
              : CompletePortablePresentationBinding(candidateType),
        ),
      },
    )
    .evaluate(mapping.body);

String? _mappedDisplay(
  PortablePresentationScope scope,
  skir.ValueMappings? mappings,
  skir.DataValue value, {
  required skir.BindingRef reference,
}) {
  final mapping = mappings?.display;
  if (mapping == null ||
      value == skir.DataValue.unfilled ||
      value == skir.DataValue.null_) {
    return null;
  }
  final result = _evaluateMapping(
    scope,
    mapping,
    value,
    candidateType: scope.expectedPayloadType(reference),
  );
  return result is PortableExpressionAvailable &&
          result.value is skir.DataValue_stringValueWrapper
      ? (result.value as skir.DataValue_stringValueWrapper).value
      : null;
}

/// Serializes one mounted editor's writes through its existing host.
class _PortableEntryEditing extends HookWidget {
  const _PortableEntryEditing({
    required this.scope,
    required this.control,
    required this.mappings,
    required this.parse,
    required this.builder,
    this.validate,
    super.key,
  });
  final PortablePresentationScope scope;
  final skir.BoundControl control;
  final skir.ValueMappings? mappings;
  final skir.DataValue Function(String) parse;
  final String? Function(skir.DataValue)? validate;
  final Widget Function(
    BuildContext,
    ValueChanged<skir.DataValue>,
    ValueChanged<TextEditingValue>,
    void Function(skir.DataValue? Function(PortablePresentationScope)),
  )
  builder;

  @override
  Widget build(BuildContext context) {
    final latest = useRef(scope)..value = scope;
    final latestValidation = useRef(validate)..value = validate;
    final active = useRef(true);
    final tail = useRef(Future<void>.value());
    final edited = useRef(false);
    final observedSource = useRef(scope.read(control.binding));
    final lastAccepted = useRef(scope.read(control.binding));
    final sourceValue = scope.read(control.binding);
    if (sourceValue != observedSource.value) {
      observedSource.value = sourceValue;
      lastAccepted.value = sourceValue;
    }
    final identity = useMemoized(Object.new, [
      scope.nativeSourceIdentity(control.binding),
      scope.diagnosticTarget(control.binding),
      control.binding,
      mappings,
    ]);
    final latestIdentity = useRef(identity)..value = identity;
    useEffect(() {
      active.value = true;
      edited.value = false;
      tail.value = Future<void>.value();
      return () {
        active.value = false;
      };
    }, [identity]);
    Future<void> feedback(String? message, {required bool completion}) {
      final source = latest.value;
      final target = source.diagnosticTarget(control.binding);
      return source.operations.run(
        key: PortableOperationKey.mapping(target, completion: completion),
        input: PortableDiagnosticObservation(
          target: target,
          value: source.read(control.binding),
        ),
        operation: () => message == null
            ? const PortablePresentationWriteApplied()
            : PortablePresentationWriteRejected([
                PortablePresentationDiagnostic(
                  code: completion ? "completion_failed" : "display_failed",
                  message: message,
                  severity: skir.DiagnosticSeverity.error,
                  targets: [target],
                ),
              ]),
      );
    }

    final currentPayload = scope.read(control.binding)?.authoredPayload;
    useEffect(() {
      final mapping = mappings?.display;
      if (mapping == null ||
          currentPayload == null ||
          currentPayload == skir.DataValue.unfilled ||
          currentPayload == skir.DataValue.null_) {
        return null;
      }
      final result = _evaluateMapping(
        scope,
        mapping,
        currentPayload,
        candidateType: scope.expectedPayloadType(control.binding),
      );
      final message =
          result is PortableExpressionAvailable &&
              result.value is skir.DataValue_stringValueWrapper
          ? null
          : "The display expression could not produce text. The exact value is shown.";
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (active.value &&
            latestIdentity.value == identity &&
            latest.value.read(control.binding)?.authoredPayload ==
                currentPayload) {
          unawaited(feedback(message, completion: false));
        }
      });
      return null;
    }, [currentPayload, mappings?.display, scope.bindings]);
    void enqueue(Future<void> Function() operation) {
      tail.value = tail.value.then((_) async {
        if (active.value && latestIdentity.value == identity) await operation();
      });
    }

    Future<void> write(
      skir.DataValue payload, {
      Iterable<PortableExpressionRead> reads = const [],
    }) async {
      if (!active.value || latestIdentity.value != identity) return;
      final current = latest.value;
      final replacement =
          payload == skir.DataValue.unfilled || payload == skir.DataValue.null_
          ? payload
          : _payloadReplacement(current, control.binding, payload);
      if (replacement == lastAccepted.value) return;
      PortablePresentationWriteResult? outcome;
      await current.operations.run(
        key: PortableOperationKey.write(
          current.diagnosticTarget(control.binding),
        ),
        input: PortableDiagnosticObservation(
          target: current.diagnosticTarget(control.binding),
          value: current.read(control.binding),
        ),
        operation: () async {
          outcome = await current.apply(
            control.binding,
            replacement,
            reads: reads,
          );
          return outcome!;
        },
      );
      if (active.value &&
          latestIdentity.value == identity &&
          outcome is PortablePresentationWriteApplied) {
        lastAccepted.value = replacement;
        if (current.host!.document.bindings.isNotEmpty ||
            mappings?.completion != null) {
          await WidgetsBinding.instance.endOfFrame;
        }
      }
    }

    return builder(
      context,
      (candidate) {
        edited.value = true;
        enqueue(() => write(candidate));
      },
      (raw) {
        if (!edited.value ||
            raw.composing.isValid && !raw.composing.isCollapsed) {
          return;
        }
        edited.value = false;
        final mapping = mappings?.completion;
        if (mapping == null) return;
        skir.DataValue candidate;
        try {
          candidate = parse(raw.text);
        } on FormatException {
          return;
        }
        if (candidate == skir.DataValue.unfilled ||
            candidate == skir.DataValue.null_) {
          return;
        }
        enqueue(() async {
          final source = latest.value;
          if (source.read(control.binding)?.authoredPayload != candidate) {
            await feedback(
              "The edited value changed before completion",
              completion: true,
            );
            return;
          }
          final result = _evaluateMapping(
            source,
            mapping,
            candidate,
            candidateType: source.expectedPayloadType(control.binding),
          );
          if (result is! PortableExpressionAvailable) {
            await feedback(
              "The completion expression could not produce a value",
              completion: true,
            );
            return;
          }
          var replacement = result.value;
          if (replacement.runtimeType != candidate.runtimeType ||
              replacement == skir.DataValue.unfilled ||
              replacement == skir.DataValue.null_) {
            await feedback(
              "The completion expression returned a different value type",
              completion: true,
            );
            return;
          }
          final numericText = switch (replacement) {
            skir.DataValue_integerWrapper(:final value) ||
            skir.DataValue_decimalWrapper(:final value) => value,
            skir.DataValue_floatWrapper(:final value) => value.toString(),
            _ => null,
          };
          if (numericText != null) {
            final admitted = admitPortableNumericInput(
              current: candidate,
              expected: source.expectedPayloadType(control.binding),
              text: numericText,
            );
            if (admitted == null) {
              await feedback(
                "The completion value exceeds the bound scalar range",
                completion: true,
              );
              return;
            }
            replacement = admitted;
          }
          final message = latestValidation.value?.call(replacement);
          if (message != null) {
            await feedback(message, completion: true);
            return;
          }
          await feedback(null, completion: true);
          await write(replacement, reads: result.reads);
        });
      },
      (transform) => enqueue(() async {
        final replacement = transform(latest.value);
        if (replacement != null) await write(replacement);
      }),
    );
  }
}
