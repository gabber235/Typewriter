import "dart:convert";
import "dart:typed_data";

import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";

extension SimpleInputRendering on PresentationElement {
  Widget render(BuildContext context, PresentationRenderScope scope) {
    final control = switch (this) {
      NumericInputElement(:final control) ||
      ToggleInputElement(:final control) ||
      SimpleInputElement(:final control) => control,
      _ => null,
    };
    if (control == null) return const SizedBox.shrink();
    final result = scope.resolve(control.binding);
    if (result case TypeFailure(:final diagnostics)) {
      return presentationDiagnostic(context, diagnostics);
    }
    final binding = result.valueOrNull!;
    final child = switch (this) {
      NumericInputElement() => binding._numeric(scope),
      ToggleInputElement() => binding._toggle(scope),
      DateTimeInputElement() => binding._timestamp(scope),
      DurationInputElement() => binding._duration(scope),
      BytesInputElement() => binding._bytes(scope),
      EnumInputElement() => binding._enumeration(scope),
      ColorInputElement() ||
      IconInputElement() ||
      NamedInputElement() => binding._named(scope),
      _ => presentationDiagnostic(context, [
        const TypeDiagnostic(
          code: TypeDiagnosticCode.invalidValue,
          message: "Input control is not supported",
        ),
      ]),
    };
    return LabeledControl(control: control, scope: scope, child: child);
  }
}

extension on ResolvedBinding {
  bool _locked(PresentationRenderScope scope) =>
      scope.readOnly || !scope.enabled || !writable;

  Widget _numeric(PresentationRenderScope scope) => DecoratedTextField(
    key: ValueKey((reference, value)),
    text: value.expressionDisplayText,
    enabled: !_locked(scope),
    keyboardType: const TextInputType.numberWithOptions(
      signed: true,
      decimal: true,
    ),
    onChanged: (text) {
      final parsed = type._parseNumber(text);
      if (parsed != null && parsed.validateAgainst(type).isEmpty) {
        scope.update(reference, parsed);
      }
    },
  );

  Widget _toggle(PresentationRenderScope scope) {
    if (type is! BooleanType || value is! BooleanValue) {
      return _diagnostic("Toggle control requires a boolean binding");
    }
    return Switch(
      value: (value as BooleanValue).value,
      onChanged: _locked(scope)
          ? null
          : (next) => scope.update(reference, BooleanValue(next)),
    );
  }

  Widget _enumeration(PresentationRenderScope scope) {
    if (type case EnumType(:final values)) {
      return Dropdown<DataValue>(
        selected: values.contains(value) ? value : null,
        dropdownMenuEntries: [
          for (final option in values)
            DropdownMenuEntry(
              value: option,
              label: option.expressionDisplayText,
            ),
        ],
        enabled: !_locked(scope),
        onSelected: (next) {
          if (next != null) scope.update(reference, next);
        },
      );
    }
    return _diagnostic("Enum control requires an enum binding");
  }

  Widget _timestamp(PresentationRenderScope scope) => _textValue(
    scope,
    value is TimestampValue
        ? (value as TimestampValue).value.toIso8601String()
        : null,
    (text) {
      final parsed = DateTime.tryParse(text);
      return parsed == null ? null : TimestampValue(parsed);
    },
    "Timestamp control requires an ISO 8601 timestamp binding",
  );

  Widget _duration(PresentationRenderScope scope) => _textValue(
    scope,
    value is DurationValue
        ? (value as DurationValue).value.inMilliseconds.toString()
        : null,
    (text) {
      final milliseconds = int.tryParse(text);
      return milliseconds == null
          ? null
          : DurationValue(Duration(milliseconds: milliseconds));
    },
    "Duration control requires milliseconds",
  );

  Widget _bytes(PresentationRenderScope scope) => _textValue(
    scope,
    value is BytesValue ? base64Encode((value as BytesValue).value) : null,
    (text) {
      try {
        return BytesValue(Uint8List.fromList(base64Decode(text)));
      } on FormatException {
        return null;
      }
    },
    "Bytes control requires base64 content",
  );

  Widget _textValue(
    PresentationRenderScope scope,
    String? text,
    DataValue? Function(String) parse,
    String diagnostic,
  ) {
    if (text == null) return _diagnostic(diagnostic);
    return DecoratedTextField(
      key: ValueKey((reference, value)),
      text: text,
      enabled: !_locked(scope),
      onChanged: (next) {
        final parsed = parse(next);
        if (parsed != null && parsed.validateAgainst(type).isEmpty) {
          scope.update(reference, parsed);
        }
      },
    );
  }

  Widget _named(PresentationRenderScope scope) {
    if (type is! NamedType) {
      return _diagnostic("Named control requires a nominal binding");
    }
    final resolved = scope.registry.resolve(type as NamedType);
    if (resolved case TypeFailure(:final diagnostics)) {
      return Builder(
        builder: (context) => presentationDiagnostic(context, diagnostics),
      );
    }
    final nominal = resolved.valueOrNull!;
    if (!nominal.isConcrete) {
      return _diagnostic("Abstract values require a polymorphic control");
    }
    const payloadId = BindingId(2147483646);
    const payloadReference = BindingReference(bindingId: payloadId);
    final childScope = scope.withVirtualBinding(
      payloadId,
      BindingSnapshot(
        type: nominal.representation,
        value: value,
        revision: revision,
        writable: writable,
      ),
      (next) => scope.update(reference, next),
    );
    return ResolvedBinding(
      reference: payloadReference,
      type: nominal.representation,
      value: value,
      revision: revision,
      writable: writable,
    ).renderDefaultPresentation(
      childScope,
      nodeId: "named.${(type as NamedType).reference.id}",
    );
  }

  Widget _diagnostic(String message) => Builder(
    builder: (context) => presentationDiagnostic(context, [
      TypeDiagnostic(code: TypeDiagnosticCode.invalidValue, message: message),
    ]),
  );
}

extension on TypeExpression {
  DataValue? _parseNumber(String text) => switch (this) {
    IntegerType() => switch (BigInt.tryParse(text)) {
      final value? => IntegerValue(value),
      null => null,
    },
    FloatType() => switch (double.tryParse(text)) {
      final value? => FloatValue(value),
      null => null,
    },
    DecimalType() =>
      RegExp(r"^-?(0|[1-9][0-9]*)(\.[0-9]+)?$").hasMatch(text)
          ? DecimalValue(text)
          : null,
    _ => null,
  };
}
