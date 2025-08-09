// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'operations.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

/// Provides the complete registry of available [Operation] implementations.
/// Add new operations here to expose them to the UI
/// Keep ordering meaningful; it will be used for presentation where applicable.
@ProviderFor(operations)
const operationsProvider = OperationsProvider._();

/// Provides the complete registry of available [Operation] implementations.
/// Add new operations here to expose them to the UI
/// Keep ordering meaningful; it will be used for presentation where applicable.
final class OperationsProvider extends $FunctionalProvider<List<Operation>,
    List<Operation>, List<Operation>> with $Provider<List<Operation>> {
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

String _$operationsHash() => r'bc74e71a98b3515f038dbeac86599efce859c909';

/// Computes the subset of registered [Operation]s that are currently
/// executable for the active selection. Emits an empty list when there is
/// no selection or nothing applicable, allowing the UI to hide controls.
@ProviderFor(availableOperations)
const availableOperationsProvider = AvailableOperationsProvider._();

/// Computes the subset of registered [Operation]s that are currently
/// executable for the active selection. Emits an empty list when there is
/// no selection or nothing applicable, allowing the UI to hide controls.
final class AvailableOperationsProvider extends $FunctionalProvider<
    List<Operation>,
    List<Operation>,
    List<Operation>> with $Provider<List<Operation>> {
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
    r'9a668d4f67690f9352f28a5031274c940c544532';

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
