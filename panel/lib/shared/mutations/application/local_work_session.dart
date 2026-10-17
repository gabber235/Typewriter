import "package:typewriter_panel/typewriter_panel.dart";

part "local_work_snapshot.dart";

/// Commands and live editor access owned by the current local work scope.
///
/// Implementations own resource leases and submission lifetimes. Callers may
/// retain a resource while a screen is alive, but must release it when the
/// screen ends. A scoped owner may reject commands after its session ends.
abstract interface class LocalWorkCommands {
  Stream<LocalWorkState> get changes;

  /// Submission records that have not yet expired or been dismissed.
  List<MutationSubmission<Object?>> get submissions;

  Future<MutationReservation> reserve(Set<Object> resources);

  /// Starts an already captured commit, optionally transferring [reservation].
  MutationSubmission<T> start<T>(
    PreparedCommit<T> commit, {
    MutationReservation? reservation,
  });

  /// Starts [commit] and returns its feature response, throwing when delivery
  /// remains uncertain.
  Future<T> execute<T>(PreparedCommit<T> commit);

  /// Adds an externally created submission to the activity journal.
  void track<T>(MutationSubmission<T> submission);

  /// Removes a settled submission from the activity journal.
  void dismiss(Object id);

  void setDestination(WorkDriverId driver, WorkDestination? destination);
  WorkReviewLease? review(WorkEntryId entry);

  /// Retries a failed submission or flushes the draft that owns its identity.
  Future<void> retrySubmission(Object id);

  Future<void> retry(WorkEntryId entry);
  Future<void> save(WorkEntryId entry);
  WorkDriverId register(WorkDriver driver, {WorkDestination? destination});

  /// Reuses the driver with [id], or transfers ownership of a newly created one.
  ///
  /// A supplied destination replaces the existing owned target. The factory
  /// must preserve [id] and the existing registration must have type [D].
  D getOrRegister<D extends WorkDriver>(
    WorkDriverId id,
    D Function() create, {
    WorkDestination? destination,
  });
  WorkLease lease(WorkDriverId driver);

  /// Discards the local draft when its save lifecycle permits it.
  bool discard(WorkEntryId entry);

  /// Opens the owning driver's current destination for [entry], if available.
  Future<void> open(WorkEntryId entry);
}

/// Owns mutable editors and submissions for one user and organization scope.
///
/// The session is the consistency boundary for resource reservations and the
/// activity journal. It publishes immutable [LocalWorkState] snapshots, while
/// editor sources and submissions remain owned objects behind this read model.
/// Dispose ends the scope, releases all resources, rejects queued reservations,
/// and prevents later publication.
final class ScopedWorkSession implements LocalWorkCommands {
  ScopedWorkSession();

  final Map<WorkDriverId, OwnedWorkDriver> _drivers = {};
  final MutationCoordinator coordinator = MutationCoordinator();
  final Map<Object, MutationSubmission<Object?>> _submissions = {};
  final Map<Object, Timer> _expiry = {};
  final StreamController<LocalWorkState> _changes =
      StreamController.broadcast();
  LocalWorkState _state = const LocalWorkState();
  bool _disposed = false;

  @override
  List<MutationSubmission<Object?>> get submissions =>
      List.unmodifiable(_submissions.values);

  /// Latest immutable read model for resources, local values, and submissions.
  LocalWorkState get state => _state;

  /// Emits a new state only when the read model changes.
  @override
  Stream<LocalWorkState> get changes => _changes.stream;

  @override
  Future<MutationReservation> reserve(Set<Object> resources) =>
      coordinator.reserve(resources);

  @override
  MutationSubmission<T> start<T>(
    PreparedCommit<T> commit, {
    MutationReservation? reservation,
  }) => _start(commit, reservation);

  MutationSubmission<T> _start<T>(
    PreparedCommit<T> commit,
    MutationReservation? initialReservation,
  ) {
    if (_disposed) throw StateError("Mutation session ended");
    if (_submissions.containsKey(commit.id)) {
      throw StateError(
        "A prepared identity is already owned; retry its submission",
      );
    }
    var reservation = initialReservation;
    final submission = MutationSubmission<T>(
      id: commit.id,
      label: commit.label,
      resources: commit.resources,
      replay: commit.replay,
      integrate: (result) async {
        try {
          await commit.integrate?.call(result);
        } finally {
          reservation?.release();
          reservation = null;
        }
      },
      onDispose: () {
        reservation?.release();
        commit.dispose?.call();
      },
      send: () async {
        reservation ??= await coordinator.reserve(commit.resources);
        return commit.send();
      },
    );
    track(submission);
    unawaited(submission.run());
    return submission;
  }

  /// Runs [commit] through the journal and returns only a settled response.
  ///
  /// Confirmed and rejected responses are returned to the caller. An
  /// uncertain result becomes [SubmissionException], preserving replay policy
  /// and the original cause for an explicit recovery decision.
  @override
  Future<T> execute<T>(PreparedCommit<T> commit) async {
    final submission = start(commit);
    return switch (await submission.run()) {
      SubmissionConfirmed(:final value) => value,
      SubmissionRejected(response: final T response) => response,
      _ => throw SubmissionException(submission),
    };
  }

