// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'presentation_element.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PresentationElement {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PresentationElement);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PresentationElement()';
}


}

/// @nodoc
class $PresentationElementCopyWith<$Res>  {
$PresentationElementCopyWith(PresentationElement _, $Res Function(PresentationElement) __);
}


/// Adds pattern-matching-related methods to [PresentationElement].
extension PresentationElementPatterns on PresentationElement {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( DiagnosticElement value)?  diagnostic,TResult Function( DefaultPresentationElement value)?  defaultPresentation,TResult Function( TextElement value)?  text,TResult Function( MarkdownElement value)?  markdown,TResult Function( IconElement value)?  icon,TResult Function( ImageElement value)?  image,TResult Function( BadgeElement value)?  badge,TResult Function( ProgressElement value)?  progress,TResult Function( TypedFieldElement value)?  typedField,TResult Function( ConditionalElement value)?  conditional,TResult Function( RepeatedElement value)?  repeated,TResult Function( ScopedBindingElement value)?  scopedBinding,TResult Function( TextInputElement value)?  textInput,TResult Function( NumericInputElement value)?  numericInput,TResult Function( ToggleInputElement value)?  toggleInput,TResult Function( SelectInputElement value)?  selectInput,TResult Function( SliderInputElement value)?  sliderInput,TResult Function( DateTimeInputElement value)?  dateTimeInput,TResult Function( DurationInputElement value)?  durationInput,TResult Function( ColorInputElement value)?  colorInput,TResult Function( SearchInputElement value)?  searchInput,TResult Function( BytesInputElement value)?  bytesInput,TResult Function( EnumInputElement value)?  enumInput,TResult Function( NamedInputElement value)?  namedInput,TResult Function( ListInputElement value)?  listInput,TResult Function( MapInputElement value)?  mapInput,TResult Function( RecordInputElement value)?  recordInput,TResult Function( PolymorphicInputElement value)?  polymorphicInput,TResult Function( ButtonElement value)?  button,TResult Function( IconButtonElement value)?  iconButton,TResult Function( MenuElement value)?  menu,TResult Function( TooltipElement value)?  tooltip,TResult Function( ColumnElement value)?  column,TResult Function( RowElement value)?  row,TResult Function( WrapElement value)?  wrap,TResult Function( StackElement value)?  stack,TResult Function( GridElement value)?  grid,TResult Function( CardElement value)?  card,TResult Function( SectionElement value)?  section,TResult Function( CollapsibleElement value)?  collapsible,TResult Function( TabsElement value)?  tabs,TResult Function( DividerElement value)?  divider,TResult Function( SpacerElement value)?  spacer,required TResult orElse(),}){
final _that = this;
switch (_that) {
case DiagnosticElement() when diagnostic != null:
return diagnostic(_that);case DefaultPresentationElement() when defaultPresentation != null:
return defaultPresentation(_that);case TextElement() when text != null:
return text(_that);case MarkdownElement() when markdown != null:
return markdown(_that);case IconElement() when icon != null:
return icon(_that);case ImageElement() when image != null:
return image(_that);case BadgeElement() when badge != null:
return badge(_that);case ProgressElement() when progress != null:
return progress(_that);case TypedFieldElement() when typedField != null:
return typedField(_that);case ConditionalElement() when conditional != null:
return conditional(_that);case RepeatedElement() when repeated != null:
return repeated(_that);case ScopedBindingElement() when scopedBinding != null:
return scopedBinding(_that);case TextInputElement() when textInput != null:
return textInput(_that);case NumericInputElement() when numericInput != null:
return numericInput(_that);case ToggleInputElement() when toggleInput != null:
return toggleInput(_that);case SelectInputElement() when selectInput != null:
return selectInput(_that);case SliderInputElement() when sliderInput != null:
return sliderInput(_that);case DateTimeInputElement() when dateTimeInput != null:
return dateTimeInput(_that);case DurationInputElement() when durationInput != null:
return durationInput(_that);case ColorInputElement() when colorInput != null:
return colorInput(_that);case SearchInputElement() when searchInput != null:
return searchInput(_that);case BytesInputElement() when bytesInput != null:
return bytesInput(_that);case EnumInputElement() when enumInput != null:
return enumInput(_that);case NamedInputElement() when namedInput != null:
return namedInput(_that);case ListInputElement() when listInput != null:
return listInput(_that);case MapInputElement() when mapInput != null:
return mapInput(_that);case RecordInputElement() when recordInput != null:
return recordInput(_that);case PolymorphicInputElement() when polymorphicInput != null:
return polymorphicInput(_that);case ButtonElement() when button != null:
return button(_that);case IconButtonElement() when iconButton != null:
return iconButton(_that);case MenuElement() when menu != null:
return menu(_that);case TooltipElement() when tooltip != null:
return tooltip(_that);case ColumnElement() when column != null:
return column(_that);case RowElement() when row != null:
return row(_that);case WrapElement() when wrap != null:
return wrap(_that);case StackElement() when stack != null:
return stack(_that);case GridElement() when grid != null:
return grid(_that);case CardElement() when card != null:
return card(_that);case SectionElement() when section != null:
return section(_that);case CollapsibleElement() when collapsible != null:
return collapsible(_that);case TabsElement() when tabs != null:
return tabs(_that);case DividerElement() when divider != null:
return divider(_that);case SpacerElement() when spacer != null:
return spacer(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( DiagnosticElement value)  diagnostic,required TResult Function( DefaultPresentationElement value)  defaultPresentation,required TResult Function( TextElement value)  text,required TResult Function( MarkdownElement value)  markdown,required TResult Function( IconElement value)  icon,required TResult Function( ImageElement value)  image,required TResult Function( BadgeElement value)  badge,required TResult Function( ProgressElement value)  progress,required TResult Function( TypedFieldElement value)  typedField,required TResult Function( ConditionalElement value)  conditional,required TResult Function( RepeatedElement value)  repeated,required TResult Function( ScopedBindingElement value)  scopedBinding,required TResult Function( TextInputElement value)  textInput,required TResult Function( NumericInputElement value)  numericInput,required TResult Function( ToggleInputElement value)  toggleInput,required TResult Function( SelectInputElement value)  selectInput,required TResult Function( SliderInputElement value)  sliderInput,required TResult Function( DateTimeInputElement value)  dateTimeInput,required TResult Function( DurationInputElement value)  durationInput,required TResult Function( ColorInputElement value)  colorInput,required TResult Function( SearchInputElement value)  searchInput,required TResult Function( BytesInputElement value)  bytesInput,required TResult Function( EnumInputElement value)  enumInput,required TResult Function( NamedInputElement value)  namedInput,required TResult Function( ListInputElement value)  listInput,required TResult Function( MapInputElement value)  mapInput,required TResult Function( RecordInputElement value)  recordInput,required TResult Function( PolymorphicInputElement value)  polymorphicInput,required TResult Function( ButtonElement value)  button,required TResult Function( IconButtonElement value)  iconButton,required TResult Function( MenuElement value)  menu,required TResult Function( TooltipElement value)  tooltip,required TResult Function( ColumnElement value)  column,required TResult Function( RowElement value)  row,required TResult Function( WrapElement value)  wrap,required TResult Function( StackElement value)  stack,required TResult Function( GridElement value)  grid,required TResult Function( CardElement value)  card,required TResult Function( SectionElement value)  section,required TResult Function( CollapsibleElement value)  collapsible,required TResult Function( TabsElement value)  tabs,required TResult Function( DividerElement value)  divider,required TResult Function( SpacerElement value)  spacer,}){
final _that = this;
switch (_that) {
case DiagnosticElement():
return diagnostic(_that);case DefaultPresentationElement():
return defaultPresentation(_that);case TextElement():
return text(_that);case MarkdownElement():
return markdown(_that);case IconElement():
return icon(_that);case ImageElement():
return image(_that);case BadgeElement():
return badge(_that);case ProgressElement():
return progress(_that);case TypedFieldElement():
return typedField(_that);case ConditionalElement():
return conditional(_that);case RepeatedElement():
return repeated(_that);case ScopedBindingElement():
return scopedBinding(_that);case TextInputElement():
return textInput(_that);case NumericInputElement():
return numericInput(_that);case ToggleInputElement():
return toggleInput(_that);case SelectInputElement():
return selectInput(_that);case SliderInputElement():
return sliderInput(_that);case DateTimeInputElement():
return dateTimeInput(_that);case DurationInputElement():
return durationInput(_that);case ColorInputElement():
return colorInput(_that);case SearchInputElement():
return searchInput(_that);case BytesInputElement():
return bytesInput(_that);case EnumInputElement():
return enumInput(_that);case NamedInputElement():
return namedInput(_that);case ListInputElement():
return listInput(_that);case MapInputElement():
return mapInput(_that);case RecordInputElement():
return recordInput(_that);case PolymorphicInputElement():
return polymorphicInput(_that);case ButtonElement():
return button(_that);case IconButtonElement():
return iconButton(_that);case MenuElement():
return menu(_that);case TooltipElement():
return tooltip(_that);case ColumnElement():
return column(_that);case RowElement():
return row(_that);case WrapElement():
return wrap(_that);case StackElement():
return stack(_that);case GridElement():
return grid(_that);case CardElement():
return card(_that);case SectionElement():
return section(_that);case CollapsibleElement():
return collapsible(_that);case TabsElement():
return tabs(_that);case DividerElement():
return divider(_that);case SpacerElement():
return spacer(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( DiagnosticElement value)?  diagnostic,TResult? Function( DefaultPresentationElement value)?  defaultPresentation,TResult? Function( TextElement value)?  text,TResult? Function( MarkdownElement value)?  markdown,TResult? Function( IconElement value)?  icon,TResult? Function( ImageElement value)?  image,TResult? Function( BadgeElement value)?  badge,TResult? Function( ProgressElement value)?  progress,TResult? Function( TypedFieldElement value)?  typedField,TResult? Function( ConditionalElement value)?  conditional,TResult? Function( RepeatedElement value)?  repeated,TResult? Function( ScopedBindingElement value)?  scopedBinding,TResult? Function( TextInputElement value)?  textInput,TResult? Function( NumericInputElement value)?  numericInput,TResult? Function( ToggleInputElement value)?  toggleInput,TResult? Function( SelectInputElement value)?  selectInput,TResult? Function( SliderInputElement value)?  sliderInput,TResult? Function( DateTimeInputElement value)?  dateTimeInput,TResult? Function( DurationInputElement value)?  durationInput,TResult? Function( ColorInputElement value)?  colorInput,TResult? Function( SearchInputElement value)?  searchInput,TResult? Function( BytesInputElement value)?  bytesInput,TResult? Function( EnumInputElement value)?  enumInput,TResult? Function( NamedInputElement value)?  namedInput,TResult? Function( ListInputElement value)?  listInput,TResult? Function( MapInputElement value)?  mapInput,TResult? Function( RecordInputElement value)?  recordInput,TResult? Function( PolymorphicInputElement value)?  polymorphicInput,TResult? Function( ButtonElement value)?  button,TResult? Function( IconButtonElement value)?  iconButton,TResult? Function( MenuElement value)?  menu,TResult? Function( TooltipElement value)?  tooltip,TResult? Function( ColumnElement value)?  column,TResult? Function( RowElement value)?  row,TResult? Function( WrapElement value)?  wrap,TResult? Function( StackElement value)?  stack,TResult? Function( GridElement value)?  grid,TResult? Function( CardElement value)?  card,TResult? Function( SectionElement value)?  section,TResult? Function( CollapsibleElement value)?  collapsible,TResult? Function( TabsElement value)?  tabs,TResult? Function( DividerElement value)?  divider,TResult? Function( SpacerElement value)?  spacer,}){
final _that = this;
switch (_that) {
case DiagnosticElement() when diagnostic != null:
return diagnostic(_that);case DefaultPresentationElement() when defaultPresentation != null:
return defaultPresentation(_that);case TextElement() when text != null:
return text(_that);case MarkdownElement() when markdown != null:
return markdown(_that);case IconElement() when icon != null:
return icon(_that);case ImageElement() when image != null:
return image(_that);case BadgeElement() when badge != null:
return badge(_that);case ProgressElement() when progress != null:
return progress(_that);case TypedFieldElement() when typedField != null:
return typedField(_that);case ConditionalElement() when conditional != null:
return conditional(_that);case RepeatedElement() when repeated != null:
return repeated(_that);case ScopedBindingElement() when scopedBinding != null:
return scopedBinding(_that);case TextInputElement() when textInput != null:
return textInput(_that);case NumericInputElement() when numericInput != null:
return numericInput(_that);case ToggleInputElement() when toggleInput != null:
return toggleInput(_that);case SelectInputElement() when selectInput != null:
return selectInput(_that);case SliderInputElement() when sliderInput != null:
return sliderInput(_that);case DateTimeInputElement() when dateTimeInput != null:
return dateTimeInput(_that);case DurationInputElement() when durationInput != null:
return durationInput(_that);case ColorInputElement() when colorInput != null:
return colorInput(_that);case SearchInputElement() when searchInput != null:
return searchInput(_that);case BytesInputElement() when bytesInput != null:
return bytesInput(_that);case EnumInputElement() when enumInput != null:
return enumInput(_that);case NamedInputElement() when namedInput != null:
return namedInput(_that);case ListInputElement() when listInput != null:
return listInput(_that);case MapInputElement() when mapInput != null:
return mapInput(_that);case RecordInputElement() when recordInput != null:
return recordInput(_that);case PolymorphicInputElement() when polymorphicInput != null:
return polymorphicInput(_that);case ButtonElement() when button != null:
return button(_that);case IconButtonElement() when iconButton != null:
return iconButton(_that);case MenuElement() when menu != null:
return menu(_that);case TooltipElement() when tooltip != null:
return tooltip(_that);case ColumnElement() when column != null:
return column(_that);case RowElement() when row != null:
return row(_that);case WrapElement() when wrap != null:
return wrap(_that);case StackElement() when stack != null:
return stack(_that);case GridElement() when grid != null:
return grid(_that);case CardElement() when card != null:
return card(_that);case SectionElement() when section != null:
return section(_that);case CollapsibleElement() when collapsible != null:
return collapsible(_that);case TabsElement() when tabs != null:
return tabs(_that);case DividerElement() when divider != null:
return divider(_that);case SpacerElement() when spacer != null:
return spacer(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( List<TypeDiagnostic> diagnostics)?  diagnostic,TResult Function( BindingReference binding,  PresentationId? presentationId)?  defaultPresentation,TResult Function( TypedExpression value)?  text,TResult Function( TypedExpression value)?  markdown,TResult Function( TypedExpression name,  TypedExpression? semanticLabel)?  icon,TResult Function( TypedExpression source,  TypedExpression? semanticLabel)?  image,TResult Function( TypedExpression label,  String tone)?  badge,TResult Function( TypedExpression value,  TypedExpression maximum,  TypedExpression? label)?  progress,TResult Function( BindingReference binding,  TypeExpression expectedType,  PresentationNode? presentation)?  typedField,TResult Function( TypedExpression condition,  PresentationNode whenTrue,  PresentationNode? whenFalse)?  conditional,TResult Function( TypedExpression source,  BindingId itemBindingId,  PresentationNode template,  PresentationNode? empty)?  repeated,TResult Function( BindingReference binding,  BindingId scopeBindingId,  PresentationNode child)?  scopedBinding,TResult Function( BoundControl control,  bool multiline,  TypedExpression? placeholder)?  textInput,TResult Function( BoundControl control)?  numericInput,TResult Function( BoundControl control)?  toggleInput,TResult Function( BoundControl control,  List<SelectOption> options,  bool allowCustomValue)?  selectInput,TResult Function( BoundControl control,  TypedExpression minimum,  TypedExpression maximum,  TypedExpression? divisions)?  sliderInput,TResult Function( BoundControl control,  bool includeDate,  bool includeTime)?  dateTimeInput,TResult Function( BoundControl control)?  durationInput,TResult Function( BoundControl control,  bool includeAlpha)?  colorInput,TResult Function( BoundControl control,  SearchSelectionMode selectionMode,  BindingId queryBindingId,  BindingId summaryBindingId,  TypedExpression maximumExtent,  SearchProvider provider,  PresentationNode? summary,  TypedExpression? placeholder,  TypedExpression? customValue)?  searchInput,TResult Function( BoundControl control)?  bytesInput,TResult Function( BoundControl control)?  enumInput,TResult Function( BoundControl control)?  namedInput,TResult Function( BoundControl control,  PresentationNode? itemPresentation,  bool allowAdd,  bool allowRemove,  bool allowReorder,  BindingId itemBindingId,  BindingId indexBindingId)?  listInput,TResult Function( BoundControl control,  PresentationNode? keyPresentation,  PresentationNode? valuePresentation,  bool allowAdd,  bool allowRemove,  BindingId keyBindingId,  BindingId valueBindingId)?  mapInput,TResult Function( BoundControl control,  PresentationNode? fieldPresentation)?  recordInput,TResult Function( BoundControl control,  List<ConcreteTypePresentation> concreteTypes)?  polymorphicInput,TResult Function( TypedExpression label,  EditorAction action)?  button,TResult Function( TypedExpression icon,  TypedExpression semanticLabel,  EditorAction action)?  iconButton,TResult Function( List<PresentationMenuItem> items,  TypedExpression? label)?  menu,TResult Function( TypedExpression message,  PresentationNode child)?  tooltip,TResult Function( List<PresentationNode> children,  double spacing,  PresentationMainAxisAlignment mainAxisAlignment,  PresentationCrossAxisAlignment crossAxisAlignment)?  column,TResult Function( List<PresentationNode> children,  double spacing,  PresentationMainAxisAlignment mainAxisAlignment,  PresentationCrossAxisAlignment crossAxisAlignment)?  row,TResult Function( List<PresentationNode> children,  double spacing,  PresentationMainAxisAlignment mainAxisAlignment,  PresentationCrossAxisAlignment crossAxisAlignment)?  wrap,TResult Function( List<PresentationNode> children,  double spacing,  PresentationMainAxisAlignment mainAxisAlignment,  PresentationCrossAxisAlignment crossAxisAlignment)?  stack,TResult Function( List<PresentationNode> children,  int columns,  double horizontalSpacing,  double verticalSpacing)?  grid,TResult Function( PresentationNode child,  bool? initiallyExpanded)?  card,TResult Function( TypedExpression title,  PresentationNode child,  TypedExpression? description,  bool? initiallyExpanded)?  section,TResult Function( TypedExpression title,  PresentationNode child,  bool initiallyExpanded)?  collapsible,TResult Function( List<TabItem> tabs,  String? initiallySelectedTabId)?  tabs,TResult Function()?  divider,TResult Function( TypedExpression? width,  TypedExpression? height)?  spacer,required TResult orElse(),}) {final _that = this;
switch (_that) {
case DiagnosticElement() when diagnostic != null:
return diagnostic(_that.diagnostics);case DefaultPresentationElement() when defaultPresentation != null:
return defaultPresentation(_that.binding,_that.presentationId);case TextElement() when text != null:
return text(_that.value);case MarkdownElement() when markdown != null:
return markdown(_that.value);case IconElement() when icon != null:
return icon(_that.name,_that.semanticLabel);case ImageElement() when image != null:
return image(_that.source,_that.semanticLabel);case BadgeElement() when badge != null:
return badge(_that.label,_that.tone);case ProgressElement() when progress != null:
return progress(_that.value,_that.maximum,_that.label);case TypedFieldElement() when typedField != null:
return typedField(_that.binding,_that.expectedType,_that.presentation);case ConditionalElement() when conditional != null:
return conditional(_that.condition,_that.whenTrue,_that.whenFalse);case RepeatedElement() when repeated != null:
return repeated(_that.source,_that.itemBindingId,_that.template,_that.empty);case ScopedBindingElement() when scopedBinding != null:
return scopedBinding(_that.binding,_that.scopeBindingId,_that.child);case TextInputElement() when textInput != null:
return textInput(_that.control,_that.multiline,_that.placeholder);case NumericInputElement() when numericInput != null:
return numericInput(_that.control);case ToggleInputElement() when toggleInput != null:
return toggleInput(_that.control);case SelectInputElement() when selectInput != null:
return selectInput(_that.control,_that.options,_that.allowCustomValue);case SliderInputElement() when sliderInput != null:
return sliderInput(_that.control,_that.minimum,_that.maximum,_that.divisions);case DateTimeInputElement() when dateTimeInput != null:
return dateTimeInput(_that.control,_that.includeDate,_that.includeTime);case DurationInputElement() when durationInput != null:
return durationInput(_that.control);case ColorInputElement() when colorInput != null:
return colorInput(_that.control,_that.includeAlpha);case SearchInputElement() when searchInput != null:
return searchInput(_that.control,_that.selectionMode,_that.queryBindingId,_that.summaryBindingId,_that.maximumExtent,_that.provider,_that.summary,_that.placeholder,_that.customValue);case BytesInputElement() when bytesInput != null:
return bytesInput(_that.control);case EnumInputElement() when enumInput != null:
return enumInput(_that.control);case NamedInputElement() when namedInput != null:
return namedInput(_that.control);case ListInputElement() when listInput != null:
return listInput(_that.control,_that.itemPresentation,_that.allowAdd,_that.allowRemove,_that.allowReorder,_that.itemBindingId,_that.indexBindingId);case MapInputElement() when mapInput != null:
return mapInput(_that.control,_that.keyPresentation,_that.valuePresentation,_that.allowAdd,_that.allowRemove,_that.keyBindingId,_that.valueBindingId);case RecordInputElement() when recordInput != null:
return recordInput(_that.control,_that.fieldPresentation);case PolymorphicInputElement() when polymorphicInput != null:
return polymorphicInput(_that.control,_that.concreteTypes);case ButtonElement() when button != null:
return button(_that.label,_that.action);case IconButtonElement() when iconButton != null:
return iconButton(_that.icon,_that.semanticLabel,_that.action);case MenuElement() when menu != null:
return menu(_that.items,_that.label);case TooltipElement() when tooltip != null:
return tooltip(_that.message,_that.child);case ColumnElement() when column != null:
return column(_that.children,_that.spacing,_that.mainAxisAlignment,_that.crossAxisAlignment);case RowElement() when row != null:
return row(_that.children,_that.spacing,_that.mainAxisAlignment,_that.crossAxisAlignment);case WrapElement() when wrap != null:
return wrap(_that.children,_that.spacing,_that.mainAxisAlignment,_that.crossAxisAlignment);case StackElement() when stack != null:
return stack(_that.children,_that.spacing,_that.mainAxisAlignment,_that.crossAxisAlignment);case GridElement() when grid != null:
return grid(_that.children,_that.columns,_that.horizontalSpacing,_that.verticalSpacing);case CardElement() when card != null:
return card(_that.child,_that.initiallyExpanded);case SectionElement() when section != null:
return section(_that.title,_that.child,_that.description,_that.initiallyExpanded);case CollapsibleElement() when collapsible != null:
return collapsible(_that.title,_that.child,_that.initiallyExpanded);case TabsElement() when tabs != null:
return tabs(_that.tabs,_that.initiallySelectedTabId);case DividerElement() when divider != null:
return divider();case SpacerElement() when spacer != null:
return spacer(_that.width,_that.height);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( List<TypeDiagnostic> diagnostics)  diagnostic,required TResult Function( BindingReference binding,  PresentationId? presentationId)  defaultPresentation,required TResult Function( TypedExpression value)  text,required TResult Function( TypedExpression value)  markdown,required TResult Function( TypedExpression name,  TypedExpression? semanticLabel)  icon,required TResult Function( TypedExpression source,  TypedExpression? semanticLabel)  image,required TResult Function( TypedExpression label,  String tone)  badge,required TResult Function( TypedExpression value,  TypedExpression maximum,  TypedExpression? label)  progress,required TResult Function( BindingReference binding,  TypeExpression expectedType,  PresentationNode? presentation)  typedField,required TResult Function( TypedExpression condition,  PresentationNode whenTrue,  PresentationNode? whenFalse)  conditional,required TResult Function( TypedExpression source,  BindingId itemBindingId,  PresentationNode template,  PresentationNode? empty)  repeated,required TResult Function( BindingReference binding,  BindingId scopeBindingId,  PresentationNode child)  scopedBinding,required TResult Function( BoundControl control,  bool multiline,  TypedExpression? placeholder)  textInput,required TResult Function( BoundControl control)  numericInput,required TResult Function( BoundControl control)  toggleInput,required TResult Function( BoundControl control,  List<SelectOption> options,  bool allowCustomValue)  selectInput,required TResult Function( BoundControl control,  TypedExpression minimum,  TypedExpression maximum,  TypedExpression? divisions)  sliderInput,required TResult Function( BoundControl control,  bool includeDate,  bool includeTime)  dateTimeInput,required TResult Function( BoundControl control)  durationInput,required TResult Function( BoundControl control,  bool includeAlpha)  colorInput,required TResult Function( BoundControl control,  SearchSelectionMode selectionMode,  BindingId queryBindingId,  BindingId summaryBindingId,  TypedExpression maximumExtent,  SearchProvider provider,  PresentationNode? summary,  TypedExpression? placeholder,  TypedExpression? customValue)  searchInput,required TResult Function( BoundControl control)  bytesInput,required TResult Function( BoundControl control)  enumInput,required TResult Function( BoundControl control)  namedInput,required TResult Function( BoundControl control,  PresentationNode? itemPresentation,  bool allowAdd,  bool allowRemove,  bool allowReorder,  BindingId itemBindingId,  BindingId indexBindingId)  listInput,required TResult Function( BoundControl control,  PresentationNode? keyPresentation,  PresentationNode? valuePresentation,  bool allowAdd,  bool allowRemove,  BindingId keyBindingId,  BindingId valueBindingId)  mapInput,required TResult Function( BoundControl control,  PresentationNode? fieldPresentation)  recordInput,required TResult Function( BoundControl control,  List<ConcreteTypePresentation> concreteTypes)  polymorphicInput,required TResult Function( TypedExpression label,  EditorAction action)  button,required TResult Function( TypedExpression icon,  TypedExpression semanticLabel,  EditorAction action)  iconButton,required TResult Function( List<PresentationMenuItem> items,  TypedExpression? label)  menu,required TResult Function( TypedExpression message,  PresentationNode child)  tooltip,required TResult Function( List<PresentationNode> children,  double spacing,  PresentationMainAxisAlignment mainAxisAlignment,  PresentationCrossAxisAlignment crossAxisAlignment)  column,required TResult Function( List<PresentationNode> children,  double spacing,  PresentationMainAxisAlignment mainAxisAlignment,  PresentationCrossAxisAlignment crossAxisAlignment)  row,required TResult Function( List<PresentationNode> children,  double spacing,  PresentationMainAxisAlignment mainAxisAlignment,  PresentationCrossAxisAlignment crossAxisAlignment)  wrap,required TResult Function( List<PresentationNode> children,  double spacing,  PresentationMainAxisAlignment mainAxisAlignment,  PresentationCrossAxisAlignment crossAxisAlignment)  stack,required TResult Function( List<PresentationNode> children,  int columns,  double horizontalSpacing,  double verticalSpacing)  grid,required TResult Function( PresentationNode child,  bool? initiallyExpanded)  card,required TResult Function( TypedExpression title,  PresentationNode child,  TypedExpression? description,  bool? initiallyExpanded)  section,required TResult Function( TypedExpression title,  PresentationNode child,  bool initiallyExpanded)  collapsible,required TResult Function( List<TabItem> tabs,  String? initiallySelectedTabId)  tabs,required TResult Function()  divider,required TResult Function( TypedExpression? width,  TypedExpression? height)  spacer,}) {final _that = this;
switch (_that) {
case DiagnosticElement():
return diagnostic(_that.diagnostics);case DefaultPresentationElement():
return defaultPresentation(_that.binding,_that.presentationId);case TextElement():
return text(_that.value);case MarkdownElement():
return markdown(_that.value);case IconElement():
return icon(_that.name,_that.semanticLabel);case ImageElement():
return image(_that.source,_that.semanticLabel);case BadgeElement():
return badge(_that.label,_that.tone);case ProgressElement():
return progress(_that.value,_that.maximum,_that.label);case TypedFieldElement():
return typedField(_that.binding,_that.expectedType,_that.presentation);case ConditionalElement():
return conditional(_that.condition,_that.whenTrue,_that.whenFalse);case RepeatedElement():
return repeated(_that.source,_that.itemBindingId,_that.template,_that.empty);case ScopedBindingElement():
return scopedBinding(_that.binding,_that.scopeBindingId,_that.child);case TextInputElement():
return textInput(_that.control,_that.multiline,_that.placeholder);case NumericInputElement():
return numericInput(_that.control);case ToggleInputElement():
return toggleInput(_that.control);case SelectInputElement():
return selectInput(_that.control,_that.options,_that.allowCustomValue);case SliderInputElement():
return sliderInput(_that.control,_that.minimum,_that.maximum,_that.divisions);case DateTimeInputElement():
return dateTimeInput(_that.control,_that.includeDate,_that.includeTime);case DurationInputElement():
return durationInput(_that.control);case ColorInputElement():
return colorInput(_that.control,_that.includeAlpha);case SearchInputElement():
return searchInput(_that.control,_that.selectionMode,_that.queryBindingId,_that.summaryBindingId,_that.maximumExtent,_that.provider,_that.summary,_that.placeholder,_that.customValue);case BytesInputElement():
return bytesInput(_that.control);case EnumInputElement():
return enumInput(_that.control);case NamedInputElement():
return namedInput(_that.control);case ListInputElement():
return listInput(_that.control,_that.itemPresentation,_that.allowAdd,_that.allowRemove,_that.allowReorder,_that.itemBindingId,_that.indexBindingId);case MapInputElement():
return mapInput(_that.control,_that.keyPresentation,_that.valuePresentation,_that.allowAdd,_that.allowRemove,_that.keyBindingId,_that.valueBindingId);case RecordInputElement():
return recordInput(_that.control,_that.fieldPresentation);case PolymorphicInputElement():
return polymorphicInput(_that.control,_that.concreteTypes);case ButtonElement():
return button(_that.label,_that.action);case IconButtonElement():
return iconButton(_that.icon,_that.semanticLabel,_that.action);case MenuElement():
return menu(_that.items,_that.label);case TooltipElement():
return tooltip(_that.message,_that.child);case ColumnElement():
return column(_that.children,_that.spacing,_that.mainAxisAlignment,_that.crossAxisAlignment);case RowElement():
return row(_that.children,_that.spacing,_that.mainAxisAlignment,_that.crossAxisAlignment);case WrapElement():
return wrap(_that.children,_that.spacing,_that.mainAxisAlignment,_that.crossAxisAlignment);case StackElement():
return stack(_that.children,_that.spacing,_that.mainAxisAlignment,_that.crossAxisAlignment);case GridElement():
return grid(_that.children,_that.columns,_that.horizontalSpacing,_that.verticalSpacing);case CardElement():
return card(_that.child,_that.initiallyExpanded);case SectionElement():
return section(_that.title,_that.child,_that.description,_that.initiallyExpanded);case CollapsibleElement():
return collapsible(_that.title,_that.child,_that.initiallyExpanded);case TabsElement():
return tabs(_that.tabs,_that.initiallySelectedTabId);case DividerElement():
return divider();case SpacerElement():
return spacer(_that.width,_that.height);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( List<TypeDiagnostic> diagnostics)?  diagnostic,TResult? Function( BindingReference binding,  PresentationId? presentationId)?  defaultPresentation,TResult? Function( TypedExpression value)?  text,TResult? Function( TypedExpression value)?  markdown,TResult? Function( TypedExpression name,  TypedExpression? semanticLabel)?  icon,TResult? Function( TypedExpression source,  TypedExpression? semanticLabel)?  image,TResult? Function( TypedExpression label,  String tone)?  badge,TResult? Function( TypedExpression value,  TypedExpression maximum,  TypedExpression? label)?  progress,TResult? Function( BindingReference binding,  TypeExpression expectedType,  PresentationNode? presentation)?  typedField,TResult? Function( TypedExpression condition,  PresentationNode whenTrue,  PresentationNode? whenFalse)?  conditional,TResult? Function( TypedExpression source,  BindingId itemBindingId,  PresentationNode template,  PresentationNode? empty)?  repeated,TResult? Function( BindingReference binding,  BindingId scopeBindingId,  PresentationNode child)?  scopedBinding,TResult? Function( BoundControl control,  bool multiline,  TypedExpression? placeholder)?  textInput,TResult? Function( BoundControl control)?  numericInput,TResult? Function( BoundControl control)?  toggleInput,TResult? Function( BoundControl control,  List<SelectOption> options,  bool allowCustomValue)?  selectInput,TResult? Function( BoundControl control,  TypedExpression minimum,  TypedExpression maximum,  TypedExpression? divisions)?  sliderInput,TResult? Function( BoundControl control,  bool includeDate,  bool includeTime)?  dateTimeInput,TResult? Function( BoundControl control)?  durationInput,TResult? Function( BoundControl control,  bool includeAlpha)?  colorInput,TResult? Function( BoundControl control,  SearchSelectionMode selectionMode,  BindingId queryBindingId,  BindingId summaryBindingId,  TypedExpression maximumExtent,  SearchProvider provider,  PresentationNode? summary,  TypedExpression? placeholder,  TypedExpression? customValue)?  searchInput,TResult? Function( BoundControl control)?  bytesInput,TResult? Function( BoundControl control)?  enumInput,TResult? Function( BoundControl control)?  namedInput,TResult? Function( BoundControl control,  PresentationNode? itemPresentation,  bool allowAdd,  bool allowRemove,  bool allowReorder,  BindingId itemBindingId,  BindingId indexBindingId)?  listInput,TResult? Function( BoundControl control,  PresentationNode? keyPresentation,  PresentationNode? valuePresentation,  bool allowAdd,  bool allowRemove,  BindingId keyBindingId,  BindingId valueBindingId)?  mapInput,TResult? Function( BoundControl control,  PresentationNode? fieldPresentation)?  recordInput,TResult? Function( BoundControl control,  List<ConcreteTypePresentation> concreteTypes)?  polymorphicInput,TResult? Function( TypedExpression label,  EditorAction action)?  button,TResult? Function( TypedExpression icon,  TypedExpression semanticLabel,  EditorAction action)?  iconButton,TResult? Function( List<PresentationMenuItem> items,  TypedExpression? label)?  menu,TResult? Function( TypedExpression message,  PresentationNode child)?  tooltip,TResult? Function( List<PresentationNode> children,  double spacing,  PresentationMainAxisAlignment mainAxisAlignment,  PresentationCrossAxisAlignment crossAxisAlignment)?  column,TResult? Function( List<PresentationNode> children,  double spacing,  PresentationMainAxisAlignment mainAxisAlignment,  PresentationCrossAxisAlignment crossAxisAlignment)?  row,TResult? Function( List<PresentationNode> children,  double spacing,  PresentationMainAxisAlignment mainAxisAlignment,  PresentationCrossAxisAlignment crossAxisAlignment)?  wrap,TResult? Function( List<PresentationNode> children,  double spacing,  PresentationMainAxisAlignment mainAxisAlignment,  PresentationCrossAxisAlignment crossAxisAlignment)?  stack,TResult? Function( List<PresentationNode> children,  int columns,  double horizontalSpacing,  double verticalSpacing)?  grid,TResult? Function( PresentationNode child,  bool? initiallyExpanded)?  card,TResult? Function( TypedExpression title,  PresentationNode child,  TypedExpression? description,  bool? initiallyExpanded)?  section,TResult? Function( TypedExpression title,  PresentationNode child,  bool initiallyExpanded)?  collapsible,TResult? Function( List<TabItem> tabs,  String? initiallySelectedTabId)?  tabs,TResult? Function()?  divider,TResult? Function( TypedExpression? width,  TypedExpression? height)?  spacer,}) {final _that = this;
switch (_that) {
case DiagnosticElement() when diagnostic != null:
return diagnostic(_that.diagnostics);case DefaultPresentationElement() when defaultPresentation != null:
return defaultPresentation(_that.binding,_that.presentationId);case TextElement() when text != null:
return text(_that.value);case MarkdownElement() when markdown != null:
return markdown(_that.value);case IconElement() when icon != null:
return icon(_that.name,_that.semanticLabel);case ImageElement() when image != null:
return image(_that.source,_that.semanticLabel);case BadgeElement() when badge != null:
return badge(_that.label,_that.tone);case ProgressElement() when progress != null:
return progress(_that.value,_that.maximum,_that.label);case TypedFieldElement() when typedField != null:
return typedField(_that.binding,_that.expectedType,_that.presentation);case ConditionalElement() when conditional != null:
return conditional(_that.condition,_that.whenTrue,_that.whenFalse);case RepeatedElement() when repeated != null:
return repeated(_that.source,_that.itemBindingId,_that.template,_that.empty);case ScopedBindingElement() when scopedBinding != null:
return scopedBinding(_that.binding,_that.scopeBindingId,_that.child);case TextInputElement() when textInput != null:
return textInput(_that.control,_that.multiline,_that.placeholder);case NumericInputElement() when numericInput != null:
return numericInput(_that.control);case ToggleInputElement() when toggleInput != null:
return toggleInput(_that.control);case SelectInputElement() when selectInput != null:
return selectInput(_that.control,_that.options,_that.allowCustomValue);case SliderInputElement() when sliderInput != null:
return sliderInput(_that.control,_that.minimum,_that.maximum,_that.divisions);case DateTimeInputElement() when dateTimeInput != null:
return dateTimeInput(_that.control,_that.includeDate,_that.includeTime);case DurationInputElement() when durationInput != null:
return durationInput(_that.control);case ColorInputElement() when colorInput != null:
return colorInput(_that.control,_that.includeAlpha);case SearchInputElement() when searchInput != null:
return searchInput(_that.control,_that.selectionMode,_that.queryBindingId,_that.summaryBindingId,_that.maximumExtent,_that.provider,_that.summary,_that.placeholder,_that.customValue);case BytesInputElement() when bytesInput != null:
return bytesInput(_that.control);case EnumInputElement() when enumInput != null:
return enumInput(_that.control);case NamedInputElement() when namedInput != null:
return namedInput(_that.control);case ListInputElement() when listInput != null:
return listInput(_that.control,_that.itemPresentation,_that.allowAdd,_that.allowRemove,_that.allowReorder,_that.itemBindingId,_that.indexBindingId);case MapInputElement() when mapInput != null:
return mapInput(_that.control,_that.keyPresentation,_that.valuePresentation,_that.allowAdd,_that.allowRemove,_that.keyBindingId,_that.valueBindingId);case RecordInputElement() when recordInput != null:
return recordInput(_that.control,_that.fieldPresentation);case PolymorphicInputElement() when polymorphicInput != null:
return polymorphicInput(_that.control,_that.concreteTypes);case ButtonElement() when button != null:
return button(_that.label,_that.action);case IconButtonElement() when iconButton != null:
return iconButton(_that.icon,_that.semanticLabel,_that.action);case MenuElement() when menu != null:
return menu(_that.items,_that.label);case TooltipElement() when tooltip != null:
return tooltip(_that.message,_that.child);case ColumnElement() when column != null:
return column(_that.children,_that.spacing,_that.mainAxisAlignment,_that.crossAxisAlignment);case RowElement() when row != null:
return row(_that.children,_that.spacing,_that.mainAxisAlignment,_that.crossAxisAlignment);case WrapElement() when wrap != null:
return wrap(_that.children,_that.spacing,_that.mainAxisAlignment,_that.crossAxisAlignment);case StackElement() when stack != null:
return stack(_that.children,_that.spacing,_that.mainAxisAlignment,_that.crossAxisAlignment);case GridElement() when grid != null:
return grid(_that.children,_that.columns,_that.horizontalSpacing,_that.verticalSpacing);case CardElement() when card != null:
return card(_that.child,_that.initiallyExpanded);case SectionElement() when section != null:
return section(_that.title,_that.child,_that.description,_that.initiallyExpanded);case CollapsibleElement() when collapsible != null:
return collapsible(_that.title,_that.child,_that.initiallyExpanded);case TabsElement() when tabs != null:
return tabs(_that.tabs,_that.initiallySelectedTabId);case DividerElement() when divider != null:
return divider();case SpacerElement() when spacer != null:
return spacer(_that.width,_that.height);case _:
  return null;

}
}

}

/// @nodoc


class DiagnosticElement implements PresentationElement {
   DiagnosticElement(final  List<TypeDiagnostic> diagnostics): assert(diagnostics.isNotEmpty, 'Diagnostics must not be empty.'),_diagnostics = diagnostics;
  

 final  List<TypeDiagnostic> _diagnostics;
 List<TypeDiagnostic> get diagnostics {
  if (_diagnostics is EqualUnmodifiableListView) return _diagnostics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_diagnostics);
}


/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DiagnosticElementCopyWith<DiagnosticElement> get copyWith => _$DiagnosticElementCopyWithImpl<DiagnosticElement>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DiagnosticElement&&const DeepCollectionEquality().equals(other._diagnostics, _diagnostics));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_diagnostics));

