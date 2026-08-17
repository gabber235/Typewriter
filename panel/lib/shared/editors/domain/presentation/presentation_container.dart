part of "presentation_element.dart";

@freezed
sealed class PresentationRadius with _$PresentationRadius {
  const factory PresentationRadius.none() = NoPresentationRadius;
  const factory PresentationRadius.small() = SmallPresentationRadius;
  const factory PresentationRadius.medium() = MediumPresentationRadius;
  const factory PresentationRadius.large() = LargePresentationRadius;
  const factory PresentationRadius.custom(TypedExpression value) =
      CustomPresentationRadius;
}
