import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "realm_publication.g.dart";

@Riverpod(keepAlive: true)
RealmPublicationRepository realmPublicationRepository(
  Ref ref,
  skir.RecordId organizationId,
  skir.RecordId realmId,
) => NatsRealmPublicationRepository(
  ref: ref,
  organizationId: organizationId,
  realmId: realmId,
);

/// Observes server publication independently of the lifetime of a toolbar.
final class PublicationWorkDriver extends ChangeNotifier implements WorkDriver {
  PublicationWorkDriver(this.scope, this.repository, this.work);
  final AuthoringScope scope;
  final RealmPublicationRepository repository;
  final LocalWorkCommands work;
  skir.PublicationReport? _report;
  skir.PublicationReport? get report => _report;
  StreamSubscription<skir.PublicationReport>? _subscription;
  Object? _failure;
  StreamSubscription<LocalWorkState>? _workObservation;
  bool _closed = false;
  @override
  WorkDriverId get id => WorkDriverId(domain: "publication", scope: scope);
  WorkEntryId get entry => WorkEntryId(driver: id, identity: "publication");

  void start() {
    if (_subscription != null || _closed) {
      throw StateError("Publication observation is already owned");
    }
    _workObservation = work.changes.listen((_) {
      if (!_closed) notifyListeners();
    });
    _subscription = repository.watch().listen(
      (report) {
        if (_closed) return;
        _report = report.id.value.isEmpty ? null : report;
        _failure = null;
        notifyListeners();
      },
      onError: (Object error) {
        if (_closed) return;
        _failure = error;
        notifyListeners();
      },
    );
  }

  Iterable<MutationSubmission<Object?>> get _requests =>
      work.submissions.where((submission) => submission.resources.contains(id));
  bool get _requestSending => _requests.any((submission) => submission.sending);
  bool get _requestUncertain =>
      _requests.any((submission) => submission.result is SubmissionUncertain);
  bool get _requestPending => _requests.any(
    (submission) => !submission.sending && submission.result == null,
  );
  bool get canPublish =>
      !_closed &&
      !(_report?.state).isActive &&
      !_requestSending &&
      !_requestUncertain &&
      !_requestPending;

  Future<skir.PublicationResult> publish() async {
    if (_closed) throw StateError("Publication work is closed");
    if (!canPublish) return skir.PublicationResult.publishing;
    final response = await work.execute(repository.preparePublish());
    return switch (response) {
      skir.PublishAuthoringResponse_resultWrapper(:final value) => value,
      _ => throw ApiException.internalServerError(),
    };
  }

  @override
  WorkDriverSnapshot get snapshot {
    final result = publicationWorkSnapshot(entryId: entry, report: _report);
    final state = result.entries.single;
    return WorkDriverSnapshot(
      entries: [
        state.copyWith(
          retained:
              state.retained ||
              _requestSending ||
              _requestUncertain ||
              _requestPending,
          hasWork:
              state.hasWork ||
              _requestSending ||
              _requestUncertain ||
              _requestPending ||
              _failure != null,
          saving: state.saving || _requestSending,
          needsAttention:
              state.needsAttention || _failure != null || _requestUncertain,
          details: [
            ...state.details,
            if (_requestSending)
              const WorkFact(
                label: "Request",
                value: "Sending publication request",
              ),
            if (_requestPending)
              const WorkFact(
                label: "Request",
                value: "Publication request is queued",
              ),
            if (_requestUncertain)
              const WorkFact(
                label: "Request",
                value: "The delivery outcome is unknown. Check the activity journal.",
              ),
            if (_failure != null)
              WorkFact(label: "Observation", value: _failure.toString()),
          ],
        ),
      ],
    );
  }

  @override
  Future<void> save(WorkEntryId entry) =>
      Future.error(StateError("Publication has no draft to save"));
  @override
  bool discard(WorkEntryId entry) => false;
  @override
  Future<void> retry(WorkEntryId entry) =>
      Future.error(StateError("Observe the result before publishing again"));
  @override
  void dispose() {
    if (_closed) return;
    _closed = true;
    unawaited(_subscription?.cancel());
    unawaited(_workObservation?.cancel());
    super.dispose();
  }
}

extension PublicationActivity on skir.PublicationState? {
  bool get isActive =>
      this == skir.PublicationState.checking ||
      this == skir.PublicationState.compiling ||
      this == skir.PublicationState.activating;
}

WorkDriverSnapshot publicationWorkSnapshot({
  required WorkEntryId entryId,
  required skir.PublicationReport? report,
}) {
  final phase = switch (report?.state) {
    skir.PublicationState.checking => "Checking saved content",
    skir.PublicationState.compiling => "Compiling saved content",
    skir.PublicationState.activating => "Selecting compiled content",
    skir.PublicationState.complete => "Published",
    skir.PublicationState_blockedWrapper() => "Blocked",
    skir.PublicationState.interrupted => "Interrupted",
    _ => "Waiting for publication status",
  };
  final active = (report?.state).isActive;
  final attention =
      report?.state is skir.PublicationState_blockedWrapper ||
      report?.state == skir.PublicationState.interrupted;
  return WorkDriverSnapshot(
    entries: [
      WorkEntryState(
        id: entryId,
        label: "Publish saved content",
        phase: phase,
        details: [
          if (report != null) ...[
            WorkFact(label: "Publication", value: report.id.value),
            for (final finding in report.findings)
              WorkFact(label: "Finding", value: finding.message),
          ],
        ],
        retained: active,
        hasWork: active || attention,
        saving: active,
        needsAttention: attention,
      ),
    ],
  );
}

extension PublicationWorkRegistration on LocalWork {
  PublicationWorkDriver getOrRegisterPublication(AuthoringScope scope) =>
      getOrRegisterScoped(
        WorkDriverId(domain: "publication", scope: scope),
        (ref) => PublicationWorkDriver(
          scope,
          ref.read(
            realmPublicationRepositoryProvider(
              scope.organizationId,
              scope.realmId,
            ),
          ),
          this,
        )..start(),
        destination: (ref) =>
            RealmWorkDestination(ref.read(appRouterProvider), scope),
      );
}

/// Immutable publication facts derived from the leased domain driver.
final class RealmPublicationView {
  const RealmPublicationView({
    required this.report,
    required this.entry,
    required this.canPublish,
  });
  final skir.PublicationReport? report;
  final WorkEntryState entry;
  final bool canPublish;
}

@riverpod
class RealmPublication extends _$RealmPublication {
  late PublicationWorkDriver _driver;
  @override
  Stream<RealmPublicationView> build(
    skir.RecordId organizationId,
    skir.RecordId realmId,
  ) {
    ref
      ..watch(localWorkScopeProvider)
      ..watch(localWorkControllerProvider);
    final work = ref.read(localWorkProvider.notifier);
    _driver = work.getOrRegisterPublication(
      AuthoringScope(organizationId: organizationId, realmId: realmId),
    );
    final lease = work.lease(_driver.id);
    ref.onDispose(lease.release);
    final driver = _driver;
    return Stream.multi((controller) {
      void changed() => controller.add(
        RealmPublicationView(
          report: driver.report,
          entry: driver.snapshot.entries.single,
          canPublish: driver.canPublish,
        ),
      );
      driver.addListener(changed);
      changed();
      controller.onCancel = () => driver.removeListener(changed);
    });
  }

  Future<skir.PublicationResult> publish() => _driver.publish();

  Future<List<skir.CompiledResourceStatus>> states(
    skir.CompilationStatusSelection selection,
  ) => _driver.repository.states(selection);
}