@override
String toString() {
  return 'PresentationElement.diagnostic(diagnostics: $diagnostics)';
}


}

/// @nodoc
abstract mixin class $DiagnosticElementCopyWith<$Res> implements $PresentationElementCopyWith<$Res> {
  factory $DiagnosticElementCopyWith(DiagnosticElement value, $Res Function(DiagnosticElement) _then) = _$DiagnosticElementCopyWithImpl;
@useResult
$Res call({
 List<TypeDiagnostic> diagnostics
});




}
/// @nodoc
class _$DiagnosticElementCopyWithImpl<$Res>
    implements $DiagnosticElementCopyWith<$Res> {
  _$DiagnosticElementCopyWithImpl(this._self, this._then);

  final DiagnosticElement _self;
  final $Res Function(DiagnosticElement) _then;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? diagnostics = null,}) {
  return _then(DiagnosticElement(
null == diagnostics ? _self._diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<TypeDiagnostic>,
  ));
}


}

/// @nodoc


class DefaultPresentationElement implements PresentationElement {
  const DefaultPresentationElement({required this.binding, this.presentationId});
  

 final  BindingReference binding;
 final  PresentationId? presentationId;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DefaultPresentationElementCopyWith<DefaultPresentationElement> get copyWith => _$DefaultPresentationElementCopyWithImpl<DefaultPresentationElement>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DefaultPresentationElement&&(identical(other.binding, binding) || other.binding == binding)&&(identical(other.presentationId, presentationId) || other.presentationId == presentationId));
}


@override
int get hashCode => Object.hash(runtimeType,binding,presentationId);

@override
String toString() {
  return 'PresentationElement.defaultPresentation(binding: $binding, presentationId: $presentationId)';
}


}

/// @nodoc
abstract mixin class $DefaultPresentationElementCopyWith<$Res> implements $PresentationElementCopyWith<$Res> {
  factory $DefaultPresentationElementCopyWith(DefaultPresentationElement value, $Res Function(DefaultPresentationElement) _then) = _$DefaultPresentationElementCopyWithImpl;
@useResult
$Res call({
 BindingReference binding, PresentationId? presentationId
});


$BindingReferenceCopyWith<$Res> get binding;$PresentationIdCopyWith<$Res>? get presentationId;

}
/// @nodoc
class _$DefaultPresentationElementCopyWithImpl<$Res>
    implements $DefaultPresentationElementCopyWith<$Res> {
  _$DefaultPresentationElementCopyWithImpl(this._self, this._then);

  final DefaultPresentationElement _self;
  final $Res Function(DefaultPresentationElement) _then;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? binding = null,Object? presentationId = freezed,}) {
  return _then(DefaultPresentationElement(
binding: null == binding ? _self.binding : binding // ignore: cast_nullable_to_non_nullable
as BindingReference,presentationId: freezed == presentationId ? _self.presentationId : presentationId // ignore: cast_nullable_to_non_nullable
as PresentationId?,
  ));
}

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BindingReferenceCopyWith<$Res> get binding {
  
  return $BindingReferenceCopyWith<$Res>(_self.binding, (value) {
    return _then(_self.copyWith(binding: value));
  });
}/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PresentationIdCopyWith<$Res>? get presentationId {
    if (_self.presentationId == null) {
    return null;
  }

  return $PresentationIdCopyWith<$Res>(_self.presentationId!, (value) {
    return _then(_self.copyWith(presentationId: value));
  });
}
}

/// @nodoc


class TextElement implements PresentationElement, TextualContentElement {
  const TextElement(this.value);
  

 final  TypedExpression value;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TextElementCopyWith<TextElement> get copyWith => _$TextElementCopyWithImpl<TextElement>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TextElement&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,value);

@override
String toString() {
  return 'PresentationElement.text(value: $value)';
}


}

/// @nodoc
abstract mixin class $TextElementCopyWith<$Res> implements $PresentationElementCopyWith<$Res> {
  factory $TextElementCopyWith(TextElement value, $Res Function(TextElement) _then) = _$TextElementCopyWithImpl;
@useResult
$Res call({
 TypedExpression value
});


$TypedExpressionCopyWith<$Res> get value;

}
/// @nodoc
class _$TextElementCopyWithImpl<$Res>
    implements $TextElementCopyWith<$Res> {
  _$TextElementCopyWithImpl(this._self, this._then);

  final TextElement _self;
  final $Res Function(TextElement) _then;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? value = null,}) {
  return _then(TextElement(
null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as TypedExpression,
  ));
}

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get value {
  
  return $TypedExpressionCopyWith<$Res>(_self.value, (value) {
    return _then(_self.copyWith(value: value));
  });
}
}

/// @nodoc


class MarkdownElement implements PresentationElement, TextualContentElement {
  const MarkdownElement(this.value);
  

 final  TypedExpression value;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MarkdownElementCopyWith<MarkdownElement> get copyWith => _$MarkdownElementCopyWithImpl<MarkdownElement>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MarkdownElement&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,value);

@override
String toString() {
  return 'PresentationElement.markdown(value: $value)';
}


}

/// @nodoc
abstract mixin class $MarkdownElementCopyWith<$Res> implements $PresentationElementCopyWith<$Res> {
  factory $MarkdownElementCopyWith(MarkdownElement value, $Res Function(MarkdownElement) _then) = _$MarkdownElementCopyWithImpl;
@useResult
$Res call({
 TypedExpression value
});


$TypedExpressionCopyWith<$Res> get value;

}
/// @nodoc
class _$MarkdownElementCopyWithImpl<$Res>
    implements $MarkdownElementCopyWith<$Res> {
  _$MarkdownElementCopyWithImpl(this._self, this._then);

  final MarkdownElement _self;
  final $Res Function(MarkdownElement) _then;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? value = null,}) {
  return _then(MarkdownElement(
null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as TypedExpression,
  ));
}

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get value {
  
  return $TypedExpressionCopyWith<$Res>(_self.value, (value) {
    return _then(_self.copyWith(value: value));
  });
}
}

/// @nodoc


class IconElement implements PresentationElement {
  const IconElement({required this.name, this.semanticLabel});
  

 final  TypedExpression name;
 final  TypedExpression? semanticLabel;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IconElementCopyWith<IconElement> get copyWith => _$IconElementCopyWithImpl<IconElement>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IconElement&&(identical(other.name, name) || other.name == name)&&(identical(other.semanticLabel, semanticLabel) || other.semanticLabel == semanticLabel));
}


@override
int get hashCode => Object.hash(runtimeType,name,semanticLabel);

@override
String toString() {
  return 'PresentationElement.icon(name: $name, semanticLabel: $semanticLabel)';
}


}

/// @nodoc
abstract mixin class $IconElementCopyWith<$Res> implements $PresentationElementCopyWith<$Res> {
  factory $IconElementCopyWith(IconElement value, $Res Function(IconElement) _then) = _$IconElementCopyWithImpl;
@useResult
$Res call({
 TypedExpression name, TypedExpression? semanticLabel
});


$TypedExpressionCopyWith<$Res> get name;$TypedExpressionCopyWith<$Res>? get semanticLabel;

}
/// @nodoc
class _$IconElementCopyWithImpl<$Res>
    implements $IconElementCopyWith<$Res> {
  _$IconElementCopyWithImpl(this._self, this._then);

  final IconElement _self;
  final $Res Function(IconElement) _then;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? name = null,Object? semanticLabel = freezed,}) {
  return _then(IconElement(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as TypedExpression,semanticLabel: freezed == semanticLabel ? _self.semanticLabel : semanticLabel // ignore: cast_nullable_to_non_nullable
as TypedExpression?,
  ));
}

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get name {
  
  return $TypedExpressionCopyWith<$Res>(_self.name, (value) {
    return _then(_self.copyWith(name: value));
  });
}/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res>? get semanticLabel {
    if (_self.semanticLabel == null) {
    return null;
  }

  return $TypedExpressionCopyWith<$Res>(_self.semanticLabel!, (value) {
    return _then(_self.copyWith(semanticLabel: value));
  });
}
}

/// @nodoc


class ImageElement implements PresentationElement {
  const ImageElement({required this.source, this.semanticLabel});
  

 final  TypedExpression source;
 final  TypedExpression? semanticLabel;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ImageElementCopyWith<ImageElement> get copyWith => _$ImageElementCopyWithImpl<ImageElement>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ImageElement&&(identical(other.source, source) || other.source == source)&&(identical(other.semanticLabel, semanticLabel) || other.semanticLabel == semanticLabel));
}


@override
int get hashCode => Object.hash(runtimeType,source,semanticLabel);

@override
String toString() {
  return 'PresentationElement.image(source: $source, semanticLabel: $semanticLabel)';
}


}

/// @nodoc
abstract mixin class $ImageElementCopyWith<$Res> implements $PresentationElementCopyWith<$Res> {
  factory $ImageElementCopyWith(ImageElement value, $Res Function(ImageElement) _then) = _$ImageElementCopyWithImpl;
@useResult
$Res call({
 TypedExpression source, TypedExpression? semanticLabel
});


$TypedExpressionCopyWith<$Res> get source;$TypedExpressionCopyWith<$Res>? get semanticLabel;

}
/// @nodoc
class _$ImageElementCopyWithImpl<$Res>
    implements $ImageElementCopyWith<$Res> {
  _$ImageElementCopyWithImpl(this._self, this._then);

  final ImageElement _self;
  final $Res Function(ImageElement) _then;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? source = null,Object? semanticLabel = freezed,}) {
  return _then(ImageElement(
source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as TypedExpression,semanticLabel: freezed == semanticLabel ? _self.semanticLabel : semanticLabel // ignore: cast_nullable_to_non_nullable
as TypedExpression?,
  ));
}

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get source {
  
  return $TypedExpressionCopyWith<$Res>(_self.source, (value) {
    return _then(_self.copyWith(source: value));
  });
}/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res>? get semanticLabel {
    if (_self.semanticLabel == null) {
    return null;
  }

  return $TypedExpressionCopyWith<$Res>(_self.semanticLabel!, (value) {
    return _then(_self.copyWith(semanticLabel: value));
  });
}
}

/// @nodoc


class BadgeElement implements PresentationElement {
  const BadgeElement({required this.label, required this.tone});
  

 final  TypedExpression label;
 final  String tone;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BadgeElementCopyWith<BadgeElement> get copyWith => _$BadgeElementCopyWithImpl<BadgeElement>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BadgeElement&&(identical(other.label, label) || other.label == label)&&(identical(other.tone, tone) || other.tone == tone));
}


@override
int get hashCode => Object.hash(runtimeType,label,tone);

@override
String toString() {
  return 'PresentationElement.badge(label: $label, tone: $tone)';
}


}

/// @nodoc
abstract mixin class $BadgeElementCopyWith<$Res> implements $PresentationElementCopyWith<$Res> {
  factory $BadgeElementCopyWith(BadgeElement value, $Res Function(BadgeElement) _then) = _$BadgeElementCopyWithImpl;
@useResult
$Res call({
 TypedExpression label, String tone
});


$TypedExpressionCopyWith<$Res> get label;

}
/// @nodoc
class _$BadgeElementCopyWithImpl<$Res>
    implements $BadgeElementCopyWith<$Res> {
  _$BadgeElementCopyWithImpl(this._self, this._then);

  final BadgeElement _self;
  final $Res Function(BadgeElement) _then;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? label = null,Object? tone = null,}) {
  return _then(BadgeElement(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as TypedExpression,tone: null == tone ? _self.tone : tone // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get label {
  
  return $TypedExpressionCopyWith<$Res>(_self.label, (value) {
    return _then(_self.copyWith(label: value));
  });
}
}

/// @nodoc


class ProgressElement implements PresentationElement {
  const ProgressElement({required this.value, required this.maximum, this.label});
  

 final  TypedExpression value;
 final  TypedExpression maximum;
 final  TypedExpression? label;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProgressElementCopyWith<ProgressElement> get copyWith => _$ProgressElementCopyWithImpl<ProgressElement>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProgressElement&&(identical(other.value, value) || other.value == value)&&(identical(other.maximum, maximum) || other.maximum == maximum)&&(identical(other.label, label) || other.label == label));
}


@override
int get hashCode => Object.hash(runtimeType,value,maximum,label);

@override
String toString() {
  return 'PresentationElement.progress(value: $value, maximum: $maximum, label: $label)';
}


}

/// @nodoc
abstract mixin class $ProgressElementCopyWith<$Res> implements $PresentationElementCopyWith<$Res> {
  factory $ProgressElementCopyWith(ProgressElement value, $Res Function(ProgressElement) _then) = _$ProgressElementCopyWithImpl;
@useResult
$Res call({
 TypedExpression value, TypedExpression maximum, TypedExpression? label
});


$TypedExpressionCopyWith<$Res> get value;$TypedExpressionCopyWith<$Res> get maximum;$TypedExpressionCopyWith<$Res>? get label;

}
/// @nodoc
class _$ProgressElementCopyWithImpl<$Res>
    implements $ProgressElementCopyWith<$Res> {
  _$ProgressElementCopyWithImpl(this._self, this._then);

  final ProgressElement _self;
  final $Res Function(ProgressElement) _then;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? value = null,Object? maximum = null,Object? label = freezed,}) {
  return _then(ProgressElement(
value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as TypedExpression,maximum: null == maximum ? _self.maximum : maximum // ignore: cast_nullable_to_non_nullable
as TypedExpression,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as TypedExpression?,
  ));
}

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get value {
  
  return $TypedExpressionCopyWith<$Res>(_self.value, (value) {
    return _then(_self.copyWith(value: value));
  });
}/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get maximum {
  
  return $TypedExpressionCopyWith<$Res>(_self.maximum, (value) {
    return _then(_self.copyWith(maximum: value));
  });
}/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res>? get label {
    if (_self.label == null) {
    return null;
  }

  return $TypedExpressionCopyWith<$Res>(_self.label!, (value) {
    return _then(_self.copyWith(label: value));
  });
}
}

/// @nodoc


class TypedFieldElement implements PresentationElement {
  const TypedFieldElement({required this.binding, required this.expectedType, this.presentation});
  

 final  BindingReference binding;
 final  TypeExpression expectedType;
 final  PresentationNode? presentation;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TypedFieldElementCopyWith<TypedFieldElement> get copyWith => _$TypedFieldElementCopyWithImpl<TypedFieldElement>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TypedFieldElement&&(identical(other.binding, binding) || other.binding == binding)&&(identical(other.expectedType, expectedType) || other.expectedType == expectedType)&&(identical(other.presentation, presentation) || other.presentation == presentation));
}


@override
int get hashCode => Object.hash(runtimeType,binding,expectedType,presentation);

@override
String toString() {
  return 'PresentationElement.typedField(binding: $binding, expectedType: $expectedType, presentation: $presentation)';
}


}

/// @nodoc
abstract mixin class $TypedFieldElementCopyWith<$Res> implements $PresentationElementCopyWith<$Res> {
  factory $TypedFieldElementCopyWith(TypedFieldElement value, $Res Function(TypedFieldElement) _then) = _$TypedFieldElementCopyWithImpl;
@useResult
$Res call({
 BindingReference binding, TypeExpression expectedType, PresentationNode? presentation
});


$BindingReferenceCopyWith<$Res> get binding;$TypeExpressionCopyWith<$Res> get expectedType;$PresentationNodeCopyWith<$Res>? get presentation;

}
/// @nodoc
class _$TypedFieldElementCopyWithImpl<$Res>
    implements $TypedFieldElementCopyWith<$Res> {
  _$TypedFieldElementCopyWithImpl(this._self, this._then);

  final TypedFieldElement _self;
  final $Res Function(TypedFieldElement) _then;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? binding = null,Object? expectedType = null,Object? presentation = freezed,}) {
  return _then(TypedFieldElement(
binding: null == binding ? _self.binding : binding // ignore: cast_nullable_to_non_nullable
as BindingReference,expectedType: null == expectedType ? _self.expectedType : expectedType // ignore: cast_nullable_to_non_nullable
as TypeExpression,presentation: freezed == presentation ? _self.presentation : presentation // ignore: cast_nullable_to_non_nullable
as PresentationNode?,
  ));
}

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BindingReferenceCopyWith<$Res> get binding {
  
  return $BindingReferenceCopyWith<$Res>(_self.binding, (value) {
    return _then(_self.copyWith(binding: value));
  });
}/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypeExpressionCopyWith<$Res> get expectedType {
  
  return $TypeExpressionCopyWith<$Res>(_self.expectedType, (value) {
    return _then(_self.copyWith(expectedType: value));
  });
}/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PresentationNodeCopyWith<$Res>? get presentation {
    if (_self.presentation == null) {
    return null;
  }

  return $PresentationNodeCopyWith<$Res>(_self.presentation!, (value) {
    return _then(_self.copyWith(presentation: value));
  });
}
}

/// @nodoc


class ConditionalElement implements PresentationElement {
  const ConditionalElement({required this.condition, required this.whenTrue, this.whenFalse});
  

 final  TypedExpression condition;
 final  PresentationNode whenTrue;
 final  PresentationNode? whenFalse;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConditionalElementCopyWith<ConditionalElement> get copyWith => _$ConditionalElementCopyWithImpl<ConditionalElement>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConditionalElement&&(identical(other.condition, condition) || other.condition == condition)&&(identical(other.whenTrue, whenTrue) || other.whenTrue == whenTrue)&&(identical(other.whenFalse, whenFalse) || other.whenFalse == whenFalse));
}


@override
int get hashCode => Object.hash(runtimeType,condition,whenTrue,whenFalse);

@override
String toString() {
  return 'PresentationElement.conditional(condition: $condition, whenTrue: $whenTrue, whenFalse: $whenFalse)';
}


}

/// @nodoc
abstract mixin class $ConditionalElementCopyWith<$Res> implements $PresentationElementCopyWith<$Res> {
  factory $ConditionalElementCopyWith(ConditionalElement value, $Res Function(ConditionalElement) _then) = _$ConditionalElementCopyWithImpl;
@useResult
$Res call({
 TypedExpression condition, PresentationNode whenTrue, PresentationNode? whenFalse
});


$TypedExpressionCopyWith<$Res> get condition;$PresentationNodeCopyWith<$Res> get whenTrue;$PresentationNodeCopyWith<$Res>? get whenFalse;

}
/// @nodoc
class _$ConditionalElementCopyWithImpl<$Res>
    implements $ConditionalElementCopyWith<$Res> {
  _$ConditionalElementCopyWithImpl(this._self, this._then);

  final ConditionalElement _self;
  final $Res Function(ConditionalElement) _then;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? condition = null,Object? whenTrue = null,Object? whenFalse = freezed,}) {
  return _then(ConditionalElement(
condition: null == condition ? _self.condition : condition // ignore: cast_nullable_to_non_nullable
as TypedExpression,whenTrue: null == whenTrue ? _self.whenTrue : whenTrue // ignore: cast_nullable_to_non_nullable
as PresentationNode,whenFalse: freezed == whenFalse ? _self.whenFalse : whenFalse // ignore: cast_nullable_to_non_nullable
as PresentationNode?,
  ));
}

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get condition {
  
  return $TypedExpressionCopyWith<$Res>(_self.condition, (value) {
    return _then(_self.copyWith(condition: value));
  });
}/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PresentationNodeCopyWith<$Res> get whenTrue {
  
  return $PresentationNodeCopyWith<$Res>(_self.whenTrue, (value) {
    return _then(_self.copyWith(whenTrue: value));
  });
}/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PresentationNodeCopyWith<$Res>? get whenFalse {
    if (_self.whenFalse == null) {
    return null;
  }

  return $PresentationNodeCopyWith<$Res>(_self.whenFalse!, (value) {
    return _then(_self.copyWith(whenFalse: value));
  });
}
}

/// @nodoc


class RepeatedElement implements PresentationElement {
  const RepeatedElement({required this.source, required this.itemBindingId, required this.template, this.empty});
  

 final  TypedExpression source;
 final  BindingId itemBindingId;
 final  PresentationNode template;
 final  PresentationNode? empty;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RepeatedElementCopyWith<RepeatedElement> get copyWith => _$RepeatedElementCopyWithImpl<RepeatedElement>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RepeatedElement&&(identical(other.source, source) || other.source == source)&&(identical(other.itemBindingId, itemBindingId) || other.itemBindingId == itemBindingId)&&(identical(other.template, template) || other.template == template)&&(identical(other.empty, empty) || other.empty == empty));
}


@override
int get hashCode => Object.hash(runtimeType,source,itemBindingId,template,empty);

@override
String toString() {
  return 'PresentationElement.repeated(source: $source, itemBindingId: $itemBindingId, template: $template, empty: $empty)';
}


}

