import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

class EagerInitialization extends ConsumerWidget {
  const EagerInitialization({required this.child, super.key});
  final Widget child;

  (T?, Widget?) require<T>(AsyncValue<T> value) {
    if (value.hasError) {
      return (null, _Error(value.error!));
    }
    if (value.isLoading) {
      return (null, const _Loading());
    }
    return (value.value, null);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (_, otelWidget) = require(ref.watch(panelTelemetryProvider));
    if (otelWidget != null) {
      return otelWidget;
    }

    // Fetch sentinel credentials before authentication checks
    final (_, sentinelWidget) = require(ref.watch(sentinelCredentialsProvider));
    if (sentinelWidget != null) {
      return sentinelWidget;
    }

    final (isAuthenticated, authenticatedWidget) = require(
      ref.watch(isAuthenticatedProvider),
    );
    if (authenticatedWidget != null) {
      return authenticatedWidget;
    }
    if (isAuthenticated != true) {
      return child;
    }

    final (token, accessWidget) = require(ref.watch(accessTokenProvider));
    if (accessWidget != null) {
      return accessWidget;
    }
    if (token == null) {
      return child;
    }

    final (_, authUserInfoWidget) = require(ref.watch(authUserInfoProvider));
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

class _Error extends HookConsumerWidget {
  const _Error(this.error);
  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: "Typewriter",
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      builder: (context, child) => Responsive(child: child!),
      home: Scaffold(
        body: ErrorScreen(message: "$error", child: SignOutButton()),
      ),
    );
  }
}
