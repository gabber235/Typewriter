// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'operations.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the complete registry of available [Operation] implementations.
/// Add new operations here to expose them to the UI
/// Keep ordering meaningful; it will be used for presentation where applicable.

@ProviderFor(operations)
const operationsProvider = OperationsProvider._();

/// Provides the complete registry of available [Operation] implementations.
/// Add new operations here to expose them to the UI
/// Keep ordering meaningful; it will be used for presentation where applicable.

final class OperationsProvider
    extends
        $FunctionalProvider<List<Operation>, List<Operation>, List<Operation>>
    with $Provider<List<Operation>> {
  /// Provides the complete registry of available [Operation] implementations.
  /// Add new operations here to expose them to the UI
  /// Keep ordering meaningful; it will be used for presentation where applicable.
  const OperationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'operationsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$operationsHash();

  @$internal
  @override
  $ProviderElement<List<Operation>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<Operation> create(Ref ref) {
    return operations(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Operation> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Operation>>(value),
    );
  }
}

String _$operationsHash() => r'5a93de0302f38a5bda7b48e4b57a09a906e76216';

/// Computes the subset of registered [Operation]s that are currently
/// executable for the active selection. Emits an empty list when there is
/// no selection or nothing applicable, allowing the UI to hide controls.

@ProviderFor(availableOperations)
const availableOperationsProvider = AvailableOperationsProvider._();

/// Computes the subset of registered [Operation]s that are currently
/// executable for the active selection. Emits an empty list when there is
/// no selection or nothing applicable, allowing the UI to hide controls.

final class AvailableOperationsProvider
    extends
        $FunctionalProvider<List<Operation>, List<Operation>, List<Operation>>
    with $Provider<List<Operation>> {
  /// Computes the subset of registered [Operation]s that are currently
  /// executable for the active selection. Emits an empty list when there is
  /// no selection or nothing applicable, allowing the UI to hide controls.
  const AvailableOperationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'availableOperationsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$availableOperationsHash();

  @$internal
  @override
  $ProviderElement<List<Operation>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<Operation> create(Ref ref) {
    return availableOperations(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Operation> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Operation>>(value),
    );
  }
}

String _$availableOperationsHash() =>
    r'8881f73674144088572f007a9f8c5dbf16869f4f';
