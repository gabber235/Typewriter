library;

import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "presentation_element.freezed.dart";
part "presentation_content.dart";
part "presentation_data.dart";
part "presentation_input.dart";
part "presentation_interaction.dart";
part "presentation_layout.dart";
part "presentation_search.dart";
part "presentation_search_composition.dart";

@freezed
sealed class PresentationElement with _$PresentationElement {
  @Assert("diagnostics.isNotEmpty", "Diagnostics must not be empty.")
  factory PresentationElement.diagnostic(List<TypeDiagnostic> diagnostics) =
      DiagnosticElement;
  const factory PresentationElement.defaultPresentation({
    required BindingReference binding,
    PresentationId? presentationId,
  }) = DefaultPresentationElement;

  @Implements<TextualContentElement>()
  const factory PresentationElement.text(TypedExpression value) = TextElement;
  @Implements<TextualContentElement>()
  const factory PresentationElement.markdown(TypedExpression value) =
      MarkdownElement;
  const factory PresentationElement.icon({
    required TypedExpression name,
    TypedExpression? semanticLabel,
  }) = IconElement;
  const factory PresentationElement.image({
    required TypedExpression source,
    TypedExpression? semanticLabel,
  }) = ImageElement;
  const factory PresentationElement.badge({
    required TypedExpression label,
    required String tone,
  }) = BadgeElement;
  const factory PresentationElement.chip({
    required TypedExpression label,
    TypedExpression? color,
  }) = ChipElement;
  const factory PresentationElement.progress({
    required TypedExpression value,
    required TypedExpression maximum,
    TypedExpression? label,
  }) = ProgressElement;

  const factory PresentationElement.typedField({
    required BindingReference binding,
    required TypeExpression expectedType,
    PresentationNode? presentation,
  }) = TypedFieldElement;
  const factory PresentationElement.conditional({
    required TypedExpression condition,
    required PresentationNode whenTrue,
    PresentationNode? whenFalse,
  }) = ConditionalElement;
  const factory PresentationElement.repeated({
    required TypedExpression source,
    required BindingId itemBindingId,
    required SequencePresentation presentation,
  }) = RepeatedElement;
  const factory PresentationElement.scopedBinding({
    required BindingReference binding,
    required BindingId scopeBindingId,
    required PresentationNode child,
  }) = ScopedBindingElement;
  const factory PresentationElement.collectionLookup({
    required PresentationCollectionSourceId sourceId,
    required BindingReference key,
    required PresentationNode found,
    required PresentationNode missing,
    PresentationNode? loading,
  }) = CollectionLookupElement;
  const factory PresentationElement.collectionGraph({
    required PresentationCollectionSourceId sourceId,
    required BindingReference roots,
    required PresentationCollectionRelationId relation,
    required CollectionGraphDirection direction,
    required BindingId pathBindingId,
    SequencePresentation? rootRows,
    SequencePresentation? reachedRows,
    SequencePresentation? paths,
    int? maximumDepth,
    @Default(true) bool deduplicate,
  }) = CollectionGraphElement;

  const factory PresentationElement.textInput({
    required BoundControl control,
    @Default(true) bool multiline,
    TypedExpression? placeholder,
  }) = TextInputElement;
  const factory PresentationElement.numericInput(BoundControl control) =
      NumericInputElement;
  const factory PresentationElement.toggleInput(BoundControl control) =
      ToggleInputElement;
  const factory PresentationElement.selectInput({
    required BoundControl control,
    required List<SelectOption> options,
    @Default(false) bool allowCustomValue,
  }) = SelectInputElement;
  const factory PresentationElement.sliderInput({
    required BoundControl control,
    required TypedExpression minimum,
    required TypedExpression maximum,
    TypedExpression? divisions,
  }) = SliderInputElement;
  @Implements<SimpleInputElement>()
  const factory PresentationElement.dateTimeInput({
    required BoundControl control,
    @Default(true) bool includeDate,
    @Default(true) bool includeTime,
  }) = DateTimeInputElement;
  @Implements<SimpleInputElement>()
  const factory PresentationElement.durationInput(BoundControl control) =
      DurationInputElement;
  @Implements<SimpleInputElement>()
  const factory PresentationElement.colorInput({
    required BoundControl control,
    @Default(false) bool includeAlpha,
  }) = ColorInputElement;
  const factory PresentationElement.searchInput({
    required BoundControl control,
    required SearchSelectionMode selectionMode,
    required BindingId queryBindingId,
    required BindingId summaryBindingId,
    required TypedExpression maximumExtent,
    required SearchProvider provider,
    PresentationNode? summary,
    TypedExpression? placeholder,
    TypedExpression? customValue,
  }) = SearchInputElement;
  @Implements<SimpleInputElement>()
  const factory PresentationElement.bytesInput(BoundControl control) =
      BytesInputElement;
  @Implements<SimpleInputElement>()
  const factory PresentationElement.enumInput(BoundControl control) =
      EnumInputElement;
  @Implements<SimpleInputElement>()
  const factory PresentationElement.namedInput(BoundControl control) =
      NamedInputElement;
  const factory PresentationElement.listInput({
    required BoundControl control,
    PresentationNode? itemPresentation,
    @Default(true) bool allowAdd,
    @Default(true) bool allowRemove,
    @Default(true) bool allowReorder,
    @Default(BindingId(1)) BindingId itemBindingId,
    @Default(BindingId(2)) BindingId indexBindingId,
  }) = ListInputElement;
  const factory PresentationElement.mapInput({
    required BoundControl control,
    PresentationNode? keyPresentation,
    PresentationNode? valuePresentation,
    @Default(true) bool allowAdd,
    @Default(true) bool allowRemove,
    @Default(BindingId(1)) BindingId keyBindingId,
    @Default(BindingId(2)) BindingId valueBindingId,
  }) = MapInputElement;
  const factory PresentationElement.recordInput({
    required BoundControl control,
    PresentationNode? fieldPresentation,
  }) = RecordInputElement;
  @Assert("concreteTypes.isNotEmpty", "Concrete types must not be empty.")
  factory PresentationElement.polymorphicInput({
    required BoundControl control,
    required List<ConcreteTypePresentation> concreteTypes,
  }) = PolymorphicInputElement;

