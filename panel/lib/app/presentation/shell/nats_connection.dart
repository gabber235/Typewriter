import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
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
        return _ConnectedContent(
          authorization: ref.watch(natsAuthorizationProvider),
          child: child,
        );
      case NatsFailed(:final failure):
        return _ConnectionFailure(failure);
      case NatsClosed():
        return const _ConnectionClosed();
    }
  }
}

/// Keeps accepted work mounted while a broader authorization scope is checked.
final class _ConnectedContent extends StatelessWidget {
  const _ConnectedContent({required this.authorization, required this.child});

  final AsyncValue<AsyncValue<Set<skir.RecordId>>> authorization;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final status = authorization.when(
      data: (value) => value,
      loading: () => null,
      error: AsyncError.new,
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        if (status case AsyncLoading())
          const _AuthorizationNotice.loading()
        else if (status case AsyncError())
          const _AuthorizationNotice.failure(),
      ],
    );
  }
}

final class _AuthorizationNotice extends StatelessWidget {
  const _AuthorizationNotice.loading()
    : title = "Checking access",
      message = "Your current work remains available while access is checked.",
      canRetry = false;

  const _AuthorizationNotice.failure()
    : title = "Access update failed",
      message = "Your current work is still available. Retry the access check.",
      canRetry = true;

  final String title;
  final String message;
  final bool canRetry;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.all(context.spacing.space4),
          child: Material(
            elevation: 8,
            borderRadius: context.shapes.mediumBorderRadius,
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.spacing.space4,
                vertical: context.spacing.space3,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!canRetry) ...[
                    const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: context.spacing.space3),
                  ],
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(message),
                      ],
                    ),
                  ),
                  if (canRetry) ...[
                    SizedBox(width: context.spacing.space4),
                    const _RetryNatsButton(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
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
