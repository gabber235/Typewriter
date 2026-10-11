import "package:typewriter_panel/typewriter_panel.dart";

/// Gates authenticated route content on the panel's NATS lifecycle.
///
/// Unauthenticated content passes through so the sign in route remains usable.
/// Authenticated routes stay mounted while connection status blocks access.
/// Failure states map to safe recovery actions. The underlying exception is
/// not displayed because it may contain sensitive connection details.
class RequiredNatsConnection extends HookConsumerWidget {
  const RequiredNatsConnection({required this.child, super.key});

  /// Content shown after authentication and NATS connection succeed.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final token = ref.watch(accessTokenProvider).value;
    // Unauthenticated content must remain reachable so the user can sign in.
    if (token == null) {
      return child;
    }

    final connectionState = ref.watch(natsLifecycleProvider);
    ref.watch(organizationPresenceProvider);
    final status = switch (connectionState) {
      NatsConnected() => null,
      NatsConnecting() || NatsReconnecting() => const LoadingScreen(),
      NatsFailed(:final failure) => _ConnectionFailure(failure),
      NatsClosed() => const _ConnectionClosed(),
    };
    final blocked = status != null;
    return Stack(
      children: [
        Positioned.fill(
          child: Offstage(
            offstage: blocked,
            child: ExcludeFocus(
              excluding: blocked,
              child: TickerMode(enabled: !blocked, child: child),
            ),
          ),
        ),
        if (status != null) Positioned.fill(child: status),
      ],
    );
  }
}

/// Converts a classified NATS failure into a safe user action.
final class _ConnectionFailure extends StatelessWidget {
  const _ConnectionFailure(this.failure);

  final NatsClientException failure;

  @override
  Widget build(BuildContext context) {
    return switch (failure.kind) {
      NatsFailureKind.authentication ||
      NatsFailureKind.permission => const ErrorScreen(
        title: "Access denied",
        message: "Your session could not be authorized. Sign out, then sign in again.",
        child: SignOutButton(),
      ),
      NatsFailureKind.protocol => ErrorScreen(
        title: "Connection incompatible",
        message: "The panel could not complete the NATS protocol handshake. Retry, then report the problem if it continues.",
        child: _RetryNatsButton(),
      ),
      NatsFailureKind.unavailable ||
      NatsFailureKind.timeout ||
      NatsFailureKind.noResponders => ErrorScreen(
        title: "Server unavailable",
        message: "The Typewriter service is unavailable. Check your connection and try again.",
        child: _RetryNatsButton(),
      ),
      NatsFailureKind.closed || NatsFailureKind.unknown => ErrorScreen(
        title: "Connection failed",
        message: "The panel could not connect to Typewriter. Retry, then report the problem if it continues.",
        child: _RetryNatsButton(),
      ),
    };
  }
}

/// Presents recovery when the NATS client has closed without a retryable error.
final class _ConnectionClosed extends StatelessWidget {
  const _ConnectionClosed();

  @override
  Widget build(BuildContext context) => const ErrorScreen(
    title: "Connection closed",
    message: "The Typewriter connection was closed.",
    child: _RetryNatsButton(),
  );
}

final class _RetryNatsButton extends ConsumerWidget {
  const _RetryNatsButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LoadingButton(
      onPressed: () => ref.read(natsProvider.notifier).retry(),
      child: const Text("Retry"),
    );
  }
}
