import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "portable_search_payload.freezed.dart";

/// Typed data carried by a portable search result.
///
/// Search remains heterogeneous outside this boundary. Portable activation and
/// row rendering accept only this payload, so wire values cannot be confused
/// with unrelated application search results.
@freezed
sealed class PortableSearchPayload with _$PortableSearchPayload {
  const factory PortableSearchPayload.mapped({
    required skir.DataValue sourceValue,
    required skir.DataValue selectedValue,
    required skir.SearchResultMapping mapping,
    required String providerPath,
    required String distinctKey,
    required SearchQueryContext query,
  }) = PortableMappedSearchPayload;

  const factory PortableSearchPayload.custom({
    required skir.DataValue selectedValue,
    required String providerPath,
    required SearchQueryContext query,
  }) = PortableCustomSearchPayload;
}

@freezed
sealed class PortableSearchSelectionResult
    with _$PortableSearchSelectionResult {
  const factory PortableSearchSelectionResult.applied({required bool added}) =
      PortableSearchSelectionApplied;

  const factory PortableSearchSelectionResult.rejected(String message) =
      PortableSearchSelectionRejected;
}