/// @nodoc
abstract mixin class $RepeatedElementCopyWith<$Res> implements $PresentationElementCopyWith<$Res> {
  factory $RepeatedElementCopyWith(RepeatedElement value, $Res Function(RepeatedElement) _then) = _$RepeatedElementCopyWithImpl;
@useResult
$Res call({
 TypedExpression source, BindingId itemBindingId, PresentationNode template, PresentationNode? empty
});


$TypedExpressionCopyWith<$Res> get source;$BindingIdCopyWith<$Res> get itemBindingId;$PresentationNodeCopyWith<$Res> get template;$PresentationNodeCopyWith<$Res>? get empty;

}
/// @nodoc
class _$RepeatedElementCopyWithImpl<$Res>
    implements $RepeatedElementCopyWith<$Res> {
  _$RepeatedElementCopyWithImpl(this._self, this._then);

  final RepeatedElement _self;
  final $Res Function(RepeatedElement) _then;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? source = null,Object? itemBindingId = null,Object? template = null,Object? empty = freezed,}) {
  return _then(RepeatedElement(
source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as TypedExpression,itemBindingId: null == itemBindingId ? _self.itemBindingId : itemBindingId // ignore: cast_nullable_to_non_nullable
as BindingId,template: null == template ? _self.template : template // ignore: cast_nullable_to_non_nullable
as PresentationNode,empty: freezed == empty ? _self.empty : empty // ignore: cast_nullable_to_non_nullable
as PresentationNode?,
  ));
}

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get source {
  
  return $TypedExpressionCopyWith<$Res>(_self.source, (value) {
    return _then(_self.copyWith(source: value));
  });
}/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BindingIdCopyWith<$Res> get itemBindingId {
  
  return $BindingIdCopyWith<$Res>(_self.itemBindingId, (value) {
    return _then(_self.copyWith(itemBindingId: value));
  });
}/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PresentationNodeCopyWith<$Res> get template {
  
  return $PresentationNodeCopyWith<$Res>(_self.template, (value) {
    return _then(_self.copyWith(template: value));
  });
}/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PresentationNodeCopyWith<$Res>? get empty {
    if (_self.empty == null) {
    return null;
  }

  return $PresentationNodeCopyWith<$Res>(_self.empty!, (value) {
    return _then(_self.copyWith(empty: value));
  });
}
}

/// @nodoc


class ScopedBindingElement implements PresentationElement {
  const ScopedBindingElement({required this.binding, required this.scopeBindingId, required this.child});
  

 final  BindingReference binding;
 final  BindingId scopeBindingId;
 final  PresentationNode child;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScopedBindingElementCopyWith<ScopedBindingElement> get copyWith => _$ScopedBindingElementCopyWithImpl<ScopedBindingElement>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScopedBindingElement&&(identical(other.binding, binding) || other.binding == binding)&&(identical(other.scopeBindingId, scopeBindingId) || other.scopeBindingId == scopeBindingId)&&(identical(other.child, child) || other.child == child));
}


@override
int get hashCode => Object.hash(runtimeType,binding,scopeBindingId,child);

@override
String toString() {
  return 'PresentationElement.scopedBinding(binding: $binding, scopeBindingId: $scopeBindingId, child: $child)';
}


}

/// @nodoc
abstract mixin class $ScopedBindingElementCopyWith<$Res> implements $PresentationElementCopyWith<$Res> {
  factory $ScopedBindingElementCopyWith(ScopedBindingElement value, $Res Function(ScopedBindingElement) _then) = _$ScopedBindingElementCopyWithImpl;
@useResult
$Res call({
 BindingReference binding, BindingId scopeBindingId, PresentationNode child
});


$BindingReferenceCopyWith<$Res> get binding;$BindingIdCopyWith<$Res> get scopeBindingId;$PresentationNodeCopyWith<$Res> get child;

}
/// @nodoc
class _$ScopedBindingElementCopyWithImpl<$Res>
    implements $ScopedBindingElementCopyWith<$Res> {
  _$ScopedBindingElementCopyWithImpl(this._self, this._then);

  final ScopedBindingElement _self;
  final $Res Function(ScopedBindingElement) _then;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? binding = null,Object? scopeBindingId = null,Object? child = null,}) {
  return _then(ScopedBindingElement(
binding: null == binding ? _self.binding : binding // ignore: cast_nullable_to_non_nullable
as BindingReference,scopeBindingId: null == scopeBindingId ? _self.scopeBindingId : scopeBindingId // ignore: cast_nullable_to_non_nullable
as BindingId,child: null == child ? _self.child : child // ignore: cast_nullable_to_non_nullable
as PresentationNode,
  ));
}

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BindingReferenceCopyWith<$Res> get binding {
  
  return $BindingReferenceCopyWith<$Res>(_self.binding, (value) {
    return _then(_self.copyWith(binding: value));
  });
}/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BindingIdCopyWith<$Res> get scopeBindingId {
  
  return $BindingIdCopyWith<$Res>(_self.scopeBindingId, (value) {
    return _then(_self.copyWith(scopeBindingId: value));
  });
}/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PresentationNodeCopyWith<$Res> get child {
  
  return $PresentationNodeCopyWith<$Res>(_self.child, (value) {
    return _then(_self.copyWith(child: value));
  });
}
}

/// @nodoc


class TextInputElement implements PresentationElement {
  const TextInputElement({required this.control, this.multiline = true, this.placeholder});
  

 final  BoundControl control;
@JsonKey() final  bool multiline;
 final  TypedExpression? placeholder;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TextInputElementCopyWith<TextInputElement> get copyWith => _$TextInputElementCopyWithImpl<TextInputElement>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TextInputElement&&(identical(other.control, control) || other.control == control)&&(identical(other.multiline, multiline) || other.multiline == multiline)&&(identical(other.placeholder, placeholder) || other.placeholder == placeholder));
}


@override
int get hashCode => Object.hash(runtimeType,control,multiline,placeholder);

@override
String toString() {
  return 'PresentationElement.textInput(control: $control, multiline: $multiline, placeholder: $placeholder)';
}


}

/// @nodoc
abstract mixin class $TextInputElementCopyWith<$Res> implements $PresentationElementCopyWith<$Res> {
  factory $TextInputElementCopyWith(TextInputElement value, $Res Function(TextInputElement) _then) = _$TextInputElementCopyWithImpl;
@useResult
$Res call({
 BoundControl control, bool multiline, TypedExpression? placeholder
});


$BoundControlCopyWith<$Res> get control;$TypedExpressionCopyWith<$Res>? get placeholder;

}
/// @nodoc
class _$TextInputElementCopyWithImpl<$Res>
    implements $TextInputElementCopyWith<$Res> {
  _$TextInputElementCopyWithImpl(this._self, this._then);

  final TextInputElement _self;
  final $Res Function(TextInputElement) _then;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? control = null,Object? multiline = null,Object? placeholder = freezed,}) {
  return _then(TextInputElement(
control: null == control ? _self.control : control // ignore: cast_nullable_to_non_nullable
as BoundControl,multiline: null == multiline ? _self.multiline : multiline // ignore: cast_nullable_to_non_nullable
as bool,placeholder: freezed == placeholder ? _self.placeholder : placeholder // ignore: cast_nullable_to_non_nullable
as TypedExpression?,
  ));
}

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BoundControlCopyWith<$Res> get control {
  
  return $BoundControlCopyWith<$Res>(_self.control, (value) {
    return _then(_self.copyWith(control: value));
  });
}/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res>? get placeholder {
    if (_self.placeholder == null) {
    return null;
  }

  return $TypedExpressionCopyWith<$Res>(_self.placeholder!, (value) {
    return _then(_self.copyWith(placeholder: value));
  });
}
}

/// @nodoc


class NumericInputElement implements PresentationElement {
  const NumericInputElement(this.control);
  

 final  BoundControl control;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NumericInputElementCopyWith<NumericInputElement> get copyWith => _$NumericInputElementCopyWithImpl<NumericInputElement>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NumericInputElement&&(identical(other.control, control) || other.control == control));
}


@override
int get hashCode => Object.hash(runtimeType,control);

@override
String toString() {
  return 'PresentationElement.numericInput(control: $control)';
}


}

/// @nodoc
abstract mixin class $NumericInputElementCopyWith<$Res> implements $PresentationElementCopyWith<$Res> {
  factory $NumericInputElementCopyWith(NumericInputElement value, $Res Function(NumericInputElement) _then) = _$NumericInputElementCopyWithImpl;
@useResult
$Res call({
 BoundControl control
});


$BoundControlCopyWith<$Res> get control;

}
/// @nodoc
class _$NumericInputElementCopyWithImpl<$Res>
    implements $NumericInputElementCopyWith<$Res> {
  _$NumericInputElementCopyWithImpl(this._self, this._then);

  final NumericInputElement _self;
  final $Res Function(NumericInputElement) _then;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? control = null,}) {
  return _then(NumericInputElement(
null == control ? _self.control : control // ignore: cast_nullable_to_non_nullable
as BoundControl,
  ));
}

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BoundControlCopyWith<$Res> get control {
  
  return $BoundControlCopyWith<$Res>(_self.control, (value) {
    return _then(_self.copyWith(control: value));
  });
}
}

/// @nodoc


class ToggleInputElement implements PresentationElement {
  const ToggleInputElement(this.control);
  

 final  BoundControl control;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ToggleInputElementCopyWith<ToggleInputElement> get copyWith => _$ToggleInputElementCopyWithImpl<ToggleInputElement>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ToggleInputElement&&(identical(other.control, control) || other.control == control));
}


@override
int get hashCode => Object.hash(runtimeType,control);

@override
String toString() {
  return 'PresentationElement.toggleInput(control: $control)';
}


}

/// @nodoc
abstract mixin class $ToggleInputElementCopyWith<$Res> implements $PresentationElementCopyWith<$Res> {
  factory $ToggleInputElementCopyWith(ToggleInputElement value, $Res Function(ToggleInputElement) _then) = _$ToggleInputElementCopyWithImpl;
@useResult
$Res call({
 BoundControl control
});


$BoundControlCopyWith<$Res> get control;

}
/// @nodoc
class _$ToggleInputElementCopyWithImpl<$Res>
    implements $ToggleInputElementCopyWith<$Res> {
  _$ToggleInputElementCopyWithImpl(this._self, this._then);

  final ToggleInputElement _self;
  final $Res Function(ToggleInputElement) _then;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? control = null,}) {
  return _then(ToggleInputElement(
null == control ? _self.control : control // ignore: cast_nullable_to_non_nullable
as BoundControl,
  ));
}

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BoundControlCopyWith<$Res> get control {
  
  return $BoundControlCopyWith<$Res>(_self.control, (value) {
    return _then(_self.copyWith(control: value));
  });
}
}

/// @nodoc


class SelectInputElement implements PresentationElement {
  const SelectInputElement({required this.control, required final  List<SelectOption> options, this.allowCustomValue = false}): _options = options;
  

 final  BoundControl control;
 final  List<SelectOption> _options;
 List<SelectOption> get options {
  if (_options is EqualUnmodifiableListView) return _options;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_options);
}

@JsonKey() final  bool allowCustomValue;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SelectInputElementCopyWith<SelectInputElement> get copyWith => _$SelectInputElementCopyWithImpl<SelectInputElement>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SelectInputElement&&(identical(other.control, control) || other.control == control)&&const DeepCollectionEquality().equals(other._options, _options)&&(identical(other.allowCustomValue, allowCustomValue) || other.allowCustomValue == allowCustomValue));
}


@override
int get hashCode => Object.hash(runtimeType,control,const DeepCollectionEquality().hash(_options),allowCustomValue);

@override
String toString() {
  return 'PresentationElement.selectInput(control: $control, options: $options, allowCustomValue: $allowCustomValue)';
}


}

/// @nodoc
abstract mixin class $SelectInputElementCopyWith<$Res> implements $PresentationElementCopyWith<$Res> {
  factory $SelectInputElementCopyWith(SelectInputElement value, $Res Function(SelectInputElement) _then) = _$SelectInputElementCopyWithImpl;
@useResult
$Res call({
 BoundControl control, List<SelectOption> options, bool allowCustomValue
});


$BoundControlCopyWith<$Res> get control;

}
/// @nodoc
class _$SelectInputElementCopyWithImpl<$Res>
    implements $SelectInputElementCopyWith<$Res> {
  _$SelectInputElementCopyWithImpl(this._self, this._then);

  final SelectInputElement _self;
  final $Res Function(SelectInputElement) _then;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? control = null,Object? options = null,Object? allowCustomValue = null,}) {
  return _then(SelectInputElement(
control: null == control ? _self.control : control // ignore: cast_nullable_to_non_nullable
as BoundControl,options: null == options ? _self._options : options // ignore: cast_nullable_to_non_nullable
as List<SelectOption>,allowCustomValue: null == allowCustomValue ? _self.allowCustomValue : allowCustomValue // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BoundControlCopyWith<$Res> get control {
  
  return $BoundControlCopyWith<$Res>(_self.control, (value) {
    return _then(_self.copyWith(control: value));
  });
}
}

/// @nodoc


class SliderInputElement implements PresentationElement {
  const SliderInputElement({required this.control, required this.minimum, required this.maximum, this.divisions});
  

 final  BoundControl control;
 final  TypedExpression minimum;
 final  TypedExpression maximum;
 final  TypedExpression? divisions;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SliderInputElementCopyWith<SliderInputElement> get copyWith => _$SliderInputElementCopyWithImpl<SliderInputElement>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SliderInputElement&&(identical(other.control, control) || other.control == control)&&(identical(other.minimum, minimum) || other.minimum == minimum)&&(identical(other.maximum, maximum) || other.maximum == maximum)&&(identical(other.divisions, divisions) || other.divisions == divisions));
}


@override
int get hashCode => Object.hash(runtimeType,control,minimum,maximum,divisions);

@override
String toString() {
  return 'PresentationElement.sliderInput(control: $control, minimum: $minimum, maximum: $maximum, divisions: $divisions)';
}


}

/// @nodoc
abstract mixin class $SliderInputElementCopyWith<$Res> implements $PresentationElementCopyWith<$Res> {
  factory $SliderInputElementCopyWith(SliderInputElement value, $Res Function(SliderInputElement) _then) = _$SliderInputElementCopyWithImpl;
@useResult
$Res call({
 BoundControl control, TypedExpression minimum, TypedExpression maximum, TypedExpression? divisions
});


$BoundControlCopyWith<$Res> get control;$TypedExpressionCopyWith<$Res> get minimum;$TypedExpressionCopyWith<$Res> get maximum;$TypedExpressionCopyWith<$Res>? get divisions;

}
/// @nodoc
class _$SliderInputElementCopyWithImpl<$Res>
    implements $SliderInputElementCopyWith<$Res> {
  _$SliderInputElementCopyWithImpl(this._self, this._then);

  final SliderInputElement _self;
  final $Res Function(SliderInputElement) _then;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? control = null,Object? minimum = null,Object? maximum = null,Object? divisions = freezed,}) {
  return _then(SliderInputElement(
control: null == control ? _self.control : control // ignore: cast_nullable_to_non_nullable
as BoundControl,minimum: null == minimum ? _self.minimum : minimum // ignore: cast_nullable_to_non_nullable
as TypedExpression,maximum: null == maximum ? _self.maximum : maximum // ignore: cast_nullable_to_non_nullable
as TypedExpression,divisions: freezed == divisions ? _self.divisions : divisions // ignore: cast_nullable_to_non_nullable
as TypedExpression?,
  ));
}

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BoundControlCopyWith<$Res> get control {
  
  return $BoundControlCopyWith<$Res>(_self.control, (value) {
    return _then(_self.copyWith(control: value));
  });
}/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get minimum {
  
  return $TypedExpressionCopyWith<$Res>(_self.minimum, (value) {
    return _then(_self.copyWith(minimum: value));
  });
}/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get maximum {
  
  return $TypedExpressionCopyWith<$Res>(_self.maximum, (value) {
    return _then(_self.copyWith(maximum: value));
  });
}/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res>? get divisions {
    if (_self.divisions == null) {
    return null;
  }

  return $TypedExpressionCopyWith<$Res>(_self.divisions!, (value) {
    return _then(_self.copyWith(divisions: value));
  });
}
}

/// @nodoc


class DateTimeInputElement implements PresentationElement, SimpleInputElement {
  const DateTimeInputElement({required this.control, this.includeDate = true, this.includeTime = true});
  

 final  BoundControl control;
@JsonKey() final  bool includeDate;
@JsonKey() final  bool includeTime;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DateTimeInputElementCopyWith<DateTimeInputElement> get copyWith => _$DateTimeInputElementCopyWithImpl<DateTimeInputElement>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DateTimeInputElement&&(identical(other.control, control) || other.control == control)&&(identical(other.includeDate, includeDate) || other.includeDate == includeDate)&&(identical(other.includeTime, includeTime) || other.includeTime == includeTime));
}


@override
int get hashCode => Object.hash(runtimeType,control,includeDate,includeTime);

@override
String toString() {
  return 'PresentationElement.dateTimeInput(control: $control, includeDate: $includeDate, includeTime: $includeTime)';
}


}

/// @nodoc
abstract mixin class $DateTimeInputElementCopyWith<$Res> implements $PresentationElementCopyWith<$Res> {
  factory $DateTimeInputElementCopyWith(DateTimeInputElement value, $Res Function(DateTimeInputElement) _then) = _$DateTimeInputElementCopyWithImpl;
@useResult
$Res call({
 BoundControl control, bool includeDate, bool includeTime
});


$BoundControlCopyWith<$Res> get control;

}
/// @nodoc
class _$DateTimeInputElementCopyWithImpl<$Res>
    implements $DateTimeInputElementCopyWith<$Res> {
  _$DateTimeInputElementCopyWithImpl(this._self, this._then);

  final DateTimeInputElement _self;
  final $Res Function(DateTimeInputElement) _then;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? control = null,Object? includeDate = null,Object? includeTime = null,}) {
  return _then(DateTimeInputElement(
control: null == control ? _self.control : control // ignore: cast_nullable_to_non_nullable
as BoundControl,includeDate: null == includeDate ? _self.includeDate : includeDate // ignore: cast_nullable_to_non_nullable
as bool,includeTime: null == includeTime ? _self.includeTime : includeTime // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BoundControlCopyWith<$Res> get control {
  
  return $BoundControlCopyWith<$Res>(_self.control, (value) {
    return _then(_self.copyWith(control: value));
  });
}
}

/// @nodoc


class DurationInputElement implements PresentationElement, SimpleInputElement {
  const DurationInputElement(this.control);
  

 final  BoundControl control;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DurationInputElementCopyWith<DurationInputElement> get copyWith => _$DurationInputElementCopyWithImpl<DurationInputElement>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DurationInputElement&&(identical(other.control, control) || other.control == control));
}


@override
int get hashCode => Object.hash(runtimeType,control);

@override
String toString() {
  return 'PresentationElement.durationInput(control: $control)';
}


}

/// @nodoc
abstract mixin class $DurationInputElementCopyWith<$Res> implements $PresentationElementCopyWith<$Res> {
  factory $DurationInputElementCopyWith(DurationInputElement value, $Res Function(DurationInputElement) _then) = _$DurationInputElementCopyWithImpl;
@useResult
$Res call({
 BoundControl control
});


$BoundControlCopyWith<$Res> get control;

}
/// @nodoc
class _$DurationInputElementCopyWithImpl<$Res>
    implements $DurationInputElementCopyWith<$Res> {
  _$DurationInputElementCopyWithImpl(this._self, this._then);

  final DurationInputElement _self;
  final $Res Function(DurationInputElement) _then;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? control = null,}) {
  return _then(DurationInputElement(
null == control ? _self.control : control // ignore: cast_nullable_to_non_nullable
as BoundControl,
  ));
}

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BoundControlCopyWith<$Res> get control {
  
  return $BoundControlCopyWith<$Res>(_self.control, (value) {
    return _then(_self.copyWith(control: value));
  });
}
}

/// @nodoc


class ColorInputElement implements PresentationElement, SimpleInputElement {
  const ColorInputElement({required this.control, this.includeAlpha = false});
  

 final  BoundControl control;
@JsonKey() final  bool includeAlpha;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ColorInputElementCopyWith<ColorInputElement> get copyWith => _$ColorInputElementCopyWithImpl<ColorInputElement>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ColorInputElement&&(identical(other.control, control) || other.control == control)&&(identical(other.includeAlpha, includeAlpha) || other.includeAlpha == includeAlpha));
}


@override
int get hashCode => Object.hash(runtimeType,control,includeAlpha);

@override
String toString() {
  return 'PresentationElement.colorInput(control: $control, includeAlpha: $includeAlpha)';
}


}

/// @nodoc
abstract mixin class $ColorInputElementCopyWith<$Res> implements $PresentationElementCopyWith<$Res> {
  factory $ColorInputElementCopyWith(ColorInputElement value, $Res Function(ColorInputElement) _then) = _$ColorInputElementCopyWithImpl;
@useResult
$Res call({
 BoundControl control, bool includeAlpha
});


$BoundControlCopyWith<$Res> get control;

}
/// @nodoc
class _$ColorInputElementCopyWithImpl<$Res>
    implements $ColorInputElementCopyWith<$Res> {
  _$ColorInputElementCopyWithImpl(this._self, this._then);

  final ColorInputElement _self;
  final $Res Function(ColorInputElement) _then;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? control = null,Object? includeAlpha = null,}) {
  return _then(ColorInputElement(
control: null == control ? _self.control : control // ignore: cast_nullable_to_non_nullable
as BoundControl,includeAlpha: null == includeAlpha ? _self.includeAlpha : includeAlpha // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BoundControlCopyWith<$Res> get control {
  
  return $BoundControlCopyWith<$Res>(_self.control, (value) {
    return _then(_self.copyWith(control: value));
  });
}
}

/// @nodoc


class SearchInputElement implements PresentationElement {
  const SearchInputElement({required this.control, required this.selectionMode, required this.queryBindingId, required this.summaryBindingId, required this.maximumExtent, required this.provider, this.summary, this.placeholder, this.customValue});
  

 final  BoundControl control;
 final  SearchSelectionMode selectionMode;
 final  BindingId queryBindingId;
 final  BindingId summaryBindingId;
 final  TypedExpression maximumExtent;
 final  SearchProvider provider;
 final  PresentationNode? summary;
 final  TypedExpression? placeholder;
 final  TypedExpression? customValue;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchInputElementCopyWith<SearchInputElement> get copyWith => _$SearchInputElementCopyWithImpl<SearchInputElement>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchInputElement&&(identical(other.control, control) || other.control == control)&&(identical(other.selectionMode, selectionMode) || other.selectionMode == selectionMode)&&(identical(other.queryBindingId, queryBindingId) || other.queryBindingId == queryBindingId)&&(identical(other.summaryBindingId, summaryBindingId) || other.summaryBindingId == summaryBindingId)&&(identical(other.maximumExtent, maximumExtent) || other.maximumExtent == maximumExtent)&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.placeholder, placeholder) || other.placeholder == placeholder)&&(identical(other.customValue, customValue) || other.customValue == customValue));
}


@override
int get hashCode => Object.hash(runtimeType,control,selectionMode,queryBindingId,summaryBindingId,maximumExtent,provider,summary,placeholder,customValue);

@override
String toString() {
  return 'PresentationElement.searchInput(control: $control, selectionMode: $selectionMode, queryBindingId: $queryBindingId, summaryBindingId: $summaryBindingId, maximumExtent: $maximumExtent, provider: $provider, summary: $summary, placeholder: $placeholder, customValue: $customValue)';
}


}

/// @nodoc
abstract mixin class $SearchInputElementCopyWith<$Res> implements $PresentationElementCopyWith<$Res> {
  factory $SearchInputElementCopyWith(SearchInputElement value, $Res Function(SearchInputElement) _then) = _$SearchInputElementCopyWithImpl;
@useResult
$Res call({
 BoundControl control, SearchSelectionMode selectionMode, BindingId queryBindingId, BindingId summaryBindingId, TypedExpression maximumExtent, SearchProvider provider, PresentationNode? summary, TypedExpression? placeholder, TypedExpression? customValue
});


$BoundControlCopyWith<$Res> get control;$BindingIdCopyWith<$Res> get queryBindingId;$BindingIdCopyWith<$Res> get summaryBindingId;$TypedExpressionCopyWith<$Res> get maximumExtent;$SearchProviderCopyWith<$Res> get provider;$PresentationNodeCopyWith<$Res>? get summary;$TypedExpressionCopyWith<$Res>? get placeholder;$TypedExpressionCopyWith<$Res>? get customValue;

}
/// @nodoc
class _$SearchInputElementCopyWithImpl<$Res>
    implements $SearchInputElementCopyWith<$Res> {
  _$SearchInputElementCopyWithImpl(this._self, this._then);

  final SearchInputElement _self;
  final $Res Function(SearchInputElement) _then;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? control = null,Object? selectionMode = null,Object? queryBindingId = null,Object? summaryBindingId = null,Object? maximumExtent = null,Object? provider = null,Object? summary = freezed,Object? placeholder = freezed,Object? customValue = freezed,}) {
  return _then(SearchInputElement(
control: null == control ? _self.control : control // ignore: cast_nullable_to_non_nullable
as BoundControl,selectionMode: null == selectionMode ? _self.selectionMode : selectionMode // ignore: cast_nullable_to_non_nullable
as SearchSelectionMode,queryBindingId: null == queryBindingId ? _self.queryBindingId : queryBindingId // ignore: cast_nullable_to_non_nullable
as BindingId,summaryBindingId: null == summaryBindingId ? _self.summaryBindingId : summaryBindingId // ignore: cast_nullable_to_non_nullable
as BindingId,maximumExtent: null == maximumExtent ? _self.maximumExtent : maximumExtent // ignore: cast_nullable_to_non_nullable
as TypedExpression,provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as SearchProvider,summary: freezed == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as PresentationNode?,placeholder: freezed == placeholder ? _self.placeholder : placeholder // ignore: cast_nullable_to_non_nullable
as TypedExpression?,customValue: freezed == customValue ? _self.customValue : customValue // ignore: cast_nullable_to_non_nullable
as TypedExpression?,
  ));
}

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BoundControlCopyWith<$Res> get control {
  
  return $BoundControlCopyWith<$Res>(_self.control, (value) {
    return _then(_self.copyWith(control: value));
  });
}/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BindingIdCopyWith<$Res> get queryBindingId {
  
  return $BindingIdCopyWith<$Res>(_self.queryBindingId, (value) {
    return _then(_self.copyWith(queryBindingId: value));
  });
}/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BindingIdCopyWith<$Res> get summaryBindingId {
  
  return $BindingIdCopyWith<$Res>(_self.summaryBindingId, (value) {
    return _then(_self.copyWith(summaryBindingId: value));
  });
}/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get maximumExtent {
  
  return $TypedExpressionCopyWith<$Res>(_self.maximumExtent, (value) {
    return _then(_self.copyWith(maximumExtent: value));
  });
}/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchProviderCopyWith<$Res> get provider {
  
  return $SearchProviderCopyWith<$Res>(_self.provider, (value) {
    return _then(_self.copyWith(provider: value));
  });
}/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PresentationNodeCopyWith<$Res>? get summary {
    if (_self.summary == null) {
    return null;
  }

  return $PresentationNodeCopyWith<$Res>(_self.summary!, (value) {
    return _then(_self.copyWith(summary: value));
  });
}/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res>? get placeholder {
    if (_self.placeholder == null) {
    return null;
  }

  return $TypedExpressionCopyWith<$Res>(_self.placeholder!, (value) {
    return _then(_self.copyWith(placeholder: value));
  });
}/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res>? get customValue {
    if (_self.customValue == null) {
    return null;
  }

  return $TypedExpressionCopyWith<$Res>(_self.customValue!, (value) {
    return _then(_self.copyWith(customValue: value));
  });
}
}

/// @nodoc


class BytesInputElement implements PresentationElement, SimpleInputElement {
  const BytesInputElement(this.control);
  

 final  BoundControl control;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BytesInputElementCopyWith<BytesInputElement> get copyWith => _$BytesInputElementCopyWithImpl<BytesInputElement>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BytesInputElement&&(identical(other.control, control) || other.control == control));
}


@override
int get hashCode => Object.hash(runtimeType,control);

@override
String toString() {
  return 'PresentationElement.bytesInput(control: $control)';
}


}

/// @nodoc
abstract mixin class $BytesInputElementCopyWith<$Res> implements $PresentationElementCopyWith<$Res> {
  factory $BytesInputElementCopyWith(BytesInputElement value, $Res Function(BytesInputElement) _then) = _$BytesInputElementCopyWithImpl;
@useResult
$Res call({
 BoundControl control
});


$BoundControlCopyWith<$Res> get control;

}
/// @nodoc
class _$BytesInputElementCopyWithImpl<$Res>
    implements $BytesInputElementCopyWith<$Res> {
  _$BytesInputElementCopyWithImpl(this._self, this._then);

  final BytesInputElement _self;
  final $Res Function(BytesInputElement) _then;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? control = null,}) {
  return _then(BytesInputElement(
null == control ? _self.control : control // ignore: cast_nullable_to_non_nullable
as BoundControl,
  ));
}

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BoundControlCopyWith<$Res> get control {
  
  return $BoundControlCopyWith<$Res>(_self.control, (value) {
    return _then(_self.copyWith(control: value));
  });
}
}

/// @nodoc


class EnumInputElement implements PresentationElement, SimpleInputElement {
  const EnumInputElement(this.control);
  

 final  BoundControl control;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EnumInputElementCopyWith<EnumInputElement> get copyWith => _$EnumInputElementCopyWithImpl<EnumInputElement>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EnumInputElement&&(identical(other.control, control) || other.control == control));
}


@override
int get hashCode => Object.hash(runtimeType,control);

@override
String toString() {
  return 'PresentationElement.enumInput(control: $control)';
}


}

/// @nodoc
abstract mixin class $EnumInputElementCopyWith<$Res> implements $PresentationElementCopyWith<$Res> {
  factory $EnumInputElementCopyWith(EnumInputElement value, $Res Function(EnumInputElement) _then) = _$EnumInputElementCopyWithImpl;
@useResult
$Res call({
 BoundControl control
});


$BoundControlCopyWith<$Res> get control;

}
/// @nodoc
class _$EnumInputElementCopyWithImpl<$Res>
    implements $EnumInputElementCopyWith<$Res> {
  _$EnumInputElementCopyWithImpl(this._self, this._then);

  final EnumInputElement _self;
  final $Res Function(EnumInputElement) _then;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? control = null,}) {
  return _then(EnumInputElement(
null == control ? _self.control : control // ignore: cast_nullable_to_non_nullable
as BoundControl,
  ));
}

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BoundControlCopyWith<$Res> get control {
  
  return $BoundControlCopyWith<$Res>(_self.control, (value) {
    return _then(_self.copyWith(control: value));
  });
}
}

/// @nodoc


class NamedInputElement implements PresentationElement, SimpleInputElement {
  const NamedInputElement(this.control);
  

 final  BoundControl control;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NamedInputElementCopyWith<NamedInputElement> get copyWith => _$NamedInputElementCopyWithImpl<NamedInputElement>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NamedInputElement&&(identical(other.control, control) || other.control == control));
}


@override
int get hashCode => Object.hash(runtimeType,control);

@override
String toString() {
  return 'PresentationElement.namedInput(control: $control)';
}


}

/// @nodoc
abstract mixin class $NamedInputElementCopyWith<$Res> implements $PresentationElementCopyWith<$Res> {
  factory $NamedInputElementCopyWith(NamedInputElement value, $Res Function(NamedInputElement) _then) = _$NamedInputElementCopyWithImpl;
@useResult
$Res call({
 BoundControl control
});


$BoundControlCopyWith<$Res> get control;

}
/// @nodoc
class _$NamedInputElementCopyWithImpl<$Res>
    implements $NamedInputElementCopyWith<$Res> {
  _$NamedInputElementCopyWithImpl(this._self, this._then);

  final NamedInputElement _self;
  final $Res Function(NamedInputElement) _then;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? control = null,}) {
  return _then(NamedInputElement(
null == control ? _self.control : control // ignore: cast_nullable_to_non_nullable
as BoundControl,
  ));
}

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BoundControlCopyWith<$Res> get control {
  
  return $BoundControlCopyWith<$Res>(_self.control, (value) {
    return _then(_self.copyWith(control: value));
  });
}
}

