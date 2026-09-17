// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'current_interaction_mode.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Owns the panel's single current interaction mode.
///
/// The provider starts in [NormalMode]. Consumers watch its state to adapt
/// focus, shortcuts, and presentation. Callers request transitions through the
/// notifier; they do not mutate a mode instance. Replacing the state is
/// synchronous, and Riverpod notifies all current watchers of the new mode.

@ProviderFor(CurrentInteractionMode)
final currentInteractionModeProvider = CurrentInteractionModeProvider._();

/// Owns the panel's single current interaction mode.
///
/// The provider starts in [NormalMode]. Consumers watch its state to adapt
/// focus, shortcuts, and presentation. Callers request transitions through the
/// notifier; they do not mutate a mode instance. Replacing the state is
/// synchronous, and Riverpod notifies all current watchers of the new mode.
final class CurrentInteractionModeProvider
    extends $NotifierProvider<CurrentInteractionMode, InteractionMode> {
  /// Owns the panel's single current interaction mode.
  ///
  /// The provider starts in [NormalMode]. Consumers watch its state to adapt
  /// focus, shortcuts, and presentation. Callers request transitions through the
  /// notifier; they do not mutate a mode instance. Replacing the state is
  /// synchronous, and Riverpod notifies all current watchers of the new mode.
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
    r'a428df52265c6d3154956f72c2e4cb6dbb4fe6b8';

/// Owns the panel's single current interaction mode.
///
/// The provider starts in [NormalMode]. Consumers watch its state to adapt
/// focus, shortcuts, and presentation. Callers request transitions through the
/// notifier; they do not mutate a mode instance. Replacing the state is
/// synchronous, and Riverpod notifies all current watchers of the new mode.

abstract class _$CurrentInteractionMode extends $Notifier<InteractionMode> {
  InteractionMode build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<InteractionMode, InteractionMode>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<InteractionMode, InteractionMode>,
              InteractionMode,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
