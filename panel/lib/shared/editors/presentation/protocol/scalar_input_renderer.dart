import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";

extension ScalarInputRendering on PresentationElement {
  Widget render(BuildContext context, PresentationRenderScope scope) {
    final element = this;
    return switch (element) {
      TextInputElement() => _TextInput(element: element, scope: scope),
      SelectInputElement() => _SelectInput(element: element, scope: scope),
      SliderInputElement() => _SliderInput(element: element, scope: scope),
      _ => const SizedBox.shrink(),
    };
  }
}

class _TextInput extends StatelessWidget {
  const _TextInput({required this.element, required this.scope});

  final TextInputElement element;
  final PresentationRenderScope scope;

  @override
  Widget build(BuildContext context) {
    final resolved = scope.resolve(element.control.binding);
    if (resolved case TypeFailure(:final diagnostics)) {
      return presentationDiagnostic(context, diagnostics);
    }
    final binding = resolved.valueOrNull!;
    final text = switch (binding.value) {
      StringValue(:final value) => value,
      _ => null,
    };
    if (text == null || binding.type is! StringType) {
      return presentationDiagnostic(context, [
        const TypeDiagnostic(
          code: TypeDiagnosticCode.invalidValue,
          message: "Text control requires a string binding",
        ),
      ]);
    }
    return LabeledControl(
      control: element.control,
      scope: scope,
      child: DecoratedTextField(
        key: ValueKey((element.control.binding, text)),
        text: text,
        enabled: scope.enabled && !scope.readOnly && binding.writable,
        minLines: element.multiline ? 3 : 1,
        maxLines: element.multiline ? 8 : 1,
        decoration: InputDecoration(
          hintText: element.placeholder == null
              ? null
              : scope.expressionText(element.placeholder!),
        ),
        onChanged: (next) {
          final value = StringValue(next);
          if (value.validateAgainst(binding.type).isEmpty) {
            scope.update(element.control.binding, value);
          }
        },
      ),
    );
  }
}

class _SelectInput extends StatelessWidget {
  const _SelectInput({required this.element, required this.scope});

  final SelectInputElement element;
  final PresentationRenderScope scope;

  @override
  Widget build(BuildContext context) {
    final resolved = scope.resolve(element.control.binding);
    if (resolved case TypeFailure(:final diagnostics)) {
      return presentationDiagnostic(context, diagnostics);
    }
    final binding = resolved.valueOrNull!;
    final options = [
      for (final option in element.options)
        if (scope.evaluate(option.value).valueOrNull case final value?)
          (option, value),
    ];
    return LabeledControl(
      control: element.control,
      scope: scope,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Dropdown<DataValue>(
            selected: options.any((option) => option.$2 == binding.value)
                ? binding.value
                : null,
            dropdownMenuEntries: [
              for (final option in options)
                DropdownMenuEntry(
                  value: option.$2,
                  label: scope.expressionText(option.$1.label),
                ),
            ],
            enabled: !scope.readOnly && scope.enabled && binding.writable,
            onSelected: (value) {
              if (value != null) scope.update(element.control.binding, value);
            },
          ),
          if (element.allowCustomValue) ...[
            const SizedBox(height: 8),
            ProtocolBoundValueEditor(
              control: BoundControl(binding: element.control.binding),
              scope: scope,
            ),
          ],
        ],
      ),
    );
  }
}

class _SliderInput extends StatelessWidget {
  const _SliderInput({required this.element, required this.scope});

  final SliderInputElement element;
  final PresentationRenderScope scope;

  @override
  Widget build(BuildContext context) {
    final resolved = scope.resolve(element.control.binding);
    if (resolved case TypeFailure(:final diagnostics)) {
      return presentationDiagnostic(context, diagnostics);
    }
    final binding = resolved.valueOrNull!;
    final value = binding.value._number;
    final minimum = scope.evaluate(element.minimum).valueOrNull._number;
    final maximum = scope.evaluate(element.maximum).valueOrNull._number;
    final divisions = element.divisions._divisions(scope);
    if (value == null ||
        minimum == null ||
        maximum == null ||
        minimum >= maximum) {
      return presentationDiagnostic(context, [
        const TypeDiagnostic(
          code: TypeDiagnosticCode.invalidValue,
          message: "Slider values are invalid",
        ),
      ]);
    }
    return LabeledControl(
      control: element.control,
      scope: scope,
      child: Slider(
        value: value.clamp(minimum, maximum),
        min: minimum,
        max: maximum,
        divisions: divisions,
        onChanged: scope.readOnly || !scope.enabled || !binding.writable
            ? null
            : (next) {
                final typed = switch (binding.type) {
                  IntegerType() => IntegerValue(BigInt.from(next.round())),
                  FloatType() => FloatValue(next),
                  DecimalType() => DecimalValue(next.toString()),
                  _ => null,
                };
                if (typed != null) scope.update(element.control.binding, typed);
              },
      ),
    );
  }
}

extension on TypedExpression? {
  int? _divisions(PresentationRenderScope scope) {
    if (this == null) return null;
    final value = scope.evaluate(this!).valueOrNull;
    if (value case IntegerValue(:final value)) {
      final divisions = value.toInt();
      return divisions > 0 ? divisions : null;
    }
    return null;
  }
}

extension on DataValue? {
  double? get _number => switch (this) {
    IntegerValue(:final value) => value.toDouble(),
    FloatValue(:final value) => value,
    DecimalValue(:final value) => double.tryParse(value),
    _ => null,
  };
}