/// @nodoc


class ListInputElement implements PresentationElement {
  const ListInputElement({required this.control, this.itemPresentation, this.allowAdd = true, this.allowRemove = true, this.allowReorder = true, this.itemBindingId = const BindingId(1), this.indexBindingId = const BindingId(2)});
  

 final  BoundControl control;
 final  PresentationNode? itemPresentation;
@JsonKey() final  bool allowAdd;
@JsonKey() final  bool allowRemove;
@JsonKey() final  bool allowReorder;
@JsonKey() final  BindingId itemBindingId;
@JsonKey() final  BindingId indexBindingId;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ListInputElementCopyWith<ListInputElement> get copyWith => _$ListInputElementCopyWithImpl<ListInputElement>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ListInputElement&&(identical(other.control, control) || other.control == control)&&(identical(other.itemPresentation, itemPresentation) || other.itemPresentation == itemPresentation)&&(identical(other.allowAdd, allowAdd) || other.allowAdd == allowAdd)&&(identical(other.allowRemove, allowRemove) || other.allowRemove == allowRemove)&&(identical(other.allowReorder, allowReorder) || other.allowReorder == allowReorder)&&(identical(other.itemBindingId, itemBindingId) || other.itemBindingId == itemBindingId)&&(identical(other.indexBindingId, indexBindingId) || other.indexBindingId == indexBindingId));
}


@override
int get hashCode => Object.hash(runtimeType,control,itemPresentation,allowAdd,allowRemove,allowReorder,itemBindingId,indexBindingId);

@override
String toString() {
  return 'PresentationElement.listInput(control: $control, itemPresentation: $itemPresentation, allowAdd: $allowAdd, allowRemove: $allowRemove, allowReorder: $allowReorder, itemBindingId: $itemBindingId, indexBindingId: $indexBindingId)';
}


}

/// @nodoc
abstract mixin class $ListInputElementCopyWith<$Res> implements $PresentationElementCopyWith<$Res> {
  factory $ListInputElementCopyWith(ListInputElement value, $Res Function(ListInputElement) _then) = _$ListInputElementCopyWithImpl;
@useResult
$Res call({
 BoundControl control, PresentationNode? itemPresentation, bool allowAdd, bool allowRemove, bool allowReorder, BindingId itemBindingId, BindingId indexBindingId
});


$BoundControlCopyWith<$Res> get control;$PresentationNodeCopyWith<$Res>? get itemPresentation;$BindingIdCopyWith<$Res> get itemBindingId;$BindingIdCopyWith<$Res> get indexBindingId;

}
/// @nodoc
class _$ListInputElementCopyWithImpl<$Res>
    implements $ListInputElementCopyWith<$Res> {
  _$ListInputElementCopyWithImpl(this._self, this._then);

  final ListInputElement _self;
  final $Res Function(ListInputElement) _then;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? control = null,Object? itemPresentation = freezed,Object? allowAdd = null,Object? allowRemove = null,Object? allowReorder = null,Object? itemBindingId = null,Object? indexBindingId = null,}) {
  return _then(ListInputElement(
control: null == control ? _self.control : control // ignore: cast_nullable_to_non_nullable
as BoundControl,itemPresentation: freezed == itemPresentation ? _self.itemPresentation : itemPresentation // ignore: cast_nullable_to_non_nullable
as PresentationNode?,allowAdd: null == allowAdd ? _self.allowAdd : allowAdd // ignore: cast_nullable_to_non_nullable
as bool,allowRemove: null == allowRemove ? _self.allowRemove : allowRemove // ignore: cast_nullable_to_non_nullable
as bool,allowReorder: null == allowReorder ? _self.allowReorder : allowReorder // ignore: cast_nullable_to_non_nullable
as bool,itemBindingId: null == itemBindingId ? _self.itemBindingId : itemBindingId // ignore: cast_nullable_to_non_nullable
as BindingId,indexBindingId: null == indexBindingId ? _self.indexBindingId : indexBindingId // ignore: cast_nullable_to_non_nullable
as BindingId,
  ));
}

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BoundControlCopyWith<$Res> get control {
  
  return $BoundControlCopyWith<$Res>(_self.control, (value) {
    return _then(_self.copyWith(control: value));
  });
}/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PresentationNodeCopyWith<$Res>? get itemPresentation {
    if (_self.itemPresentation == null) {
    return null;
  }

  return $PresentationNodeCopyWith<$Res>(_self.itemPresentation!, (value) {
    return _then(_self.copyWith(itemPresentation: value));
  });
}/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BindingIdCopyWith<$Res> get itemBindingId {
  
  return $BindingIdCopyWith<$Res>(_self.itemBindingId, (value) {
    return _then(_self.copyWith(itemBindingId: value));
  });
}/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BindingIdCopyWith<$Res> get indexBindingId {
  
  return $BindingIdCopyWith<$Res>(_self.indexBindingId, (value) {
    return _then(_self.copyWith(indexBindingId: value));
  });
}
}

/// @nodoc


class MapInputElement implements PresentationElement {
  const MapInputElement({required this.control, this.keyPresentation, this.valuePresentation, this.allowAdd = true, this.allowRemove = true, this.keyBindingId = const BindingId(1), this.valueBindingId = const BindingId(2)});
  

 final  BoundControl control;
 final  PresentationNode? keyPresentation;
 final  PresentationNode? valuePresentation;
@JsonKey() final  bool allowAdd;
@JsonKey() final  bool allowRemove;
@JsonKey() final  BindingId keyBindingId;
@JsonKey() final  BindingId valueBindingId;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MapInputElementCopyWith<MapInputElement> get copyWith => _$MapInputElementCopyWithImpl<MapInputElement>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MapInputElement&&(identical(other.control, control) || other.control == control)&&(identical(other.keyPresentation, keyPresentation) || other.keyPresentation == keyPresentation)&&(identical(other.valuePresentation, valuePresentation) || other.valuePresentation == valuePresentation)&&(identical(other.allowAdd, allowAdd) || other.allowAdd == allowAdd)&&(identical(other.allowRemove, allowRemove) || other.allowRemove == allowRemove)&&(identical(other.keyBindingId, keyBindingId) || other.keyBindingId == keyBindingId)&&(identical(other.valueBindingId, valueBindingId) || other.valueBindingId == valueBindingId));
}


@override
int get hashCode => Object.hash(runtimeType,control,keyPresentation,valuePresentation,allowAdd,allowRemove,keyBindingId,valueBindingId);

@override
String toString() {
  return 'PresentationElement.mapInput(control: $control, keyPresentation: $keyPresentation, valuePresentation: $valuePresentation, allowAdd: $allowAdd, allowRemove: $allowRemove, keyBindingId: $keyBindingId, valueBindingId: $valueBindingId)';
}


}

/// @nodoc
abstract mixin class $MapInputElementCopyWith<$Res> implements $PresentationElementCopyWith<$Res> {
  factory $MapInputElementCopyWith(MapInputElement value, $Res Function(MapInputElement) _then) = _$MapInputElementCopyWithImpl;
@useResult
$Res call({
 BoundControl control, PresentationNode? keyPresentation, PresentationNode? valuePresentation, bool allowAdd, bool allowRemove, BindingId keyBindingId, BindingId valueBindingId
});


$BoundControlCopyWith<$Res> get control;$PresentationNodeCopyWith<$Res>? get keyPresentation;$PresentationNodeCopyWith<$Res>? get valuePresentation;$BindingIdCopyWith<$Res> get keyBindingId;$BindingIdCopyWith<$Res> get valueBindingId;

}
/// @nodoc
class _$MapInputElementCopyWithImpl<$Res>
    implements $MapInputElementCopyWith<$Res> {
  _$MapInputElementCopyWithImpl(this._self, this._then);

  final MapInputElement _self;
  final $Res Function(MapInputElement) _then;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? control = null,Object? keyPresentation = freezed,Object? valuePresentation = freezed,Object? allowAdd = null,Object? allowRemove = null,Object? keyBindingId = null,Object? valueBindingId = null,}) {
  return _then(MapInputElement(
control: null == control ? _self.control : control // ignore: cast_nullable_to_non_nullable
as BoundControl,keyPresentation: freezed == keyPresentation ? _self.keyPresentation : keyPresentation // ignore: cast_nullable_to_non_nullable
as PresentationNode?,valuePresentation: freezed == valuePresentation ? _self.valuePresentation : valuePresentation // ignore: cast_nullable_to_non_nullable
as PresentationNode?,allowAdd: null == allowAdd ? _self.allowAdd : allowAdd // ignore: cast_nullable_to_non_nullable
as bool,allowRemove: null == allowRemove ? _self.allowRemove : allowRemove // ignore: cast_nullable_to_non_nullable
as bool,keyBindingId: null == keyBindingId ? _self.keyBindingId : keyBindingId // ignore: cast_nullable_to_non_nullable
as BindingId,valueBindingId: null == valueBindingId ? _self.valueBindingId : valueBindingId // ignore: cast_nullable_to_non_nullable
as BindingId,
  ));
}

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BoundControlCopyWith<$Res> get control {
  
  return $BoundControlCopyWith<$Res>(_self.control, (value) {
    return _then(_self.copyWith(control: value));
  });
}/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PresentationNodeCopyWith<$Res>? get keyPresentation {
    if (_self.keyPresentation == null) {
    return null;
  }

  return $PresentationNodeCopyWith<$Res>(_self.keyPresentation!, (value) {
    return _then(_self.copyWith(keyPresentation: value));
  });
}/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PresentationNodeCopyWith<$Res>? get valuePresentation {
    if (_self.valuePresentation == null) {
    return null;
  }

  return $PresentationNodeCopyWith<$Res>(_self.valuePresentation!, (value) {
    return _then(_self.copyWith(valuePresentation: value));
  });
}/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BindingIdCopyWith<$Res> get keyBindingId {
  
  return $BindingIdCopyWith<$Res>(_self.keyBindingId, (value) {
    return _then(_self.copyWith(keyBindingId: value));
  });
}/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BindingIdCopyWith<$Res> get valueBindingId {
  
  return $BindingIdCopyWith<$Res>(_self.valueBindingId, (value) {
    return _then(_self.copyWith(valueBindingId: value));
  });
}
}

/// @nodoc


class RecordInputElement implements PresentationElement {
  const RecordInputElement({required this.control, this.fieldPresentation});
  

 final  BoundControl control;
 final  PresentationNode? fieldPresentation;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecordInputElementCopyWith<RecordInputElement> get copyWith => _$RecordInputElementCopyWithImpl<RecordInputElement>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecordInputElement&&(identical(other.control, control) || other.control == control)&&(identical(other.fieldPresentation, fieldPresentation) || other.fieldPresentation == fieldPresentation));
}


@override
int get hashCode => Object.hash(runtimeType,control,fieldPresentation);

@override
String toString() {
  return 'PresentationElement.recordInput(control: $control, fieldPresentation: $fieldPresentation)';
}


}

/// @nodoc
abstract mixin class $RecordInputElementCopyWith<$Res> implements $PresentationElementCopyWith<$Res> {
  factory $RecordInputElementCopyWith(RecordInputElement value, $Res Function(RecordInputElement) _then) = _$RecordInputElementCopyWithImpl;
@useResult
$Res call({
 BoundControl control, PresentationNode? fieldPresentation
});


$BoundControlCopyWith<$Res> get control;$PresentationNodeCopyWith<$Res>? get fieldPresentation;

}
/// @nodoc
class _$RecordInputElementCopyWithImpl<$Res>
    implements $RecordInputElementCopyWith<$Res> {
  _$RecordInputElementCopyWithImpl(this._self, this._then);

  final RecordInputElement _self;
  final $Res Function(RecordInputElement) _then;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? control = null,Object? fieldPresentation = freezed,}) {
  return _then(RecordInputElement(
control: null == control ? _self.control : control // ignore: cast_nullable_to_non_nullable
as BoundControl,fieldPresentation: freezed == fieldPresentation ? _self.fieldPresentation : fieldPresentation // ignore: cast_nullable_to_non_nullable
as PresentationNode?,
  ));
}

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BoundControlCopyWith<$Res> get control {
  
  return $BoundControlCopyWith<$Res>(_self.control, (value) {
    return _then(_self.copyWith(control: value));
  });
}/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PresentationNodeCopyWith<$Res>? get fieldPresentation {
    if (_self.fieldPresentation == null) {
    return null;
  }

  return $PresentationNodeCopyWith<$Res>(_self.fieldPresentation!, (value) {
    return _then(_self.copyWith(fieldPresentation: value));
  });
}
}

/// @nodoc


class PolymorphicInputElement implements PresentationElement {
   PolymorphicInputElement({required this.control, required final  List<ConcreteTypePresentation> concreteTypes}): assert(concreteTypes.isNotEmpty, 'Concrete types must not be empty.'),_concreteTypes = concreteTypes;
  

 final  BoundControl control;
 final  List<ConcreteTypePresentation> _concreteTypes;
 List<ConcreteTypePresentation> get concreteTypes {
  if (_concreteTypes is EqualUnmodifiableListView) return _concreteTypes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_concreteTypes);
}


/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PolymorphicInputElementCopyWith<PolymorphicInputElement> get copyWith => _$PolymorphicInputElementCopyWithImpl<PolymorphicInputElement>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PolymorphicInputElement&&(identical(other.control, control) || other.control == control)&&const DeepCollectionEquality().equals(other._concreteTypes, _concreteTypes));
}


@override
int get hashCode => Object.hash(runtimeType,control,const DeepCollectionEquality().hash(_concreteTypes));

@override
String toString() {
  return 'PresentationElement.polymorphicInput(control: $control, concreteTypes: $concreteTypes)';
}


}

/// @nodoc
abstract mixin class $PolymorphicInputElementCopyWith<$Res> implements $PresentationElementCopyWith<$Res> {
  factory $PolymorphicInputElementCopyWith(PolymorphicInputElement value, $Res Function(PolymorphicInputElement) _then) = _$PolymorphicInputElementCopyWithImpl;
@useResult
$Res call({
 BoundControl control, List<ConcreteTypePresentation> concreteTypes
});


$BoundControlCopyWith<$Res> get control;

}
/// @nodoc
class _$PolymorphicInputElementCopyWithImpl<$Res>
    implements $PolymorphicInputElementCopyWith<$Res> {
  _$PolymorphicInputElementCopyWithImpl(this._self, this._then);

  final PolymorphicInputElement _self;
  final $Res Function(PolymorphicInputElement) _then;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? control = null,Object? concreteTypes = null,}) {
  return _then(PolymorphicInputElement(
control: null == control ? _self.control : control // ignore: cast_nullable_to_non_nullable
as BoundControl,concreteTypes: null == concreteTypes ? _self._concreteTypes : concreteTypes // ignore: cast_nullable_to_non_nullable
as List<ConcreteTypePresentation>,
  ));
}

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BoundControlCopyWith<$Res> get control {
  
  return $BoundControlCopyWith<$Res>(_self.control, (value) {
    return _then(_self.copyWith(control: value));
  });
}
}

/// @nodoc


class ButtonElement implements PresentationElement {
  const ButtonElement({required this.label, required this.action});
  

 final  TypedExpression label;
 final  EditorAction action;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ButtonElementCopyWith<ButtonElement> get copyWith => _$ButtonElementCopyWithImpl<ButtonElement>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ButtonElement&&(identical(other.label, label) || other.label == label)&&(identical(other.action, action) || other.action == action));
}


@override
int get hashCode => Object.hash(runtimeType,label,action);

@override
String toString() {
  return 'PresentationElement.button(label: $label, action: $action)';
}


}

/// @nodoc
abstract mixin class $ButtonElementCopyWith<$Res> implements $PresentationElementCopyWith<$Res> {
  factory $ButtonElementCopyWith(ButtonElement value, $Res Function(ButtonElement) _then) = _$ButtonElementCopyWithImpl;
@useResult
$Res call({
 TypedExpression label, EditorAction action
});


$TypedExpressionCopyWith<$Res> get label;$EditorActionCopyWith<$Res> get action;

}
/// @nodoc
class _$ButtonElementCopyWithImpl<$Res>
    implements $ButtonElementCopyWith<$Res> {
  _$ButtonElementCopyWithImpl(this._self, this._then);

  final ButtonElement _self;
  final $Res Function(ButtonElement) _then;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? label = null,Object? action = null,}) {
  return _then(ButtonElement(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as TypedExpression,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as EditorAction,
  ));
}

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get label {
  
  return $TypedExpressionCopyWith<$Res>(_self.label, (value) {
    return _then(_self.copyWith(label: value));
  });
}/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EditorActionCopyWith<$Res> get action {
  
  return $EditorActionCopyWith<$Res>(_self.action, (value) {
    return _then(_self.copyWith(action: value));
  });
}
}

/// @nodoc


class IconButtonElement implements PresentationElement {
  const IconButtonElement({required this.icon, required this.semanticLabel, required this.action});
  

 final  TypedExpression icon;
 final  TypedExpression semanticLabel;
 final  EditorAction action;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IconButtonElementCopyWith<IconButtonElement> get copyWith => _$IconButtonElementCopyWithImpl<IconButtonElement>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IconButtonElement&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.semanticLabel, semanticLabel) || other.semanticLabel == semanticLabel)&&(identical(other.action, action) || other.action == action));
}


@override
int get hashCode => Object.hash(runtimeType,icon,semanticLabel,action);

@override
String toString() {
  return 'PresentationElement.iconButton(icon: $icon, semanticLabel: $semanticLabel, action: $action)';
}


}

/// @nodoc
abstract mixin class $IconButtonElementCopyWith<$Res> implements $PresentationElementCopyWith<$Res> {
  factory $IconButtonElementCopyWith(IconButtonElement value, $Res Function(IconButtonElement) _then) = _$IconButtonElementCopyWithImpl;
@useResult
$Res call({
 TypedExpression icon, TypedExpression semanticLabel, EditorAction action
});


$TypedExpressionCopyWith<$Res> get icon;$TypedExpressionCopyWith<$Res> get semanticLabel;$EditorActionCopyWith<$Res> get action;

}
/// @nodoc
class _$IconButtonElementCopyWithImpl<$Res>
    implements $IconButtonElementCopyWith<$Res> {
  _$IconButtonElementCopyWithImpl(this._self, this._then);

  final IconButtonElement _self;
  final $Res Function(IconButtonElement) _then;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? icon = null,Object? semanticLabel = null,Object? action = null,}) {
  return _then(IconButtonElement(
icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as TypedExpression,semanticLabel: null == semanticLabel ? _self.semanticLabel : semanticLabel // ignore: cast_nullable_to_non_nullable
as TypedExpression,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as EditorAction,
  ));
}

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get icon {
  
  return $TypedExpressionCopyWith<$Res>(_self.icon, (value) {
    return _then(_self.copyWith(icon: value));
  });
}/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get semanticLabel {
  
  return $TypedExpressionCopyWith<$Res>(_self.semanticLabel, (value) {
    return _then(_self.copyWith(semanticLabel: value));
  });
}/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EditorActionCopyWith<$Res> get action {
  
  return $EditorActionCopyWith<$Res>(_self.action, (value) {
    return _then(_self.copyWith(action: value));
  });
}
}

/// @nodoc


class MenuElement implements PresentationElement {
   MenuElement({required final  List<PresentationMenuItem> items, this.label}): assert(items.isNotEmpty, 'Menu items must not be empty.'),_items = items;
  

 final  List<PresentationMenuItem> _items;
 List<PresentationMenuItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

 final  TypedExpression? label;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MenuElementCopyWith<MenuElement> get copyWith => _$MenuElementCopyWithImpl<MenuElement>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MenuElement&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.label, label) || other.label == label));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),label);

@override
String toString() {
  return 'PresentationElement.menu(items: $items, label: $label)';
}


}

/// @nodoc
abstract mixin class $MenuElementCopyWith<$Res> implements $PresentationElementCopyWith<$Res> {
  factory $MenuElementCopyWith(MenuElement value, $Res Function(MenuElement) _then) = _$MenuElementCopyWithImpl;
@useResult
$Res call({
 List<PresentationMenuItem> items, TypedExpression? label
});


$TypedExpressionCopyWith<$Res>? get label;

}
/// @nodoc
class _$MenuElementCopyWithImpl<$Res>
    implements $MenuElementCopyWith<$Res> {
  _$MenuElementCopyWithImpl(this._self, this._then);

  final MenuElement _self;
  final $Res Function(MenuElement) _then;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? items = null,Object? label = freezed,}) {
  return _then(MenuElement(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<PresentationMenuItem>,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as TypedExpression?,
  ));
}

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res>? get label {
    if (_self.label == null) {
    return null;
  }

  return $TypedExpressionCopyWith<$Res>(_self.label!, (value) {
    return _then(_self.copyWith(label: value));
  });
}
}

/// @nodoc


class TooltipElement implements PresentationElement {
  const TooltipElement({required this.message, required this.child});
  

 final  TypedExpression message;
 final  PresentationNode child;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TooltipElementCopyWith<TooltipElement> get copyWith => _$TooltipElementCopyWithImpl<TooltipElement>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TooltipElement&&(identical(other.message, message) || other.message == message)&&(identical(other.child, child) || other.child == child));
}


@override
int get hashCode => Object.hash(runtimeType,message,child);

@override
String toString() {
  return 'PresentationElement.tooltip(message: $message, child: $child)';
}


}

/// @nodoc
abstract mixin class $TooltipElementCopyWith<$Res> implements $PresentationElementCopyWith<$Res> {
  factory $TooltipElementCopyWith(TooltipElement value, $Res Function(TooltipElement) _then) = _$TooltipElementCopyWithImpl;
@useResult
$Res call({
 TypedExpression message, PresentationNode child
});


$TypedExpressionCopyWith<$Res> get message;$PresentationNodeCopyWith<$Res> get child;

}
/// @nodoc
class _$TooltipElementCopyWithImpl<$Res>
    implements $TooltipElementCopyWith<$Res> {
  _$TooltipElementCopyWithImpl(this._self, this._then);

  final TooltipElement _self;
  final $Res Function(TooltipElement) _then;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,Object? child = null,}) {
  return _then(TooltipElement(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as TypedExpression,child: null == child ? _self.child : child // ignore: cast_nullable_to_non_nullable
as PresentationNode,
  ));
}

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get message {
  
  return $TypedExpressionCopyWith<$Res>(_self.message, (value) {
    return _then(_self.copyWith(message: value));
  });
}/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PresentationNodeCopyWith<$Res> get child {
  
  return $PresentationNodeCopyWith<$Res>(_self.child, (value) {
    return _then(_self.copyWith(child: value));
  });
}
}

/// @nodoc


class ColumnElement implements PresentationElement, ChildrenLayoutElement {
  const ColumnElement({required final  List<PresentationNode> children, this.spacing = 0, this.mainAxisAlignment = PresentationMainAxisAlignment.start, this.crossAxisAlignment = PresentationCrossAxisAlignment.center}): assert(spacing >= 0, 'Spacing must not be negative.'),_children = children;
  

 final  List<PresentationNode> _children;
 List<PresentationNode> get children {
  if (_children is EqualUnmodifiableListView) return _children;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_children);
}

@JsonKey() final  double spacing;
@JsonKey() final  PresentationMainAxisAlignment mainAxisAlignment;
@JsonKey() final  PresentationCrossAxisAlignment crossAxisAlignment;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ColumnElementCopyWith<ColumnElement> get copyWith => _$ColumnElementCopyWithImpl<ColumnElement>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ColumnElement&&const DeepCollectionEquality().equals(other._children, _children)&&(identical(other.spacing, spacing) || other.spacing == spacing)&&(identical(other.mainAxisAlignment, mainAxisAlignment) || other.mainAxisAlignment == mainAxisAlignment)&&(identical(other.crossAxisAlignment, crossAxisAlignment) || other.crossAxisAlignment == crossAxisAlignment));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_children),spacing,mainAxisAlignment,crossAxisAlignment);

@override
String toString() {
  return 'PresentationElement.column(children: $children, spacing: $spacing, mainAxisAlignment: $mainAxisAlignment, crossAxisAlignment: $crossAxisAlignment)';
}


}

/// @nodoc
abstract mixin class $ColumnElementCopyWith<$Res> implements $PresentationElementCopyWith<$Res> {
  factory $ColumnElementCopyWith(ColumnElement value, $Res Function(ColumnElement) _then) = _$ColumnElementCopyWithImpl;
@useResult
$Res call({
 List<PresentationNode> children, double spacing, PresentationMainAxisAlignment mainAxisAlignment, PresentationCrossAxisAlignment crossAxisAlignment
});




}
/// @nodoc
class _$ColumnElementCopyWithImpl<$Res>
    implements $ColumnElementCopyWith<$Res> {
  _$ColumnElementCopyWithImpl(this._self, this._then);

  final ColumnElement _self;
  final $Res Function(ColumnElement) _then;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? children = null,Object? spacing = null,Object? mainAxisAlignment = null,Object? crossAxisAlignment = null,}) {
  return _then(ColumnElement(
children: null == children ? _self._children : children // ignore: cast_nullable_to_non_nullable
as List<PresentationNode>,spacing: null == spacing ? _self.spacing : spacing // ignore: cast_nullable_to_non_nullable
as double,mainAxisAlignment: null == mainAxisAlignment ? _self.mainAxisAlignment : mainAxisAlignment // ignore: cast_nullable_to_non_nullable
as PresentationMainAxisAlignment,crossAxisAlignment: null == crossAxisAlignment ? _self.crossAxisAlignment : crossAxisAlignment // ignore: cast_nullable_to_non_nullable
as PresentationCrossAxisAlignment,
  ));
}


}

/// @nodoc


class RowElement implements PresentationElement, ChildrenLayoutElement {
  const RowElement({required final  List<PresentationNode> children, this.spacing = 0, this.mainAxisAlignment = PresentationMainAxisAlignment.start, this.crossAxisAlignment = PresentationCrossAxisAlignment.center}): assert(spacing >= 0, 'Spacing must not be negative.'),_children = children;
  

 final  List<PresentationNode> _children;
 List<PresentationNode> get children {
  if (_children is EqualUnmodifiableListView) return _children;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_children);
}

@JsonKey() final  double spacing;
@JsonKey() final  PresentationMainAxisAlignment mainAxisAlignment;
@JsonKey() final  PresentationCrossAxisAlignment crossAxisAlignment;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RowElementCopyWith<RowElement> get copyWith => _$RowElementCopyWithImpl<RowElement>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RowElement&&const DeepCollectionEquality().equals(other._children, _children)&&(identical(other.spacing, spacing) || other.spacing == spacing)&&(identical(other.mainAxisAlignment, mainAxisAlignment) || other.mainAxisAlignment == mainAxisAlignment)&&(identical(other.crossAxisAlignment, crossAxisAlignment) || other.crossAxisAlignment == crossAxisAlignment));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_children),spacing,mainAxisAlignment,crossAxisAlignment);

@override
String toString() {
  return 'PresentationElement.row(children: $children, spacing: $spacing, mainAxisAlignment: $mainAxisAlignment, crossAxisAlignment: $crossAxisAlignment)';
}


}

/// @nodoc
abstract mixin class $RowElementCopyWith<$Res> implements $PresentationElementCopyWith<$Res> {
  factory $RowElementCopyWith(RowElement value, $Res Function(RowElement) _then) = _$RowElementCopyWithImpl;
@useResult
$Res call({
 List<PresentationNode> children, double spacing, PresentationMainAxisAlignment mainAxisAlignment, PresentationCrossAxisAlignment crossAxisAlignment
});




}
/// @nodoc
class _$RowElementCopyWithImpl<$Res>
    implements $RowElementCopyWith<$Res> {
  _$RowElementCopyWithImpl(this._self, this._then);

  final RowElement _self;
  final $Res Function(RowElement) _then;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? children = null,Object? spacing = null,Object? mainAxisAlignment = null,Object? crossAxisAlignment = null,}) {
  return _then(RowElement(
children: null == children ? _self._children : children // ignore: cast_nullable_to_non_nullable
as List<PresentationNode>,spacing: null == spacing ? _self.spacing : spacing // ignore: cast_nullable_to_non_nullable
as double,mainAxisAlignment: null == mainAxisAlignment ? _self.mainAxisAlignment : mainAxisAlignment // ignore: cast_nullable_to_non_nullable
as PresentationMainAxisAlignment,crossAxisAlignment: null == crossAxisAlignment ? _self.crossAxisAlignment : crossAxisAlignment // ignore: cast_nullable_to_non_nullable
as PresentationCrossAxisAlignment,
  ));
}


}

/// @nodoc


class WrapElement implements PresentationElement, ChildrenLayoutElement {
  const WrapElement({required final  List<PresentationNode> children, this.spacing = 0, this.mainAxisAlignment = PresentationMainAxisAlignment.start, this.crossAxisAlignment = PresentationCrossAxisAlignment.start}): assert(spacing >= 0, 'Spacing must not be negative.'),_children = children;
  

 final  List<PresentationNode> _children;
 List<PresentationNode> get children {
  if (_children is EqualUnmodifiableListView) return _children;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_children);
}

@JsonKey() final  double spacing;
@JsonKey() final  PresentationMainAxisAlignment mainAxisAlignment;
@JsonKey() final  PresentationCrossAxisAlignment crossAxisAlignment;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WrapElementCopyWith<WrapElement> get copyWith => _$WrapElementCopyWithImpl<WrapElement>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WrapElement&&const DeepCollectionEquality().equals(other._children, _children)&&(identical(other.spacing, spacing) || other.spacing == spacing)&&(identical(other.mainAxisAlignment, mainAxisAlignment) || other.mainAxisAlignment == mainAxisAlignment)&&(identical(other.crossAxisAlignment, crossAxisAlignment) || other.crossAxisAlignment == crossAxisAlignment));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_children),spacing,mainAxisAlignment,crossAxisAlignment);

@override
String toString() {
  return 'PresentationElement.wrap(children: $children, spacing: $spacing, mainAxisAlignment: $mainAxisAlignment, crossAxisAlignment: $crossAxisAlignment)';
}


}

/// @nodoc
abstract mixin class $WrapElementCopyWith<$Res> implements $PresentationElementCopyWith<$Res> {
  factory $WrapElementCopyWith(WrapElement value, $Res Function(WrapElement) _then) = _$WrapElementCopyWithImpl;
@useResult
$Res call({
 List<PresentationNode> children, double spacing, PresentationMainAxisAlignment mainAxisAlignment, PresentationCrossAxisAlignment crossAxisAlignment
});




}
/// @nodoc
class _$WrapElementCopyWithImpl<$Res>
    implements $WrapElementCopyWith<$Res> {
  _$WrapElementCopyWithImpl(this._self, this._then);

  final WrapElement _self;
  final $Res Function(WrapElement) _then;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? children = null,Object? spacing = null,Object? mainAxisAlignment = null,Object? crossAxisAlignment = null,}) {
  return _then(WrapElement(
children: null == children ? _self._children : children // ignore: cast_nullable_to_non_nullable
as List<PresentationNode>,spacing: null == spacing ? _self.spacing : spacing // ignore: cast_nullable_to_non_nullable
as double,mainAxisAlignment: null == mainAxisAlignment ? _self.mainAxisAlignment : mainAxisAlignment // ignore: cast_nullable_to_non_nullable
as PresentationMainAxisAlignment,crossAxisAlignment: null == crossAxisAlignment ? _self.crossAxisAlignment : crossAxisAlignment // ignore: cast_nullable_to_non_nullable
as PresentationCrossAxisAlignment,
  ));
}


}

