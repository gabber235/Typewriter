part of "presentation_element.dart";

enum PresentationTextOverflow { clip, ellipsis }

enum PresentationTextTone { primary, secondary }

@freezed
abstract class TextParagraph with _$TextParagraph {
  @Assert("maxLines == null || maxLines > 0", "Maximum lines must be positive.")
  const factory TextParagraph({
    int? maxLines,
    @Default(PresentationTextOverflow.clip) PresentationTextOverflow overflow,
    @Default(true) bool softWrap,
    @Default(false) bool selectable,
    @Default(PresentationTextTone.primary) PresentationTextTone tone,
  }) = _TextParagraph;
}

@freezed
abstract class PresentationTextStyle with _$PresentationTextStyle {
  const factory PresentationTextStyle({
    TypedExpression? color,
    TypedExpression? fontWeight,
    TypedExpression? fontItalic,
    TypedExpression? decoration,
  }) = _PresentationTextStyle;
}

@freezed
abstract class PresentationTextRun with _$PresentationTextRun {
  const factory PresentationTextRun({
    required TypedExpression text,
    PresentationTextStyle? style,
  }) = _PresentationTextRun;
}

extension PresentationParagraphDefault on TextParagraph? {
  TextParagraph get orDefault => this ?? TextParagraph();
}
