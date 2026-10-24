import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "realm_inbox.freezed.dart";
part "realm_inbox.g.dart";

/// Resource findings share one projection; work retains its own lifecycle.
@freezed
sealed class RealmInboxIssue with _$RealmInboxIssue {
  const factory RealmInboxIssue.finding(ResourceIssue finding) =
      RealmInboxFinding;
  const factory RealmInboxIssue.work(WorkEntryState entry) =
      RealmInboxWorkIssue;
  const factory RealmInboxIssue.submission(
    LocalWorkSubmissionState submission,
  ) = RealmInboxSubmissionIssue;
  const RealmInboxIssue._();
  Object get identity => switch (this) {
    RealmInboxFinding(:final finding) => finding.identity,
    RealmInboxWorkIssue(:final entry) => ("work", entry.id),
    RealmInboxSubmissionIssue(:final submission) => (
      "submission",
      submission.id,
    ),
  };
  String get message => switch (this) {
    RealmInboxFinding(:final finding) => finding.diagnostic.message,
    RealmInboxWorkIssue(:final entry) => entry.phase,
    RealmInboxSubmissionIssue(:final submission) =>
      submission.message ?? "Publication outcome is unknown",
  };
  skir.DiagnosticSeverity get severity => switch (this) {
    RealmInboxFinding(:final finding) => finding.diagnostic.severity,
    _ => skir.DiagnosticSeverity.error,
  };
  skir.ValueLocation? get primary => switch (this) {
    RealmInboxFinding(:final finding) => finding.primary,
    _ => null,
  };
  List<skir.ValueLocation> get related => switch (this) {
    RealmInboxFinding(:final finding) => finding.locations.skip(1).toList(),
    _ => [],
  };
  String get provenance => switch (this) {
    RealmInboxFinding(:final finding) => finding.provenance,
    RealmInboxWorkIssue() => "Local work. Does not block saved publication",
    RealmInboxSubmissionIssue() => "Request activity",
  };
}

@freezed
abstract class RealmInboxState with _$RealmInboxState {
  const factory RealmInboxState({
    required RealmPublicationView publication,
    @Default([]) List<RealmInboxIssue> issues,
    @Default([]) List<skir.PublicationChange> changes,
    @Default([]) List<skir.CompilationRoot> pendingRoots,
    @Default([]) List<WorkEntryState> localWork,
    @Default([]) List<LocalWorkSubmissionState> submissions,
  }) = _RealmInboxState;
}

bool realmOwnsWork(AuthoringScope scope, WorkDriverId driver) =>
    driver.scope == scope ||
    (driver.scope is EditorResourceKey &&
        (driver.scope as EditorResourceKey).scope == scope);

bool realmOwnsReservation(AuthoringScope scope, Object resource) =>
    switch (resource) {
      WorkDriverId() => realmOwnsWork(scope, resource),
      EditorResourceKey() => resource.scope == scope,
      (
        final skir.RecordId organization,
        final skir.RecordId realm,
        skir.ResourceId _,
      ) =>
        organization == scope.organizationId && realm == scope.realmId,
      _ => false,
    };

/// Projects saved issues from publication and local activity from its owners.
@riverpod
RealmInboxState realmInbox(Ref ref, AuthoringScope scope) {
  final publication =
      ref
          .watch(realmPublicationProvider(scope.organizationId, scope.realmId))
          .value ??
      const RealmPublicationView.checking();
  final projected = ref.watch(resourceIssuesProvider(scope));
  final work = ref.watch(localWorkProvider);
  final local = work.entries.values
      .where(
        (entry) =>
            entry.id.driver.domain != "publication" &&
            realmOwnsWork(scope, entry.id.driver),
      )
      .toList();
  final submissions = work.submissions
      .where(
        (submission) => submission.resources.any(
          (resource) => realmOwnsReservation(scope, resource),
        ),
      )
      .toList();
  final issues = <Object, RealmInboxIssue>{};
  void add(RealmInboxIssue issue) => issues[issue.identity] = issue;
  final semantic =
      projected.value?.findings ??
      publication.projectSavedIssues(null).toList();
  for (final finding in semantic) {
    add(RealmInboxIssue.finding(finding));
  }
  final review = publication.review;
  for (final entry in local.where(
    (entry) => entry.needsAttention || entry.needsInput,
  )) {
    add(RealmInboxIssue.work(entry));
  }
  for (final submission in submissions.where(
    (submission) =>
        submission.integrationFailed ||
        submission.result == LocalWorkSubmissionResult.uncertain ||
        submission.result == LocalWorkSubmissionResult.rejected ||
        submission.result == LocalWorkSubmissionResult.notSubmitted,
  )) {
    add(RealmInboxIssue.submission(submission));
  }
  final changes = switch (review) {
    skir.PublicationStatus_readyWrapper(:final value) => [
      value.changes.first,
      ...value.changes.additional,
    ],
    skir.PublicationStatus_blockedWrapper(:final value) =>
      value.confirmedChanges.toList(),
    skir.PublicationStatus_publishingWrapper(:final value) =>
      value.next.confirmedChanges.toList(),
    _ => const <skir.PublicationChange>[],
  };
  final pending = switch (review) {
    skir.PublicationStatus_blockedWrapper(:final value) =>
      value.pendingRoots.toList(),
    skir.PublicationStatus_publishingWrapper(:final value) =>
      value.next.pendingRoots.toList(),
    _ => const <skir.CompilationRoot>[],
  };
  final sorted = issues.values.toList()
    ..sort((a, b) => b.severity.kind.index.compareTo(a.severity.kind.index));
  return RealmInboxState(
    publication: publication,
    issues: sorted,
    changes: changes,
    pendingRoots: pending,
    localWork: local,
    submissions: submissions,
  );
}

/// Reveals the editor for the issue location.
@riverpod
Future<bool> openRealmInboxLocation(
  Ref ref,
  AuthoringScope scope,
  skir.ValueLocation location,
) async {
  // The inbox closes before navigation completes, so the operation owns its
  // lifetime until resource selection and the field reveal have been requested.
  final retention = ref.keepAlive();
  try {
    return await ref
        .read(realmSurfaceNavigationProvider)
        .reveal(scope, location);
  } finally {
    retention.close();
  }
}
