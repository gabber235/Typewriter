import "package:typewriter_panel/typewriter_panel.dart";

/// Gates authenticated route content on the panel's NATS lifecycle.
///
/// Unauthenticated content passes through so the sign in route remains usable.
/// Authenticated content is withheld while connecting, and failure states are
/// mapped to safe recovery actions. The underlying exception is not displayed
/// because it may contain sensitive connection details.
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
    switch (connectionState) {
      case NatsConnecting() || NatsReconnecting():
        return const LoadingScreen();
      case NatsConnected():
        return child;
      case NatsFailed(:final failure):
        return _ConnectionFailure(failure);
      case NatsClosed():
        return const _ConnectionClosed();
    }
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
