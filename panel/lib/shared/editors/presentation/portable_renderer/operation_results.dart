part of "../portable_presentation_renderer.dart";

@freezed
sealed class PortableOperationKey with _$PortableOperationKey {
  const factory PortableOperationKey.write(PortableDiagnosticTarget target) =
      _PortableWriteKey;
  const factory PortableOperationKey.execute(skir.EditorAction action) =
      _PortableExecuteKey;
  const factory PortableOperationKey.addItem(PortableDiagnosticTarget target) =
      _PortableAddItemKey;
  const factory PortableOperationKey.addMapRow(
    PortableDiagnosticTarget target,
  ) = _PortableAddMapRowKey;
  const factory PortableOperationKey.status() = _PortableStatusKey;
}

@freezed
abstract class PortableOperationOutcome with _$PortableOperationOutcome {
  const factory PortableOperationOutcome({
    required Object request,
    PortableDiagnosticObservation? input,
    @Default(false) bool pending,
    @Default([]) List<PortablePresentationDiagnostic> diagnostics,
  }) = _PortableOperationOutcome;
}

@freezed
abstract class PortableOperationState with _$PortableOperationState {
  const factory PortableOperationState({
    @Default({}) Map<PortableOperationKey, PortableOperationOutcome> outcomes,
  }) = _PortableOperationState;
  const PortableOperationState._();

  Set<Object> obsoleteRequests(
    PortableDiagnosticObservation? Function(PortableDiagnosticTarget) observe,
  ) => {
    for (final outcome in outcomes.values)
      if (outcome.input case final input?)
        if (observe(input.target) case final current?)
          if (current.value != input.value) outcome.request,
  };
}

/// Retains one latest outcome per operation without owning its edited value.
///
/// A newer request supersedes older completions. Known input changes permanently
/// retire their request tokens, and disposal prevents completion notifications.
/// The renderer or explicit scope caller owns this object's lifetime.
class PortableOperationResults extends ValueNotifier<PortableOperationState> {
  PortableOperationResults() : super(const PortableOperationState());
  bool _closed = false;
  ValueChanged<String>? onStatus;

  Future<void> run({
    required PortableOperationKey key,
    required FutureOr<PortablePresentationWriteResult> Function() operation,
    PortableDiagnosticObservation? input,
  }) async {
    if (_closed) return;
    final request = Object();
    final previous = value.outcomes[key];
    _put(
      key,
      PortableOperationOutcome(
        request: request,
        input: input,
        pending: true,
        diagnostics: previous?.input == input
            ? previous?.diagnostics ?? const []
            : const [],
      ),
    );
    PortablePresentationWriteResult result;
    try {
      result = await operation();
    } on Object catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: "portable presentation",
        ),
      );
      result = PortablePresentationWriteResult.rejected([
        PortablePresentationDiagnostic(
          code: "operation_failed",
          message: "This edit could not be completed",
          severity: skir.DiagnosticSeverity.error,
          targets: input == null ? const [] : [input.target],
        ),
      ]);
    }
    if (_closed || !identical(value.outcomes[key]?.request, request)) return;
    switch (result) {
      case PortablePresentationWriteApplied():
        value = value.copyWith(outcomes: {...value.outcomes}..remove(key));
      case PortablePresentationWriteRejected(:final diagnostics):
        _put(
          key,
          PortableOperationOutcome(
            request: request,
            input: input,
            diagnostics: diagnostics,
          ),
        );
        for (final diagnostic in diagnostics.where(
          (item) => item.targets.isEmpty,
        )) {
          onStatus?.call(diagnostic.message);
        }
    }
  }

  /// Stops completions from a replaced adapter while retaining settled feedback.
  void retirePending() {
    retire({
      for (final outcome in value.outcomes.values)
        if (outcome.pending) outcome.request,
    });
  }

  void retire(Set<Object> requests) {
    if (_closed || requests.isEmpty) return;
    value = value.copyWith(
      outcomes: {
        for (final entry in value.outcomes.entries)
          if (!requests.contains(entry.value.request)) entry.key: entry.value,
      },
    );
  }

  void reportStatus(String message) {
    if (_closed) return;
    _put(
      const PortableOperationKey.status(),
      PortableOperationOutcome(
        request: Object(),
        diagnostics: [
          PortablePresentationDiagnostic(
            code: "presentation_status",
            message: message,
            severity: skir.DiagnosticSeverity.error,
          ),
        ],
      ),
    );
    onStatus?.call(message);
  }

  void _put(PortableOperationKey key, PortableOperationOutcome outcome) {
    value = value.copyWith(outcomes: {...value.outcomes, key: outcome});
  }

  @override
  void dispose() {
    _closed = true;
    super.dispose();
  }
}
