library;

import "package:typewriter_panel/infrastructure/protocols/skir/editor_codec_support.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/binding.dart"
    as wire_binding;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/expression.dart"
    as wire_expression;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/presentation.dart"
    as wire;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/type_catalog.dart"
    as wire_type;
import "package:typewriter_panel/typewriter_panel.dart";

part "editor_presentation_content_encoder.dart";
part "editor_presentation_data_encoder.dart";
part "editor_presentation_header_encoder.dart";
part "editor_presentation_input_encoder.dart";
part "editor_presentation_interaction_encoder.dart";
part "editor_presentation_layout_encoder.dart";
part "editor_presentation_search_encoder.dart";
part "editor_presentation_search_provider_encoder.dart";

final class SkirPresentationEncoder {
  const SkirPresentationEncoder(this.expressions, this.actions, this.types);

  final SkirExpressionEncoder expressions;
  final SkirActionEncoder actions;
  final SkirTypeCodec types;

  TypeResult<wire.PresentationNode> encodeNode(PresentationNode value) {
    final element = _element(value.element);
    final enabled = _optional(value.properties.enabledIf);
    final header = value.header == null
        ? const TypeResult<wire.PresentationHeader?>.success(null)
        : _header(value.header!).mapValue((value) => value);
    final diagnostics = [
      ...element.diagnostics,
      ...enabled.diagnostics,
      ...header.diagnostics,
    ];
    return diagnostics.isEmpty
        ? TypeResult.success(
            wire.PresentationNode(
              nodeId: value.id,
              properties: wire.PresentationProperties(
                enabledIf: enabled.valueOrNull,
                readOnly: value.properties.readOnly,
              ),
              element: element.valueOrNull,
              header: header.valueOrNull,
            ),
          )
        : TypeResult.failure(diagnostics);
  }

  TypeResult<wire.PresentationElement> _element(PresentationElement value) =>
      switch (value) {
        ColumnElement() => _children(
          value,
          wire.PresentationElement.wrapColumn,
        ),
        RowElement() => _children(value, wire.PresentationElement.wrapRow),
        WrapElement() => _children(value, wire.PresentationElement.wrapWrap),
        StackElement() => _children(value, wire.PresentationElement.wrapStack),
        GridElement() => _grid(value),
        CardElement() => encodeNode(value.child).mapValue(
          (child) => wire.PresentationElement.createCard(
            child: child,
            initiallyExpanded: value.initiallyExpanded,
          ),
        ),
        SectionElement() => _section(value),
        TabsElement() => _tabs(value),
        DividerElement() => const TypeResult.success(
          wire.PresentationElement.divider,
        ),
        SpacerElement() => _spacer(value),
        TextElement() => _text(value.value, wire.PresentationElement.wrapText),
        MarkdownElement() => _text(
          value.value,
          wire.PresentationElement.wrapMarkdown,
        ),
        IconElement() => _icon(value),
        ImageElement() => _image(value),
        BadgeElement() => _badge(value),
        ProgressElement() => _progress(value),
        TypedFieldElement() => _typedField(value),
        ConditionalElement() => _conditional(value),
        RepeatedElement() => _repeated(value),
        ScopedBindingElement() => _scoped(value),
        TextInputElement() => _textInput(value),
        NumericInputElement() => _boundElement(
          value.control,
          wire.PresentationElement.wrapNumericInput,
        ),
        ToggleInputElement() => _boundElement(
          value.control,
          wire.PresentationElement.wrapToggleInput,
        ),
        SelectInputElement() => _select(value),
        SliderInputElement() => _slider(value),
        DateTimeInputElement() => _dateTimeInput(value),
        DurationInputElement() => _boundElement(
          value.control,
          wire.PresentationElement.wrapDurationInput,
        ),
        ColorInputElement() => _colorInput(value),
        SearchInputElement() => _searchInput(value),
        BytesInputElement() => _boundElement(
          value.control,
          wire.PresentationElement.wrapBytesInput,
        ),
        ListInputElement() => _listInput(value),
        MapInputElement() => _mapInput(value),
        RecordInputElement() => _recordInput(value),
        EnumInputElement() => _boundElement(
          value.control,
          wire.PresentationElement.wrapEnumInput,
        ),
        PolymorphicInputElement() => _polymorphic(value),
        NamedInputElement() => _boundElement(
          value.control,
          wire.PresentationElement.wrapNamedInput,
        ),
        ButtonElement() => _button(value),
        IconButtonElement() => _iconButton(value),
        MenuElement() => _menu(value),
        TooltipElement() => _tooltip(value),
        DefaultPresentationElement() => _defaultPresentation(value),
        CollapsibleElement() => _collapsible(value),
        DiagnosticElement() => _diagnostic(value),
      };

  TypeResult<wire_expression.TypedExpression?> _optional(
    TypedExpression? value,
  ) => value == null
      ? const TypeResult.success(null)
      : expressions.encode(value).mapValue((value) => value);
}
