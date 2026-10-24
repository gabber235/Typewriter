// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dialog_shortcuts.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Shortcuts that dialogs shown through [showAdvancedDialog] offer beside the
/// current mode's shortcuts.
///
/// Capabilities above the dialog layer, such as clearing the selection,
/// contribute them through appOverrides. Containers built without
/// appOverrides offer none.

@ProviderFor(dialogShortcuts)
final dialogShortcutsProvider = DialogShortcutsProvider._();

/// Shortcuts that dialogs shown through [showAdvancedDialog] offer beside the
/// current mode's shortcuts.
///
/// Capabilities above the dialog layer, such as clearing the selection,
/// contribute them through appOverrides. Containers built without
/// appOverrides offer none.

final class DialogShortcutsProvider
    extends
        $FunctionalProvider<
          List<ActionShortcut>,
          List<ActionShortcut>,
          List<ActionShortcut>
        >
    with $Provider<List<ActionShortcut>> {
  /// Shortcuts that dialogs shown through [showAdvancedDialog] offer beside the
  /// current mode's shortcuts.
  ///
  /// Capabilities above the dialog layer, such as clearing the selection,
  /// contribute them through appOverrides. Containers built without
  /// appOverrides offer none.
  DialogShortcutsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dialogShortcutsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dialogShortcutsHash();

  @$internal
  @override
  $ProviderElement<List<ActionShortcut>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<ActionShortcut> create(Ref ref) {
    return dialogShortcuts(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<ActionShortcut> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<ActionShortcut>>(value),
    );
  }
}

String _$dialogShortcutsHash() => r'1131991d5afe64b8a25d9efed63ee6b58372b151';
