import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "realm_publication_view.freezed.dart";

@freezed
sealed class PublicationObservation with _$PublicationObservation {
  const factory PublicationObservation.fetching(
    skir.PublicationViewId expected,
  ) = FetchingPublicationObservation;
  const factory PublicationObservation.available(skir.PublicationView view) =
      AvailablePublicationObservation;
  const factory PublicationObservation.unavailable(String message) =
      UnavailablePublicationObservation;
}

/// Only a coherent ready review carries a callable publish capability.
@freezed
sealed class RealmPublicationView with _$RealmPublicationView {
  const factory RealmPublicationView.empty(skir.PublicationStatus_Empty data) =
      EmptyRealmPublication;
  const factory RealmPublicationView.current(
    skir.PublicationStatus_Current data,
  ) = CurrentRealmPublication;
  const factory RealmPublicationView.ready(
    skir.PublicationStatus_Ready data,
    RealmPublishCommand command,
  ) = ReadyRealmPublication;
  const factory RealmPublicationView.blocked(
    skir.PublicationStatus_Blocked data,
  ) = BlockedRealmPublication;
  const factory RealmPublicationView.checking({
    skir.PublicationStatus? display,
  }) = CheckingRealmPublication;
  const factory RealmPublicationView.publishing(
    skir.PublicationStatus_Publishing data,
  ) = PublishingRealmPublication;
  const factory RealmPublicationView.unavailable(
    String message, {
    skir.PublicationStatus? display,
  }) = UnavailableRealmPublication;
  const factory RealmPublicationView.requestActive({
    skir.PublicationStatus? display,
  }) = RequestActiveRealmPublication;
  const factory RealmPublicationView.uncertain(
    String message, {
    skir.PublicationStatus? display,
  }) = UncertainRealmPublication;

  const RealmPublicationView._();
  skir.PublicationStatus? get review => switch (this) {
    EmptyRealmPublication(:final data) => skir.PublicationStatus.wrapEmpty(
      data,
    ),
    CurrentRealmPublication(:final data) => skir.PublicationStatus.wrapCurrent(
      data,
    ),
    ReadyRealmPublication(:final data) => skir.PublicationStatus.wrapReady(
      data,
    ),
    BlockedRealmPublication(:final data) => skir.PublicationStatus.wrapBlocked(
      data,
    ),
    PublishingRealmPublication(:final data) =>
      skir.PublicationStatus.wrapPublishing(data),
    CheckingRealmPublication(:final display) ||
    UnavailableRealmPublication(:final display) ||
    RequestActiveRealmPublication(:final display) ||
    UncertainRealmPublication(:final display) => display,
  };
}

/// Captures the reviewed saved candidate. Later observations revoke invocation.
final class RealmPublishCommand {
  RealmPublishCommand(this.candidate, this._invoke);
  final skir.PublicationCandidateId candidate;
  final Future<skir.PublicationResult> Function() _invoke;
  Future<skir.PublicationResult> invoke() => _invoke();
}

/// Rejects default or future wire variants before deriving a command capability.
bool validPublicationStatus(skir.PublicationStatus status) {
  bool baseline(skir.PublicationBaseline value) => switch (value) {
    skir.PublicationBaseline.initial => true,
    skir.PublicationBaseline_selectedWrapper(:final value) =>
      value.value.isNotEmpty,
    _ => false,
  };
  bool details(skir.PublicationDiagnosticDetails value) =>
      value.id.value.isNotEmpty;
  bool notices(Iterable<skir.PublicationNotice> values) => values.every(
    (notice) => switch (notice) {
      skir.PublicationNotice_informationWrapper(:final value) ||
      skir.PublicationNotice_warningWrapper(:final value) => details(value),
      _ => false,
    },
  );
  bool change(skir.PublicationChange value) => switch (value) {
    skir.PublicationChange_rootAddedWrapper(:final value) ||
    skir.PublicationChange_rootUpdatedWrapper(:final value) ||
    skir.PublicationChange_rootRemovedWrapper(
      :final value,
    ) => value.resource.value.isNotEmpty && value.projection.value.isNotEmpty,
    skir.PublicationChange.requirementsChanged => true,
    _ => false,
  };
  bool delta(skir.PublicationDelta value) =>
      [value.first, ...value.additional].every(change) &&
      {value.first, ...value.additional}.length == value.additional.length + 1;
  bool blockers(skir.PublicationBlockers value) => [
    value.first,
    ...value.additional,
  ].every((blocker) => details(blocker.details));
  return switch (status) {
    skir.PublicationStatus_emptyWrapper(:final value) => notices(value.notices),
    skir.PublicationStatus_currentWrapper(:final value) =>
      value.selected.value.isNotEmpty && notices(value.notices),
    skir.PublicationStatus_readyWrapper(:final value) =>
      value.candidate.value.isNotEmpty &&
          baseline(value.baseline) &&
          delta(value.changes) &&
          notices(value.notices),
    skir.PublicationStatus_blockedWrapper(:final value) =>
      baseline(value.baseline) &&
          blockers(value.blockers) &&
          notices(value.notices) &&
          value.confirmedChanges.every(change),
    skir.PublicationStatus_checkingWrapper(:final value) => baseline(
      value.baseline,
    ),
    skir.PublicationStatus_publishingWrapper(:final value) =>
      value.publication.value.isNotEmpty &&
          value.phase is! skir.PublicationActivationPhase_unknown &&
          delta(value.releasing) &&
          value.next.confirmedChanges.every(change) &&
          value.next.blockers.every((blocker) => details(blocker.details)) &&
          notices(value.next.notices),
    skir.PublicationStatus_unavailableWrapper(:final value) =>
      baseline(value.baseline) &&
          value.failure is! skir.PublicationFailure_unknown,
    _ => false,
  };
}
