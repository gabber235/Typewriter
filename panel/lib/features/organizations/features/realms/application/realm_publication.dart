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

/// Owns publication observation and reviewed candidate commands across popup lifetimes.
///
/// The application local work owner retains this driver while needed. Repository
/// observations replace review state, while submission activity independently
/// distinguishes sending and uncertain outcomes. A command is usable only for the
/// exact ready view it captured; disposal retires listeners without deciding the
/// outcome of an already owned submission.
final class PublicationWorkDriver extends ChangeNotifier implements WorkDriver {
  PublicationWorkDriver(this.scope, this.repository, this.work);
  final AuthoringScope scope;
  final RealmPublicationRepository repository;
  final LocalWorkCommands work;
  PublicationObservation _observation = PublicationObservation.fetching(
    skir.PublicationViewId(value: "initial"),
  );
  skir.PublicationView? _last;
  String? _awaitingView;
  StreamSubscription<PublicationObservation>? _subscription;
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
    _observe();
  }

  void _observe() {
    _subscription = repository.watch().listen(
      (observation) {
        if (_closed) return;
        _observation = observation;
        if (observation case AvailablePublicationObservation(:final view)) {
          _last = view;
          if (view.id.value != _awaitingView) _awaitingView = null;
        }
        notifyListeners();
      },
      onError: (Object error) {
        if (_closed) return;
        _observation = PublicationObservation.unavailable(error.toString());
        notifyListeners();
      },
    );
  }

  Iterable<MutationSubmission<Object?>> get _requests =>
      work.submissions.where((submission) => submission.resources.contains(id));
  RealmPublicationView get view {
    final display = _last?.status;
    final uncertain = _requests
        .where((request) => request.result is SubmissionUncertain)
        .firstOrNull;
    if (uncertain != null) {
      return RealmPublicationView.uncertain(
        "The publication request outcome is unknown. Review the activity journal.",
        display: display,
      );
    }
    if (_requests.any((request) => request.sending || request.result == null) ||
        _awaitingView != null) {
      return RealmPublicationView.requestActive(display: display);
    }
    if (_observation case UnavailablePublicationObservation(:final message)) {
      return RealmPublicationView.unavailable(message, display: display);
    }
    if (_observation is FetchingPublicationObservation) {
      return RealmPublicationView.checking(display: display);
    }
    final observed = (_observation as AvailablePublicationObservation).view;
    if (observed.id.value.isEmpty || !validPublicationStatus(observed.status)) {
      return RealmPublicationView.unavailable(
        "The publication view has no identity",
        display: display,
      );
    }
    return switch (observed.status) {
      skir.PublicationStatus_emptyWrapper(:final value) =>
        RealmPublicationView.empty(value),
      skir.PublicationStatus_currentWrapper(:final value)
          when value.selected.value.isNotEmpty =>
        RealmPublicationView.current(value),
      skir.PublicationStatus_readyWrapper(:final value)
          when value.candidate.value.isNotEmpty &&
              value.changes.first is! skir.PublicationChange_unknown =>
        RealmPublicationView.ready(
          value,
          RealmPublishCommand(
            value.candidate,
            () => _publish(value.candidate, observed.id),
          ),
        ),
      skir.PublicationStatus_blockedWrapper(:final value) =>
        RealmPublicationView.blocked(value),
      skir.PublicationStatus_checkingWrapper() => RealmPublicationView.checking(
        display: observed.status,
      ),
      skir.PublicationStatus_publishingWrapper(:final value) =>
        RealmPublicationView.publishing(value),
      skir.PublicationStatus_unavailableWrapper(:final value) =>
        RealmPublicationView.unavailable(
          value.failure.toString(),
          display: observed.status,
        ),
      _ => RealmPublicationView.unavailable(
        "The publication review could not be interpreted",
        display: display,
      ),
    };
  }

  Future<skir.PublishAuthoringResponse> _publish(
    skir.PublicationCandidateId candidate,
    skir.PublicationViewId reviewed,
  ) async {
    if (_closed) throw StateError("Publication work is closed");
    if (view is! ReadyRealmPublication || _last?.id != reviewed) {
      return skir.PublishAuthoringResponse.wrapCandidateChangedError(
        skir.PublicationViewChanged(current: _last?.id ?? reviewed),
      );
    }
    _awaitingView = reviewed.value;
    notifyListeners();
    try {
      final response = await work.execute(repository.preparePublish(candidate));
      return switch (response) {
        skir.PublishAuthoringResponse_internalErrorWrapper() ||
        skir.PublishAuthoringResponse_unknown() =>
          throw ApiException.internalServerError(),
        _ => response,
      };
    } finally {
      await _subscription?.cancel();
      if (!_closed) {
        _observation = PublicationObservation.fetching(_last?.id ?? reviewed);
        _awaitingView = null;
        _observe();
        notifyListeners();
      }
    }
  }

  @override
  WorkDriverSnapshot get snapshot =>
      publicationWorkSnapshot(entryId: entry, view: view);
  @override
  Future<void> save(WorkEntryId entry) =>
      Future.error(StateError("Publication has no draft to save"));
  @override
  bool discard(WorkEntryId entry) => false;
  @override
  Future<void> retry(WorkEntryId entry) => Future.error(
    StateError("Review current saved content before publishing"),
  );
  @override
  void dispose() {
    if (_closed) return;
    _closed = true;
    unawaited(_subscription?.cancel());
    unawaited(_workObservation?.cancel());
    super.dispose();
  }
}

WorkDriverSnapshot publicationWorkSnapshot({
  required WorkEntryId entryId,
  required RealmPublicationView view,
}) {
  final active =
      view is CheckingRealmPublication ||
      view is PublishingRealmPublication ||
      view is RequestActiveRealmPublication;
  final attention =
      view is BlockedRealmPublication ||
      view is UnavailableRealmPublication ||
      view is UncertainRealmPublication;
  final phase = switch (view) {
    EmptyRealmPublication() => "No saved content to publish",
    CurrentRealmPublication() => "Everything is published",
    ReadyRealmPublication() => "Saved changes ready",
    BlockedRealmPublication() => "Publish blocked",
    CheckingRealmPublication() => "Checking saved content",
    PublishingRealmPublication() => "Publishing saved content",
    RequestActiveRealmPublication() => "Awaiting publication status",
    UnavailableRealmPublication() => "Publication review unavailable",
    UncertainRealmPublication() => "Publication outcome unknown",
  };
  return WorkDriverSnapshot(
    entries: [
      WorkEntryState(
        id: entryId,
        label: "Publish saved content",
        phase: phase,
        retained: active || attention,
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
      void changed() => controller.add(driver.view);
      driver.addListener(changed);
      changed();
      controller.onCancel = () => driver.removeListener(changed);
    });
  }

  Future<List<skir.CompiledResourceStatus>> states(
    skir.CompilationStatusSelection selection,
  ) => _driver.repository.states(selection);
}
