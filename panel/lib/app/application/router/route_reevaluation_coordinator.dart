import "dart:async";

import "package:flutter/foundation.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/app/application/router/access/route_access_coordinator.dart";

part "route_reevaluation_coordinator.freezed.dart";

@freezed
sealed class RouteReevaluationState with _$RouteReevaluationState {
  const factory RouteReevaluationState.idle() = RouteReevaluationIdle;
  const factory RouteReevaluationState.running({
    @Default(false) bool followUpRequested,
  }) = RouteReevaluationRunning;
  const factory RouteReevaluationState.disposed() = RouteReevaluationDisposed;
}

final class RouteReevaluationCoordinator {
  RouteReevaluationCoordinator({
    required RouteAccessCoordinator access,
    required Future<void> Function() reevaluateGuards,
  }) : _access = access,
       _reevaluateGuards = reevaluateGuards {
    _access.addListener(_requestReevaluation);
  }

  final RouteAccessCoordinator _access;
  final Future<void> Function() _reevaluateGuards;
  RouteReevaluationState _state = const RouteReevaluationState.idle();

  void _requestReevaluation() {
    switch (_state) {
      case RouteReevaluationIdle():
        _state = const RouteReevaluationState.running();
        unawaited(_drain());
      case RouteReevaluationRunning(followUpRequested: false):
        _state = const RouteReevaluationState.running(followUpRequested: true);
      case RouteReevaluationRunning(followUpRequested: true):
      case RouteReevaluationDisposed():
    }
  }

  Future<void> _drain() async {
    while (_state is RouteReevaluationRunning) {
      try {
        await _reevaluateGuards();
      } on Object catch (error, stackTrace) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: "Typewriter route reevaluation",
            context: ErrorDescription("while reevaluating route guards"),
          ),
        );
      }

      switch (_state) {
        case RouteReevaluationRunning(followUpRequested: false):
          _state = const RouteReevaluationState.idle();
        case RouteReevaluationRunning(followUpRequested: true):
          _state = const RouteReevaluationState.running();
        case RouteReevaluationDisposed():
          return;
        case RouteReevaluationIdle():
          throw StateError("Route reevaluation became idle while running");
      }
    }
  }

  void dispose() {
    if (_state is RouteReevaluationDisposed) return;
    _access.removeListener(_requestReevaluation);
    _state = const RouteReevaluationState.disposed();
  }
}
