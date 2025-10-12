import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/widgets/generic/components/loading_indicator.dart";
import "package:typewriter_panel/widgets/generic/components/retry_indicator.dart";
import "package:typewriter_panel/widgets/generic/screens/error_screen.dart";

class StateException implements Exception {
  const StateException(this.message);
  final String message;

  @override
  String toString() => message;
}

extension AsyncValueExtension<T> on AsyncValue<T> {
  Widget call({
    required String name,
    required Widget Function(T value) builder,
    bool shrink = false,
    Widget Function(String name)? loading,
    Widget Function(String title, String message)? error,
  }) {
    return when(
      data: (value) => HookBuilder(builder: (context) => builder(value)),
      loading: loading != null
          ? () => loading(name)
          : () => LoadingIndicator(message: "Loading $name...", shrink: shrink),
      error: (e, stackTrace) {
        final title = "Failed to load $name";
        final message = e.toString();
        if (error != null) {
          return error(title, message);
        }
        if (shrink) {
          return ErrorScreen.small(
            title: "Failed to load $name",
            message: e.toString(),
          );
        }
        return ErrorScreen(
          title: "Failed to load $name",
          message: e.toString(),
          child: RetryIndicator(),
        );
      },
    );
  }

  bool matches(AsyncValue<T> other, bool Function(T a, T b) matcher) {
    if (runtimeType != other.runtimeType) return false;
    if (hasValue && other.hasValue) {
      return matcher(requireValue, other.requireValue);
    }
    return this == other;
  }

  void ensureReady() {
    if (isLoading) {
      throw StateException("Cannot perform operation while loading");
    }
    if (hasError) {
      throw StateException("Cannot perform operation while in error state");
    }
  }
}

extension RefExtension on Ref {
  Future<void> debounce(Duration duration) async {
    var didDispose = false;
    onDispose(() => didDispose = true);
    await Future.delayed(duration);

    /// Its safe to throw an exception as it will be caught by riverpod.
    if (didDispose) throw Exception("Debounce was disposed");
  }
}
