// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'global_operation_shortcuts.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether selection shortcuts apply: only in [NormalMode] while interaction
/// is not suspended.

@ProviderFor(selectionShortcutsEnabled)
final selectionShortcutsEnabledProvider = SelectionShortcutsEnabledProvider._();

/// Whether selection shortcuts apply: only in [NormalMode] while interaction
/// is not suspended.

final class SelectionShortcutsEnabledProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether selection shortcuts apply: only in [NormalMode] while interaction
  /// is not suspended.
  SelectionShortcutsEnabledProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectionShortcutsEnabledProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectionShortcutsEnabledHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return selectionShortcutsEnabled(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$selectionShortcutsEnabledHash() =>
    r'6ecf8a246e384d6744f6bdf420492cc88dabc505';

/// The shortcut that clears the selection while selection shortcuts apply.
///
/// [GlobalOperationShortcuts] offers it, and the app offers it in dialogs
/// through [dialogShortcutsProvider].

@ProviderFor(selectionClearingShortcuts)
final selectionClearingShortcutsProvider =
    SelectionClearingShortcutsProvider._();

/// The shortcut that clears the selection while selection shortcuts apply.
///
/// [GlobalOperationShortcuts] offers it, and the app offers it in dialogs
/// through [dialogShortcutsProvider].

final class SelectionClearingShortcutsProvider
    extends
        $FunctionalProvider<
          List<ActionShortcut>,
          List<ActionShortcut>,
          List<ActionShortcut>
        >
    with $Provider<List<ActionShortcut>> {
  /// The shortcut that clears the selection while selection shortcuts apply.
  ///
  /// [GlobalOperationShortcuts] offers it, and the app offers it in dialogs
  /// through [dialogShortcutsProvider].
  SelectionClearingShortcutsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectionClearingShortcutsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectionClearingShortcutsHash();

  @$internal
  @override
  $ProviderElement<List<ActionShortcut>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<ActionShortcut> create(Ref ref) {
    return selectionClearingShortcuts(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<ActionShortcut> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<ActionShortcut>>(value),
    );
  }
}

String _$selectionClearingShortcutsHash() =>
    r'88ebed9bf9b1b0fdac5d8a508a6bed6daf944623';
