import "dart:async";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:hooks_riverpod/misc.dart";
import "package:rxdart/rxdart.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// Signals that an operation was requested while its provider state was not
/// ready to accept it.
class StateException implements Exception {
  const StateException(this.message);
  final String message;

  @override
  String toString() => message;
}

extension AsyncValueExtension<T> on AsyncValue<T> {
  /// Renders data, loading, and error states using the panel's standard widgets.
  ///
  /// [builder] receives data. Optional builders replace the default loading and
  /// error presentations. The source [AsyncValue] remains the state owner.
  Widget call({
    required String name,
    required Widget Function(T value) builder,
    bool shrink = false,
    bool skipLoadingOnReload = true,
    Widget Function(String name)? loading,
    Widget Function(String title, String message)? error,
  }) {
    return when(
      skipLoadingOnReload: skipLoadingOnReload,
      data: (value) => HookBuilder(builder: (context) => builder(value)),
      loading: loading != null
          ? () => loading(name)
          : () => LoadingIndicator(
              message: "Loading ${name.formatted}...",
              shrink: shrink,
            ),
      error: (e, stackTrace) {
        final title = "";
        final message = e.toString();
        if (error != null) {
          return error(title, message);
        }
        if (shrink) {
          return ErrorScreen.small(title: title, message: message);
        }
        return ErrorScreen(title: title, message: message);
      },
    );
  }

  /// Compares two states, using [matcher] when both states contain data.
  ///
  /// Non data states use [AsyncValue]'s equality, including their error and
  /// loading metadata.
  bool matches(AsyncValue<T> other, bool Function(T a, T b) matcher) {
    if (runtimeType != other.runtimeType) return false;
    if (hasValue && other.hasValue) {
      return matcher(requireValue, other.requireValue);
    }
    return this == other;
  }

  /// Throws [StateException] unless this state contains usable data.
  void ensureReady() {
    if (isLoading) {
      throw StateException("Cannot perform operation while loading");
    }
    if (hasError) {
      throw StateException("Cannot perform operation while in error state");
    }
  }

  /// Converts loading or error state while preserving its meaningful metadata.
  ///
  /// Returns `null` for a data state and for loading states that already carry
  /// a previous value, because those states remain usable by the caller.
  AsyncValue<O>? mapUnready<O>() => switch (this) {
    AsyncLoading(:final progress, :final value)
        when progress != null && value == null =>
      AsyncValue.loading(progress: progress),
    AsyncLoading(:final value) when value == null => AsyncValue.loading(),
    AsyncError(:final error, :final stackTrace) => AsyncValue.error(
      error,
      stackTrace,
    ),
    _ => null,
  };
}

/// Lifecycle aware helpers for Riverpod references.
extension RefExtension on Ref {
  /// Delays provider work and fails if the provider was disposed meanwhile.
  ///
  /// The failure is intentional. Riverpod catches it at the provider boundary,
  /// preventing delayed work from continuing after its owner is gone.
  Future<void> debounce(Duration duration) async {
    var didDispose = false;
    onDispose(() => didDispose = true);
    await Future.delayed(duration);

    if (didDispose) throw Exception("Debounce was disposed");
  }

  Stream<StateT> streamed<StateT>(ProviderListenable<StateT> provider) {
    final subject = BehaviorSubject<StateT>();
    onDispose(subject.close);
    listen(
      provider,
      fireImmediately: true,
      (previous, next) => subject.add(next),
    );
    return subject.stream;
  }

  ValueListenable<StateT> valued<StateT>(ProviderListenable<StateT> provider) {
    final notifier = ValueNotifier<StateT>(read(provider));
    listen(
      provider,
      fireImmediately: true,
      (previous, next) => notifier.value = next,
    );
    return notifier;
  }
}