/// @nodoc


class StackElement implements PresentationElement, ChildrenLayoutElement {
  const StackElement({required final  List<PresentationNode> children, this.spacing = 0, this.mainAxisAlignment = PresentationMainAxisAlignment.start, this.crossAxisAlignment = PresentationCrossAxisAlignment.center}): assert(spacing >= 0, 'Spacing must not be negative.'),_children = children;
  

 final  List<PresentationNode> _children;
 List<PresentationNode> get children {
  if (_children is EqualUnmodifiableListView) return _children;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_children);
}

@JsonKey() final  double spacing;
@JsonKey() final  PresentationMainAxisAlignment mainAxisAlignment;
@JsonKey() final  PresentationCrossAxisAlignment crossAxisAlignment;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StackElementCopyWith<StackElement> get copyWith => _$StackElementCopyWithImpl<StackElement>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StackElement&&const DeepCollectionEquality().equals(other._children, _children)&&(identical(other.spacing, spacing) || other.spacing == spacing)&&(identical(other.mainAxisAlignment, mainAxisAlignment) || other.mainAxisAlignment == mainAxisAlignment)&&(identical(other.crossAxisAlignment, crossAxisAlignment) || other.crossAxisAlignment == crossAxisAlignment));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_children),spacing,mainAxisAlignment,crossAxisAlignment);

@override
String toString() {
  return 'PresentationElement.stack(children: $children, spacing: $spacing, mainAxisAlignment: $mainAxisAlignment, crossAxisAlignment: $crossAxisAlignment)';
}


}

/// @nodoc
abstract mixin class $StackElementCopyWith<$Res> implements $PresentationElementCopyWith<$Res> {
  factory $StackElementCopyWith(StackElement value, $Res Function(StackElement) _then) = _$StackElementCopyWithImpl;
@useResult
$Res call({
 List<PresentationNode> children, double spacing, PresentationMainAxisAlignment mainAxisAlignment, PresentationCrossAxisAlignment crossAxisAlignment
});




}
/// @nodoc
class _$StackElementCopyWithImpl<$Res>
    implements $StackElementCopyWith<$Res> {
  _$StackElementCopyWithImpl(this._self, this._then);

  final StackElement _self;
  final $Res Function(StackElement) _then;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? children = null,Object? spacing = null,Object? mainAxisAlignment = null,Object? crossAxisAlignment = null,}) {
  return _then(StackElement(
children: null == children ? _self._children : children // ignore: cast_nullable_to_non_nullable
as List<PresentationNode>,spacing: null == spacing ? _self.spacing : spacing // ignore: cast_nullable_to_non_nullable
as double,mainAxisAlignment: null == mainAxisAlignment ? _self.mainAxisAlignment : mainAxisAlignment // ignore: cast_nullable_to_non_nullable
as PresentationMainAxisAlignment,crossAxisAlignment: null == crossAxisAlignment ? _self.crossAxisAlignment : crossAxisAlignment // ignore: cast_nullable_to_non_nullable
as PresentationCrossAxisAlignment,
  ));
}


}

/// @nodoc


class GridElement implements PresentationElement {
  const GridElement({required final  List<PresentationNode> children, required this.columns, this.horizontalSpacing = 0, this.verticalSpacing = 0}): assert(columns > 0, 'Column count must be positive.'),assert(horizontalSpacing >= 0, 'Horizontal spacing must not be negative.'),assert(verticalSpacing >= 0, 'Vertical spacing must not be negative.'),_children = children;
  

 final  List<PresentationNode> _children;
 List<PresentationNode> get children {
  if (_children is EqualUnmodifiableListView) return _children;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_children);
}

 final  int columns;
@JsonKey() final  double horizontalSpacing;
@JsonKey() final  double verticalSpacing;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GridElementCopyWith<GridElement> get copyWith => _$GridElementCopyWithImpl<GridElement>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GridElement&&const DeepCollectionEquality().equals(other._children, _children)&&(identical(other.columns, columns) || other.columns == columns)&&(identical(other.horizontalSpacing, horizontalSpacing) || other.horizontalSpacing == horizontalSpacing)&&(identical(other.verticalSpacing, verticalSpacing) || other.verticalSpacing == verticalSpacing));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_children),columns,horizontalSpacing,verticalSpacing);

@override
String toString() {
  return 'PresentationElement.grid(children: $children, columns: $columns, horizontalSpacing: $horizontalSpacing, verticalSpacing: $verticalSpacing)';
}


}

/// @nodoc
abstract mixin class $GridElementCopyWith<$Res> implements $PresentationElementCopyWith<$Res> {
  factory $GridElementCopyWith(GridElement value, $Res Function(GridElement) _then) = _$GridElementCopyWithImpl;
@useResult
$Res call({
 List<PresentationNode> children, int columns, double horizontalSpacing, double verticalSpacing
});




}
/// @nodoc
class _$GridElementCopyWithImpl<$Res>
    implements $GridElementCopyWith<$Res> {
  _$GridElementCopyWithImpl(this._self, this._then);

  final GridElement _self;
  final $Res Function(GridElement) _then;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? children = null,Object? columns = null,Object? horizontalSpacing = null,Object? verticalSpacing = null,}) {
  return _then(GridElement(
children: null == children ? _self._children : children // ignore: cast_nullable_to_non_nullable
as List<PresentationNode>,columns: null == columns ? _self.columns : columns // ignore: cast_nullable_to_non_nullable
as int,horizontalSpacing: null == horizontalSpacing ? _self.horizontalSpacing : horizontalSpacing // ignore: cast_nullable_to_non_nullable
as double,verticalSpacing: null == verticalSpacing ? _self.verticalSpacing : verticalSpacing // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc


class CardElement implements PresentationElement, SingleChildLayoutElement {
  const CardElement(this.child, {this.initiallyExpanded});
  

 final  PresentationNode child;
 final  bool? initiallyExpanded;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CardElementCopyWith<CardElement> get copyWith => _$CardElementCopyWithImpl<CardElement>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CardElement&&(identical(other.child, child) || other.child == child)&&(identical(other.initiallyExpanded, initiallyExpanded) || other.initiallyExpanded == initiallyExpanded));
}


@override
int get hashCode => Object.hash(runtimeType,child,initiallyExpanded);

@override
String toString() {
  return 'PresentationElement.card(child: $child, initiallyExpanded: $initiallyExpanded)';
}


}

/// @nodoc
abstract mixin class $CardElementCopyWith<$Res> implements $PresentationElementCopyWith<$Res> {
  factory $CardElementCopyWith(CardElement value, $Res Function(CardElement) _then) = _$CardElementCopyWithImpl;
@useResult
$Res call({
 PresentationNode child, bool? initiallyExpanded
});


$PresentationNodeCopyWith<$Res> get child;

}
/// @nodoc
class _$CardElementCopyWithImpl<$Res>
    implements $CardElementCopyWith<$Res> {
  _$CardElementCopyWithImpl(this._self, this._then);

  final CardElement _self;
  final $Res Function(CardElement) _then;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? child = null,Object? initiallyExpanded = freezed,}) {
  return _then(CardElement(
null == child ? _self.child : child // ignore: cast_nullable_to_non_nullable
as PresentationNode,initiallyExpanded: freezed == initiallyExpanded ? _self.initiallyExpanded : initiallyExpanded // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PresentationNodeCopyWith<$Res> get child {
  
  return $PresentationNodeCopyWith<$Res>(_self.child, (value) {
    return _then(_self.copyWith(child: value));
  });
}
}

/// @nodoc


class SectionElement implements PresentationElement, SingleChildLayoutElement {
  const SectionElement({required this.title, required this.child, this.description, this.initiallyExpanded});
  

 final  TypedExpression title;
 final  PresentationNode child;
 final  TypedExpression? description;
 final  bool? initiallyExpanded;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SectionElementCopyWith<SectionElement> get copyWith => _$SectionElementCopyWithImpl<SectionElement>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SectionElement&&(identical(other.title, title) || other.title == title)&&(identical(other.child, child) || other.child == child)&&(identical(other.description, description) || other.description == description)&&(identical(other.initiallyExpanded, initiallyExpanded) || other.initiallyExpanded == initiallyExpanded));
}


@override
int get hashCode => Object.hash(runtimeType,title,child,description,initiallyExpanded);

@override
String toString() {
  return 'PresentationElement.section(title: $title, child: $child, description: $description, initiallyExpanded: $initiallyExpanded)';
}


}

/// @nodoc
abstract mixin class $SectionElementCopyWith<$Res> implements $PresentationElementCopyWith<$Res> {
  factory $SectionElementCopyWith(SectionElement value, $Res Function(SectionElement) _then) = _$SectionElementCopyWithImpl;
@useResult
$Res call({
 TypedExpression title, PresentationNode child, TypedExpression? description, bool? initiallyExpanded
});


$TypedExpressionCopyWith<$Res> get title;$PresentationNodeCopyWith<$Res> get child;$TypedExpressionCopyWith<$Res>? get description;

}
/// @nodoc
class _$SectionElementCopyWithImpl<$Res>
    implements $SectionElementCopyWith<$Res> {
  _$SectionElementCopyWithImpl(this._self, this._then);

  final SectionElement _self;
  final $Res Function(SectionElement) _then;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? title = null,Object? child = null,Object? description = freezed,Object? initiallyExpanded = freezed,}) {
  return _then(SectionElement(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as TypedExpression,child: null == child ? _self.child : child // ignore: cast_nullable_to_non_nullable
as PresentationNode,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as TypedExpression?,initiallyExpanded: freezed == initiallyExpanded ? _self.initiallyExpanded : initiallyExpanded // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get title {
  
  return $TypedExpressionCopyWith<$Res>(_self.title, (value) {
    return _then(_self.copyWith(title: value));
  });
}/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PresentationNodeCopyWith<$Res> get child {
  
  return $PresentationNodeCopyWith<$Res>(_self.child, (value) {
    return _then(_self.copyWith(child: value));
  });
}/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res>? get description {
    if (_self.description == null) {
    return null;
  }

  return $TypedExpressionCopyWith<$Res>(_self.description!, (value) {
    return _then(_self.copyWith(description: value));
  });
}
}

/// @nodoc


class CollapsibleElement implements PresentationElement, SingleChildLayoutElement {
  const CollapsibleElement({required this.title, required this.child, this.initiallyExpanded = false});
  

 final  TypedExpression title;
 final  PresentationNode child;
@JsonKey() final  bool initiallyExpanded;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CollapsibleElementCopyWith<CollapsibleElement> get copyWith => _$CollapsibleElementCopyWithImpl<CollapsibleElement>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CollapsibleElement&&(identical(other.title, title) || other.title == title)&&(identical(other.child, child) || other.child == child)&&(identical(other.initiallyExpanded, initiallyExpanded) || other.initiallyExpanded == initiallyExpanded));
}


@override
int get hashCode => Object.hash(runtimeType,title,child,initiallyExpanded);

@override
String toString() {
  return 'PresentationElement.collapsible(title: $title, child: $child, initiallyExpanded: $initiallyExpanded)';
}


}

/// @nodoc
abstract mixin class $CollapsibleElementCopyWith<$Res> implements $PresentationElementCopyWith<$Res> {
  factory $CollapsibleElementCopyWith(CollapsibleElement value, $Res Function(CollapsibleElement) _then) = _$CollapsibleElementCopyWithImpl;
@useResult
$Res call({
 TypedExpression title, PresentationNode child, bool initiallyExpanded
});


$TypedExpressionCopyWith<$Res> get title;$PresentationNodeCopyWith<$Res> get child;

}
/// @nodoc
class _$CollapsibleElementCopyWithImpl<$Res>
    implements $CollapsibleElementCopyWith<$Res> {
  _$CollapsibleElementCopyWithImpl(this._self, this._then);

  final CollapsibleElement _self;
  final $Res Function(CollapsibleElement) _then;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? title = null,Object? child = null,Object? initiallyExpanded = null,}) {
  return _then(CollapsibleElement(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as TypedExpression,child: null == child ? _self.child : child // ignore: cast_nullable_to_non_nullable
as PresentationNode,initiallyExpanded: null == initiallyExpanded ? _self.initiallyExpanded : initiallyExpanded // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get title {
  
  return $TypedExpressionCopyWith<$Res>(_self.title, (value) {
    return _then(_self.copyWith(title: value));
  });
}/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PresentationNodeCopyWith<$Res> get child {
  
  return $PresentationNodeCopyWith<$Res>(_self.child, (value) {
    return _then(_self.copyWith(child: value));
  });
}
}

/// @nodoc


class TabsElement implements PresentationElement {
   TabsElement({required final  List<TabItem> tabs, this.initiallySelectedTabId}): assert(tabs.isNotEmpty, 'Tabs must not be empty.'),_tabs = tabs;
  

 final  List<TabItem> _tabs;
 List<TabItem> get tabs {
  if (_tabs is EqualUnmodifiableListView) return _tabs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tabs);
}

 final  String? initiallySelectedTabId;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TabsElementCopyWith<TabsElement> get copyWith => _$TabsElementCopyWithImpl<TabsElement>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TabsElement&&const DeepCollectionEquality().equals(other._tabs, _tabs)&&(identical(other.initiallySelectedTabId, initiallySelectedTabId) || other.initiallySelectedTabId == initiallySelectedTabId));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_tabs),initiallySelectedTabId);

@override
String toString() {
  return 'PresentationElement.tabs(tabs: $tabs, initiallySelectedTabId: $initiallySelectedTabId)';
}


}

/// @nodoc
abstract mixin class $TabsElementCopyWith<$Res> implements $PresentationElementCopyWith<$Res> {
  factory $TabsElementCopyWith(TabsElement value, $Res Function(TabsElement) _then) = _$TabsElementCopyWithImpl;
@useResult
$Res call({
 List<TabItem> tabs, String? initiallySelectedTabId
});




}
/// @nodoc
class _$TabsElementCopyWithImpl<$Res>
    implements $TabsElementCopyWith<$Res> {
  _$TabsElementCopyWithImpl(this._self, this._then);

  final TabsElement _self;
  final $Res Function(TabsElement) _then;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? tabs = null,Object? initiallySelectedTabId = freezed,}) {
  return _then(TabsElement(
tabs: null == tabs ? _self._tabs : tabs // ignore: cast_nullable_to_non_nullable
as List<TabItem>,initiallySelectedTabId: freezed == initiallySelectedTabId ? _self.initiallySelectedTabId : initiallySelectedTabId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class DividerElement implements PresentationElement {
  const DividerElement();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DividerElement);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PresentationElement.divider()';
}


}




/// @nodoc


class SpacerElement implements PresentationElement {
  const SpacerElement({this.width, this.height});
  

 final  TypedExpression? width;
 final  TypedExpression? height;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SpacerElementCopyWith<SpacerElement> get copyWith => _$SpacerElementCopyWithImpl<SpacerElement>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SpacerElement&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height));
}


@override
int get hashCode => Object.hash(runtimeType,width,height);

@override
String toString() {
  return 'PresentationElement.spacer(width: $width, height: $height)';
}


}

/// @nodoc
abstract mixin class $SpacerElementCopyWith<$Res> implements $PresentationElementCopyWith<$Res> {
  factory $SpacerElementCopyWith(SpacerElement value, $Res Function(SpacerElement) _then) = _$SpacerElementCopyWithImpl;
@useResult
$Res call({
 TypedExpression? width, TypedExpression? height
});


$TypedExpressionCopyWith<$Res>? get width;$TypedExpressionCopyWith<$Res>? get height;

}
/// @nodoc
class _$SpacerElementCopyWithImpl<$Res>
    implements $SpacerElementCopyWith<$Res> {
  _$SpacerElementCopyWithImpl(this._self, this._then);

  final SpacerElement _self;
  final $Res Function(SpacerElement) _then;

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? width = freezed,Object? height = freezed,}) {
  return _then(SpacerElement(
width: freezed == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as TypedExpression?,height: freezed == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as TypedExpression?,
  ));
}

/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res>? get width {
    if (_self.width == null) {
    return null;
  }

  return $TypedExpressionCopyWith<$Res>(_self.width!, (value) {
    return _then(_self.copyWith(width: value));
  });
}/// Create a copy of PresentationElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res>? get height {
    if (_self.height == null) {
    return null;
  }

  return $TypedExpressionCopyWith<$Res>(_self.height!, (value) {
    return _then(_self.copyWith(height: value));
  });
}
}

/// @nodoc
mixin _$BoundControl {

 BindingReference get binding; TypedExpression? get label; TypedExpression? get description;
/// Create a copy of BoundControl
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BoundControlCopyWith<BoundControl> get copyWith => _$BoundControlCopyWithImpl<BoundControl>(this as BoundControl, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BoundControl&&(identical(other.binding, binding) || other.binding == binding)&&(identical(other.label, label) || other.label == label)&&(identical(other.description, description) || other.description == description));
}


@override
int get hashCode => Object.hash(runtimeType,binding,label,description);

@override
String toString() {
  return 'BoundControl(binding: $binding, label: $label, description: $description)';
}


}

/// @nodoc
abstract mixin class $BoundControlCopyWith<$Res>  {
  factory $BoundControlCopyWith(BoundControl value, $Res Function(BoundControl) _then) = _$BoundControlCopyWithImpl;
@useResult
$Res call({
 BindingReference binding, TypedExpression? label, TypedExpression? description
});


$BindingReferenceCopyWith<$Res> get binding;$TypedExpressionCopyWith<$Res>? get label;$TypedExpressionCopyWith<$Res>? get description;

}
/// @nodoc
class _$BoundControlCopyWithImpl<$Res>
    implements $BoundControlCopyWith<$Res> {
  _$BoundControlCopyWithImpl(this._self, this._then);

  final BoundControl _self;
  final $Res Function(BoundControl) _then;

/// Create a copy of BoundControl
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? binding = null,Object? label = freezed,Object? description = freezed,}) {
  return _then(_self.copyWith(
binding: null == binding ? _self.binding : binding // ignore: cast_nullable_to_non_nullable
as BindingReference,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as TypedExpression?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as TypedExpression?,
  ));
}
/// Create a copy of BoundControl
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BindingReferenceCopyWith<$Res> get binding {
  
  return $BindingReferenceCopyWith<$Res>(_self.binding, (value) {
    return _then(_self.copyWith(binding: value));
  });
}/// Create a copy of BoundControl
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res>? get label {
    if (_self.label == null) {
    return null;
  }

  return $TypedExpressionCopyWith<$Res>(_self.label!, (value) {
    return _then(_self.copyWith(label: value));
  });
}/// Create a copy of BoundControl
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res>? get description {
    if (_self.description == null) {
    return null;
  }

  return $TypedExpressionCopyWith<$Res>(_self.description!, (value) {
    return _then(_self.copyWith(description: value));
  });
}
}


/// Adds pattern-matching-related methods to [BoundControl].
extension BoundControlPatterns on BoundControl {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BoundControl value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BoundControl() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BoundControl value)  $default,){
final _that = this;
switch (_that) {
case _BoundControl():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BoundControl value)?  $default,){
final _that = this;
switch (_that) {
case _BoundControl() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BindingReference binding,  TypedExpression? label,  TypedExpression? description)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BoundControl() when $default != null:
return $default(_that.binding,_that.label,_that.description);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BindingReference binding,  TypedExpression? label,  TypedExpression? description)  $default,) {final _that = this;
switch (_that) {
case _BoundControl():
return $default(_that.binding,_that.label,_that.description);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BindingReference binding,  TypedExpression? label,  TypedExpression? description)?  $default,) {final _that = this;
switch (_that) {
case _BoundControl() when $default != null:
return $default(_that.binding,_that.label,_that.description);case _:
  return null;

}
}

}

/// @nodoc


class _BoundControl implements BoundControl {
  const _BoundControl({required this.binding, this.label, this.description});
  

@override final  BindingReference binding;
@override final  TypedExpression? label;
@override final  TypedExpression? description;

/// Create a copy of BoundControl
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BoundControlCopyWith<_BoundControl> get copyWith => __$BoundControlCopyWithImpl<_BoundControl>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BoundControl&&(identical(other.binding, binding) || other.binding == binding)&&(identical(other.label, label) || other.label == label)&&(identical(other.description, description) || other.description == description));
}


@override
int get hashCode => Object.hash(runtimeType,binding,label,description);

@override
String toString() {
  return 'BoundControl(binding: $binding, label: $label, description: $description)';
}


}

/// @nodoc
abstract mixin class _$BoundControlCopyWith<$Res> implements $BoundControlCopyWith<$Res> {
  factory _$BoundControlCopyWith(_BoundControl value, $Res Function(_BoundControl) _then) = __$BoundControlCopyWithImpl;
@override @useResult
$Res call({
 BindingReference binding, TypedExpression? label, TypedExpression? description
});


@override $BindingReferenceCopyWith<$Res> get binding;@override $TypedExpressionCopyWith<$Res>? get label;@override $TypedExpressionCopyWith<$Res>? get description;

}
/// @nodoc
class __$BoundControlCopyWithImpl<$Res>
    implements _$BoundControlCopyWith<$Res> {
  __$BoundControlCopyWithImpl(this._self, this._then);

  final _BoundControl _self;
  final $Res Function(_BoundControl) _then;

/// Create a copy of BoundControl
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? binding = null,Object? label = freezed,Object? description = freezed,}) {
  return _then(_BoundControl(
binding: null == binding ? _self.binding : binding // ignore: cast_nullable_to_non_nullable
as BindingReference,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as TypedExpression?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as TypedExpression?,
  ));
}

/// Create a copy of BoundControl
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BindingReferenceCopyWith<$Res> get binding {
  
  return $BindingReferenceCopyWith<$Res>(_self.binding, (value) {
    return _then(_self.copyWith(binding: value));
  });
}/// Create a copy of BoundControl
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res>? get label {
    if (_self.label == null) {
    return null;
  }

  return $TypedExpressionCopyWith<$Res>(_self.label!, (value) {
    return _then(_self.copyWith(label: value));
  });
}/// Create a copy of BoundControl
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res>? get description {
    if (_self.description == null) {
    return null;
  }

  return $TypedExpressionCopyWith<$Res>(_self.description!, (value) {
    return _then(_self.copyWith(description: value));
  });
}
}

/// @nodoc
mixin _$SelectOption {

 String get id; TypedExpression get label; TypedExpression get value;
/// Create a copy of SelectOption
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SelectOptionCopyWith<SelectOption> get copyWith => _$SelectOptionCopyWithImpl<SelectOption>(this as SelectOption, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SelectOption&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,id,label,value);

@override
String toString() {
  return 'SelectOption(id: $id, label: $label, value: $value)';
}


}

/// @nodoc
abstract mixin class $SelectOptionCopyWith<$Res>  {
  factory $SelectOptionCopyWith(SelectOption value, $Res Function(SelectOption) _then) = _$SelectOptionCopyWithImpl;
@useResult
$Res call({
 String id, TypedExpression label, TypedExpression value
});


$TypedExpressionCopyWith<$Res> get label;$TypedExpressionCopyWith<$Res> get value;

}
/// @nodoc
class _$SelectOptionCopyWithImpl<$Res>
    implements $SelectOptionCopyWith<$Res> {
  _$SelectOptionCopyWithImpl(this._self, this._then);

  final SelectOption _self;
  final $Res Function(SelectOption) _then;

/// Create a copy of SelectOption
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = null,Object? value = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as TypedExpression,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as TypedExpression,
  ));
}
/// Create a copy of SelectOption
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get label {
  
  return $TypedExpressionCopyWith<$Res>(_self.label, (value) {
    return _then(_self.copyWith(label: value));
  });
}/// Create a copy of SelectOption
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get value {
  
  return $TypedExpressionCopyWith<$Res>(_self.value, (value) {
    return _then(_self.copyWith(value: value));
  });
}
}


/// Adds pattern-matching-related methods to [SelectOption].
extension SelectOptionPatterns on SelectOption {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SelectOption value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SelectOption() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SelectOption value)  $default,){
final _that = this;
switch (_that) {
case _SelectOption():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SelectOption value)?  $default,){
final _that = this;
switch (_that) {
case _SelectOption() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  TypedExpression label,  TypedExpression value)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SelectOption() when $default != null:
return $default(_that.id,_that.label,_that.value);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  TypedExpression label,  TypedExpression value)  $default,) {final _that = this;
switch (_that) {
case _SelectOption():
return $default(_that.id,_that.label,_that.value);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  TypedExpression label,  TypedExpression value)?  $default,) {final _that = this;
switch (_that) {
case _SelectOption() when $default != null:
return $default(_that.id,_that.label,_that.value);case _:
  return null;

}
}

}

/// @nodoc


class _SelectOption implements SelectOption {
  const _SelectOption({required this.id, required this.label, required this.value}): assert(id != "", 'Select option ID must not be empty.');
  

@override final  String id;
@override final  TypedExpression label;
@override final  TypedExpression value;

/// Create a copy of SelectOption
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SelectOptionCopyWith<_SelectOption> get copyWith => __$SelectOptionCopyWithImpl<_SelectOption>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SelectOption&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,id,label,value);

@override
String toString() {
  return 'SelectOption(id: $id, label: $label, value: $value)';
}


}

/// @nodoc
abstract mixin class _$SelectOptionCopyWith<$Res> implements $SelectOptionCopyWith<$Res> {
  factory _$SelectOptionCopyWith(_SelectOption value, $Res Function(_SelectOption) _then) = __$SelectOptionCopyWithImpl;
@override @useResult
$Res call({
 String id, TypedExpression label, TypedExpression value
});


@override $TypedExpressionCopyWith<$Res> get label;@override $TypedExpressionCopyWith<$Res> get value;

}
/// @nodoc
class __$SelectOptionCopyWithImpl<$Res>
    implements _$SelectOptionCopyWith<$Res> {
  __$SelectOptionCopyWithImpl(this._self, this._then);

  final _SelectOption _self;
  final $Res Function(_SelectOption) _then;

/// Create a copy of SelectOption
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = null,Object? value = null,}) {
  return _then(_SelectOption(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as TypedExpression,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as TypedExpression,
  ));
}

/// Create a copy of SelectOption
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get label {
  
  return $TypedExpressionCopyWith<$Res>(_self.label, (value) {
    return _then(_self.copyWith(label: value));
  });
}/// Create a copy of SelectOption
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get value {
  
  return $TypedExpressionCopyWith<$Res>(_self.value, (value) {
    return _then(_self.copyWith(value: value));
  });
}
}

/// @nodoc
mixin _$ConcreteTypePresentation {

 ResolvedTypeRef get type; TypedExpression get label; PresentationNode? get presentation;
/// Create a copy of ConcreteTypePresentation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConcreteTypePresentationCopyWith<ConcreteTypePresentation> get copyWith => _$ConcreteTypePresentationCopyWithImpl<ConcreteTypePresentation>(this as ConcreteTypePresentation, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConcreteTypePresentation&&(identical(other.type, type) || other.type == type)&&(identical(other.label, label) || other.label == label)&&(identical(other.presentation, presentation) || other.presentation == presentation));
}


@override
int get hashCode => Object.hash(runtimeType,type,label,presentation);

@override
String toString() {
  return 'ConcreteTypePresentation(type: $type, label: $label, presentation: $presentation)';
}


}

/// @nodoc
abstract mixin class $ConcreteTypePresentationCopyWith<$Res>  {
  factory $ConcreteTypePresentationCopyWith(ConcreteTypePresentation value, $Res Function(ConcreteTypePresentation) _then) = _$ConcreteTypePresentationCopyWithImpl;
@useResult
$Res call({
 ResolvedTypeRef type, TypedExpression label, PresentationNode? presentation
});


$ResolvedTypeRefCopyWith<$Res> get type;$TypedExpressionCopyWith<$Res> get label;$PresentationNodeCopyWith<$Res>? get presentation;

}
/// @nodoc
class _$ConcreteTypePresentationCopyWithImpl<$Res>
    implements $ConcreteTypePresentationCopyWith<$Res> {
  _$ConcreteTypePresentationCopyWithImpl(this._self, this._then);

  final ConcreteTypePresentation _self;
  final $Res Function(ConcreteTypePresentation) _then;

/// Create a copy of ConcreteTypePresentation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? label = null,Object? presentation = freezed,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ResolvedTypeRef,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as TypedExpression,presentation: freezed == presentation ? _self.presentation : presentation // ignore: cast_nullable_to_non_nullable
as PresentationNode?,
  ));
}
/// Create a copy of ConcreteTypePresentation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ResolvedTypeRefCopyWith<$Res> get type {
  
  return $ResolvedTypeRefCopyWith<$Res>(_self.type, (value) {
    return _then(_self.copyWith(type: value));
  });
}/// Create a copy of ConcreteTypePresentation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get label {
  
  return $TypedExpressionCopyWith<$Res>(_self.label, (value) {
    return _then(_self.copyWith(label: value));
  });
}/// Create a copy of ConcreteTypePresentation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PresentationNodeCopyWith<$Res>? get presentation {
    if (_self.presentation == null) {
    return null;
  }

  return $PresentationNodeCopyWith<$Res>(_self.presentation!, (value) {
    return _then(_self.copyWith(presentation: value));
  });
}
}


/// Adds pattern-matching-related methods to [ConcreteTypePresentation].
extension ConcreteTypePresentationPatterns on ConcreteTypePresentation {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ConcreteTypePresentation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ConcreteTypePresentation() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ConcreteTypePresentation value)  $default,){
final _that = this;
switch (_that) {
case _ConcreteTypePresentation():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ConcreteTypePresentation value)?  $default,){
final _that = this;
switch (_that) {
case _ConcreteTypePresentation() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ResolvedTypeRef type,  TypedExpression label,  PresentationNode? presentation)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ConcreteTypePresentation() when $default != null:
return $default(_that.type,_that.label,_that.presentation);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ResolvedTypeRef type,  TypedExpression label,  PresentationNode? presentation)  $default,) {final _that = this;
switch (_that) {
case _ConcreteTypePresentation():
return $default(_that.type,_that.label,_that.presentation);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ResolvedTypeRef type,  TypedExpression label,  PresentationNode? presentation)?  $default,) {final _that = this;
switch (_that) {
case _ConcreteTypePresentation() when $default != null:
return $default(_that.type,_that.label,_that.presentation);case _:
  return null;

}
}

}

/// @nodoc


class _ConcreteTypePresentation implements ConcreteTypePresentation {
  const _ConcreteTypePresentation({required this.type, required this.label, this.presentation});
  

@override final  ResolvedTypeRef type;
@override final  TypedExpression label;
@override final  PresentationNode? presentation;

/// Create a copy of ConcreteTypePresentation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConcreteTypePresentationCopyWith<_ConcreteTypePresentation> get copyWith => __$ConcreteTypePresentationCopyWithImpl<_ConcreteTypePresentation>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConcreteTypePresentation&&(identical(other.type, type) || other.type == type)&&(identical(other.label, label) || other.label == label)&&(identical(other.presentation, presentation) || other.presentation == presentation));
}


@override
int get hashCode => Object.hash(runtimeType,type,label,presentation);

