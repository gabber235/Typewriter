import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

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
  (T?, Widget?) require<T>(AsyncValue<T> value, VoidCallback retry) {
    if (value.hasError) {
      return (null, _Error(value.error!, retry));
    }
    if (value.isLoading) {
      return (null, const _Loading());
    }
    return (value.value, null);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (_, otelWidget) = require(
      ref.watch(panelTelemetryProvider),
      () => ref.invalidate(panelTelemetryProvider),
    );
    if (otelWidget != null) {
      return otelWidget;
    }

    // Fetch sentinel credentials before authentication checks
    final (_, sentinelWidget) = require(
      ref.watch(sentinelCredentialsProvider),
      () => ref.invalidate(sentinelCredentialsProvider),
    );
    if (sentinelWidget != null) {
      return sentinelWidget;
    }

    final (isAuthenticated, authenticatedWidget) = require(
      ref.watch(isAuthenticatedProvider),
      () => ref.invalidate(authProvider),
    );
    if (authenticatedWidget != null) {
      return authenticatedWidget;
    }
    if (isAuthenticated != true) {
      return child;
    }

    final (token, accessWidget) = require(
      ref.watch(accessTokenProvider),
      () => ref.invalidate(authProvider),
    );
    if (accessWidget != null) {
      return accessWidget;
    }
    if (token == null) {
      return child;
    }

    final (_, authUserInfoWidget) = require(
      ref.watch(authUserInfoProvider),
      () => ref.invalidate(authProvider),
    );
    if (authUserInfoWidget != null) {
      return authUserInfoWidget;
    }

    return child;
  }
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
