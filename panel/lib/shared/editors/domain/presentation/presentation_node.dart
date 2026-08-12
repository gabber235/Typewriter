import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "presentation_node.freezed.dart";

@freezed
abstract class PresentationNode with _$PresentationNode {
  @Assert("id != \"\"", "Presentation node ID must not be empty.")
  const factory PresentationNode({
    required String id,
    required PresentationElement element,
    @Default(PresentationProperties()) PresentationProperties properties,
    PresentationHeader? header,
  }) = _PresentationNode;
}

@freezed
abstract class PresentationProperties with _$PresentationProperties {
  const factory PresentationProperties({
    TypedExpression? enabledIf,
    @Default(false) bool readOnly,
  }) = _PresentationProperties;
}
