import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "realm_inbox.freezed.dart";
part "realm_inbox.g.dart";

@riverpod
PortableLocationRevealController realmLocationReveal(
  Ref ref,
  AuthoringScope scope,
) {
  final controller = PortableLocationRevealController();
  ref.onDispose(controller.dispose);
  return controller;
}

/// Provenance determines meaning. A local problem never blocks a saved release.
@freezed
sealed class RealmInboxIssue with _$RealmInboxIssue {
  const factory RealmInboxIssue.blocker(
    skir.PublicationDiagnosticDetails details,
  ) = RealmInboxBlocker;
  const factory RealmInboxIssue.notice(skir.PublicationNotice notice) =
      RealmInboxNotice;
  const factory RealmInboxIssue.savedFinding(AuthoredFindingView finding) =
      RealmInboxSavedFinding;
  const factory RealmInboxIssue.localFinding(
    PortablePresentationDiagnostic diagnostic,
  ) = RealmInboxLocalFinding;
  const factory RealmInboxIssue.work(WorkEntryState entry) =
      RealmInboxWorkIssue;
  const factory RealmInboxIssue.submission(
    LocalWorkSubmissionState submission,
  ) = RealmInboxSubmissionIssue;

  const RealmInboxIssue._();
  Object get identity => switch (this) {
    RealmInboxBlocker(:final details) => ("saved", details.id),
    RealmInboxNotice() => ("saved", _noticeDetails!.id),
    RealmInboxSavedFinding(:final finding) => ("saved", finding.diagnostic.id),
    RealmInboxLocalFinding(:final diagnostic) => (
      "local",
      diagnostic.targets,
      diagnostic.code,
    ),
    RealmInboxWorkIssue(:final entry) => ("work", entry.id),
    RealmInboxSubmissionIssue(:final submission) => (
      "submission",
      submission.id,
    ),
  };
  skir.PublicationDiagnosticDetails? get _noticeDetails => switch (this) {
    RealmInboxNotice(
      notice: skir.PublicationNotice_informationWrapper(:final value) ||
          skir.PublicationNotice_warningWrapper(:final value),
    ) =>
      value,
    _ => null,
  };
  String get message => switch (this) {
    RealmInboxBlocker(:final details) => details.message,
    RealmInboxNotice() =>
      _noticeDetails?.message ?? "Unknown publication notice",
    RealmInboxSavedFinding(:final finding) => finding.diagnostic.message,
    RealmInboxLocalFinding(:final diagnostic) => diagnostic.message,
    RealmInboxWorkIssue(:final entry) => entry.phase,
    RealmInboxSubmissionIssue(:final submission) =>
      submission.message ?? "Publication outcome is unknown",
  };
  skir.DiagnosticSeverity get severity => switch (this) {
    RealmInboxBlocker() ||
    RealmInboxWorkIssue() ||
    RealmInboxSubmissionIssue() => skir.DiagnosticSeverity.error,
    RealmInboxNotice(notice: skir.PublicationNotice_warningWrapper()) =>
      skir.DiagnosticSeverity.warning,
    RealmInboxSavedFinding(:final finding) => finding.diagnostic.severity,
    RealmInboxLocalFinding(:final diagnostic) => diagnostic.severity,
    _ => skir.DiagnosticSeverity.information,
  };
  skir.ValueLocation? get primary => switch (this) {
    RealmInboxBlocker(:final details) => details.primary,
    RealmInboxNotice() => _noticeDetails?.primary,
    RealmInboxSavedFinding(:final finding) =>
      finding.diagnostic.primary ?? finding.source.ticket.instance.location,
    RealmInboxLocalFinding(:final diagnostic) =>
      diagnostic.targets
          .whereType<PortableValueDiagnosticTarget>()
          .map((target) => target.location)
          .firstOrNull,
    _ => null,
  };
  List<skir.ValueLocation> get related => switch (this) {
    RealmInboxBlocker(:final details) => details.related.toList(),
    RealmInboxNotice() => _noticeDetails?.related.toList() ?? [],
    RealmInboxSavedFinding(:final finding) =>
      finding.diagnostic.related.toList(),
    RealmInboxLocalFinding(:final diagnostic) =>
      diagnostic.targets
          .whereType<PortableValueDiagnosticTarget>()
          .map((target) => target.location)
          .skip(1)
          .toList(growable: false),
    _ => [],
  };
  String get provenance => switch (this) {
    RealmInboxBlocker() => "Saved content. Blocks publication",
    RealmInboxNotice() => "Saved content",
    RealmInboxSavedFinding(:final finding) =>
      finding.isOutdated
          ? "Previous saved state. Checking again"
          : "Saved content",
    RealmInboxLocalFinding() => "Local draft. Does not block saved publication",
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

/// Joins immutable observations from their existing owners without retaining work.
@riverpod
RealmInboxState realmInbox(Ref ref, AuthoringScope scope) {
  final publication =
      ref
          .watch(realmPublicationProvider(scope.organizationId, scope.realmId))
          .value ??
      const RealmPublicationView.checking();
  final editing = ref.watch(realmEditingStateProvider(scope));
  final work = ref.watch(localWorkProvider);
  final authoring = ref.watch(
    authoringSessionProvider(scope.organizationId, scope.realmId),
  );
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
  for (final set in authoring.findings) {
    for (final diagnostic in [
      ...set.findings,
      if (set.outcome case skir.CheckOutcome_failedWrapper(:final value))
        ...value,
    ]) {
      add(
        RealmInboxIssue.savedFinding(
          AuthoredFindingView(source: set, diagnostic: diagnostic),
        ),
      );
    }
  }
  final review = publication.review;
  final notices = switch (review) {
    skir.PublicationStatus_emptyWrapper(:final value) => value.notices,
    skir.PublicationStatus_currentWrapper(:final value) => value.notices,
    skir.PublicationStatus_readyWrapper(:final value) => value.notices,
    skir.PublicationStatus_blockedWrapper(:final value) => value.notices,
    skir.PublicationStatus_publishingWrapper(:final value) =>
      value.next.notices,
    _ => const <skir.PublicationNotice>[],
  };
  for (final notice in notices) {
    if (notice is! skir.PublicationNotice_unknown) {
      add(RealmInboxIssue.notice(notice));
    }
  }
  if (review case skir.PublicationStatus_blockedWrapper(:final value)) {
    for (final blocker in [
      value.blockers.first,
      ...value.blockers.additional,
    ]) {
      add(RealmInboxIssue.blocker(blocker.details));
    }
  }
  if (review case skir.PublicationStatus_publishingWrapper(:final value)) {
    for (final blocker in value.next.blockers) {
      add(RealmInboxIssue.blocker(blocker.details));
    }
  }
  if (editing.working case final document?) {
    final changed = {
      for (final group in editing.groups.values)
        ...group.resources.whereType<skir.ResourceId>(),
    };
    for (final resource in changed) {
      for (final diagnostic in AuthoredRuleProjection.evaluate(
        draft: document,
        catalog: document.catalog,
        resource: resource,
        budget: skir.EvaluationBudget(
          maxSteps: 10000,
          maxCollectionItems: 10000,
        ),
      ).diagnostics) {
        add(RealmInboxIssue.localFinding(diagnostic));
      }
    }
  }
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

/// Reuses the resource navigation registry for inbox destinations.
@riverpod
Future<bool> openRealmInboxLocation(
  Ref ref,
  AuthoringScope scope,
  skir.ValueLocation location,
) async {
  final document = ref.read(workingAuthoringDocumentProvider(scope)).value;
  final resource = document?.entry(location.resource);
  if (resource == null || document == null) return false;
  final definition = document.catalog.snapshot.resourceDefinitions
      .where((item) => item.id == resource.definition)
      .firstOrNull;
  final handler = definition?.navigationHandler;
  return ref
      .read(authoringResourceNavigationRegistryProvider)
      .open(
        ref,
        handler,
        OpenAuthoringResourceEffect(
          organizationId: scope.organizationId,
          realmId: scope.realmId,
          resourceId: resource.id,
          definition: resource.definition,
          configuration: resource.content.configuration,
          navigationHandler: handler,
          location: location,
        ),
      );
}
