import "dart:async";

import "package:flutter/foundation.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:riverpod/riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "local_work.freezed.dart";
part "local_work.g.dart";

/// Scope that determines which authenticated workspace owns local work.
///
/// A change to either value replaces the private [LocalWorkSession]. Work is
/// therefore never carried across users or organizations accidentally.
@freezed
abstract class LocalWorkScope with _$LocalWorkScope {
  const factory LocalWorkScope({
    required String? userId,
    required RecordId? organizationId,
  }) = _LocalWorkScope;
}

/// Optional organization and realm scope used to distinguish editor resources.
///
/// The scope is part of an [EditorResourceKey], so equal identities in
/// different resource domains do not share draft or submission state.
@freezed
abstract class EditorResourceScope with _$EditorResourceScope {
  const factory EditorResourceScope({
    required RecordId organizationId,
    RecordId? realmId,
  }) = _EditorResourceScope;
}

/// Stable identity of a resource inside the local work session.
///
/// [identity] identifies the resource and [scope] prevents collisions between
/// domains that use the same identity shape. The key is also the lease and
/// mutation reservation boundary.
@freezed
abstract class EditorResourceKey with _$EditorResourceKey {
  const factory EditorResourceKey({
    required Object? scope,
    required Object identity,
  }) = _EditorResourceKey;
}

/// A live navigation destination owned by one local work session.
///
/// The destination reports whether the resource is currently visible and
/// opens that exact resource when requested. The resource owner disposes it
/// when its lease and draft work both end.
abstract class EditorDestination extends ChangeNotifier {
  /// Whether this destination currently displays its resource.
  bool get isCurrent;

  /// Navigates to the resource represented by this destination.
  Future<void> open();
}

@Riverpod(keepAlive: true)
LocalWorkScope localWorkScope(Ref ref) => LocalWorkScope(
  userId: ref.watch(userIdProvider.select((value) => value.value)),
  organizationId: ref.watch(organizationIdProvider),
);

/// Stable command owner that privately replaces work when its scope changes.
///
/// Riverpod keeps this command surface stable for callers. Mutable resources,
/// reservations, submissions, and editor lifetimes belong to the current
/// [LocalWorkSession], which is discarded when [localWorkScope] changes.
@Riverpod(keepAlive: true)
class LocalWork extends _$LocalWork implements LocalWorkCommands {
  LocalWorkScope? _scope;
  LocalWorkSession? _session;
  StreamSubscription<LocalWorkState>? _subscription;
  bool _disposeRegistered = false;

  LocalWorkSession get _activeSession => _session!;

  @override
  LocalWorkState build() {
    final scope = ref.watch(localWorkScopeProvider);
    if (_session == null || _scope != scope) _replace(scope);
    if (!_disposeRegistered) {
      _disposeRegistered = true;
      ref.onDispose(_dispose);
    }
    return _activeSession.state;
  }

  void _replace(LocalWorkScope scope) {
    unawaited(_subscription?.cancel());
    _session?.dispose();
    final session = LocalWorkSession();
    _scope = scope;
    _session = session;
    _subscription = session.changes.listen((next) {
      if (ref.mounted && identical(_session, session)) state = next;
    });
  }

  void _dispose() {
    unawaited(_subscription?.cancel());
    _session?.dispose();
    _subscription = null;
  }

  @override
  Map<EditorResourceKey, EditorResource> get resources =>
      _activeSession.resources;

  @override
  List<MutationSubmission<Object?>> get submissions =>
      _activeSession.submissions;

  @override
  Future<MutationSubmission<T>> enqueue<T>(PendingCommit<T> pending) =>
      _activeSession.enqueue(pending);

  @override
  MutationSubmission<T> start<T>(
    PreparedCommit<T> commit, {
    MutationReservation? reservation,
  }) => _activeSession.start(commit, reservation: reservation);

  @override
  Future<T> execute<T>(PreparedCommit<T> commit) =>
      _activeSession.execute(commit);

  @override
  void track<T>(MutationSubmission<T> submission) =>
      _activeSession.track(submission);

  @override
  void dismiss(Object id) => _activeSession.dismiss(id);

  @override
  EditorSource editor(EditorTarget target) => _activeSession.editor(target);

  @override
  void retain(EditorResourceKey key) => _activeSession.retain(key);

  @override
  void release(EditorResourceKey key) => _activeSession.release(key);

  @override
  Future<void> retry(Object id) => _activeSession.retry(id);

  @override
  void discard(EditorResourceKey key) => _activeSession.discard(key);

  @override
  Future<void> open(EditorResourceKey key) => _activeSession.open(key);

  @override
  EditorSource? source(EditorResourceKey key) => _activeSession.source(key);
}

/// Exposes the stable command owner without exposing its scoped session.
///
/// Callers use this provider for commands so they do not retain a session that
/// may have been invalidated by authentication or organization changes.
@Riverpod(keepAlive: true)
LocalWorkCommands localWorkController(Ref ref) {
  ref.watch(localWorkProvider);
  return ref.watch(localWorkProvider.notifier);
}
