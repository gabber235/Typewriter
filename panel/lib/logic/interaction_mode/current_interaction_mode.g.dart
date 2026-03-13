// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'current_interaction_mode.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Riverpod notifier that manages the current active interaction mode.
///
/// This notifier provides centralized state management for the modal interface
/// system, allowing components throughout the app to:
/// - Watch the current active mode
/// - Transition between modes
/// - Access mode-specific functionality in a type-safe manner

@ProviderFor(CurrentInteractionMode)
final currentInteractionModeProvider = CurrentInteractionModeProvider._();

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
  CurrentInteractionModeProvider._()
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

/// Riverpod notifier that manages the current active interaction mode.
///
/// This notifier provides centralized state management for the modal interface
/// system, allowing components throughout the app to:
/// - Watch the current active mode
/// - Transition between modes
/// - Access mode-specific functionality in a type-safe manner

abstract class _$CurrentInteractionMode extends $Notifier<InteractionMode> {
  InteractionMode build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<InteractionMode, InteractionMode>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<InteractionMode, InteractionMode>,
              InteractionMode,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
