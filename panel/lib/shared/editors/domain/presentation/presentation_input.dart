part of "presentation_element.dart";

@freezed
abstract class BoundControl with _$BoundControl {
  const factory BoundControl({
    required BindingReference binding,
    TypedExpression? label,
    TypedExpression? description,
  }) = _BoundControl;
}

@freezed
abstract class SelectOption with _$SelectOption {
  @Assert("id != \"\"", "Select option ID must not be empty.")
  const factory SelectOption({
    required String id,
    required TypedExpression label,
    required TypedExpression value,
  }) = _SelectOption;
}

@freezed
abstract class ConcreteTypePresentation with _$ConcreteTypePresentation {
  const factory ConcreteTypePresentation({
    required ResolvedTypeRef type,
    required TypedExpression label,
    PresentationNode? presentation,
  }) = _ConcreteTypePresentation;
}

abstract interface class SimpleInputElement {
  BoundControl get control;
}
