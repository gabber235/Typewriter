// ignore_for_file: prefer_initializing_formals

import "dart:async";

import "package:collection/collection.dart";
import "package:flutter/foundation.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:typewriter_panel/typewriter_panel.dart";

typedef CommandSurfaceEffectCallback = FutureOr<void> Function(
  SearchSurfaceEffect effect,
);

/// Owns one active search command and publishes its lifecycle to the surface.
class CommandController with ChangeNotifier {
  CommandController({
    required CommandSurfaceEffectCallback effectCallback,
    required SearchPromptHost prompts,
    List<SearchHostEffectExecutor<SearchHostEffect>> hostEffectExecutors =
        const [],
  }) : _effectCallback = effectCallback,
       _executionContext = SearchCommandExecutionContext(prompts: prompts),
       _hostEffectExecutors = _validateHostEffectExecutors(hostEffectExecutors);

  final CommandSurfaceEffectCallback _effectCallback;
  final SearchCommandExecutionContext _executionContext;
  final List<SearchHostEffectExecutor<SearchHostEffect>> _hostEffectExecutors;

  var _disposed = false;
  var _state = const SearchCommandExecutionState.idle();

  SearchCommandExecutionState get state => _state;

  SearchCommandSubmitResult execute(
    SearchCommand command,
    SearchCommandTarget target,
  ) {
    if (_state is SearchCommandRunning) {
      return SearchCommandSubmitResult.busy;
    }
    if (command.evaluate(target) is! SearchCommandEnabled) {
      return SearchCommandSubmitResult.notApplicable;
    }

    unawaited(_execute(command, target));
    return SearchCommandSubmitResult.submitted;
  }

  Future<void> _execute(
    SearchCommand command,
    SearchCommandTarget target,
  ) async {
    if (_disposed) return;

    final resultIds = target.selection.map((result) => result.id).toSet();
    _state = SearchCommandExecutionState.running(
      command: command.id,
      resultIds: resultIds,
    );
    notifyListeners();

    try {
      final result = await command.execute(_executionContext, target);
      if (_disposed) return;

      switch (result) {
        case SearchCommandResultCancelled():
          _state = const SearchCommandExecutionState.idle();
          notifyListeners();
          return;
        case SearchCommandResultFailed(:final message, :final surfaceEffect):
          _state = SearchCommandExecutionState.failed(
            command: command.id,
            resultIds: resultIds,
            message: message,
          );
          notifyListeners();
          await _effectCallback(surfaceEffect);
        case SearchCommandResultCompleted(
          :final surfaceEffect,
          :final hostEffects,
        ):
          _state = SearchCommandExecutionState.completed(
            command: command.id,
            resultIds: resultIds,
          );
          notifyListeners();
          await _effectCallback(surfaceEffect);
          await _executeHostEffects(hostEffects);
      }
    } on Object catch (error, stackTrace) {
      debugPrint(error.toString());
      debugPrint(stackTrace.toString());
      if (_disposed) return;
      _state = SearchCommandExecutionState.failed(
        command: command.id,
        resultIds: resultIds,
        message: error.toString(),
      );
      notifyListeners();
    }
    await _clearAutoReset();
  }

  Future<void> _executeHostEffects(List<SearchHostEffect> effects) async {
    for (final effect in effects) {
      final executor = _hostEffectExecutors
          .where((candidate) => candidate.accepts(effect))
          .firstOrNull;
      if (executor == null) {
        throw StateError(
          "No executor registered for host effect ${effect.runtimeType}.",
        );
      }
      await executor(effect);
    }
  }

  Future<void> _clearAutoReset() async {
    if (_disposed) return;
    await Future<void>.delayed(
      _state is SearchCommandFailed ? 10.seconds : 3.seconds,
    );
    if (_disposed || _state is SearchCommandRunning) return;
    _state = const SearchCommandExecutionState.idle();
    notifyListeners();
  }

  @override
  void dispose() {
    assert(!_disposed);
    _disposed = true;
    super.dispose();
  }
}

List<SearchHostEffectExecutor<SearchHostEffect>> _validateHostEffectExecutors(
  List<SearchHostEffectExecutor<SearchHostEffect>> executors,
) {
  final indexed = <Type>{};
  for (final executor in executors) {
    if (!indexed.add(executor.effectType)) {
      throw ArgumentError.value(
        executors,
        "executors",
        "Multiple executors registered for ${executor.effectType}.",
      );
    }
  }
  return List.unmodifiable(executors);
}
