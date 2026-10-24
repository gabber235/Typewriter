import "package:typewriter_panel/typewriter_panel.dart";

part "eager_initialization.freezed.dart";

/// Resolves global startup dependencies before exposing the application shell.
///
/// Providers are watched in dependency order. Telemetry and sentinel
/// credentials are required for transport setup, while authentication data is
/// only loaded after authentication has been established. Loading and failure
/// are rendered locally so the router never evaluates guards against partial
/// startup state.
class EagerInitialization extends ConsumerWidget {
  const EagerInitialization({required this.child, super.key});
  final Widget child;

  /// Converts an asynchronous dependency into either its value or a boundary
  /// widget. A null value is valid and therefore remains distinct from an
  /// error or loading state. Retry recomputes the owner of the failed dependency.
  _StartupDependency<T> _require<T>(AsyncValue<T> value, VoidCallback retry) {
    if (value.hasError) {
      return _StartupDependency.blocked(_Error(value.error!, retry));
    }
    if (value.isLoading) {
      return const _StartupDependency.blocked(_Loading());
    }
    return _StartupDependency.ready(value.value);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (_require(
          ref.watch(panelTelemetryProvider),
          () => ref.invalidate(panelTelemetryProvider),
        )
        case _BlockedDependency(:final boundary)) {
      return boundary;
    }

    // Fetch sentinel credentials before authentication checks
    if (_require(
          ref.watch(sentinelCredentialsProvider),
          () => ref.invalidate(sentinelCredentialsProvider),
        )
        case _BlockedDependency(:final boundary)) {
      return boundary;
    }

    switch (_require(
      ref.watch(isAuthenticatedProvider),
      () => ref.invalidate(authProvider),
    )) {
      case _BlockedDependency(:final boundary):
        return boundary;
      case _ReadyDependency(:final value) when value != true:
        return child;
      case _ReadyDependency():
        break;
    }

    switch (_require(
      ref.watch(accessTokenProvider),
      () => ref.invalidate(authProvider),
    )) {
      case _BlockedDependency(:final boundary):
        return boundary;
      case _ReadyDependency(:final value) when value == null:
        return child;
      case _ReadyDependency():
        break;
    }

    if (_require(
          ref.watch(authUserInfoProvider),
          () => ref.invalidate(authProvider),
        )
        case _BlockedDependency(:final boundary)) {
      return boundary;
    }

    return child;
  }
}

/// A startup dependency that is either resolved or represented by the boundary
/// widget shown while it loads or after it fails.
@freezed
sealed class _StartupDependency<T> with _$StartupDependency<T> {
  const factory _StartupDependency.ready(T? value) = _ReadyDependency<T>;
  const factory _StartupDependency.blocked(Widget boundary) =
      _BlockedDependency<T>;
}

class _Loading extends HookWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Typewriter",
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      builder: (context, child) => Responsive(child: child!),
      home: Scaffold(body: const LoadingScreen(title: "Authenticating User")),
    );
  }
}

class _Error extends StatelessWidget {
  const _Error(this.error, this.retry);
  final Object error;
  final VoidCallback retry;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Typewriter",
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      builder: (context, child) => Responsive(child: child!),
      home: Scaffold(
        body: ErrorScreen(
          message: "$error",
          child: ElevatedButton(onPressed: retry, child: const Text("Retry")),
        ),
      ),
    );
  }
}
