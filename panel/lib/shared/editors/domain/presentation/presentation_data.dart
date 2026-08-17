part of "presentation_element.dart";

@freezed
abstract class SequencePresentation with _$SequencePresentation {
  const factory SequencePresentation({
    required PresentationNode item,
    PresentationNode? empty,
    PresentationNode? separator,
    @Default(
      PresentationSequenceLayout.children(PresentationChildrenLayout.column()),
    )
    PresentationSequenceLayout layout,
  }) = _SequencePresentation;
}
