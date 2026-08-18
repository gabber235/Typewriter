part of "presentation_element.dart";

@freezed
abstract class PresentationMenuItem with _$PresentationMenuItem {
  @Assert("id != \"\"", "Menu item ID must not be empty.")
  const factory PresentationMenuItem({
    required String id,
    required TypedExpression label,
    required EditorAction action,
  }) = _PresentationMenuItem;
}
