part of "editor_presentation_encoder.dart";

extension SkirPresentationInputEncoder on SkirPresentationEncoder {
  TypeResult<wire.BoundControl> _bound(BoundControl value) {
    final binding = expressions.binding(value.binding);
    final label = _optional(value.label);
    final description = _optional(value.description);
    final diagnostics = [
      ...binding.diagnostics,
      ...label.diagnostics,
      ...description.diagnostics,
    ];
    return diagnostics.isEmpty
        ? TypeResult.success(
            wire.BoundControl(
              binding: binding.valueOrNull!,
              label: label.valueOrNull,
              description: description.valueOrNull,
            ),
          )
        : TypeResult.failure(diagnostics);
  }

  TypeResult<wire.PresentationElement> _boundElement(
    BoundControl value,
    wire.PresentationElement Function(wire.BoundControl) wrap,
  ) => _bound(value).mapValue(wrap);

  TypeResult<wire.PresentationElement> _textInput(TextInputElement value) {
    final control = _bound(value.control);
    final placeholder = _optional(value.placeholder);
    return combineResults(
      control,
      placeholder,
      (control, placeholder) => wire.PresentationElement.createTextInput(
        control: control,
        multiline: value.multiline,
        placeholder: placeholder,
      ),
    );
  }

  TypeResult<wire.PresentationElement> _colorInput(ColorInputElement value) =>
      _bound(value.control).mapValue(
        (control) => wire.PresentationElement.createColorInput(
          control: control,
          includeAlpha: value.includeAlpha,
        ),
      );

  TypeResult<wire.PresentationElement> _dateTimeInput(
    DateTimeInputElement value,
  ) => _bound(value.control).mapValue(
    (control) => wire.PresentationElement.createDateTimeInput(
      control: control,
      includeDate: value.includeDate,
      includeTime: value.includeTime,
    ),
  );

  TypeResult<wire.PresentationElement> _select(SelectInputElement value) {
    final control = _bound(value.control);
    final options = <wire.SelectOption>[];
    final diagnostics = <TypeDiagnostic>[...control.diagnostics];
    for (final option in value.options) {
      final label = expressions.encode(option.label);
      final item = expressions.encode(option.value);
      diagnostics
        ..addAll(label.diagnostics)
        ..addAll(item.diagnostics);
      if (label.valueOrNull case final encodedLabel?) {
        if (item.valueOrNull case final encodedValue?) {
          options.add(
            wire.SelectOption(
              optionId: option.id,
              label: encodedLabel,
              value: encodedValue,
            ),
          );
        }
      }
    }
    return diagnostics.isEmpty
        ? TypeResult.success(
            wire.PresentationElement.createSelectInput(
              control: control.valueOrNull!,
              options: options,
              allowCustomValue: value.allowCustomValue,
            ),
          )
        : TypeResult.failure(diagnostics);
  }

  TypeResult<wire.PresentationElement> _slider(SliderInputElement value) {
    final control = _bound(value.control);
    final minimum = expressions.encode(value.minimum);
    final maximum = expressions.encode(value.maximum);
    final divisions = _optional(value.divisions);
    final diagnostics = [
      ...control.diagnostics,
      ...minimum.diagnostics,
      ...maximum.diagnostics,
      ...divisions.diagnostics,
    ];
    return diagnostics.isEmpty
        ? TypeResult.success(
            wire.PresentationElement.createSliderInput(
              control: control.valueOrNull!,
              minimum: minimum.valueOrNull!,
              maximum: maximum.valueOrNull!,
              divisions: divisions.valueOrNull,
            ),
          )
        : TypeResult.failure(diagnostics);
  }

  TypeResult<wire.PresentationElement> _listInput(ListInputElement value) {
    final control = _bound(value.control);
    final item = value.itemPresentation == null
        ? const TypeResult<wire.PresentationNode?>.success(null)
        : encodeNode(value.itemPresentation!).mapValue((value) => value);
    return combineResults(
      control,
      item,
      (control, item) => wire.PresentationElement.createListInput(
        control: control,
        itemPresentation: item,
        allowAdd: value.allowAdd,
        allowRemove: value.allowRemove,
        allowReorder: value.allowReorder,
        itemBindingId: wire_binding.BindingId(value: value.itemBindingId.value),
        indexBindingId: wire_binding.BindingId(
          value: value.indexBindingId.value,
        ),
      ),
    );
  }

  TypeResult<wire.PresentationElement> _mapInput(MapInputElement value) {
    final control = _bound(value.control);
    final key = value.keyPresentation == null
        ? const TypeResult<wire.PresentationNode?>.success(null)
        : encodeNode(value.keyPresentation!).mapValue((value) => value);
    final item = value.valuePresentation == null
        ? const TypeResult<wire.PresentationNode?>.success(null)
        : encodeNode(value.valuePresentation!).mapValue((value) => value);
    final diagnostics = [
      ...control.diagnostics,
      ...key.diagnostics,
      ...item.diagnostics,
    ];
    return diagnostics.isEmpty
        ? TypeResult.success(
            wire.PresentationElement.createMapInput(
              control: control.valueOrNull!,
              keyPresentation: key.valueOrNull,
              valuePresentation: item.valueOrNull,
              allowAdd: value.allowAdd,
              allowRemove: value.allowRemove,
              keyBindingId: wire_binding.BindingId(
                value: value.keyBindingId.value,
              ),
              valueBindingId: wire_binding.BindingId(
                value: value.valueBindingId.value,
              ),
            ),
          )
        : TypeResult.failure(diagnostics);
  }

  TypeResult<wire.PresentationElement> _recordInput(RecordInputElement value) {
    final control = _bound(value.control);
    final field = value.fieldPresentation == null
        ? const TypeResult<wire.PresentationNode?>.success(null)
        : encodeNode(value.fieldPresentation!).mapValue((value) => value);
    return combineResults(
      control,
      field,
      (control, field) => wire.PresentationElement.createRecordInput(
        control: control,
        fieldPresentation: field,
      ),
    );
  }

  TypeResult<wire.PresentationElement> _polymorphic(
    PolymorphicInputElement value,
  ) {
    final control = _bound(value.control);
    final types = <wire.ConcreteTypePresentation>[];
    final diagnostics = <TypeDiagnostic>[...control.diagnostics];
    for (final item in value.concreteTypes) {
      final type = this.types.encodeReference(item.type);
      final label = expressions.encode(item.label);
      final presentation = item.presentation == null
          ? const TypeResult<wire.PresentationNode?>.success(null)
          : encodeNode(item.presentation!).mapValue((value) => value);
      diagnostics
        ..addAll(type.diagnostics)
        ..addAll(label.diagnostics)
        ..addAll(presentation.diagnostics);
      if (type.valueOrNull case final encodedType?) {
        if (label.valueOrNull case final encodedLabel?) {
          types.add(
            wire.ConcreteTypePresentation(
              concreteType: encodedType,
              label: encodedLabel,
              presentation: presentation.valueOrNull,
            ),
          );
        }
      }
    }
    return diagnostics.isEmpty
        ? TypeResult.success(
            wire.PresentationElement.createPolymorphicInput(
              control: control.valueOrNull!,
              concreteTypes: types,
            ),
          )
        : TypeResult.failure(diagnostics);
  }
}
