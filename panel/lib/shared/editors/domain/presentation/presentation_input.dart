part of "presentation_element.dart";

@freezed
abstract class BoundControl with _$BoundControl {
  const factory BoundControl({
    required BindingReference binding,
    TypedExpression? label,
    TypedExpression? description,
    PresentationNode? prefix,
    TypedExpression? semanticLabel,
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

@freezed
abstract class PolymorphicMatchCase with _$PolymorphicMatchCase {
  const factory PolymorphicMatchCase({
    required ResolvedTypeRef type,
    required PresentationNode child,
  }) = _PolymorphicMatchCase;
}

abstract interface class SimpleInputElement {
  BoundControl get control;
}

@freezed
abstract class ReferencePolicyId with _$ReferencePolicyId {
  @Assert("value != \"\"", "Reference policy ID must not be empty.")
  const factory ReferencePolicyId(String value) = _ReferencePolicyId;
}

enum ReferenceRejectionDisplay { hidden, disabled }
