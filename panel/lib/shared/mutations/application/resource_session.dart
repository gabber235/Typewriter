import "package:typewriter_panel/typewriter_panel.dart";

part "resource_session.g.dart";

/// The authenticated mutation transport of the active local work scope.
///
/// Repositories of every capability hold it. It ends when the scope changes,
/// and a repository used after that fails fast.
final class ResourceSession {
  ResourceSession(this.transport, this.userId);

  final SkirMutationClient transport;
  final String? userId;
  bool _ended = false;

  /// Fails fast when a repository is used after the scope ended.
  void checkActive() {
    if (_ended) throw StateError("The resource session ended");
  }

  String requireUserId() {
    checkActive();
    return userId ?? (throw ApiException.notAuthenticated());
  }

  /// Ends the scope; repositories that still hold this session fail fast.
  void end() => _ended = true;
}

/// Provides the resource session for the active local work scope.
///
/// A new scope or user replaces the session, which in turn replaces every
/// capability repository built on it.
@Riverpod(keepAlive: true)
ResourceSession resourceSession(Ref ref) {
  ref.watch(localWorkScopeProvider);
  final telemetry = ref.watch(panelTelemetryProvider.future);
  final session = ResourceSession(
    SkirMutationClient(() => ref.read(natsProvider), () => telemetry),
    ref.watch(userIdProvider).value,
  );
  ref.onDispose(session.end);
  return session;
}
