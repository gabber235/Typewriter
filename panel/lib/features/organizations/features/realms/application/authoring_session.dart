// Authoring state and commands for one organization and realm.
//
// AuthoringSession is the owner of the canonical authoring read model. It
// keeps one sequence aligned with the server change stream, routes commands
// through the authoring batch protocol, and reconciles gaps or conflicts from
// authoritative snapshots. Editors keep unsubmitted values in
// LocalWorkCommands, not in this session.
//
// The session is keyed by organization and realm through Riverpod. It starts
// its watches when a scope is acquired or the provider is observed, and
// releases subscriptions when its provider is disposed. Library, book, and
// page leases determine which snapshot slices are retained and whether the
// session should stay alive.
//
// AuthoringResourceRepository owns editor resource requests and their mutation
// combiner. SkirMutationClient owns request transport and local submission
// integration. RealmServiceAddress only maps the organization and realm
// identifiers to service subjects. The realm service owns durable persistence.
import "dart:async";

import "package:freezed_annotation/freezed_annotation.dart";
import "package:hooks_riverpod/hooks_riverpod.dart" show WidgetRef;
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "authoring_session.freezed.dart";
part "authoring_session.g.dart";
part "authoring_session_snapshots.dart";
part "authoring_resource_repository.dart";
part "authoring_editor_resource.dart";
part "authoring_session_state.dart";
part "authoring_session_sync.dart";
part "authoring_operation_resources.dart";
part "authoring_operation_label.dart";

