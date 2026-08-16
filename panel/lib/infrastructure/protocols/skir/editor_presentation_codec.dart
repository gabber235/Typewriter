library;

import "package:typewriter_panel/infrastructure/protocols/skir/editor_codec_support.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/expression.dart"
    as wire_expression;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/presentation.dart"
    as wire;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/type_catalog.dart"
    as wire_type;
import "package:typewriter_panel/typewriter_panel.dart";

part "editor_presentation_content_codec.dart";
part "editor_presentation_data_codec.dart";
part "editor_presentation_header_codec.dart";
part "editor_presentation_input_codec.dart";
part "editor_presentation_interaction_codec.dart";
part "editor_presentation_layout_codec.dart";
part "editor_presentation_search_codec.dart";
part "editor_presentation_search_provider_codec.dart";

final class SkirPresentationDecoder {
  const SkirPresentationDecoder(this.expressions, this.actions, this.types);

  final SkirExpressionDecoder expressions;
  final SkirActionDecoder actions;
  final SkirTypeCodec types;

  PresentationNode decodeNode(wire.PresentationNode value) {
    final enabled = _optionalExpression(value.properties.enabledIf);
    final element = value.element == null
        ? invalidWire<PresentationElement>("Presentation element is missing")
        : _element(value.element!);
    final diagnostics = [...enabled.diagnostics, ...element.diagnostics];
    return PresentationNode(
      id: value.nodeId.isEmpty ? "wire.invalid" : value.nodeId,
      properties: PresentationProperties(
        enabledIf: enabled.valueOrNull,
        readOnly: value.properties.readOnly,
      ),
      header: value.header == null ? null : _header(value.header!),
      element: diagnostics.isEmpty
          ? element.valueOrNull!
          : DiagnosticElement(diagnostics),
    );
  }

  TypeResult<PresentationElement> _element(
    wire.PresentationElement value,
  ) => switch (value) {
    wire.PresentationElement_childrenWrapper(:final value) => _children(value),
    wire.PresentationElement_cardWrapper(:final value) => TypeResult.success(
      CardElement(
        decodeNode(value.child),
        initiallyExpanded: value.initiallyExpanded,
      ),
    ),
    wire.PresentationElement_sectionWrapper(:final value) => _section(value),
    wire.PresentationElement_tabsWrapper(:final value) => _tabs(value),
    wire.PresentationElement.divider => const TypeResult.success(
      DividerElement(),
    ),
    wire.PresentationElement_spacerWrapper(:final value) => _spacer(value),
    wire.PresentationElement_textWrapper(:final value) => _text(
      value,
      TextElement.new,
    ),
    wire.PresentationElement_markdownWrapper(:final value) => _text(
      value,
      MarkdownElement.new,
    ),
    wire.PresentationElement_iconWrapper(:final value) => _icon(value),
    wire.PresentationElement_imageWrapper(:final value) => _image(value),
    wire.PresentationElement_badgeWrapper(:final value) => _badge(value),
    wire.PresentationElement_chipWrapper(:final value) => _chip(value),
    wire.PresentationElement_progressWrapper(:final value) => _progress(value),
    wire.PresentationElement_typedFieldWrapper(:final value) => _typedField(
      value,
    ),
    wire.PresentationElement_conditionalWrapper(:final value) => _conditional(
      value,
    ),
    wire.PresentationElement_repeatedWrapper(:final value) => _repeated(value),
    wire.PresentationElement_scopedBindingWrapper(:final value) => _scoped(
      value,
    ),
    wire.PresentationElement_collectionLookupWrapper(:final value) =>
      _collectionLookup(value),
    wire.PresentationElement_collectionGraphWrapper(:final value) =>
      _collectionGraph(value),
    wire.PresentationElement_textInputWrapper(:final value) => _textInput(
      value,
    ),
    wire.PresentationElement_numericInputWrapper(:final value) => _bound(
      value,
    ).mapValue(NumericInputElement.new),
    wire.PresentationElement_toggleInputWrapper(:final value) => _bound(
      value,
    ).mapValue(ToggleInputElement.new),
    wire.PresentationElement_selectInputWrapper(:final value) => _select(value),
    wire.PresentationElement_sliderInputWrapper(:final value) => _slider(value),
    wire.PresentationElement_dateTimeInputWrapper(:final value) =>
      _dateTimeInput(value),
    wire.PresentationElement_durationInputWrapper(:final value) => _bound(
      value,
    ).mapValue(DurationInputElement.new),
    wire.PresentationElement_colorInputWrapper(:final value) => _colorInput(
      value,
    ),
    wire.PresentationElement_searchInputWrapper(:final value) => _searchInput(
      value,
    ),
    wire.PresentationElement_bytesInputWrapper(:final value) => _bound(
      value,
    ).mapValue(BytesInputElement.new),
    wire.PresentationElement_listInputWrapper(:final value) => _listInput(
      value,
    ),
    wire.PresentationElement_mapInputWrapper(:final value) => _mapInput(value),
    wire.PresentationElement_recordInputWrapper(:final value) => _recordInput(
      value,
    ),
    wire.PresentationElement_enumInputWrapper(:final value) => _bound(
      value,
    ).mapValue(EnumInputElement.new),
    wire.PresentationElement_polymorphicInputWrapper(:final value) =>
      _polymorphic(value),
    wire.PresentationElement_namedInputWrapper(:final value) => _bound(
      value,
    ).mapValue(NamedInputElement.new),
    wire.PresentationElement_defaultPresentationWrapper(:final value) =>
      _defaultPresentation(value),
    wire.PresentationElement_collapsibleWrapper(:final value) => _collapsible(
      value,
    ),
    wire.PresentationElement_buttonWrapper(:final value) => _button(value),
    wire.PresentationElement_iconButtonWrapper(:final value) => _iconButton(
      value,
    ),
    wire.PresentationElement_menuWrapper(:final value) => _menu(value),
    wire.PresentationElement_tooltipWrapper(:final value) => _tooltip(value),
    wire.PresentationElement_unknown() => invalidWire(
      "Unknown presentation element",
    ),
  };

  TypeResult<TypedExpression?> _optionalExpression(
    wire_expression.TypedExpression? wireExpression,
  ) => wireExpression == null
      ? const TypeResult.success(null)
      : expressions.decode(wireExpression).mapValue((value) => value);
}
