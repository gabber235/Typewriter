// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'current_interaction_mode.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

/// Riverpod notifier that manages the current active interaction mode.
///
/// This notifier provides centralized state management for the modal interface
/// system, allowing components throughout the app to:
/// - Watch the current active mode
/// - Transition between modes
/// - Access mode-specific functionality in a type-safe manner
@ProviderFor(CurrentInteractionMode)
const currentInteractionModeProvider = CurrentInteractionModeProvider._();

/// Riverpod notifier that manages the current active interaction mode.
///
/// This notifier provides centralized state management for the modal interface
/// system, allowing components throughout the app to:
/// - Watch the current active mode
/// - Transition between modes
/// - Access mode-specific functionality in a type-safe manner
final class CurrentInteractionModeProvider
    extends $NotifierProvider<CurrentInteractionMode, InteractionMode> {
  /// Riverpod notifier that manages the current active interaction mode.
  ///
  /// This notifier provides centralized state management for the modal interface
  /// system, allowing components throughout the app to:
  /// - Watch the current active mode
  /// - Transition between modes
  /// - Access mode-specific functionality in a type-safe manner
  const CurrentInteractionModeProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'currentInteractionModeProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$currentInteractionModeHash();

  @$internal
  @override
  CurrentInteractionMode create() => CurrentInteractionMode();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InteractionMode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InteractionMode>(value),
    );
  }
}

String _$currentInteractionModeHash() =>
    r'88cbef4900ef96fdde55db0a60861bc02d5cd68b';

abstract class _$CurrentInteractionMode extends $Notifier<InteractionMode> {
  InteractionMode build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<InteractionMode, InteractionMode>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<InteractionMode, InteractionMode>,
        InteractionMode,
        Object?,
        Object?>;
    element.handleValue(ref, created);
  }
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