@riverpod
/// Owns the canonical authoring state for one organization and realm.
///
/// Canonical state contains only server accepted books, tags, pages, and page
/// documents. Local editor drafts belong to [LocalWorkCommands] and are
/// projected over this state by editor resources. A state [sequence] couples
/// every canonical projection to the server revision that produced it. The
/// session applies only the next sequence, buffers future changes, and fetches
/// a snapshot when a gap, conflict, reconnect, or indirect page dependency
/// makes incremental reconciliation unsafe.
///
/// Use a scope lease before reading a resource that needs an authoritative
/// snapshot. The lease keeps this provider alive, waits for subscriptions and
/// its initial refresh through [AuthoringScopeLease.ready], and must be
/// released when the resource stops being used.
///
/// Direct create and delete commands are routed through [prepare] and
/// [apply]. Editor updates normally enter through
/// [AuthoringResourceRepository.combiner], so several editor intents can share
/// one authoring batch without the session owning editor presentation state.
class AuthoringSession extends _$AuthoringSession
    with _AuthoringSessionSnapshots, _AuthoringSessionSync {
  @override
  AuthoringSessionState build(
    skir.RecordId organizationId,
    skir.RecordId realmId,
  ) {
    _client = ref.watch(natsProvider);
    final repository = ref
        .watch(resourceRepositoriesProvider)
        .authoring(organizationId, realmId);
    final results = repository.changes.listen(_accept);
    final invalidations = repository.invalidations.listen(
      (_) => _scheduleRefresh(),
    );
    ref
      ..onDispose(results.cancel)
      ..onDispose(invalidations.cancel);
    _address = RealmServiceAddress(
      organizationId: organizationId,
      realmId: realmId,
    );

    ref.onDispose(_dispose);
    _startOperation = _start();
    return const AuthoringSessionState();
  }

  /// Returns the current canonical read model without creating a copy.
  ///
  /// The model may be empty before a held scope has completed [refresh]. It
  /// never includes local editor drafts.
  AuthoringSessionState get snapshot => state;

  /// Fetches authoritative snapshots for all currently held scopes.
  ///
  /// The operation updates [snapshot] and sequence state when the response is
  /// current enough to reconcile. It is safe to call while another refresh is
  /// running because refresh requests coalesce.
  Future<void> refresh() => _refresh();

  /// Retains the library scope and returns its lifecycle lease.
  ///
  /// Await [AuthoringScopeLease.ready] before using library collections, then
  /// call [AuthoringScopeLease.release] exactly once when finished.
  AuthoringScopeLease acquireLibrary() =>
      _acquire(const _AuthoringScope.library());

  /// Retains the book scope and returns its lifecycle lease.
  ///
  /// The first lease for [bookId] fetches the book and its pages. Await
  /// [AuthoringScopeLease.ready] before reading the resulting canonical state.
  /// Release the lease when the book is no longer in use.
  AuthoringScopeLease acquireBook(skir.ResourceId bookId) =>
      _acquire(_AuthoringScope.book(bookId));

  /// Retains the page scope and returns its lifecycle lease.
  ///
  /// The first lease for [pageId] fetches the page and its document. Await
  /// [AuthoringScopeLease.ready] before reading the resulting canonical state.
  /// Release the lease when the page is no longer in use.
  AuthoringScopeLease acquirePage(skir.ResourceId pageId) =>
      _acquire(_AuthoringScope.page(pageId));

  /// Prepares one authoring batch for the shared local mutation owner.
  ///
  /// The caller supplies operations that already contain their expected values.
  /// [batchId] may identify a retry; an omitted value creates a new id. The
  /// returned commit captures the request, reserves every affected resource,
  /// and classifies applied, rejected, and unconfirmed responses. Integration
  /// advances canonical state from the applied event and refreshes after a
  /// conflict. The caller must submit the returned commit through
  /// [LocalWorkCommands], not send it directly.
  PreparedCommit<skir.ApplyAuthoringBatchResponse> prepare(
    Iterable<skir.AuthoringOperation> operations, {
    String? batchId,
  }) {
    final request = skir.ApplyAuthoringBatchRequest(
      batchId: batchId ?? uuid.v4(),
      generation:
          state.generation ??
          (throw StateError("The authoring catalog is not loaded")),
      operations: operations,
    );
    return ref.prepareSkir(
      _address.request("library.authoring.batch.apply"),
      skir.ApplyAuthoringBatchRequest.serializer.toBytes(request),
      skir.ApplyAuthoringBatchResponse.serializer,
      label: _authoringLabel(request.operations),
      classify: (response) => switch (response) {
        skir.ApplyAuthoringBatchResponse_appliedWrapper() =>
          MutationResponseDisposition.confirmed,
        skir.ApplyAuthoringBatchResponse_unknown() ||
        skir.ApplyAuthoringBatchResponse_internalErrorWrapper() =>
          MutationResponseDisposition.uncertain,
        _ => MutationResponseDisposition.rejected,
      },
      onResponse: (response) async {
        switch (response) {
          case skir.ApplyAuthoringBatchResponse_appliedWrapper(:final value):
            _accept(value);
          case skir.ApplyAuthoringBatchResponse_conflictWrapper():
            await _refresh();
          case skir.ApplyAuthoringBatchResponse_catalogChangedWrapper():
            await _refresh();
          case skir.ApplyAuthoringBatchResponse_invalidWrapper() ||
              skir.ApplyAuthoringBatchResponse_internalErrorWrapper() ||
              skir.ApplyAuthoringBatchResponse_unknown():
        }
      },
      submissionId: request.batchId,
      resources: {
        for (final operation in request.operations)
          for (final resource in _operationResources(operation))
            (organizationId, realmId, resource),
      },
      replay: SubmissionReplay.identicalRequest,
    );
  }

  /// Applies one authoring batch through the shared local mutation owner.
  ///
  /// Each operation must carry the expected server value required by the
  /// authoring protocol. On success, the applied change is integrated into
  /// canonical state. A conflict triggers authoritative refresh before the
  /// failure returns to the caller.
  Future<skir.ApplyAuthoringBatchResponse> apply(
    Iterable<skir.AuthoringOperation> operations, {
    String? batchId,
  }) async {
    final commit = prepare(operations, batchId: batchId);
    try {
      return await ref.read(localWorkControllerProvider).execute(commit);
    } on Object {
      _scheduleRefresh();
      rethrow;
    }
  }

  /// Executes operations and Realm page rules without committing state.
  Future<skir.PreviewAuthoringBatchResponse> preview(
    Iterable<skir.AuthoringOperation> operations,
  ) {
    final request = skir.PreviewAuthoringBatchRequest(
      generation:
          state.generation ??
          (throw StateError("The authoring catalog is not loaded")),
      operations: operations,
    );
    return ref.requestSkir(
      _address.request("library.authoring.batch.preview"),
      skir.PreviewAuthoringBatchRequest.serializer.toBytes(request),
      skir.PreviewAuthoringBatchResponse.serializer,
    );
  }

  _AuthoringScopeLease _acquire(_AuthoringScope scope) {
    final added = !_scopeCounts.containsKey(scope);
    _scopeCounts.update(scope, (count) => count + 1, ifAbsent: () => 1);
    final ready = added
        ? _scopeReadiness[scope] = _startOperation.then((_) => _refresh())
        : _scopeReadiness[scope] ?? _startOperation;
    final retention = ref.keepAlive();
    return _AuthoringScopeLease(ready, () {
      _release(scope);
      retention.close();
    });
  }

  void _release(_AuthoringScope scope) {
    final count = _scopeCounts[scope];
    if (count == null) return;
    if (count == 1) {
      _scopeCounts.remove(scope);
      _scopeReadiness.remove(scope);
    } else {
      _scopeCounts[scope] = count - 1;
    }
  }
}

/// Pairs the session command owner with the canonical state read for one
/// organization and realm.
@freezed
abstract class AuthoringSessionAccess with _$AuthoringSessionAccess {
  const factory AuthoringSessionAccess({
    required AuthoringSession notifier,
    required AuthoringSessionState state,
  }) = _AuthoringSessionAccess;
}

