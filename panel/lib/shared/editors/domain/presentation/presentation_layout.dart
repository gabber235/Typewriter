part of "presentation_element.dart";

enum PresentationMainAxisAlignment {
  start,
  center,
  end,
  spaceBetween,
  spaceAround,
  spaceEvenly,
}

enum PresentationCrossAxisAlignment { start, center, end, stretch }

abstract interface class ChildrenLayoutElement {
  List<PresentationNode> get children;
  double get spacing;
  PresentationMainAxisAlignment get mainAxisAlignment;
  PresentationCrossAxisAlignment get crossAxisAlignment;
}

abstract interface class SingleChildLayoutElement {
  PresentationNode get child;
}

@freezed
abstract class TabItem with _$TabItem {
  @Assert("id != \"\"", "Tab ID must not be empty.")
  const factory TabItem({
    required String id,
    required TypedExpression label,
    required PresentationNode child,
  }) = _TabItem;
}