@override
String toString() {
  return 'ConcreteTypePresentation(type: $type, label: $label, presentation: $presentation)';
}


}

/// @nodoc
abstract mixin class _$ConcreteTypePresentationCopyWith<$Res> implements $ConcreteTypePresentationCopyWith<$Res> {
  factory _$ConcreteTypePresentationCopyWith(_ConcreteTypePresentation value, $Res Function(_ConcreteTypePresentation) _then) = __$ConcreteTypePresentationCopyWithImpl;
@override @useResult
$Res call({
 ResolvedTypeRef type, TypedExpression label, PresentationNode? presentation
});


@override $ResolvedTypeRefCopyWith<$Res> get type;@override $TypedExpressionCopyWith<$Res> get label;@override $PresentationNodeCopyWith<$Res>? get presentation;

}
/// @nodoc
class __$ConcreteTypePresentationCopyWithImpl<$Res>
    implements _$ConcreteTypePresentationCopyWith<$Res> {
  __$ConcreteTypePresentationCopyWithImpl(this._self, this._then);

  final _ConcreteTypePresentation _self;
  final $Res Function(_ConcreteTypePresentation) _then;

/// Create a copy of ConcreteTypePresentation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? label = null,Object? presentation = freezed,}) {
  return _then(_ConcreteTypePresentation(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ResolvedTypeRef,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as TypedExpression,presentation: freezed == presentation ? _self.presentation : presentation // ignore: cast_nullable_to_non_nullable
as PresentationNode?,
  ));
}

/// Create a copy of ConcreteTypePresentation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ResolvedTypeRefCopyWith<$Res> get type {
  
  return $ResolvedTypeRefCopyWith<$Res>(_self.type, (value) {
    return _then(_self.copyWith(type: value));
  });
}/// Create a copy of ConcreteTypePresentation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get label {
  
  return $TypedExpressionCopyWith<$Res>(_self.label, (value) {
    return _then(_self.copyWith(label: value));
  });
}/// Create a copy of ConcreteTypePresentation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PresentationNodeCopyWith<$Res>? get presentation {
    if (_self.presentation == null) {
    return null;
  }

  return $PresentationNodeCopyWith<$Res>(_self.presentation!, (value) {
    return _then(_self.copyWith(presentation: value));
  });
}
}

/// @nodoc
mixin _$PresentationMenuItem {

 String get id; TypedExpression get label; EditorAction get action;
/// Create a copy of PresentationMenuItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PresentationMenuItemCopyWith<PresentationMenuItem> get copyWith => _$PresentationMenuItemCopyWithImpl<PresentationMenuItem>(this as PresentationMenuItem, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PresentationMenuItem&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.action, action) || other.action == action));
}


@override
int get hashCode => Object.hash(runtimeType,id,label,action);

@override
String toString() {
  return 'PresentationMenuItem(id: $id, label: $label, action: $action)';
}


}

/// @nodoc
abstract mixin class $PresentationMenuItemCopyWith<$Res>  {
  factory $PresentationMenuItemCopyWith(PresentationMenuItem value, $Res Function(PresentationMenuItem) _then) = _$PresentationMenuItemCopyWithImpl;
@useResult
$Res call({
 String id, TypedExpression label, EditorAction action
});


$TypedExpressionCopyWith<$Res> get label;$EditorActionCopyWith<$Res> get action;

}
/// @nodoc
class _$PresentationMenuItemCopyWithImpl<$Res>
    implements $PresentationMenuItemCopyWith<$Res> {
  _$PresentationMenuItemCopyWithImpl(this._self, this._then);

  final PresentationMenuItem _self;
  final $Res Function(PresentationMenuItem) _then;

/// Create a copy of PresentationMenuItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = null,Object? action = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as TypedExpression,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as EditorAction,
  ));
}
/// Create a copy of PresentationMenuItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get label {
  
  return $TypedExpressionCopyWith<$Res>(_self.label, (value) {
    return _then(_self.copyWith(label: value));
  });
}/// Create a copy of PresentationMenuItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EditorActionCopyWith<$Res> get action {
  
  return $EditorActionCopyWith<$Res>(_self.action, (value) {
    return _then(_self.copyWith(action: value));
  });
}
}


/// Adds pattern-matching-related methods to [PresentationMenuItem].
extension PresentationMenuItemPatterns on PresentationMenuItem {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PresentationMenuItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PresentationMenuItem() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PresentationMenuItem value)  $default,){
final _that = this;
switch (_that) {
case _PresentationMenuItem():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PresentationMenuItem value)?  $default,){
final _that = this;
switch (_that) {
case _PresentationMenuItem() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  TypedExpression label,  EditorAction action)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PresentationMenuItem() when $default != null:
return $default(_that.id,_that.label,_that.action);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  TypedExpression label,  EditorAction action)  $default,) {final _that = this;
switch (_that) {
case _PresentationMenuItem():
return $default(_that.id,_that.label,_that.action);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  TypedExpression label,  EditorAction action)?  $default,) {final _that = this;
switch (_that) {
case _PresentationMenuItem() when $default != null:
return $default(_that.id,_that.label,_that.action);case _:
  return null;

}
}

}

/// @nodoc


class _PresentationMenuItem implements PresentationMenuItem {
  const _PresentationMenuItem({required this.id, required this.label, required this.action}): assert(id != "", 'Menu item ID must not be empty.');
  

@override final  String id;
@override final  TypedExpression label;
@override final  EditorAction action;

/// Create a copy of PresentationMenuItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PresentationMenuItemCopyWith<_PresentationMenuItem> get copyWith => __$PresentationMenuItemCopyWithImpl<_PresentationMenuItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PresentationMenuItem&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.action, action) || other.action == action));
}


@override
int get hashCode => Object.hash(runtimeType,id,label,action);

@override
String toString() {
  return 'PresentationMenuItem(id: $id, label: $label, action: $action)';
}


}

/// @nodoc
abstract mixin class _$PresentationMenuItemCopyWith<$Res> implements $PresentationMenuItemCopyWith<$Res> {
  factory _$PresentationMenuItemCopyWith(_PresentationMenuItem value, $Res Function(_PresentationMenuItem) _then) = __$PresentationMenuItemCopyWithImpl;
@override @useResult
$Res call({
 String id, TypedExpression label, EditorAction action
});


@override $TypedExpressionCopyWith<$Res> get label;@override $EditorActionCopyWith<$Res> get action;

}
/// @nodoc
class __$PresentationMenuItemCopyWithImpl<$Res>
    implements _$PresentationMenuItemCopyWith<$Res> {
  __$PresentationMenuItemCopyWithImpl(this._self, this._then);

  final _PresentationMenuItem _self;
  final $Res Function(_PresentationMenuItem) _then;

/// Create a copy of PresentationMenuItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = null,Object? action = null,}) {
  return _then(_PresentationMenuItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as TypedExpression,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as EditorAction,
  ));
}

/// Create a copy of PresentationMenuItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get label {
  
  return $TypedExpressionCopyWith<$Res>(_self.label, (value) {
    return _then(_self.copyWith(label: value));
  });
}/// Create a copy of PresentationMenuItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EditorActionCopyWith<$Res> get action {
  
  return $EditorActionCopyWith<$Res>(_self.action, (value) {
    return _then(_self.copyWith(action: value));
  });
}
}

/// @nodoc
mixin _$TabItem {

 String get id; TypedExpression get label; PresentationNode get child;
/// Create a copy of TabItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TabItemCopyWith<TabItem> get copyWith => _$TabItemCopyWithImpl<TabItem>(this as TabItem, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TabItem&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.child, child) || other.child == child));
}


@override
int get hashCode => Object.hash(runtimeType,id,label,child);

@override
String toString() {
  return 'TabItem(id: $id, label: $label, child: $child)';
}


}

/// @nodoc
abstract mixin class $TabItemCopyWith<$Res>  {
  factory $TabItemCopyWith(TabItem value, $Res Function(TabItem) _then) = _$TabItemCopyWithImpl;
@useResult
$Res call({
 String id, TypedExpression label, PresentationNode child
});


$TypedExpressionCopyWith<$Res> get label;$PresentationNodeCopyWith<$Res> get child;

}
/// @nodoc
class _$TabItemCopyWithImpl<$Res>
    implements $TabItemCopyWith<$Res> {
  _$TabItemCopyWithImpl(this._self, this._then);

  final TabItem _self;
  final $Res Function(TabItem) _then;

/// Create a copy of TabItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = null,Object? child = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as TypedExpression,child: null == child ? _self.child : child // ignore: cast_nullable_to_non_nullable
as PresentationNode,
  ));
}
/// Create a copy of TabItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get label {
  
  return $TypedExpressionCopyWith<$Res>(_self.label, (value) {
    return _then(_self.copyWith(label: value));
  });
}/// Create a copy of TabItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PresentationNodeCopyWith<$Res> get child {
  
  return $PresentationNodeCopyWith<$Res>(_self.child, (value) {
    return _then(_self.copyWith(child: value));
  });
}
}


/// Adds pattern-matching-related methods to [TabItem].
extension TabItemPatterns on TabItem {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TabItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TabItem() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TabItem value)  $default,){
final _that = this;
switch (_that) {
case _TabItem():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TabItem value)?  $default,){
final _that = this;
switch (_that) {
case _TabItem() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  TypedExpression label,  PresentationNode child)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TabItem() when $default != null:
return $default(_that.id,_that.label,_that.child);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  TypedExpression label,  PresentationNode child)  $default,) {final _that = this;
switch (_that) {
case _TabItem():
return $default(_that.id,_that.label,_that.child);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  TypedExpression label,  PresentationNode child)?  $default,) {final _that = this;
switch (_that) {
case _TabItem() when $default != null:
return $default(_that.id,_that.label,_that.child);case _:
  return null;

}
}

}

/// @nodoc


class _TabItem implements TabItem {
  const _TabItem({required this.id, required this.label, required this.child}): assert(id != "", 'Tab ID must not be empty.');
  

@override final  String id;
@override final  TypedExpression label;
@override final  PresentationNode child;

/// Create a copy of TabItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TabItemCopyWith<_TabItem> get copyWith => __$TabItemCopyWithImpl<_TabItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TabItem&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.child, child) || other.child == child));
}


@override
int get hashCode => Object.hash(runtimeType,id,label,child);

@override
String toString() {
  return 'TabItem(id: $id, label: $label, child: $child)';
}


}

/// @nodoc
abstract mixin class _$TabItemCopyWith<$Res> implements $TabItemCopyWith<$Res> {
  factory _$TabItemCopyWith(_TabItem value, $Res Function(_TabItem) _then) = __$TabItemCopyWithImpl;
@override @useResult
$Res call({
 String id, TypedExpression label, PresentationNode child
});


@override $TypedExpressionCopyWith<$Res> get label;@override $PresentationNodeCopyWith<$Res> get child;

}
/// @nodoc
class __$TabItemCopyWithImpl<$Res>
    implements _$TabItemCopyWith<$Res> {
  __$TabItemCopyWithImpl(this._self, this._then);

  final _TabItem _self;
  final $Res Function(_TabItem) _then;

/// Create a copy of TabItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = null,Object? child = null,}) {
  return _then(_TabItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as TypedExpression,child: null == child ? _self.child : child // ignore: cast_nullable_to_non_nullable
as PresentationNode,
  ));
}

/// Create a copy of TabItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get label {
  
  return $TypedExpressionCopyWith<$Res>(_self.label, (value) {
    return _then(_self.copyWith(label: value));
  });
}/// Create a copy of TabItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PresentationNodeCopyWith<$Res> get child {
  
  return $PresentationNodeCopyWith<$Res>(_self.child, (value) {
    return _then(_self.copyWith(child: value));
  });
}
}

/// @nodoc
mixin _$SearchSelectorValues {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchSelectorValues);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SearchSelectorValues()';
}


}

/// @nodoc
class $SearchSelectorValuesCopyWith<$Res>  {
$SearchSelectorValuesCopyWith(SearchSelectorValues _, $Res Function(SearchSelectorValues) __);
}


/// Adds pattern-matching-related methods to [SearchSelectorValues].
extension SearchSelectorValuesPatterns on SearchSelectorValues {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( FreeTextSearchSelectorValues value)?  freeText,TResult Function( EnumeratedSearchSelectorValues value)?  enumeration,required TResult orElse(),}){
final _that = this;
switch (_that) {
case FreeTextSearchSelectorValues() when freeText != null:
return freeText(_that);case EnumeratedSearchSelectorValues() when enumeration != null:
return enumeration(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( FreeTextSearchSelectorValues value)  freeText,required TResult Function( EnumeratedSearchSelectorValues value)  enumeration,}){
final _that = this;
switch (_that) {
case FreeTextSearchSelectorValues():
return freeText(_that);case EnumeratedSearchSelectorValues():
return enumeration(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( FreeTextSearchSelectorValues value)?  freeText,TResult? Function( EnumeratedSearchSelectorValues value)?  enumeration,}){
final _that = this;
switch (_that) {
case FreeTextSearchSelectorValues() when freeText != null:
return freeText(_that);case EnumeratedSearchSelectorValues() when enumeration != null:
return enumeration(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  freeText,TResult Function( List<String> values)?  enumeration,required TResult orElse(),}) {final _that = this;
switch (_that) {
case FreeTextSearchSelectorValues() when freeText != null:
return freeText();case EnumeratedSearchSelectorValues() when enumeration != null:
return enumeration(_that.values);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  freeText,required TResult Function( List<String> values)  enumeration,}) {final _that = this;
switch (_that) {
case FreeTextSearchSelectorValues():
return freeText();case EnumeratedSearchSelectorValues():
return enumeration(_that.values);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  freeText,TResult? Function( List<String> values)?  enumeration,}) {final _that = this;
switch (_that) {
case FreeTextSearchSelectorValues() when freeText != null:
return freeText();case EnumeratedSearchSelectorValues() when enumeration != null:
return enumeration(_that.values);case _:
  return null;

}
}

}

/// @nodoc


class FreeTextSearchSelectorValues implements SearchSelectorValues {
  const FreeTextSearchSelectorValues();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FreeTextSearchSelectorValues);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SearchSelectorValues.freeText()';
}


}




/// @nodoc


class EnumeratedSearchSelectorValues implements SearchSelectorValues {
   EnumeratedSearchSelectorValues(final  List<String> values): assert(values.isNotEmpty, 'Selector values must not be empty.'),_values = values;
  

 final  List<String> _values;
 List<String> get values {
  if (_values is EqualUnmodifiableListView) return _values;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_values);
}


/// Create a copy of SearchSelectorValues
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EnumeratedSearchSelectorValuesCopyWith<EnumeratedSearchSelectorValues> get copyWith => _$EnumeratedSearchSelectorValuesCopyWithImpl<EnumeratedSearchSelectorValues>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EnumeratedSearchSelectorValues&&const DeepCollectionEquality().equals(other._values, _values));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_values));

@override
String toString() {
  return 'SearchSelectorValues.enumeration(values: $values)';
}


}

/// @nodoc
abstract mixin class $EnumeratedSearchSelectorValuesCopyWith<$Res> implements $SearchSelectorValuesCopyWith<$Res> {
  factory $EnumeratedSearchSelectorValuesCopyWith(EnumeratedSearchSelectorValues value, $Res Function(EnumeratedSearchSelectorValues) _then) = _$EnumeratedSearchSelectorValuesCopyWithImpl;
@useResult
$Res call({
 List<String> values
});




}
/// @nodoc
class _$EnumeratedSearchSelectorValuesCopyWithImpl<$Res>
    implements $EnumeratedSearchSelectorValuesCopyWith<$Res> {
  _$EnumeratedSearchSelectorValuesCopyWithImpl(this._self, this._then);

  final EnumeratedSearchSelectorValues _self;
  final $Res Function(EnumeratedSearchSelectorValues) _then;

/// Create a copy of SearchSelectorValues
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? values = null,}) {
  return _then(EnumeratedSearchSelectorValues(
null == values ? _self._values : values // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

/// @nodoc
mixin _$SearchSelectorDefinition {

 String get id; String get key; BindingId get valueBindingId; SearchSelectorValues get values; bool get caseSensitive; SearchSelectorMultiplicity get multiplicity; int? get colorValue;
/// Create a copy of SearchSelectorDefinition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchSelectorDefinitionCopyWith<SearchSelectorDefinition> get copyWith => _$SearchSelectorDefinitionCopyWithImpl<SearchSelectorDefinition>(this as SearchSelectorDefinition, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchSelectorDefinition&&(identical(other.id, id) || other.id == id)&&(identical(other.key, key) || other.key == key)&&(identical(other.valueBindingId, valueBindingId) || other.valueBindingId == valueBindingId)&&(identical(other.values, values) || other.values == values)&&(identical(other.caseSensitive, caseSensitive) || other.caseSensitive == caseSensitive)&&(identical(other.multiplicity, multiplicity) || other.multiplicity == multiplicity)&&(identical(other.colorValue, colorValue) || other.colorValue == colorValue));
}


@override
int get hashCode => Object.hash(runtimeType,id,key,valueBindingId,values,caseSensitive,multiplicity,colorValue);

@override
String toString() {
  return 'SearchSelectorDefinition(id: $id, key: $key, valueBindingId: $valueBindingId, values: $values, caseSensitive: $caseSensitive, multiplicity: $multiplicity, colorValue: $colorValue)';
}


}

/// @nodoc
abstract mixin class $SearchSelectorDefinitionCopyWith<$Res>  {
  factory $SearchSelectorDefinitionCopyWith(SearchSelectorDefinition value, $Res Function(SearchSelectorDefinition) _then) = _$SearchSelectorDefinitionCopyWithImpl;
@useResult
$Res call({
 String id, String key, BindingId valueBindingId, SearchSelectorValues values, bool caseSensitive, SearchSelectorMultiplicity multiplicity, int? colorValue
});


$BindingIdCopyWith<$Res> get valueBindingId;$SearchSelectorValuesCopyWith<$Res> get values;

}
/// @nodoc
class _$SearchSelectorDefinitionCopyWithImpl<$Res>
    implements $SearchSelectorDefinitionCopyWith<$Res> {
  _$SearchSelectorDefinitionCopyWithImpl(this._self, this._then);

  final SearchSelectorDefinition _self;
  final $Res Function(SearchSelectorDefinition) _then;

/// Create a copy of SearchSelectorDefinition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? key = null,Object? valueBindingId = null,Object? values = null,Object? caseSensitive = null,Object? multiplicity = null,Object? colorValue = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,valueBindingId: null == valueBindingId ? _self.valueBindingId : valueBindingId // ignore: cast_nullable_to_non_nullable
as BindingId,values: null == values ? _self.values : values // ignore: cast_nullable_to_non_nullable
as SearchSelectorValues,caseSensitive: null == caseSensitive ? _self.caseSensitive : caseSensitive // ignore: cast_nullable_to_non_nullable
as bool,multiplicity: null == multiplicity ? _self.multiplicity : multiplicity // ignore: cast_nullable_to_non_nullable
as SearchSelectorMultiplicity,colorValue: freezed == colorValue ? _self.colorValue : colorValue // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}
/// Create a copy of SearchSelectorDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BindingIdCopyWith<$Res> get valueBindingId {
  
  return $BindingIdCopyWith<$Res>(_self.valueBindingId, (value) {
    return _then(_self.copyWith(valueBindingId: value));
  });
}/// Create a copy of SearchSelectorDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchSelectorValuesCopyWith<$Res> get values {
  
  return $SearchSelectorValuesCopyWith<$Res>(_self.values, (value) {
    return _then(_self.copyWith(values: value));
  });
}
}


/// Adds pattern-matching-related methods to [SearchSelectorDefinition].
extension SearchSelectorDefinitionPatterns on SearchSelectorDefinition {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( KeyValueSearchSelectorDefinition value)?  keyValue,required TResult orElse(),}){
final _that = this;
switch (_that) {
case KeyValueSearchSelectorDefinition() when keyValue != null:
return keyValue(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( KeyValueSearchSelectorDefinition value)  keyValue,}){
final _that = this;
switch (_that) {
case KeyValueSearchSelectorDefinition():
return keyValue(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( KeyValueSearchSelectorDefinition value)?  keyValue,}){
final _that = this;
switch (_that) {
case KeyValueSearchSelectorDefinition() when keyValue != null:
return keyValue(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String id,  String key,  BindingId valueBindingId,  SearchSelectorValues values,  bool caseSensitive,  SearchSelectorMultiplicity multiplicity,  int? colorValue)?  keyValue,required TResult orElse(),}) {final _that = this;
switch (_that) {
case KeyValueSearchSelectorDefinition() when keyValue != null:
return keyValue(_that.id,_that.key,_that.valueBindingId,_that.values,_that.caseSensitive,_that.multiplicity,_that.colorValue);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String id,  String key,  BindingId valueBindingId,  SearchSelectorValues values,  bool caseSensitive,  SearchSelectorMultiplicity multiplicity,  int? colorValue)  keyValue,}) {final _that = this;
switch (_that) {
case KeyValueSearchSelectorDefinition():
return keyValue(_that.id,_that.key,_that.valueBindingId,_that.values,_that.caseSensitive,_that.multiplicity,_that.colorValue);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String id,  String key,  BindingId valueBindingId,  SearchSelectorValues values,  bool caseSensitive,  SearchSelectorMultiplicity multiplicity,  int? colorValue)?  keyValue,}) {final _that = this;
switch (_that) {
case KeyValueSearchSelectorDefinition() when keyValue != null:
return keyValue(_that.id,_that.key,_that.valueBindingId,_that.values,_that.caseSensitive,_that.multiplicity,_that.colorValue);case _:
  return null;

}
}

}

/// @nodoc


class KeyValueSearchSelectorDefinition implements SearchSelectorDefinition {
  const KeyValueSearchSelectorDefinition({required this.id, required this.key, required this.valueBindingId, required this.values, this.caseSensitive = false, this.multiplicity = SearchSelectorMultiplicity.single, this.colorValue}): assert(id != "", 'Selector ID must not be empty.'),assert(key != "", 'Selector key must not be empty.');
  

@override final  String id;
@override final  String key;
@override final  BindingId valueBindingId;
@override final  SearchSelectorValues values;
@override@JsonKey() final  bool caseSensitive;
@override@JsonKey() final  SearchSelectorMultiplicity multiplicity;
@override final  int? colorValue;

/// Create a copy of SearchSelectorDefinition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KeyValueSearchSelectorDefinitionCopyWith<KeyValueSearchSelectorDefinition> get copyWith => _$KeyValueSearchSelectorDefinitionCopyWithImpl<KeyValueSearchSelectorDefinition>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KeyValueSearchSelectorDefinition&&(identical(other.id, id) || other.id == id)&&(identical(other.key, key) || other.key == key)&&(identical(other.valueBindingId, valueBindingId) || other.valueBindingId == valueBindingId)&&(identical(other.values, values) || other.values == values)&&(identical(other.caseSensitive, caseSensitive) || other.caseSensitive == caseSensitive)&&(identical(other.multiplicity, multiplicity) || other.multiplicity == multiplicity)&&(identical(other.colorValue, colorValue) || other.colorValue == colorValue));
}


@override
int get hashCode => Object.hash(runtimeType,id,key,valueBindingId,values,caseSensitive,multiplicity,colorValue);

@override
String toString() {
  return 'SearchSelectorDefinition.keyValue(id: $id, key: $key, valueBindingId: $valueBindingId, values: $values, caseSensitive: $caseSensitive, multiplicity: $multiplicity, colorValue: $colorValue)';
}


}

/// @nodoc
abstract mixin class $KeyValueSearchSelectorDefinitionCopyWith<$Res> implements $SearchSelectorDefinitionCopyWith<$Res> {
  factory $KeyValueSearchSelectorDefinitionCopyWith(KeyValueSearchSelectorDefinition value, $Res Function(KeyValueSearchSelectorDefinition) _then) = _$KeyValueSearchSelectorDefinitionCopyWithImpl;
@override @useResult
$Res call({
 String id, String key, BindingId valueBindingId, SearchSelectorValues values, bool caseSensitive, SearchSelectorMultiplicity multiplicity, int? colorValue
});


@override $BindingIdCopyWith<$Res> get valueBindingId;@override $SearchSelectorValuesCopyWith<$Res> get values;

}
/// @nodoc
class _$KeyValueSearchSelectorDefinitionCopyWithImpl<$Res>
    implements $KeyValueSearchSelectorDefinitionCopyWith<$Res> {
  _$KeyValueSearchSelectorDefinitionCopyWithImpl(this._self, this._then);

  final KeyValueSearchSelectorDefinition _self;
  final $Res Function(KeyValueSearchSelectorDefinition) _then;

/// Create a copy of SearchSelectorDefinition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? key = null,Object? valueBindingId = null,Object? values = null,Object? caseSensitive = null,Object? multiplicity = null,Object? colorValue = freezed,}) {
  return _then(KeyValueSearchSelectorDefinition(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,valueBindingId: null == valueBindingId ? _self.valueBindingId : valueBindingId // ignore: cast_nullable_to_non_nullable
as BindingId,values: null == values ? _self.values : values // ignore: cast_nullable_to_non_nullable
as SearchSelectorValues,caseSensitive: null == caseSensitive ? _self.caseSensitive : caseSensitive // ignore: cast_nullable_to_non_nullable
as bool,multiplicity: null == multiplicity ? _self.multiplicity : multiplicity // ignore: cast_nullable_to_non_nullable
as SearchSelectorMultiplicity,colorValue: freezed == colorValue ? _self.colorValue : colorValue // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

/// Create a copy of SearchSelectorDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BindingIdCopyWith<$Res> get valueBindingId {
  
  return $BindingIdCopyWith<$Res>(_self.valueBindingId, (value) {
    return _then(_self.copyWith(valueBindingId: value));
  });
}/// Create a copy of SearchSelectorDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchSelectorValuesCopyWith<$Res> get values {
  
  return $SearchSelectorValuesCopyWith<$Res>(_self.values, (value) {
    return _then(_self.copyWith(values: value));
  });
}
}

/// @nodoc
mixin _$SearchResultMapping {

 BindingId get bindingId; TypedExpression get key; TypedExpression get selectedValue; PresentationNode get presentation;
/// Create a copy of SearchResultMapping
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchResultMappingCopyWith<SearchResultMapping> get copyWith => _$SearchResultMappingCopyWithImpl<SearchResultMapping>(this as SearchResultMapping, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchResultMapping&&(identical(other.bindingId, bindingId) || other.bindingId == bindingId)&&(identical(other.key, key) || other.key == key)&&(identical(other.selectedValue, selectedValue) || other.selectedValue == selectedValue)&&(identical(other.presentation, presentation) || other.presentation == presentation));
}


@override
int get hashCode => Object.hash(runtimeType,bindingId,key,selectedValue,presentation);

@override
String toString() {
  return 'SearchResultMapping(bindingId: $bindingId, key: $key, selectedValue: $selectedValue, presentation: $presentation)';
}


}

/// @nodoc
abstract mixin class $SearchResultMappingCopyWith<$Res>  {
  factory $SearchResultMappingCopyWith(SearchResultMapping value, $Res Function(SearchResultMapping) _then) = _$SearchResultMappingCopyWithImpl;
@useResult
$Res call({
 BindingId bindingId, TypedExpression key, TypedExpression selectedValue, PresentationNode presentation
});


$BindingIdCopyWith<$Res> get bindingId;$TypedExpressionCopyWith<$Res> get key;$TypedExpressionCopyWith<$Res> get selectedValue;$PresentationNodeCopyWith<$Res> get presentation;

}
/// @nodoc
class _$SearchResultMappingCopyWithImpl<$Res>
    implements $SearchResultMappingCopyWith<$Res> {
  _$SearchResultMappingCopyWithImpl(this._self, this._then);

  final SearchResultMapping _self;
  final $Res Function(SearchResultMapping) _then;

/// Create a copy of SearchResultMapping
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? bindingId = null,Object? key = null,Object? selectedValue = null,Object? presentation = null,}) {
  return _then(_self.copyWith(
bindingId: null == bindingId ? _self.bindingId : bindingId // ignore: cast_nullable_to_non_nullable
as BindingId,key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as TypedExpression,selectedValue: null == selectedValue ? _self.selectedValue : selectedValue // ignore: cast_nullable_to_non_nullable
as TypedExpression,presentation: null == presentation ? _self.presentation : presentation // ignore: cast_nullable_to_non_nullable
as PresentationNode,
  ));
}
/// Create a copy of SearchResultMapping
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BindingIdCopyWith<$Res> get bindingId {
  
  return $BindingIdCopyWith<$Res>(_self.bindingId, (value) {
    return _then(_self.copyWith(bindingId: value));
  });
}/// Create a copy of SearchResultMapping
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get key {
  
  return $TypedExpressionCopyWith<$Res>(_self.key, (value) {
    return _then(_self.copyWith(key: value));
  });
}/// Create a copy of SearchResultMapping
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get selectedValue {
  
  return $TypedExpressionCopyWith<$Res>(_self.selectedValue, (value) {
    return _then(_self.copyWith(selectedValue: value));
  });
}/// Create a copy of SearchResultMapping
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PresentationNodeCopyWith<$Res> get presentation {
  
  return $PresentationNodeCopyWith<$Res>(_self.presentation, (value) {
    return _then(_self.copyWith(presentation: value));
  });
}
}


/// Adds pattern-matching-related methods to [SearchResultMapping].
extension SearchResultMappingPatterns on SearchResultMapping {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchResultMapping value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchResultMapping() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchResultMapping value)  $default,){
final _that = this;
switch (_that) {
case _SearchResultMapping():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchResultMapping value)?  $default,){
final _that = this;
switch (_that) {
case _SearchResultMapping() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BindingId bindingId,  TypedExpression key,  TypedExpression selectedValue,  PresentationNode presentation)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchResultMapping() when $default != null:
return $default(_that.bindingId,_that.key,_that.selectedValue,_that.presentation);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BindingId bindingId,  TypedExpression key,  TypedExpression selectedValue,  PresentationNode presentation)  $default,) {final _that = this;
switch (_that) {
case _SearchResultMapping():
return $default(_that.bindingId,_that.key,_that.selectedValue,_that.presentation);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BindingId bindingId,  TypedExpression key,  TypedExpression selectedValue,  PresentationNode presentation)?  $default,) {final _that = this;
switch (_that) {
case _SearchResultMapping() when $default != null:
return $default(_that.bindingId,_that.key,_that.selectedValue,_that.presentation);case _:
  return null;

}
}

}

/// @nodoc


class _SearchResultMapping implements SearchResultMapping {
  const _SearchResultMapping({required this.bindingId, required this.key, required this.selectedValue, required this.presentation});
  

@override final  BindingId bindingId;
@override final  TypedExpression key;
@override final  TypedExpression selectedValue;
@override final  PresentationNode presentation;

/// Create a copy of SearchResultMapping
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchResultMappingCopyWith<_SearchResultMapping> get copyWith => __$SearchResultMappingCopyWithImpl<_SearchResultMapping>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchResultMapping&&(identical(other.bindingId, bindingId) || other.bindingId == bindingId)&&(identical(other.key, key) || other.key == key)&&(identical(other.selectedValue, selectedValue) || other.selectedValue == selectedValue)&&(identical(other.presentation, presentation) || other.presentation == presentation));
}