  /// Adds [submission] to the journal and observes its lifecycle.
  ///
  /// A later submission with the same label and resources replaces an earlier
  /// settled rejection. Active or uncertain records are preserved because
  /// dismissing them could hide an unresolved persistence outcome.
  @override
  void track<T>(MutationSubmission<T> submission) {
    if (_disposed) throw StateError("Mutation journal is disposed");
    if (_submissions.containsKey(submission.id)) return;
    for (final previous in _submissions.values.toList()) {
      if (!previous.sending &&
          previous.result is SubmissionRejected &&
          submission.resources.isNotEmpty &&
          previous.label == submission.label &&
          setEquals(previous.resources, submission.resources)) {
        dismiss(previous.id);
      }
    }
    _submissions[submission.id] = submission;
    submission.addListener(_publish);
    _publish();
  }

  @override
  void dismiss(Object id) {
    final submission = _submissions[id];
    if (submission == null ||
        submission.sending ||
        submission.result is SubmissionUncertain) {
      return;
    }
    _expiry.remove(id)?.cancel();
    _submissions.remove(id)?.removeListener(_publish);
    submission.dispose();
    _publish();
  }

  @override
  void setDestination(WorkDriverId driver, WorkDestination? destination) {
    final owned = _drivers[driver];
    if (_disposed || owned == null) {
      destination?.dispose();
      throw StateError("The work driver is unavailable");
    }
    owned.destination = destination;
    _publish();
  }

  @override
  WorkDriverId register(WorkDriver driver, {WorkDestination? destination}) {
    if (_disposed) throw StateError("The work session ended");
    if (_drivers.containsKey(driver.id)) {
      throw StateError("A work driver identity is already owned");
    }
    void changed() {
      _publish();
      scheduleMicrotask(() => _tryRelease(driver.id));
    }

    final owned = OwnedWorkDriver(driver, changed, destination: destination);
    _drivers[driver.id] = owned;
    driver.addListener(changed);
    _publish();
    return driver.id;
  }

  @override
  D getOrRegister<D extends WorkDriver>(
    WorkDriverId id,
    D Function() create, {
    WorkDestination? destination,
  }) {
    if (_disposed) throw StateError("The work session ended");
    final existing = _drivers[id];
    if (existing != null) {
      if (existing.driver is! D) {
        throw StateError("The work identity has another driver type");
      }
      if (destination != null &&
          !identical(existing.destination, destination)) {
        existing.destination = destination;
      }
      return existing.driver as D;
    }
    final driver = create();
    if (driver.id != id) {
      driver.dispose();
      throw StateError(
        "The registered driver must preserve its requested identity",
      );
    }
    register(driver, destination: destination);
    return driver;
  }

  @override
  WorkLease lease(WorkDriverId driver) {
    if (_disposed) throw StateError("The work session ended");
    final owned = _drivers[driver];
    if (owned == null) throw StateError("The work driver is unavailable");
    owned.leases++;
    _publish();
    return WorkLease(() {
      if (_disposed || !identical(_drivers[driver], owned)) return;
      owned.leases--;
      _tryRelease(driver);
    });
  }

  void _tryRelease(WorkDriverId id) {
    if (_disposed) return;
    final owned = _drivers[id];
    if (owned == null || owned.leases > 0 || owned.retained) return;
    _drivers.remove(id);
    owned.dispose();
    _publish();
  }

  @override
  Future<void> retrySubmission(Object id) async {
    final submission = _submissions[id];
    if (submission == null) return;
    await submission.run();
  }

  @override
  WorkReviewLease? review(WorkEntryId entry) {
    final owned = _drivers[entry.driver];
    if (_disposed || owned == null || owned.driver is! WorkReviewProvider) {
      return null;
    }
    final retained = lease(entry.driver);
    try {
      final content = (owned.driver as WorkReviewProvider).buildReview(entry);
      if (content == null) {
        retained.release();
        return null;
      }
      return WorkReviewLease(content, retained);
    } on Object {
      retained.release();
      rethrow;
    }
  }

  WorkEntryState _entry(WorkEntryId entry) {
    if (_disposed) throw StateError("The work session ended");
    final driver = _drivers[entry.driver]?.driver;
    if (driver == null) throw StateError("The work driver is unavailable");
    return driver.snapshot.entries.firstWhere((value) => value.id == entry);
  }

  @override
  Future<void> save(WorkEntryId entry) {
    if (!_entry(entry).canSave) {
      return Future.error(StateError("This work cannot currently be saved"));
    }
    return _drivers[entry.driver]!.driver.save(entry);
  }

  @override
  Future<void> retry(WorkEntryId entry) {
    if (!_entry(entry).canRetry) {
      return Future.error(StateError("This work cannot currently be retried"));
    }
    return _drivers[entry.driver]!.driver.retry(entry);
  }

  @override
  bool discard(WorkEntryId entry) =>
      _entry(entry).canDiscard && _drivers[entry.driver]!.driver.discard(entry);

  @override
  Future<void> open(WorkEntryId entry) async {
    final owned = _drivers[entry.driver];
    await owned?.destination?.open();
  }

  /// Ends this scope and releases every owned resource and submission.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final owned in _drivers.values) {
      owned.dispose();
    }
    _drivers.clear();
    coordinator.dispose();
    for (final timer in _expiry.values) {
      timer.cancel();
    }
    for (final submission in _submissions.values) {
      submission
        ..removeListener(_publish)
        ..dispose();
    }
    _expiry.clear();
    _submissions.clear();
    unawaited(_changes.close());
  }
}
