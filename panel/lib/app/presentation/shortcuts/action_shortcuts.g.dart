// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'action_shortcuts.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Riverpod registry of mounted action sets and their winning actions.
///
/// Each action set owns its registration through a [GlobalKey]. Re registering
/// replaces that set's previous entries, while [sweep] removes entries whose
/// owner is no longer mounted. The registry is the shared source for keyboard
/// actions and the visible [ActionRow].

@ProviderFor(ActionShortcuts)
final actionShortcutsProvider = ActionShortcutsProvider._();

/// Riverpod registry of mounted action sets and their winning actions.
///
/// Each action set owns its registration through a [GlobalKey]. Re registering
/// replaces that set's previous entries, while [sweep] removes entries whose
/// owner is no longer mounted. The registry is the shared source for keyboard
/// actions and the visible [ActionRow].
final class ActionShortcutsProvider
    extends $NotifierProvider<ActionShortcuts, Map<String, ActionShortcut>> {
  /// Riverpod registry of mounted action sets and their winning actions.
  ///
  /// Each action set owns its registration through a [GlobalKey]. Re registering
  /// replaces that set's previous entries, while [sweep] removes entries whose
  /// owner is no longer mounted. The registry is the shared source for keyboard
  /// actions and the visible [ActionRow].
  ActionShortcutsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'actionShortcutsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$actionShortcutsHash();

  @$internal
  @override
  ActionShortcuts create() => ActionShortcuts();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, ActionShortcut> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, ActionShortcut>>(value),
    );
  }
}

String _$actionShortcutsHash() => r'bba5f306a5a974f4139fc669b110e6005ea7f0fc';

/// Riverpod registry of mounted action sets and their winning actions.
///
/// Each action set owns its registration through a [GlobalKey]. Re registering
/// replaces that set's previous entries, while [sweep] removes entries whose
/// owner is no longer mounted. The registry is the shared source for keyboard
/// actions and the visible [ActionRow].

abstract class _$ActionShortcuts
    extends $Notifier<Map<String, ActionShortcut>> {
  Map<String, ActionShortcut> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<Map<String, ActionShortcut>, Map<String, ActionShortcut>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                Map<String, ActionShortcut>,
                Map<String, ActionShortcut>
              >,
              Map<String, ActionShortcut>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