@override
int get hashCode => Object.hash(runtimeType,bindingId,key,selectedValue,presentation);

@override
String toString() {
  return 'SearchResultMapping(bindingId: $bindingId, key: $key, selectedValue: $selectedValue, presentation: $presentation)';
}


}

/// @nodoc
abstract mixin class _$SearchResultMappingCopyWith<$Res> implements $SearchResultMappingCopyWith<$Res> {
  factory _$SearchResultMappingCopyWith(_SearchResultMapping value, $Res Function(_SearchResultMapping) _then) = __$SearchResultMappingCopyWithImpl;
@override @useResult
$Res call({
 BindingId bindingId, TypedExpression key, TypedExpression selectedValue, PresentationNode presentation
});


@override $BindingIdCopyWith<$Res> get bindingId;@override $TypedExpressionCopyWith<$Res> get key;@override $TypedExpressionCopyWith<$Res> get selectedValue;@override $PresentationNodeCopyWith<$Res> get presentation;

}
/// @nodoc
class __$SearchResultMappingCopyWithImpl<$Res>
    implements _$SearchResultMappingCopyWith<$Res> {
  __$SearchResultMappingCopyWithImpl(this._self, this._then);

  final _SearchResultMapping _self;
  final $Res Function(_SearchResultMapping) _then;

/// Create a copy of SearchResultMapping
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? bindingId = null,Object? key = null,Object? selectedValue = null,Object? presentation = null,}) {
  return _then(_SearchResultMapping(
bindingId: null == bindingId ? _self.bindingId : bindingId // ignore: cast_nullable_to_non_nullable
as BindingId,key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as TypedExpression,selectedValue: null == selectedValue ? _self.selectedValue : selectedValue // ignore: cast_nullable_to_non_nullable
as TypedExpression,presentation: null == presentation ? _self.presentation : presentation // ignore: cast_nullable_to_non_nullable
as PresentationNode,
  ));
}

/// Create a copy of SearchResultMapping
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BindingIdCopyWith<$Res> get bindingId {
  
  return $BindingIdCopyWith<$Res>(_self.bindingId, (value) {
    return _then(_self.copyWith(bindingId: value));
  });
}/// Create a copy of SearchResultMapping
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get key {
  
  return $TypedExpressionCopyWith<$Res>(_self.key, (value) {
    return _then(_self.copyWith(key: value));
  });
}/// Create a copy of SearchResultMapping
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get selectedValue {
  
  return $TypedExpressionCopyWith<$Res>(_self.selectedValue, (value) {
    return _then(_self.copyWith(selectedValue: value));
  });
}/// Create a copy of SearchResultMapping
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PresentationNodeCopyWith<$Res> get presentation {
  
  return $PresentationNodeCopyWith<$Res>(_self.presentation, (value) {
    return _then(_self.copyWith(presentation: value));
  });
}
}

/// @nodoc
mixin _$HttpQueryParameter {

 String get name; TypedExpression get value; bool get omitIfEmpty;
/// Create a copy of HttpQueryParameter
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HttpQueryParameterCopyWith<HttpQueryParameter> get copyWith => _$HttpQueryParameterCopyWithImpl<HttpQueryParameter>(this as HttpQueryParameter, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HttpQueryParameter&&(identical(other.name, name) || other.name == name)&&(identical(other.value, value) || other.value == value)&&(identical(other.omitIfEmpty, omitIfEmpty) || other.omitIfEmpty == omitIfEmpty));
}


@override
int get hashCode => Object.hash(runtimeType,name,value,omitIfEmpty);

@override
String toString() {
  return 'HttpQueryParameter(name: $name, value: $value, omitIfEmpty: $omitIfEmpty)';
}


}

/// @nodoc
abstract mixin class $HttpQueryParameterCopyWith<$Res>  {
  factory $HttpQueryParameterCopyWith(HttpQueryParameter value, $Res Function(HttpQueryParameter) _then) = _$HttpQueryParameterCopyWithImpl;
@useResult
$Res call({
 String name, TypedExpression value, bool omitIfEmpty
});


$TypedExpressionCopyWith<$Res> get value;

}
/// @nodoc
class _$HttpQueryParameterCopyWithImpl<$Res>
    implements $HttpQueryParameterCopyWith<$Res> {
  _$HttpQueryParameterCopyWithImpl(this._self, this._then);

  final HttpQueryParameter _self;
  final $Res Function(HttpQueryParameter) _then;

/// Create a copy of HttpQueryParameter
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? value = null,Object? omitIfEmpty = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as TypedExpression,omitIfEmpty: null == omitIfEmpty ? _self.omitIfEmpty : omitIfEmpty // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of HttpQueryParameter
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get value {
  
  return $TypedExpressionCopyWith<$Res>(_self.value, (value) {
    return _then(_self.copyWith(value: value));
  });
}
}


/// Adds pattern-matching-related methods to [HttpQueryParameter].
extension HttpQueryParameterPatterns on HttpQueryParameter {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HttpQueryParameter value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HttpQueryParameter() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HttpQueryParameter value)  $default,){
final _that = this;
switch (_that) {
case _HttpQueryParameter():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HttpQueryParameter value)?  $default,){
final _that = this;
switch (_that) {
case _HttpQueryParameter() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  TypedExpression value,  bool omitIfEmpty)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HttpQueryParameter() when $default != null:
return $default(_that.name,_that.value,_that.omitIfEmpty);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  TypedExpression value,  bool omitIfEmpty)  $default,) {final _that = this;
switch (_that) {
case _HttpQueryParameter():
return $default(_that.name,_that.value,_that.omitIfEmpty);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  TypedExpression value,  bool omitIfEmpty)?  $default,) {final _that = this;
switch (_that) {
case _HttpQueryParameter() when $default != null:
return $default(_that.name,_that.value,_that.omitIfEmpty);case _:
  return null;

}
}

}

/// @nodoc


class _HttpQueryParameter implements HttpQueryParameter {
  const _HttpQueryParameter({required this.name, required this.value, this.omitIfEmpty = false}): assert(name != "", 'Query parameter name must not be empty.');
  

@override final  String name;
@override final  TypedExpression value;
@override@JsonKey() final  bool omitIfEmpty;

/// Create a copy of HttpQueryParameter
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HttpQueryParameterCopyWith<_HttpQueryParameter> get copyWith => __$HttpQueryParameterCopyWithImpl<_HttpQueryParameter>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HttpQueryParameter&&(identical(other.name, name) || other.name == name)&&(identical(other.value, value) || other.value == value)&&(identical(other.omitIfEmpty, omitIfEmpty) || other.omitIfEmpty == omitIfEmpty));
}


@override
int get hashCode => Object.hash(runtimeType,name,value,omitIfEmpty);

@override
String toString() {
  return 'HttpQueryParameter(name: $name, value: $value, omitIfEmpty: $omitIfEmpty)';
}


}

/// @nodoc
abstract mixin class _$HttpQueryParameterCopyWith<$Res> implements $HttpQueryParameterCopyWith<$Res> {
  factory _$HttpQueryParameterCopyWith(_HttpQueryParameter value, $Res Function(_HttpQueryParameter) _then) = __$HttpQueryParameterCopyWithImpl;
@override @useResult
$Res call({
 String name, TypedExpression value, bool omitIfEmpty
});


@override $TypedExpressionCopyWith<$Res> get value;

}
/// @nodoc
class __$HttpQueryParameterCopyWithImpl<$Res>
    implements _$HttpQueryParameterCopyWith<$Res> {
  __$HttpQueryParameterCopyWithImpl(this._self, this._then);

  final _HttpQueryParameter _self;
  final $Res Function(_HttpQueryParameter) _then;

/// Create a copy of HttpQueryParameter
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? value = null,Object? omitIfEmpty = null,}) {
  return _then(_HttpQueryParameter(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as TypedExpression,omitIfEmpty: null == omitIfEmpty ? _self.omitIfEmpty : omitIfEmpty // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of HttpQueryParameter
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get value {
  
  return $TypedExpressionCopyWith<$Res>(_self.value, (value) {
    return _then(_self.copyWith(value: value));
  });
}
}

/// @nodoc
mixin _$HttpJsonContextBinding {

 BindingId get bindingId; String get path; TypeExpression get type;
/// Create a copy of HttpJsonContextBinding
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HttpJsonContextBindingCopyWith<HttpJsonContextBinding> get copyWith => _$HttpJsonContextBindingCopyWithImpl<HttpJsonContextBinding>(this as HttpJsonContextBinding, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HttpJsonContextBinding&&(identical(other.bindingId, bindingId) || other.bindingId == bindingId)&&(identical(other.path, path) || other.path == path)&&(identical(other.type, type) || other.type == type));
}


@override
int get hashCode => Object.hash(runtimeType,bindingId,path,type);

@override
String toString() {
  return 'HttpJsonContextBinding(bindingId: $bindingId, path: $path, type: $type)';
}


}

/// @nodoc
abstract mixin class $HttpJsonContextBindingCopyWith<$Res>  {
  factory $HttpJsonContextBindingCopyWith(HttpJsonContextBinding value, $Res Function(HttpJsonContextBinding) _then) = _$HttpJsonContextBindingCopyWithImpl;
@useResult
$Res call({
 BindingId bindingId, String path, TypeExpression type
});


$BindingIdCopyWith<$Res> get bindingId;$TypeExpressionCopyWith<$Res> get type;

}
/// @nodoc
class _$HttpJsonContextBindingCopyWithImpl<$Res>
    implements $HttpJsonContextBindingCopyWith<$Res> {
  _$HttpJsonContextBindingCopyWithImpl(this._self, this._then);

  final HttpJsonContextBinding _self;
  final $Res Function(HttpJsonContextBinding) _then;

/// Create a copy of HttpJsonContextBinding
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? bindingId = null,Object? path = null,Object? type = null,}) {
  return _then(_self.copyWith(
bindingId: null == bindingId ? _self.bindingId : bindingId // ignore: cast_nullable_to_non_nullable
as BindingId,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TypeExpression,
  ));
}
/// Create a copy of HttpJsonContextBinding
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BindingIdCopyWith<$Res> get bindingId {
  
  return $BindingIdCopyWith<$Res>(_self.bindingId, (value) {
    return _then(_self.copyWith(bindingId: value));
  });
}/// Create a copy of HttpJsonContextBinding
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypeExpressionCopyWith<$Res> get type {
  
  return $TypeExpressionCopyWith<$Res>(_self.type, (value) {
    return _then(_self.copyWith(type: value));
  });
}
}


/// Adds pattern-matching-related methods to [HttpJsonContextBinding].
extension HttpJsonContextBindingPatterns on HttpJsonContextBinding {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HttpJsonContextBinding value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HttpJsonContextBinding() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HttpJsonContextBinding value)  $default,){
final _that = this;
switch (_that) {
case _HttpJsonContextBinding():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HttpJsonContextBinding value)?  $default,){
final _that = this;
switch (_that) {
case _HttpJsonContextBinding() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BindingId bindingId,  String path,  TypeExpression type)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HttpJsonContextBinding() when $default != null:
return $default(_that.bindingId,_that.path,_that.type);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BindingId bindingId,  String path,  TypeExpression type)  $default,) {final _that = this;
switch (_that) {
case _HttpJsonContextBinding():
return $default(_that.bindingId,_that.path,_that.type);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BindingId bindingId,  String path,  TypeExpression type)?  $default,) {final _that = this;
switch (_that) {
case _HttpJsonContextBinding() when $default != null:
return $default(_that.bindingId,_that.path,_that.type);case _:
  return null;

}
}

}

/// @nodoc


class _HttpJsonContextBinding implements HttpJsonContextBinding {
  const _HttpJsonContextBinding({required this.bindingId, required this.path, required this.type}): assert(path != "", 'Context binding path must not be empty.');
  

@override final  BindingId bindingId;
@override final  String path;
@override final  TypeExpression type;

/// Create a copy of HttpJsonContextBinding
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HttpJsonContextBindingCopyWith<_HttpJsonContextBinding> get copyWith => __$HttpJsonContextBindingCopyWithImpl<_HttpJsonContextBinding>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HttpJsonContextBinding&&(identical(other.bindingId, bindingId) || other.bindingId == bindingId)&&(identical(other.path, path) || other.path == path)&&(identical(other.type, type) || other.type == type));
}


@override
int get hashCode => Object.hash(runtimeType,bindingId,path,type);

@override
String toString() {
  return 'HttpJsonContextBinding(bindingId: $bindingId, path: $path, type: $type)';
}


}

/// @nodoc
abstract mixin class _$HttpJsonContextBindingCopyWith<$Res> implements $HttpJsonContextBindingCopyWith<$Res> {
  factory _$HttpJsonContextBindingCopyWith(_HttpJsonContextBinding value, $Res Function(_HttpJsonContextBinding) _then) = __$HttpJsonContextBindingCopyWithImpl;
@override @useResult
$Res call({
 BindingId bindingId, String path, TypeExpression type
});


@override $BindingIdCopyWith<$Res> get bindingId;@override $TypeExpressionCopyWith<$Res> get type;

}
/// @nodoc
class __$HttpJsonContextBindingCopyWithImpl<$Res>
    implements _$HttpJsonContextBindingCopyWith<$Res> {
  __$HttpJsonContextBindingCopyWithImpl(this._self, this._then);

  final _HttpJsonContextBinding _self;
  final $Res Function(_HttpJsonContextBinding) _then;

/// Create a copy of HttpJsonContextBinding
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? bindingId = null,Object? path = null,Object? type = null,}) {
  return _then(_HttpJsonContextBinding(
bindingId: null == bindingId ? _self.bindingId : bindingId // ignore: cast_nullable_to_non_nullable
as BindingId,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TypeExpression,
  ));
}

/// Create a copy of HttpJsonContextBinding
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BindingIdCopyWith<$Res> get bindingId {
  
  return $BindingIdCopyWith<$Res>(_self.bindingId, (value) {
    return _then(_self.copyWith(bindingId: value));
  });
}/// Create a copy of HttpJsonContextBinding
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypeExpressionCopyWith<$Res> get type {
  
  return $TypeExpressionCopyWith<$Res>(_self.type, (value) {
    return _then(_self.copyWith(type: value));
  });
}
}

/// @nodoc
mixin _$SearchRankingField {

 TypedExpression get expression; int get weight;
/// Create a copy of SearchRankingField
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchRankingFieldCopyWith<SearchRankingField> get copyWith => _$SearchRankingFieldCopyWithImpl<SearchRankingField>(this as SearchRankingField, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchRankingField&&(identical(other.expression, expression) || other.expression == expression)&&(identical(other.weight, weight) || other.weight == weight));
}


@override
int get hashCode => Object.hash(runtimeType,expression,weight);

@override
String toString() {
  return 'SearchRankingField(expression: $expression, weight: $weight)';
}


}

/// @nodoc
abstract mixin class $SearchRankingFieldCopyWith<$Res>  {
  factory $SearchRankingFieldCopyWith(SearchRankingField value, $Res Function(SearchRankingField) _then) = _$SearchRankingFieldCopyWithImpl;
@useResult
$Res call({
 TypedExpression expression, int weight
});


$TypedExpressionCopyWith<$Res> get expression;

}
/// @nodoc
class _$SearchRankingFieldCopyWithImpl<$Res>
    implements $SearchRankingFieldCopyWith<$Res> {
  _$SearchRankingFieldCopyWithImpl(this._self, this._then);

  final SearchRankingField _self;
  final $Res Function(SearchRankingField) _then;

/// Create a copy of SearchRankingField
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? expression = null,Object? weight = null,}) {
  return _then(_self.copyWith(
expression: null == expression ? _self.expression : expression // ignore: cast_nullable_to_non_nullable
as TypedExpression,weight: null == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of SearchRankingField
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get expression {
  
  return $TypedExpressionCopyWith<$Res>(_self.expression, (value) {
    return _then(_self.copyWith(expression: value));
  });
}
}


/// Adds pattern-matching-related methods to [SearchRankingField].
extension SearchRankingFieldPatterns on SearchRankingField {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchRankingField value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchRankingField() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchRankingField value)  $default,){
final _that = this;
switch (_that) {
case _SearchRankingField():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchRankingField value)?  $default,){
final _that = this;
switch (_that) {
case _SearchRankingField() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( TypedExpression expression,  int weight)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchRankingField() when $default != null:
return $default(_that.expression,_that.weight);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( TypedExpression expression,  int weight)  $default,) {final _that = this;
switch (_that) {
case _SearchRankingField():
return $default(_that.expression,_that.weight);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( TypedExpression expression,  int weight)?  $default,) {final _that = this;
switch (_that) {
case _SearchRankingField() when $default != null:
return $default(_that.expression,_that.weight);case _:
  return null;

}
}

}

/// @nodoc


class _SearchRankingField implements SearchRankingField {
  const _SearchRankingField({required this.expression, required this.weight}): assert(weight > 0, 'Ranking weight must be positive.');
  

@override final  TypedExpression expression;
@override final  int weight;

/// Create a copy of SearchRankingField
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchRankingFieldCopyWith<_SearchRankingField> get copyWith => __$SearchRankingFieldCopyWithImpl<_SearchRankingField>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchRankingField&&(identical(other.expression, expression) || other.expression == expression)&&(identical(other.weight, weight) || other.weight == weight));
}


@override
int get hashCode => Object.hash(runtimeType,expression,weight);

@override
String toString() {
  return 'SearchRankingField(expression: $expression, weight: $weight)';
}


}

/// @nodoc
abstract mixin class _$SearchRankingFieldCopyWith<$Res> implements $SearchRankingFieldCopyWith<$Res> {
  factory _$SearchRankingFieldCopyWith(_SearchRankingField value, $Res Function(_SearchRankingField) _then) = __$SearchRankingFieldCopyWithImpl;
@override @useResult
$Res call({
 TypedExpression expression, int weight
});


@override $TypedExpressionCopyWith<$Res> get expression;

}
/// @nodoc
class __$SearchRankingFieldCopyWithImpl<$Res>
    implements _$SearchRankingFieldCopyWith<$Res> {
  __$SearchRankingFieldCopyWithImpl(this._self, this._then);

  final _SearchRankingField _self;
  final $Res Function(_SearchRankingField) _then;

/// Create a copy of SearchRankingField
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? expression = null,Object? weight = null,}) {
  return _then(_SearchRankingField(
expression: null == expression ? _self.expression : expression // ignore: cast_nullable_to_non_nullable
as TypedExpression,weight: null == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of SearchRankingField
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get expression {
  
  return $TypedExpressionCopyWith<$Res>(_self.expression, (value) {
    return _then(_self.copyWith(expression: value));
  });
}
}

/// @nodoc
mixin _$SearchProvider {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchProvider);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SearchProvider()';
}


}

/// @nodoc
class $SearchProviderCopyWith<$Res>  {
$SearchProviderCopyWith(SearchProvider _, $Res Function(SearchProvider) __);
}


/// Adds pattern-matching-related methods to [SearchProvider].
extension SearchProviderPatterns on SearchProvider {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( StaticSearchProvider value)?  staticValues,TResult Function( HttpJsonSearchProvider value)?  httpJson,TResult Function( RealmCallbackSearchProvider value)?  realmCallback,TResult Function( GatedSearchProvider value)?  gate,TResult Function( DebouncedSearchProvider value)?  debounce,TResult Function( CachedSearchProvider value)?  cache,TResult Function( RankedSearchProvider value)?  rank,TResult Function( LimitedSearchProvider value)?  limit,TResult Function( DistinctSearchProvider value)?  distinct,TResult Function( HistoricalSearchProvider value)?  history,TResult Function( SectionSearchProvider value)?  section,TResult Function( MergedSearchProvider value)?  merge,required TResult orElse(),}){
final _that = this;
switch (_that) {
case StaticSearchProvider() when staticValues != null:
return staticValues(_that);case HttpJsonSearchProvider() when httpJson != null:
return httpJson(_that);case RealmCallbackSearchProvider() when realmCallback != null:
return realmCallback(_that);case GatedSearchProvider() when gate != null:
return gate(_that);case DebouncedSearchProvider() when debounce != null:
return debounce(_that);case CachedSearchProvider() when cache != null:
return cache(_that);case RankedSearchProvider() when rank != null:
return rank(_that);case LimitedSearchProvider() when limit != null:
return limit(_that);case DistinctSearchProvider() when distinct != null:
return distinct(_that);case HistoricalSearchProvider() when history != null:
return history(_that);case SectionSearchProvider() when section != null:
return section(_that);case MergedSearchProvider() when merge != null:
return merge(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( StaticSearchProvider value)  staticValues,required TResult Function( HttpJsonSearchProvider value)  httpJson,required TResult Function( RealmCallbackSearchProvider value)  realmCallback,required TResult Function( GatedSearchProvider value)  gate,required TResult Function( DebouncedSearchProvider value)  debounce,required TResult Function( CachedSearchProvider value)  cache,required TResult Function( RankedSearchProvider value)  rank,required TResult Function( LimitedSearchProvider value)  limit,required TResult Function( DistinctSearchProvider value)  distinct,required TResult Function( HistoricalSearchProvider value)  history,required TResult Function( SectionSearchProvider value)  section,required TResult Function( MergedSearchProvider value)  merge,}){
final _that = this;
switch (_that) {
case StaticSearchProvider():
return staticValues(_that);case HttpJsonSearchProvider():
return httpJson(_that);case RealmCallbackSearchProvider():
return realmCallback(_that);case GatedSearchProvider():
return gate(_that);case DebouncedSearchProvider():
return debounce(_that);case CachedSearchProvider():
return cache(_that);case RankedSearchProvider():
return rank(_that);case LimitedSearchProvider():
return limit(_that);case DistinctSearchProvider():
return distinct(_that);case HistoricalSearchProvider():
return history(_that);case SectionSearchProvider():
return section(_that);case MergedSearchProvider():
return merge(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( StaticSearchProvider value)?  staticValues,TResult? Function( HttpJsonSearchProvider value)?  httpJson,TResult? Function( RealmCallbackSearchProvider value)?  realmCallback,TResult? Function( GatedSearchProvider value)?  gate,TResult? Function( DebouncedSearchProvider value)?  debounce,TResult? Function( CachedSearchProvider value)?  cache,TResult? Function( RankedSearchProvider value)?  rank,TResult? Function( LimitedSearchProvider value)?  limit,TResult? Function( DistinctSearchProvider value)?  distinct,TResult? Function( HistoricalSearchProvider value)?  history,TResult? Function( SectionSearchProvider value)?  section,TResult? Function( MergedSearchProvider value)?  merge,}){
final _that = this;
switch (_that) {
case StaticSearchProvider() when staticValues != null:
return staticValues(_that);case HttpJsonSearchProvider() when httpJson != null:
return httpJson(_that);case RealmCallbackSearchProvider() when realmCallback != null:
return realmCallback(_that);case GatedSearchProvider() when gate != null:
return gate(_that);case DebouncedSearchProvider() when debounce != null:
return debounce(_that);case CachedSearchProvider() when cache != null:
return cache(_that);case RankedSearchProvider() when rank != null:
return rank(_that);case LimitedSearchProvider() when limit != null:
return limit(_that);case DistinctSearchProvider() when distinct != null:
return distinct(_that);case HistoricalSearchProvider() when history != null:
return history(_that);case SectionSearchProvider() when section != null:
return section(_that);case MergedSearchProvider() when merge != null:
return merge(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( TypedExpression values,  SearchResultMapping result,  List<SearchSelectorDefinition> selectors)?  staticValues,TResult Function( TypedExpression uri,  List<HttpQueryParameter> parameters,  String resultPath,  TypeExpression resultType,  SearchResultMapping result,  List<HttpJsonContextBinding> contextBindings,  List<SearchSelectorDefinition> selectors,  Duration timeout)?  httpJson,TResult Function( RealmActionId actionId,  TypedExpression payload,  SearchResultMapping result,  List<SearchSelectorDefinition> selectors)?  realmCallback,TResult Function( TypedExpression condition,  SearchProvider child,  TypedExpression? guidance)?  gate,TResult Function( Duration duration,  SearchProvider child)?  debounce,TResult Function( int capacity,  SearchProvider child,  bool retainStaleResults)?  cache,TResult Function( List<SearchRankingField> fields,  SearchProvider child)?  rank,TResult Function( TypedExpression maximum,  SearchProvider child)?  limit,TResult Function( SearchProvider child)?  distinct,TResult Function( String key,  TypedExpression label,  int capacity,  SearchProvider child)?  history,TResult Function( String id,  TypedExpression label,  SearchProvider child)?  section,TResult Function( List<SearchProvider> children)?  merge,required TResult orElse(),}) {final _that = this;
switch (_that) {
case StaticSearchProvider() when staticValues != null:
return staticValues(_that.values,_that.result,_that.selectors);case HttpJsonSearchProvider() when httpJson != null:
return httpJson(_that.uri,_that.parameters,_that.resultPath,_that.resultType,_that.result,_that.contextBindings,_that.selectors,_that.timeout);case RealmCallbackSearchProvider() when realmCallback != null:
return realmCallback(_that.actionId,_that.payload,_that.result,_that.selectors);case GatedSearchProvider() when gate != null:
return gate(_that.condition,_that.child,_that.guidance);case DebouncedSearchProvider() when debounce != null:
return debounce(_that.duration,_that.child);case CachedSearchProvider() when cache != null:
return cache(_that.capacity,_that.child,_that.retainStaleResults);case RankedSearchProvider() when rank != null:
return rank(_that.fields,_that.child);case LimitedSearchProvider() when limit != null:
return limit(_that.maximum,_that.child);case DistinctSearchProvider() when distinct != null:
return distinct(_that.child);case HistoricalSearchProvider() when history != null:
return history(_that.key,_that.label,_that.capacity,_that.child);case SectionSearchProvider() when section != null:
return section(_that.id,_that.label,_that.child);case MergedSearchProvider() when merge != null:
return merge(_that.children);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( TypedExpression values,  SearchResultMapping result,  List<SearchSelectorDefinition> selectors)  staticValues,required TResult Function( TypedExpression uri,  List<HttpQueryParameter> parameters,  String resultPath,  TypeExpression resultType,  SearchResultMapping result,  List<HttpJsonContextBinding> contextBindings,  List<SearchSelectorDefinition> selectors,  Duration timeout)  httpJson,required TResult Function( RealmActionId actionId,  TypedExpression payload,  SearchResultMapping result,  List<SearchSelectorDefinition> selectors)  realmCallback,required TResult Function( TypedExpression condition,  SearchProvider child,  TypedExpression? guidance)  gate,required TResult Function( Duration duration,  SearchProvider child)  debounce,required TResult Function( int capacity,  SearchProvider child,  bool retainStaleResults)  cache,required TResult Function( List<SearchRankingField> fields,  SearchProvider child)  rank,required TResult Function( TypedExpression maximum,  SearchProvider child)  limit,required TResult Function( SearchProvider child)  distinct,required TResult Function( String key,  TypedExpression label,  int capacity,  SearchProvider child)  history,required TResult Function( String id,  TypedExpression label,  SearchProvider child)  section,required TResult Function( List<SearchProvider> children)  merge,}) {final _that = this;
switch (_that) {
case StaticSearchProvider():
return staticValues(_that.values,_that.result,_that.selectors);case HttpJsonSearchProvider():
return httpJson(_that.uri,_that.parameters,_that.resultPath,_that.resultType,_that.result,_that.contextBindings,_that.selectors,_that.timeout);case RealmCallbackSearchProvider():
return realmCallback(_that.actionId,_that.payload,_that.result,_that.selectors);case GatedSearchProvider():
return gate(_that.condition,_that.child,_that.guidance);case DebouncedSearchProvider():
return debounce(_that.duration,_that.child);case CachedSearchProvider():
return cache(_that.capacity,_that.child,_that.retainStaleResults);case RankedSearchProvider():
return rank(_that.fields,_that.child);case LimitedSearchProvider():
return limit(_that.maximum,_that.child);case DistinctSearchProvider():
return distinct(_that.child);case HistoricalSearchProvider():
return history(_that.key,_that.label,_that.capacity,_that.child);case SectionSearchProvider():
return section(_that.id,_that.label,_that.child);case MergedSearchProvider():
return merge(_that.children);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( TypedExpression values,  SearchResultMapping result,  List<SearchSelectorDefinition> selectors)?  staticValues,TResult? Function( TypedExpression uri,  List<HttpQueryParameter> parameters,  String resultPath,  TypeExpression resultType,  SearchResultMapping result,  List<HttpJsonContextBinding> contextBindings,  List<SearchSelectorDefinition> selectors,  Duration timeout)?  httpJson,TResult? Function( RealmActionId actionId,  TypedExpression payload,  SearchResultMapping result,  List<SearchSelectorDefinition> selectors)?  realmCallback,TResult? Function( TypedExpression condition,  SearchProvider child,  TypedExpression? guidance)?  gate,TResult? Function( Duration duration,  SearchProvider child)?  debounce,TResult? Function( int capacity,  SearchProvider child,  bool retainStaleResults)?  cache,TResult? Function( List<SearchRankingField> fields,  SearchProvider child)?  rank,TResult? Function( TypedExpression maximum,  SearchProvider child)?  limit,TResult? Function( SearchProvider child)?  distinct,TResult? Function( String key,  TypedExpression label,  int capacity,  SearchProvider child)?  history,TResult? Function( String id,  TypedExpression label,  SearchProvider child)?  section,TResult? Function( List<SearchProvider> children)?  merge,}) {final _that = this;
switch (_that) {
case StaticSearchProvider() when staticValues != null:
return staticValues(_that.values,_that.result,_that.selectors);case HttpJsonSearchProvider() when httpJson != null:
return httpJson(_that.uri,_that.parameters,_that.resultPath,_that.resultType,_that.result,_that.contextBindings,_that.selectors,_that.timeout);case RealmCallbackSearchProvider() when realmCallback != null:
return realmCallback(_that.actionId,_that.payload,_that.result,_that.selectors);case GatedSearchProvider() when gate != null:
return gate(_that.condition,_that.child,_that.guidance);case DebouncedSearchProvider() when debounce != null:
return debounce(_that.duration,_that.child);case CachedSearchProvider() when cache != null:
return cache(_that.capacity,_that.child,_that.retainStaleResults);case RankedSearchProvider() when rank != null:
return rank(_that.fields,_that.child);case LimitedSearchProvider() when limit != null:
return limit(_that.maximum,_that.child);case DistinctSearchProvider() when distinct != null:
return distinct(_that.child);case HistoricalSearchProvider() when history != null:
return history(_that.key,_that.label,_that.capacity,_that.child);case SectionSearchProvider() when section != null:
return section(_that.id,_that.label,_that.child);case MergedSearchProvider() when merge != null:
return merge(_that.children);case _:
  return null;

}
}

}

/// @nodoc


class StaticSearchProvider implements SearchProvider {
  const StaticSearchProvider({required this.values, required this.result, final  List<SearchSelectorDefinition> selectors = const []}): _selectors = selectors;
  

 final  TypedExpression values;
 final  SearchResultMapping result;
 final  List<SearchSelectorDefinition> _selectors;
@JsonKey() List<SearchSelectorDefinition> get selectors {
  if (_selectors is EqualUnmodifiableListView) return _selectors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_selectors);
}


/// Create a copy of SearchProvider
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StaticSearchProviderCopyWith<StaticSearchProvider> get copyWith => _$StaticSearchProviderCopyWithImpl<StaticSearchProvider>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StaticSearchProvider&&(identical(other.values, values) || other.values == values)&&(identical(other.result, result) || other.result == result)&&const DeepCollectionEquality().equals(other._selectors, _selectors));
}


