import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "realm_presentation_search_transport.freezed.dart";

@freezed
abstract class RealmPresentationSearchRequest
    with _$RealmPresentationSearchRequest {
  const factory RealmPresentationSearchRequest({
    required String subscriptionId,
    required RealmActionId actionId,
    required DataValue payload,
    required TypeExpression resultType,
    required SearchQueryContext query,
  }) = _RealmPresentationSearchRequest;
}

@freezed
sealed class RealmPresentationSearchUpdate
    with _$RealmPresentationSearchUpdate {
  const factory RealmPresentationSearchUpdate.snapshot({
    required String subscriptionId,
    required SearchSourceStatus status,
    required List<DataValue> values,
    @Default([]) List<String> guidance,
    @Default([]) List<TypeDiagnostic> diagnostics,
  }) = RealmPresentationSearchSnapshotUpdate;

  const factory RealmPresentationSearchUpdate.unavailable({
    required String subscriptionId,
    required List<TypeDiagnostic> diagnostics,
  }) = RealmPresentationSearchUnavailableUpdate;
}

typedef RealmPresentationSearchTransport =
    Stream<RealmPresentationSearchUpdate> Function(
      RealmPresentationSearchRequest request,
    );
