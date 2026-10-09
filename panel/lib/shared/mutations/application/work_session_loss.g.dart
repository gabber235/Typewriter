// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'work_session_loss.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Shares one session loss decision owner across account and route actions.

@ProviderFor(workSessionLoss)
final workSessionLossProvider = WorkSessionLossProvider._();

/// Shares one session loss decision owner across account and route actions.

final class WorkSessionLossProvider
    extends
        $FunctionalProvider<
          WorkSessionLossController,
          WorkSessionLossController,
          WorkSessionLossController
        >
    with $Provider<WorkSessionLossController> {
  /// Shares one session loss decision owner across account and route actions.
  WorkSessionLossProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workSessionLossProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workSessionLossHash();

  @$internal
  @override
  $ProviderElement<WorkSessionLossController> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WorkSessionLossController create(Ref ref) {
    return workSessionLoss(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WorkSessionLossController value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WorkSessionLossController>(value),
    );
  }
}

String _$workSessionLossHash() => r'd5a591ba70839ca1c28bc53e708f63182b6b11fa';
