// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'action_shortcuts.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ActionShortcuts)
final actionShortcutsProvider = ActionShortcutsProvider._();

final class ActionShortcutsProvider
    extends $NotifierProvider<ActionShortcuts, Map<String, ActionShortcut>> {
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

abstract class _$ActionShortcuts
    extends $Notifier<Map<String, ActionShortcut>> {
  Map<String, ActionShortcut> build();
  @$mustCallSuper
  @override
  void runBuild() {
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
    element.handleCreate(ref, build);
  }
}