/// Adds provider helpers for acquiring the selected authoring session.
extension AuthoringSessionRef on Ref {
  /// Resolves the selected organization and realm session for a provider.
  ///
  /// Throws when no organization or realm is selected.
  AuthoringSessionAccess readAuthoringSession() {
    final organizationId = read(organizationIdProvider);
    final realmId = read(realmIdProvider);
    if (organizationId == null) throw ApiException.noOrganization();
    if (realmId == null) throw ApiException.badRequest("No realm selected");
    final provider = authoringSessionProvider(organizationId, realmId);
    return AuthoringSessionAccess(
      notifier: read(provider.notifier),
      state: read(provider),
    );
  }
}

/// Adds the selected authoring session helper to widget references.
extension AuthoringSessionWidgetRef on WidgetRef {
  /// Resolves the selected organization and realm session for a widget.
  ///
  /// Throws when no organization or realm is selected.
  AuthoringSessionAccess readAuthoringSession() {
    final organizationId = read(organizationIdProvider);
    final realmId = read(realmIdProvider);
    if (organizationId == null) throw ApiException.noOrganization();
    if (realmId == null) throw ApiException.badRequest("No realm selected");
    final provider = authoringSessionProvider(organizationId, realmId);
    return AuthoringSessionAccess(
      notifier: read(provider.notifier),
      state: read(provider),
    );
  }
}

/// Converts authoring validation diagnostics into the panel's API error type.
extension AuthoringInvalidFailure on skir.AuthoringInvalid {
  String get message =>
      diagnostics.map((diagnostic) => diagnostic.message).join("; ");

  ApiException toApiException() => ApiException.badRequest(message);
}

/// Converts non applied authoring batch responses into caller visible errors.
extension AuthoringBatchFailure on skir.ApplyAuthoringBatchResponse {
  void requireApplied({required String conflictMessage}) {
    switch (this) {
      case skir.ApplyAuthoringBatchResponse_appliedWrapper():
        return;
      case skir.ApplyAuthoringBatchResponse_conflictWrapper():
        throw ApiException.conflict(conflictMessage);
      case skir.ApplyAuthoringBatchResponse_catalogChangedWrapper():
        throw ApiException.conflict("The authoring catalog changed");
      case skir.ApplyAuthoringBatchResponse_invalidWrapper() ||
          skir.ApplyAuthoringBatchResponse_internalErrorWrapper() ||
          skir.ApplyAuthoringBatchResponse_unknown():
        throw toApiException();
    }
  }

  ApiException toApiException() => switch (this) {
    skir.ApplyAuthoringBatchResponse_invalidWrapper(:final value) =>
      value.toApiException(),
    skir.ApplyAuthoringBatchResponse_internalErrorWrapper() =>
      ApiException.internalServerError(),
    skir.ApplyAuthoringBatchResponse_unknown() =>
      ApiException.unknownResponseMessage(),
    skir.ApplyAuthoringBatchResponse_catalogChangedWrapper() =>
      ApiException.conflict("The authoring catalog changed"),
    _ => throw StateError("The authoring response is not a failure"),
  };

  TypedMutationResult toMutationFailure({required String unavailableMessage}) =>
      switch (this) {
        skir.ApplyAuthoringBatchResponse_invalidWrapper(:final value) =>
          invalidMutation(value.message),
        skir.ApplyAuthoringBatchResponse_internalErrorWrapper() ||
        skir.ApplyAuthoringBatchResponse_unknown() => unavailableMutation(
          unavailableMessage,
        ),
        _ => throw StateError(
          "The authoring response is not a mutation failure",
        ),
      };
}

/// Keeps the library projection and its session alive while observed.
@riverpod
AuthoringScopeLease authoringLibraryScope(
  Ref ref,
  skir.RecordId organizationId,
  skir.RecordId realmId,
) {
  final session = authoringSessionProvider(organizationId, realmId);
  final lease = ref.read(session.notifier).acquireLibrary();
  ref.onDispose(lease.release);
  return lease;
}

/// Keeps a book projection and its session alive while observed.
@riverpod
AuthoringScopeLease authoringBookScope(
  Ref ref,
  skir.RecordId organizationId,
  skir.RecordId realmId,
  skir.ResourceId bookId,
) {
  final session = authoringSessionProvider(organizationId, realmId);
  final lease = ref.read(session.notifier).acquireBook(bookId);
  ref.onDispose(lease.release);
  return lease;
}

/// Keeps a page projection and its session alive while observed.
@riverpod
AuthoringScopeLease authoringPageScope(
  Ref ref,
  skir.RecordId organizationId,
  skir.RecordId realmId,
  skir.ResourceId pageId,
) {
  final session = authoringSessionProvider(organizationId, realmId);
  final lease = ref.read(session.notifier).acquirePage(pageId);
  ref.onDispose(lease.release);
  return lease;
}