@override
int get hashCode => Object.hash(runtimeType,values,result,const DeepCollectionEquality().hash(_selectors));

@override
String toString() {
  return 'SearchProvider.staticValues(values: $values, result: $result, selectors: $selectors)';
}


}

/// @nodoc
abstract mixin class $StaticSearchProviderCopyWith<$Res> implements $SearchProviderCopyWith<$Res> {
  factory $StaticSearchProviderCopyWith(StaticSearchProvider value, $Res Function(StaticSearchProvider) _then) = _$StaticSearchProviderCopyWithImpl;
@useResult
$Res call({
 TypedExpression values, SearchResultMapping result, List<SearchSelectorDefinition> selectors
});


$TypedExpressionCopyWith<$Res> get values;$SearchResultMappingCopyWith<$Res> get result;

}
/// @nodoc
class _$StaticSearchProviderCopyWithImpl<$Res>
    implements $StaticSearchProviderCopyWith<$Res> {
  _$StaticSearchProviderCopyWithImpl(this._self, this._then);

  final StaticSearchProvider _self;
  final $Res Function(StaticSearchProvider) _then;

/// Create a copy of SearchProvider
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? values = null,Object? result = null,Object? selectors = null,}) {
  return _then(StaticSearchProvider(
values: null == values ? _self.values : values // ignore: cast_nullable_to_non_nullable
as TypedExpression,result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as SearchResultMapping,selectors: null == selectors ? _self._selectors : selectors // ignore: cast_nullable_to_non_nullable
as List<SearchSelectorDefinition>,
  ));
}

/// Create a copy of SearchProvider
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get values {
  
  return $TypedExpressionCopyWith<$Res>(_self.values, (value) {
    return _then(_self.copyWith(values: value));
  });
}/// Create a copy of SearchProvider
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchResultMappingCopyWith<$Res> get result {
  
  return $SearchResultMappingCopyWith<$Res>(_self.result, (value) {
    return _then(_self.copyWith(result: value));
  });
}
}

/// @nodoc


class HttpJsonSearchProvider implements SearchProvider {
  const HttpJsonSearchProvider({required this.uri, required final  List<HttpQueryParameter> parameters, required this.resultPath, required this.resultType, required this.result, final  List<HttpJsonContextBinding> contextBindings = const [], final  List<SearchSelectorDefinition> selectors = const [], this.timeout = const Duration(seconds: 5)}): assert(resultPath != "", 'Result path must not be empty.'),_parameters = parameters,_contextBindings = contextBindings,_selectors = selectors;
  

 final  TypedExpression uri;
 final  List<HttpQueryParameter> _parameters;
 List<HttpQueryParameter> get parameters {
  if (_parameters is EqualUnmodifiableListView) return _parameters;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_parameters);
}

 final  String resultPath;
 final  TypeExpression resultType;
 final  SearchResultMapping result;
 final  List<HttpJsonContextBinding> _contextBindings;
@JsonKey() List<HttpJsonContextBinding> get contextBindings {
  if (_contextBindings is EqualUnmodifiableListView) return _contextBindings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_contextBindings);
}

 final  List<SearchSelectorDefinition> _selectors;
@JsonKey() List<SearchSelectorDefinition> get selectors {
  if (_selectors is EqualUnmodifiableListView) return _selectors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_selectors);
}

@JsonKey() final  Duration timeout;

/// Create a copy of SearchProvider
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HttpJsonSearchProviderCopyWith<HttpJsonSearchProvider> get copyWith => _$HttpJsonSearchProviderCopyWithImpl<HttpJsonSearchProvider>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HttpJsonSearchProvider&&(identical(other.uri, uri) || other.uri == uri)&&const DeepCollectionEquality().equals(other._parameters, _parameters)&&(identical(other.resultPath, resultPath) || other.resultPath == resultPath)&&(identical(other.resultType, resultType) || other.resultType == resultType)&&(identical(other.result, result) || other.result == result)&&const DeepCollectionEquality().equals(other._contextBindings, _contextBindings)&&const DeepCollectionEquality().equals(other._selectors, _selectors)&&(identical(other.timeout, timeout) || other.timeout == timeout));
}


@override
int get hashCode => Object.hash(runtimeType,uri,const DeepCollectionEquality().hash(_parameters),resultPath,resultType,result,const DeepCollectionEquality().hash(_contextBindings),const DeepCollectionEquality().hash(_selectors),timeout);

@override
String toString() {
  return 'SearchProvider.httpJson(uri: $uri, parameters: $parameters, resultPath: $resultPath, resultType: $resultType, result: $result, contextBindings: $contextBindings, selectors: $selectors, timeout: $timeout)';
}


}

/// @nodoc
abstract mixin class $HttpJsonSearchProviderCopyWith<$Res> implements $SearchProviderCopyWith<$Res> {
  factory $HttpJsonSearchProviderCopyWith(HttpJsonSearchProvider value, $Res Function(HttpJsonSearchProvider) _then) = _$HttpJsonSearchProviderCopyWithImpl;
@useResult
$Res call({
 TypedExpression uri, List<HttpQueryParameter> parameters, String resultPath, TypeExpression resultType, SearchResultMapping result, List<HttpJsonContextBinding> contextBindings, List<SearchSelectorDefinition> selectors, Duration timeout
});


$TypedExpressionCopyWith<$Res> get uri;$TypeExpressionCopyWith<$Res> get resultType;$SearchResultMappingCopyWith<$Res> get result;

}
/// @nodoc
class _$HttpJsonSearchProviderCopyWithImpl<$Res>
    implements $HttpJsonSearchProviderCopyWith<$Res> {
  _$HttpJsonSearchProviderCopyWithImpl(this._self, this._then);

  final HttpJsonSearchProvider _self;
  final $Res Function(HttpJsonSearchProvider) _then;

/// Create a copy of SearchProvider
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? uri = null,Object? parameters = null,Object? resultPath = null,Object? resultType = null,Object? result = null,Object? contextBindings = null,Object? selectors = null,Object? timeout = null,}) {
  return _then(HttpJsonSearchProvider(
uri: null == uri ? _self.uri : uri // ignore: cast_nullable_to_non_nullable
as TypedExpression,parameters: null == parameters ? _self._parameters : parameters // ignore: cast_nullable_to_non_nullable
as List<HttpQueryParameter>,resultPath: null == resultPath ? _self.resultPath : resultPath // ignore: cast_nullable_to_non_nullable
as String,resultType: null == resultType ? _self.resultType : resultType // ignore: cast_nullable_to_non_nullable
as TypeExpression,result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as SearchResultMapping,contextBindings: null == contextBindings ? _self._contextBindings : contextBindings // ignore: cast_nullable_to_non_nullable
as List<HttpJsonContextBinding>,selectors: null == selectors ? _self._selectors : selectors // ignore: cast_nullable_to_non_nullable
as List<SearchSelectorDefinition>,timeout: null == timeout ? _self.timeout : timeout // ignore: cast_nullable_to_non_nullable
as Duration,
  ));
}

/// Create a copy of SearchProvider
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get uri {
  
  return $TypedExpressionCopyWith<$Res>(_self.uri, (value) {
    return _then(_self.copyWith(uri: value));
  });
}/// Create a copy of SearchProvider
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypeExpressionCopyWith<$Res> get resultType {
  
  return $TypeExpressionCopyWith<$Res>(_self.resultType, (value) {
    return _then(_self.copyWith(resultType: value));
  });
}/// Create a copy of SearchProvider
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchResultMappingCopyWith<$Res> get result {
  
  return $SearchResultMappingCopyWith<$Res>(_self.result, (value) {
    return _then(_self.copyWith(result: value));
  });
}
}

/// @nodoc


class RealmCallbackSearchProvider implements SearchProvider {
  const RealmCallbackSearchProvider({required this.actionId, required this.payload, required this.result, final  List<SearchSelectorDefinition> selectors = const []}): _selectors = selectors;
  

 final  RealmActionId actionId;
 final  TypedExpression payload;
 final  SearchResultMapping result;
 final  List<SearchSelectorDefinition> _selectors;
@JsonKey() List<SearchSelectorDefinition> get selectors {
  if (_selectors is EqualUnmodifiableListView) return _selectors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_selectors);
}


/// Create a copy of SearchProvider
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RealmCallbackSearchProviderCopyWith<RealmCallbackSearchProvider> get copyWith => _$RealmCallbackSearchProviderCopyWithImpl<RealmCallbackSearchProvider>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RealmCallbackSearchProvider&&(identical(other.actionId, actionId) || other.actionId == actionId)&&(identical(other.payload, payload) || other.payload == payload)&&(identical(other.result, result) || other.result == result)&&const DeepCollectionEquality().equals(other._selectors, _selectors));
}


@override
int get hashCode => Object.hash(runtimeType,actionId,payload,result,const DeepCollectionEquality().hash(_selectors));

@override
String toString() {
  return 'SearchProvider.realmCallback(actionId: $actionId, payload: $payload, result: $result, selectors: $selectors)';
}


}

/// @nodoc
abstract mixin class $RealmCallbackSearchProviderCopyWith<$Res> implements $SearchProviderCopyWith<$Res> {
  factory $RealmCallbackSearchProviderCopyWith(RealmCallbackSearchProvider value, $Res Function(RealmCallbackSearchProvider) _then) = _$RealmCallbackSearchProviderCopyWithImpl;
@useResult
$Res call({
 RealmActionId actionId, TypedExpression payload, SearchResultMapping result, List<SearchSelectorDefinition> selectors
});


$RealmActionIdCopyWith<$Res> get actionId;$TypedExpressionCopyWith<$Res> get payload;$SearchResultMappingCopyWith<$Res> get result;

}
/// @nodoc
class _$RealmCallbackSearchProviderCopyWithImpl<$Res>
    implements $RealmCallbackSearchProviderCopyWith<$Res> {
  _$RealmCallbackSearchProviderCopyWithImpl(this._self, this._then);

  final RealmCallbackSearchProvider _self;
  final $Res Function(RealmCallbackSearchProvider) _then;

/// Create a copy of SearchProvider
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? actionId = null,Object? payload = null,Object? result = null,Object? selectors = null,}) {
  return _then(RealmCallbackSearchProvider(
actionId: null == actionId ? _self.actionId : actionId // ignore: cast_nullable_to_non_nullable
as RealmActionId,payload: null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as TypedExpression,result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as SearchResultMapping,selectors: null == selectors ? _self._selectors : selectors // ignore: cast_nullable_to_non_nullable
as List<SearchSelectorDefinition>,
  ));
}

/// Create a copy of SearchProvider
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RealmActionIdCopyWith<$Res> get actionId {
  
  return $RealmActionIdCopyWith<$Res>(_self.actionId, (value) {
    return _then(_self.copyWith(actionId: value));
  });
}/// Create a copy of SearchProvider
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get payload {
  
  return $TypedExpressionCopyWith<$Res>(_self.payload, (value) {
    return _then(_self.copyWith(payload: value));
  });
}/// Create a copy of SearchProvider
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchResultMappingCopyWith<$Res> get result {
  
  return $SearchResultMappingCopyWith<$Res>(_self.result, (value) {
    return _then(_self.copyWith(result: value));
  });
}
}

/// @nodoc


class GatedSearchProvider implements SearchProvider {
  const GatedSearchProvider({required this.condition, required this.child, this.guidance});
  

 final  TypedExpression condition;
 final  SearchProvider child;
 final  TypedExpression? guidance;

/// Create a copy of SearchProvider
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GatedSearchProviderCopyWith<GatedSearchProvider> get copyWith => _$GatedSearchProviderCopyWithImpl<GatedSearchProvider>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GatedSearchProvider&&(identical(other.condition, condition) || other.condition == condition)&&(identical(other.child, child) || other.child == child)&&(identical(other.guidance, guidance) || other.guidance == guidance));
}


@override
int get hashCode => Object.hash(runtimeType,condition,child,guidance);

@override
String toString() {
  return 'SearchProvider.gate(condition: $condition, child: $child, guidance: $guidance)';
}


}

/// @nodoc
abstract mixin class $GatedSearchProviderCopyWith<$Res> implements $SearchProviderCopyWith<$Res> {
  factory $GatedSearchProviderCopyWith(GatedSearchProvider value, $Res Function(GatedSearchProvider) _then) = _$GatedSearchProviderCopyWithImpl;
@useResult
$Res call({
 TypedExpression condition, SearchProvider child, TypedExpression? guidance
});


$TypedExpressionCopyWith<$Res> get condition;$SearchProviderCopyWith<$Res> get child;$TypedExpressionCopyWith<$Res>? get guidance;

}
/// @nodoc
class _$GatedSearchProviderCopyWithImpl<$Res>
    implements $GatedSearchProviderCopyWith<$Res> {
  _$GatedSearchProviderCopyWithImpl(this._self, this._then);

  final GatedSearchProvider _self;
  final $Res Function(GatedSearchProvider) _then;

/// Create a copy of SearchProvider
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? condition = null,Object? child = null,Object? guidance = freezed,}) {
  return _then(GatedSearchProvider(
condition: null == condition ? _self.condition : condition // ignore: cast_nullable_to_non_nullable
as TypedExpression,child: null == child ? _self.child : child // ignore: cast_nullable_to_non_nullable
as SearchProvider,guidance: freezed == guidance ? _self.guidance : guidance // ignore: cast_nullable_to_non_nullable
as TypedExpression?,
  ));
}

/// Create a copy of SearchProvider
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get condition {
  
  return $TypedExpressionCopyWith<$Res>(_self.condition, (value) {
    return _then(_self.copyWith(condition: value));
  });
}/// Create a copy of SearchProvider
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchProviderCopyWith<$Res> get child {
  
  return $SearchProviderCopyWith<$Res>(_self.child, (value) {
    return _then(_self.copyWith(child: value));
  });
}/// Create a copy of SearchProvider
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res>? get guidance {
    if (_self.guidance == null) {
    return null;
  }

  return $TypedExpressionCopyWith<$Res>(_self.guidance!, (value) {
    return _then(_self.copyWith(guidance: value));
  });
}
}

/// @nodoc


class DebouncedSearchProvider implements SearchProvider {
  const DebouncedSearchProvider({required this.duration, required this.child});
  

 final  Duration duration;
 final  SearchProvider child;

/// Create a copy of SearchProvider
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DebouncedSearchProviderCopyWith<DebouncedSearchProvider> get copyWith => _$DebouncedSearchProviderCopyWithImpl<DebouncedSearchProvider>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DebouncedSearchProvider&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.child, child) || other.child == child));
}


@override
int get hashCode => Object.hash(runtimeType,duration,child);

@override
String toString() {
  return 'SearchProvider.debounce(duration: $duration, child: $child)';
}


}

/// @nodoc
abstract mixin class $DebouncedSearchProviderCopyWith<$Res> implements $SearchProviderCopyWith<$Res> {
  factory $DebouncedSearchProviderCopyWith(DebouncedSearchProvider value, $Res Function(DebouncedSearchProvider) _then) = _$DebouncedSearchProviderCopyWithImpl;
@useResult
$Res call({
 Duration duration, SearchProvider child
});


$SearchProviderCopyWith<$Res> get child;

}
/// @nodoc
class _$DebouncedSearchProviderCopyWithImpl<$Res>
    implements $DebouncedSearchProviderCopyWith<$Res> {
  _$DebouncedSearchProviderCopyWithImpl(this._self, this._then);

  final DebouncedSearchProvider _self;
  final $Res Function(DebouncedSearchProvider) _then;

/// Create a copy of SearchProvider
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? duration = null,Object? child = null,}) {
  return _then(DebouncedSearchProvider(
duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration,child: null == child ? _self.child : child // ignore: cast_nullable_to_non_nullable
as SearchProvider,
  ));
}

/// Create a copy of SearchProvider
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchProviderCopyWith<$Res> get child {
  
  return $SearchProviderCopyWith<$Res>(_self.child, (value) {
    return _then(_self.copyWith(child: value));
  });
}
}

/// @nodoc


class CachedSearchProvider implements SearchProvider {
  const CachedSearchProvider({required this.capacity, required this.child, this.retainStaleResults = true}): assert(capacity > 0, 'Cache capacity must be positive.');
  

 final  int capacity;
 final  SearchProvider child;
@JsonKey() final  bool retainStaleResults;

/// Create a copy of SearchProvider
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CachedSearchProviderCopyWith<CachedSearchProvider> get copyWith => _$CachedSearchProviderCopyWithImpl<CachedSearchProvider>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CachedSearchProvider&&(identical(other.capacity, capacity) || other.capacity == capacity)&&(identical(other.child, child) || other.child == child)&&(identical(other.retainStaleResults, retainStaleResults) || other.retainStaleResults == retainStaleResults));
}


@override
int get hashCode => Object.hash(runtimeType,capacity,child,retainStaleResults);

@override
String toString() {
  return 'SearchProvider.cache(capacity: $capacity, child: $child, retainStaleResults: $retainStaleResults)';
}


}

/// @nodoc
abstract mixin class $CachedSearchProviderCopyWith<$Res> implements $SearchProviderCopyWith<$Res> {
  factory $CachedSearchProviderCopyWith(CachedSearchProvider value, $Res Function(CachedSearchProvider) _then) = _$CachedSearchProviderCopyWithImpl;
@useResult
$Res call({
 int capacity, SearchProvider child, bool retainStaleResults
});


$SearchProviderCopyWith<$Res> get child;

}
/// @nodoc
class _$CachedSearchProviderCopyWithImpl<$Res>
    implements $CachedSearchProviderCopyWith<$Res> {
  _$CachedSearchProviderCopyWithImpl(this._self, this._then);

  final CachedSearchProvider _self;
  final $Res Function(CachedSearchProvider) _then;

/// Create a copy of SearchProvider
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? capacity = null,Object? child = null,Object? retainStaleResults = null,}) {
  return _then(CachedSearchProvider(
capacity: null == capacity ? _self.capacity : capacity // ignore: cast_nullable_to_non_nullable
as int,child: null == child ? _self.child : child // ignore: cast_nullable_to_non_nullable
as SearchProvider,retainStaleResults: null == retainStaleResults ? _self.retainStaleResults : retainStaleResults // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of SearchProvider
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchProviderCopyWith<$Res> get child {
  
  return $SearchProviderCopyWith<$Res>(_self.child, (value) {
    return _then(_self.copyWith(child: value));
  });
}
}

/// @nodoc


class RankedSearchProvider implements SearchProvider {
   RankedSearchProvider({required final  List<SearchRankingField> fields, required this.child}): assert(fields.isNotEmpty, 'Ranking fields must not be empty.'),_fields = fields;
  

 final  List<SearchRankingField> _fields;
 List<SearchRankingField> get fields {
  if (_fields is EqualUnmodifiableListView) return _fields;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_fields);
}

 final  SearchProvider child;

/// Create a copy of SearchProvider
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RankedSearchProviderCopyWith<RankedSearchProvider> get copyWith => _$RankedSearchProviderCopyWithImpl<RankedSearchProvider>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RankedSearchProvider&&const DeepCollectionEquality().equals(other._fields, _fields)&&(identical(other.child, child) || other.child == child));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_fields),child);

@override
String toString() {
  return 'SearchProvider.rank(fields: $fields, child: $child)';
}


}

/// @nodoc
abstract mixin class $RankedSearchProviderCopyWith<$Res> implements $SearchProviderCopyWith<$Res> {
  factory $RankedSearchProviderCopyWith(RankedSearchProvider value, $Res Function(RankedSearchProvider) _then) = _$RankedSearchProviderCopyWithImpl;
@useResult
$Res call({
 List<SearchRankingField> fields, SearchProvider child
});


$SearchProviderCopyWith<$Res> get child;

}
/// @nodoc
class _$RankedSearchProviderCopyWithImpl<$Res>
    implements $RankedSearchProviderCopyWith<$Res> {
  _$RankedSearchProviderCopyWithImpl(this._self, this._then);

  final RankedSearchProvider _self;
  final $Res Function(RankedSearchProvider) _then;

/// Create a copy of SearchProvider
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? fields = null,Object? child = null,}) {
  return _then(RankedSearchProvider(
fields: null == fields ? _self._fields : fields // ignore: cast_nullable_to_non_nullable
as List<SearchRankingField>,child: null == child ? _self.child : child // ignore: cast_nullable_to_non_nullable
as SearchProvider,
  ));
}

/// Create a copy of SearchProvider
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchProviderCopyWith<$Res> get child {
  
  return $SearchProviderCopyWith<$Res>(_self.child, (value) {
    return _then(_self.copyWith(child: value));
  });
}
}

/// @nodoc


class LimitedSearchProvider implements SearchProvider {
  const LimitedSearchProvider({required this.maximum, required this.child});
  

 final  TypedExpression maximum;
 final  SearchProvider child;

/// Create a copy of SearchProvider
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LimitedSearchProviderCopyWith<LimitedSearchProvider> get copyWith => _$LimitedSearchProviderCopyWithImpl<LimitedSearchProvider>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LimitedSearchProvider&&(identical(other.maximum, maximum) || other.maximum == maximum)&&(identical(other.child, child) || other.child == child));
}


@override
int get hashCode => Object.hash(runtimeType,maximum,child);

@override
String toString() {
  return 'SearchProvider.limit(maximum: $maximum, child: $child)';
}


}

/// @nodoc
abstract mixin class $LimitedSearchProviderCopyWith<$Res> implements $SearchProviderCopyWith<$Res> {
  factory $LimitedSearchProviderCopyWith(LimitedSearchProvider value, $Res Function(LimitedSearchProvider) _then) = _$LimitedSearchProviderCopyWithImpl;
@useResult
$Res call({
 TypedExpression maximum, SearchProvider child
});


$TypedExpressionCopyWith<$Res> get maximum;$SearchProviderCopyWith<$Res> get child;

}
/// @nodoc
class _$LimitedSearchProviderCopyWithImpl<$Res>
    implements $LimitedSearchProviderCopyWith<$Res> {
  _$LimitedSearchProviderCopyWithImpl(this._self, this._then);

  final LimitedSearchProvider _self;
  final $Res Function(LimitedSearchProvider) _then;

/// Create a copy of SearchProvider
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? maximum = null,Object? child = null,}) {
  return _then(LimitedSearchProvider(
maximum: null == maximum ? _self.maximum : maximum // ignore: cast_nullable_to_non_nullable
as TypedExpression,child: null == child ? _self.child : child // ignore: cast_nullable_to_non_nullable
as SearchProvider,
  ));
}

/// Create a copy of SearchProvider
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get maximum {
  
  return $TypedExpressionCopyWith<$Res>(_self.maximum, (value) {
    return _then(_self.copyWith(maximum: value));
  });
}/// Create a copy of SearchProvider
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchProviderCopyWith<$Res> get child {
  
  return $SearchProviderCopyWith<$Res>(_self.child, (value) {
    return _then(_self.copyWith(child: value));
  });
}
}

/// @nodoc


class DistinctSearchProvider implements SearchProvider {
  const DistinctSearchProvider({required this.child});
  

 final  SearchProvider child;

/// Create a copy of SearchProvider
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DistinctSearchProviderCopyWith<DistinctSearchProvider> get copyWith => _$DistinctSearchProviderCopyWithImpl<DistinctSearchProvider>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DistinctSearchProvider&&(identical(other.child, child) || other.child == child));
}


@override
int get hashCode => Object.hash(runtimeType,child);

@override
String toString() {
  return 'SearchProvider.distinct(child: $child)';
}


}

/// @nodoc
abstract mixin class $DistinctSearchProviderCopyWith<$Res> implements $SearchProviderCopyWith<$Res> {
  factory $DistinctSearchProviderCopyWith(DistinctSearchProvider value, $Res Function(DistinctSearchProvider) _then) = _$DistinctSearchProviderCopyWithImpl;
@useResult
$Res call({
 SearchProvider child
});


$SearchProviderCopyWith<$Res> get child;

}
/// @nodoc
class _$DistinctSearchProviderCopyWithImpl<$Res>
    implements $DistinctSearchProviderCopyWith<$Res> {
  _$DistinctSearchProviderCopyWithImpl(this._self, this._then);

  final DistinctSearchProvider _self;
  final $Res Function(DistinctSearchProvider) _then;

/// Create a copy of SearchProvider
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? child = null,}) {
  return _then(DistinctSearchProvider(
child: null == child ? _self.child : child // ignore: cast_nullable_to_non_nullable
as SearchProvider,
  ));
}

/// Create a copy of SearchProvider
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchProviderCopyWith<$Res> get child {
  
  return $SearchProviderCopyWith<$Res>(_self.child, (value) {
    return _then(_self.copyWith(child: value));
  });
}
}

/// @nodoc


class HistoricalSearchProvider implements SearchProvider {
  const HistoricalSearchProvider({required this.key, required this.label, required this.capacity, required this.child}): assert(key != "", 'History key must not be empty.'),assert(capacity > 0, 'History capacity must be positive.');
  

 final  String key;
 final  TypedExpression label;
 final  int capacity;
 final  SearchProvider child;

/// Create a copy of SearchProvider
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HistoricalSearchProviderCopyWith<HistoricalSearchProvider> get copyWith => _$HistoricalSearchProviderCopyWithImpl<HistoricalSearchProvider>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HistoricalSearchProvider&&(identical(other.key, key) || other.key == key)&&(identical(other.label, label) || other.label == label)&&(identical(other.capacity, capacity) || other.capacity == capacity)&&(identical(other.child, child) || other.child == child));
}


@override
int get hashCode => Object.hash(runtimeType,key,label,capacity,child);

@override
String toString() {
  return 'SearchProvider.history(key: $key, label: $label, capacity: $capacity, child: $child)';
}


}

/// @nodoc
abstract mixin class $HistoricalSearchProviderCopyWith<$Res> implements $SearchProviderCopyWith<$Res> {
  factory $HistoricalSearchProviderCopyWith(HistoricalSearchProvider value, $Res Function(HistoricalSearchProvider) _then) = _$HistoricalSearchProviderCopyWithImpl;
@useResult
$Res call({
 String key, TypedExpression label, int capacity, SearchProvider child
});


$TypedExpressionCopyWith<$Res> get label;$SearchProviderCopyWith<$Res> get child;

}
/// @nodoc
class _$HistoricalSearchProviderCopyWithImpl<$Res>
    implements $HistoricalSearchProviderCopyWith<$Res> {
  _$HistoricalSearchProviderCopyWithImpl(this._self, this._then);

  final HistoricalSearchProvider _self;
  final $Res Function(HistoricalSearchProvider) _then;

/// Create a copy of SearchProvider
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? key = null,Object? label = null,Object? capacity = null,Object? child = null,}) {
  return _then(HistoricalSearchProvider(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as TypedExpression,capacity: null == capacity ? _self.capacity : capacity // ignore: cast_nullable_to_non_nullable
as int,child: null == child ? _self.child : child // ignore: cast_nullable_to_non_nullable
as SearchProvider,
  ));
}

/// Create a copy of SearchProvider
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get label {
  
  return $TypedExpressionCopyWith<$Res>(_self.label, (value) {
    return _then(_self.copyWith(label: value));
  });
}/// Create a copy of SearchProvider
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchProviderCopyWith<$Res> get child {
  
  return $SearchProviderCopyWith<$Res>(_self.child, (value) {
    return _then(_self.copyWith(child: value));
  });
}
}

/// @nodoc


class SectionSearchProvider implements SearchProvider {
  const SectionSearchProvider({required this.id, required this.label, required this.child}): assert(id != "", 'Section ID must not be empty.');
  

 final  String id;
 final  TypedExpression label;
 final  SearchProvider child;

/// Create a copy of SearchProvider
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SectionSearchProviderCopyWith<SectionSearchProvider> get copyWith => _$SectionSearchProviderCopyWithImpl<SectionSearchProvider>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SectionSearchProvider&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.child, child) || other.child == child));
}


@override
int get hashCode => Object.hash(runtimeType,id,label,child);

@override
String toString() {
  return 'SearchProvider.section(id: $id, label: $label, child: $child)';
}


}

/// @nodoc
abstract mixin class $SectionSearchProviderCopyWith<$Res> implements $SearchProviderCopyWith<$Res> {
  factory $SectionSearchProviderCopyWith(SectionSearchProvider value, $Res Function(SectionSearchProvider) _then) = _$SectionSearchProviderCopyWithImpl;
@useResult
$Res call({
 String id, TypedExpression label, SearchProvider child
});


$TypedExpressionCopyWith<$Res> get label;$SearchProviderCopyWith<$Res> get child;

}
/// @nodoc
class _$SectionSearchProviderCopyWithImpl<$Res>
    implements $SectionSearchProviderCopyWith<$Res> {
  _$SectionSearchProviderCopyWithImpl(this._self, this._then);

  final SectionSearchProvider _self;
  final $Res Function(SectionSearchProvider) _then;

/// Create a copy of SearchProvider
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = null,Object? child = null,}) {
  return _then(SectionSearchProvider(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as TypedExpression,child: null == child ? _self.child : child // ignore: cast_nullable_to_non_nullable
as SearchProvider,
  ));
}

/// Create a copy of SearchProvider
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedExpressionCopyWith<$Res> get label {
  
  return $TypedExpressionCopyWith<$Res>(_self.label, (value) {
    return _then(_self.copyWith(label: value));
  });
}/// Create a copy of SearchProvider
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchProviderCopyWith<$Res> get child {
  
  return $SearchProviderCopyWith<$Res>(_self.child, (value) {
    return _then(_self.copyWith(child: value));
  });
}
}

/// @nodoc


class MergedSearchProvider implements SearchProvider {
   MergedSearchProvider({required final  List<SearchProvider> children}): assert(children.isNotEmpty, 'Merged providers must not be empty.'),_children = children;
  

 final  List<SearchProvider> _children;
 List<SearchProvider> get children {
  if (_children is EqualUnmodifiableListView) return _children;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_children);
}


/// Create a copy of SearchProvider
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MergedSearchProviderCopyWith<MergedSearchProvider> get copyWith => _$MergedSearchProviderCopyWithImpl<MergedSearchProvider>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MergedSearchProvider&&const DeepCollectionEquality().equals(other._children, _children));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_children));

@override
String toString() {
  return 'SearchProvider.merge(children: $children)';
}


}

/// @nodoc
abstract mixin class $MergedSearchProviderCopyWith<$Res> implements $SearchProviderCopyWith<$Res> {
  factory $MergedSearchProviderCopyWith(MergedSearchProvider value, $Res Function(MergedSearchProvider) _then) = _$MergedSearchProviderCopyWithImpl;
@useResult
$Res call({
 List<SearchProvider> children
});




}
/// @nodoc
class _$MergedSearchProviderCopyWithImpl<$Res>
    implements $MergedSearchProviderCopyWith<$Res> {
  _$MergedSearchProviderCopyWithImpl(this._self, this._then);

  final MergedSearchProvider _self;
  final $Res Function(MergedSearchProvider) _then;

/// Create a copy of SearchProvider
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? children = null,}) {
  return _then(MergedSearchProvider(
children: null == children ? _self._children : children // ignore: cast_nullable_to_non_nullable
as List<SearchProvider>,
  ));
}


}

// dart format on
