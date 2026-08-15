import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "presentation_search_models.freezed.dart";

const presentationSearchResultType = SearchResultType(
  id: "presentation",
  rowRendererId: "presentation",
  label: "Result",
);

@freezed
abstract class PresentationSearchResultPayload
    with _$PresentationSearchResultPayload {
  const factory PresentationSearchResultPayload({
    required DataValue selectedValue,
    required PresentationNode presentation,
    required ExpressionContext expressions,
    required String providerKey,
  }) = _PresentationSearchResultPayload;
}

@freezed
abstract class PresentationSearchSelectionEvent
    with _$PresentationSearchSelectionEvent {
  const factory PresentationSearchSelectionEvent({
    required SearchResult result,
    required String historyNamespace,
  }) = _PresentationSearchSelectionEvent;
}
