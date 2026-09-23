/// Encodes the panel presentation model into the canonical editor protocol.
///
/// Catalog producers own presentation meaning and the panel owns rendering, so
/// this boundary carries declarations without transferring persistence or edit
/// ownership. Nested expression, action, and type values are delegated to their
/// codecs instead of being reinterpreted here.
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
part "editor_presentation_composition_encoder.dart";
part "editor_presentation_connection_encoder.dart";
part "editor_presentation_data_encoder.dart";
part "editor_presentation_header_encoder.dart";
part "editor_presentation_input_encoder.dart";
part "editor_presentation_interaction_encoder.dart";
part "editor_presentation_layout_encoder.dart";
part "editor_presentation_search_encoder.dart";
part "editor_presentation_search_provider_encoder.dart";

/// Encodes panel presentation nodes while validating nested protocol values.
///
/// A failed nested conversion makes the whole node conversion fail. That keeps
/// invalid catalog declarations out of the wire contract, unlike decoding where
/// diagnostics can be rendered to explain a bad received node.
final class SkirPresentationEncoder {
  /// Creates an encoder with the codecs needed by nested presentation values.
  const SkirPresentationEncoder(this.expressions, this.actions, this.types);

  /// Encodes expressions used by presentation properties and elements.
  final SkirExpressionEncoder expressions;

  /// Encodes actions exposed by interactive presentation elements.
  final SkirActionEncoder actions;

  /// Encodes type references used by typed fields and polymorphic controls.
  final SkirTypeCodec types;

  /// Encodes one recursive presentation node for catalog transport.
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
        ColumnElement() ||
        RowElement() => _axisChildren(value as ChildrenLayoutElement),
        WrapElement() || StackElement() || GridElement() => _children(value),
        SectionElement() => _section(value),
        ContainerElement() => _container(value),
        PresentationAnchorElement() => _anchor(value),
        ConnectionLayerElement() => _connectionLayer(value),
        PaddingElement() => _padding(value),
        CommitControlsElement() =>
          expressions
              .binding(value.binding)
              .mapValue(
                (binding) => wire.PresentationElement.createCommitControls(
                  binding: binding,
                ),
              ),
        PresentationSlotElement() => _slot(value),
        TabsElement() => _tabs(value),
        DividerElement() => const TypeResult.success(
          wire.PresentationElement.divider,
        ),
        SpacerElement() => _spacer(value),
        AdaptiveLeadingElement() => _adaptiveLeading(value),
        TextElement() => _text(value),
        RichTextElement() => _richText(value),
        MarkdownElement() => _markdown(value),
        IconElement() => _icon(value),
        ImageElement() => _image(value),
        BadgeElement() => _badge(value),
        ChipElement() => _chip(value),
        ProgressElement() => _progress(value),
        StatusElement() => _status(value),
        DateTimeElement() => _dateTime(value),
        RelativeTimeElement() => _relativeTime(value),
        TypedFieldElement() => _typedField(value),
        ConditionalElement() => _conditional(value),
        RepeatedElement() => _repeated(value),
        ScopedBindingElement() => _scoped(value),
        CollectionLookupElement() => _collectionLookup(value),
        CollectionGraphElement() => _collectionGraph(value),
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
        PolymorphicMatchElement() => _polymorphicMatch(value),
        NamedInputElement() => _boundElement(
          value.control,
          wire.PresentationElement.wrapNamedInput,
        ),
        ReferenceInputElement() => _referenceInput(value),
        ButtonElement() => _button(value),
        IconButtonElement() => _iconButton(value),
        MenuElement() => _menu(value),
        TooltipElement() => _tooltip(value),
        DefaultPresentationElement() => _defaultPresentation(value),
        PresentationInvocationElement() => _invocation(value),
        DiagnosticElement() => _diagnostic(value),
      };

  TypeResult<wire_expression.TypedExpression?> _optional(
    TypedExpression? value,
  ) => value == null
      ? const TypeResult.success(null)
      : expressions.encode(value).mapValue((value) => value);
}
