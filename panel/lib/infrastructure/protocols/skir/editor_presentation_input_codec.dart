part of "editor_presentation_codec.dart";

extension SkirPresentationInputDecoder on SkirPresentationDecoder {
  TypeResult<BoundControl> _bound(wire.BoundControl value) {
    final binding = expressions.binding(value.binding);
    final label = _optionalExpression(value.label);
    final description = _optionalExpression(value.description);
    final semanticLabel = _optionalExpression(value.semanticLabel);
    final diagnostics = [
      ...binding.diagnostics,
      ...label.diagnostics,
      ...description.diagnostics,
      ...semanticLabel.diagnostics,
    ];
    return diagnostics.isEmpty
        ? TypeResult.success(
            BoundControl(
              binding: binding.valueOrNull!,
              label: label.valueOrNull,
              description: description.valueOrNull,
              prefix: value.prefix == null ? null : decodeNode(value.prefix!),
              semanticLabel: semanticLabel.valueOrNull,
            ),
          )
        : TypeResult.failure(diagnostics);
  }

  TypeResult<PresentationElement> _textInput(wire.TextControl value) {
    final control = _bound(value.control);
    final placeholder = _optionalExpression(value.placeholder);
    return combineResults(control, placeholder, (control, placeholder) {
      return TextInputElement(
        control: control,
        multiline: value.multiline ?? true,
        placeholder: placeholder,
      );
    });
  }

  TypeResult<PresentationElement> _colorInput(wire.ColorControl value) =>
      _bound(value.control).mapValue(
        (control) => ColorInputElement(
          control: control,
          includeAlpha: value.includeAlpha,
        ),
      );

  TypeResult<PresentationElement> _dateTimeInput(wire.DateTimeControl value) =>
      _bound(value.control).mapValue(
        (control) => DateTimeInputElement(
          control: control,
          includeDate: value.includeDate ?? true,
          includeTime: value.includeTime ?? true,
        ),
      );

  TypeResult<PresentationElement> _select(wire.SelectControl value) {
    final control = _bound(value.control);
    final options = <SelectOption>[];
    final diagnostics = <TypeDiagnostic>[...control.diagnostics];
    for (final option in value.options) {
      final label = expressions.decode(option.label);
      final item = expressions.decode(option.value);
      diagnostics
        ..addAll(label.diagnostics)
        ..addAll(item.diagnostics);
      if (option.optionId.isEmpty) {
        diagnostics.add(wireDiagnostic("Select option id is empty"));
      } else if (label.valueOrNull case final decodedLabel?) {
        if (item.valueOrNull case final decodedValue?) {
          options.add(
            SelectOption(
              id: option.optionId,
              label: decodedLabel,
              value: decodedValue,
            ),
          );
        }
      }
    }
    return diagnostics.isEmpty
        ? TypeResult.success(
            SelectInputElement(
              control: control.valueOrNull!,
              options: options,
              allowCustomValue: value.allowCustomValue,
            ),
          )
        : TypeResult.failure(diagnostics);
  }

  TypeResult<PresentationElement> _slider(wire.SliderControl value) {
    final control = _bound(value.control);
    final minimum = expressions.decode(value.minimum);
    final maximum = expressions.decode(value.maximum);
    final divisions = _optionalExpression(value.divisions);
    final diagnostics = [
      ...control.diagnostics,
      ...minimum.diagnostics,
      ...maximum.diagnostics,
      ...divisions.diagnostics,
    ];
    return diagnostics.isEmpty
        ? TypeResult.success(
            SliderInputElement(
              control: control.valueOrNull!,
              minimum: minimum.valueOrNull!,
              maximum: maximum.valueOrNull!,
              divisions: divisions.valueOrNull,
            ),
          )
        : TypeResult.failure(diagnostics);
  }

  TypeResult<PresentationElement> _listInput(wire.ListControl value) =>
      _bound(value.control).mapValue(
        (control) => ListInputElement(
          control: control,
          itemPresentation: value.itemPresentation == null
              ? null
              : decodeNode(value.itemPresentation!),
          allowAdd: value.allowAdd,
          allowRemove: value.allowRemove,
          allowReorder: value.allowReorder,
          itemBindingId: value.itemBindingId.value < 0
              ? const BindingId(1)
              : BindingId(value.itemBindingId.value),
          indexBindingId: value.indexBindingId.value < 0
              ? const BindingId(2)
              : BindingId(value.indexBindingId.value),
        ),
      );

  TypeResult<PresentationElement> _mapInput(wire.MapControl value) =>
      _bound(value.control).mapValue(
        (control) => MapInputElement(
          control: control,
          keyPresentation: value.keyPresentation == null
              ? null
              : decodeNode(value.keyPresentation!),
          valuePresentation: value.valuePresentation == null
              ? null
              : decodeNode(value.valuePresentation!),
          allowAdd: value.allowAdd,
          allowRemove: value.allowRemove,
          keyBindingId: value.keyBindingId.value < 0
              ? const BindingId(1)
              : BindingId(value.keyBindingId.value),
          valueBindingId: value.valueBindingId.value < 0
              ? const BindingId(2)
              : BindingId(value.valueBindingId.value),
        ),
      );

  TypeResult<PresentationElement> _recordInput(wire.RecordControl value) =>
      _bound(value.control).mapValue(
        (control) => RecordInputElement(
          control: control,
          fieldPresentation: value.fieldPresentation == null
              ? null
              : decodeNode(value.fieldPresentation!),
        ),
      );

  TypeResult<PresentationElement> _polymorphic(wire.PolymorphicControl value) {
    final control = _bound(value.control);
    final concreteTypes = <ConcreteTypePresentation>[];
    final diagnostics = <TypeDiagnostic>[...control.diagnostics];
    for (final item in value.concreteTypes) {
      final type = types.decodeReference(item.concreteType);
      final label = expressions.decode(item.label);
      diagnostics
        ..addAll(type.diagnostics)
        ..addAll(label.diagnostics);
      if (type.valueOrNull case final decodedType?) {
        if (label.valueOrNull case final decodedLabel?) {
          concreteTypes.add(
            ConcreteTypePresentation(
              type: decodedType,
              label: decodedLabel,
              presentation: item.presentation == null
                  ? null
                  : decodeNode(item.presentation!),
            ),
          );
        }
      }
    }
    if (concreteTypes.isEmpty) {
      diagnostics.add(wireDiagnostic("Polymorphic control has no types"));
    }
    return diagnostics.isEmpty
        ? TypeResult.success(
            PolymorphicInputElement(
              control: control.valueOrNull!,
              concreteTypes: concreteTypes,
            ),
          )
        : TypeResult.failure(diagnostics);
  }
}
