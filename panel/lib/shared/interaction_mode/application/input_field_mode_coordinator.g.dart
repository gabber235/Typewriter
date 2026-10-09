// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'input_field_mode_coordinator.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the coordinator that synchronizes input focus with interaction mode.
///
/// The provider owns the coordinator for its Riverpod container. Disposing that
/// container removes the global focus listener and clears registrations.

@ProviderFor(inputFieldModeCoordinator)
final inputFieldModeCoordinatorProvider = InputFieldModeCoordinatorProvider._();

/// Provides the coordinator that synchronizes input focus with interaction mode.
///
/// The provider owns the coordinator for its Riverpod container. Disposing that
/// container removes the global focus listener and clears registrations.

final class InputFieldModeCoordinatorProvider
    extends
        $FunctionalProvider<
          InputFieldModeCoordinator,
          InputFieldModeCoordinator,
          InputFieldModeCoordinator
        >
    with $Provider<InputFieldModeCoordinator> {
  /// Provides the coordinator that synchronizes input focus with interaction mode.
  ///
  /// The provider owns the coordinator for its Riverpod container. Disposing that
  /// container removes the global focus listener and clears registrations.
  InputFieldModeCoordinatorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inputFieldModeCoordinatorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inputFieldModeCoordinatorHash();

  @$internal
  @override
  $ProviderElement<InputFieldModeCoordinator> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  InputFieldModeCoordinator create(Ref ref) {
    return inputFieldModeCoordinator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InputFieldModeCoordinator value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InputFieldModeCoordinator>(value),
    );
  }
}

String _$inputFieldModeCoordinatorHash() =>
    r'df90847646df1c9981a98fb393b16a8013877c93';