  const factory PresentationElement.button({
    required TypedExpression label,
    required EditorAction action,
  }) = ButtonElement;
  const factory PresentationElement.iconButton({
    required TypedExpression icon,
    required TypedExpression semanticLabel,
    required EditorAction action,
  }) = IconButtonElement;
  @Assert("items.isNotEmpty", "Menu items must not be empty.")
  factory PresentationElement.menu({
    required List<PresentationMenuItem> items,
    TypedExpression? label,
  }) = MenuElement;
  const factory PresentationElement.tooltip({
    required TypedExpression message,
    required PresentationNode child,
  }) = TooltipElement;

  @Implements<ChildrenLayoutElement>()
  @Assert("spacing >= 0", "Spacing must not be negative.")
  const factory PresentationElement.column({
    required List<PresentationNode> children,
    @Default(0) double spacing,
    @Default(PresentationMainAxisAlignment.start)
    PresentationMainAxisAlignment mainAxisAlignment,
    @Default(PresentationCrossAxisAlignment.center)
    PresentationCrossAxisAlignment crossAxisAlignment,
  }) = ColumnElement;
  @Implements<ChildrenLayoutElement>()
  @Assert("spacing >= 0", "Spacing must not be negative.")
  const factory PresentationElement.row({
    required List<PresentationNode> children,
    @Default(0) double spacing,
    @Default(PresentationMainAxisAlignment.start)
    PresentationMainAxisAlignment mainAxisAlignment,
    @Default(PresentationCrossAxisAlignment.center)
    PresentationCrossAxisAlignment crossAxisAlignment,
  }) = RowElement;
  @Implements<ChildrenLayoutElement>()
  @Assert("spacing >= 0", "Spacing must not be negative.")
  const factory PresentationElement.wrap({
    required List<PresentationNode> children,
    @Default(0) double spacing,
    @Default(0) double runSpacing,
    @Default(PresentationMainAxisAlignment.start)
    PresentationMainAxisAlignment mainAxisAlignment,
    @Default(PresentationCrossAxisAlignment.start)
    PresentationCrossAxisAlignment crossAxisAlignment,
  }) = WrapElement;
  const factory PresentationElement.stack({
    required List<PresentationNode> children,
  }) = StackElement;
  @Assert("columns > 0", "Column count must be positive.")
  @Assert("horizontalSpacing >= 0", "Horizontal spacing must not be negative.")
  @Assert("verticalSpacing >= 0", "Vertical spacing must not be negative.")
  const factory PresentationElement.grid({
    required List<PresentationNode> children,
    required int columns,
    @Default(0) double horizontalSpacing,
    @Default(0) double verticalSpacing,
  }) = GridElement;
  @Implements<SingleChildLayoutElement>()
  const factory PresentationElement.section({
    required PresentationNode child,
    PresentationBorder? border,
  }) = SectionElement;
  @Assert("tabs.isNotEmpty", "Tabs must not be empty.")
  factory PresentationElement.tabs({
    required List<TabItem> tabs,
    String? initiallySelectedTabId,
  }) = TabsElement;
  const factory PresentationElement.divider() = DividerElement;
  const factory PresentationElement.spacer({
    TypedExpression? width,
    TypedExpression? height,
  }) = SpacerElement;
}
