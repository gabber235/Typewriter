// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'selection.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Owns the canonical ordered list of selected identifiers.
///
/// Selection is independent from keyboard focus. Focus identifies the item
/// receiving keyboard input, while this provider represents the items acted on
/// by the inspector and batch operations. Widgets mutate this state through
/// the methods below; resolved selectable objects are derived by [Selected].

@ProviderFor(Selection)
final selectionProvider = SelectionProvider._();

/// Owns the canonical ordered list of selected identifiers.
///
/// Selection is independent from keyboard focus. Focus identifies the item
/// receiving keyboard input, while this provider represents the items acted on
/// by the inspector and batch operations. Widgets mutate this state through
/// the methods below; resolved selectable objects are derived by [Selected].
final class SelectionProvider
    extends $NotifierProvider<Selection, List<SelectableIdentifier>> {
  /// Owns the canonical ordered list of selected identifiers.
  ///
  /// Selection is independent from keyboard focus. Focus identifies the item
  /// receiving keyboard input, while this provider represents the items acted on
  /// by the inspector and batch operations. Widgets mutate this state through
  /// the methods below; resolved selectable objects are derived by [Selected].
  SelectionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectionHash();

  @$internal
  @override
  Selection create() => Selection();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<SelectableIdentifier> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<SelectableIdentifier>>(value),
    );
  }
}

String _$selectionHash() => r'd645c1a9fdfbbd8d448744b7dfec3cdd70631878';

/// Owns the canonical ordered list of selected identifiers.
///
/// Selection is independent from keyboard focus. Focus identifies the item
/// receiving keyboard input, while this provider represents the items acted on
/// by the inspector and batch operations. Widgets mutate this state through
/// the methods below; resolved selectable objects are derived by [Selected].

abstract class _$Selection extends $Notifier<List<SelectableIdentifier>> {
  List<SelectableIdentifier> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<List<SelectableIdentifier>, List<SelectableIdentifier>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                List<SelectableIdentifier>,
                List<SelectableIdentifier>
              >,
              List<SelectableIdentifier>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Whether at least one identifier is selected.

@ProviderFor(hasSelection)
final hasSelectionProvider = HasSelectionProvider._();

/// Whether at least one identifier is selected.

final class HasSelectionProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether at least one identifier is selected.
  HasSelectionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hasSelectionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hasSelectionHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return hasSelection(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$hasSelectionHash() => r'7cdf141b65386b5998eafaac1335fa4d897f6223';

/// Whether [selectable] is in the canonical selection.

@ProviderFor(isSelected)
final isSelectedProvider = IsSelectedFamily._();

/// Whether [selectable] is in the canonical selection.

final class IsSelectedProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether [selectable] is in the canonical selection.
  IsSelectedProvider._({
    required IsSelectedFamily super.from,
    required SelectableIdentifier super.argument,
  }) : super(
         retry: null,
         name: r'isSelectedProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$isSelectedHash();

  @override
  String toString() {
    return r'isSelectedProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    final argument = this.argument as SelectableIdentifier;
    return isSelected(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is IsSelectedProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$isSelectedHash() => r'12ed0fbd15b765b16a5b9e3afdb645cd81ea914d';

/// Whether [selectable] is in the canonical selection.

final class IsSelectedFamily extends $Family
    with $FunctionalFamilyOverride<bool, SelectableIdentifier> {
  IsSelectedFamily._()
    : super(
        retry: null,
        name: r'isSelectedProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Whether [selectable] is in the canonical selection.

  IsSelectedProvider call(SelectableIdentifier selectable) =>
      IsSelectedProvider._(argument: selectable, from: this);

  @override
  String toString() => r'isSelectedProvider';
}

/// Resolves the canonical identifier selection into current selectable objects.
///
/// This provider is the boundary between selection state and resource state.
/// It preserves the order of [selectionProvider], returns loading or error
/// state when any identifier cannot resolve, and publishes a complete list
/// only after every identifier has resolved.

@ProviderFor(Selected)
final selectedProvider = SelectedProvider._();

/// Resolves the canonical identifier selection into current selectable objects.
///
/// This provider is the boundary between selection state and resource state.
/// It preserves the order of [selectionProvider], returns loading or error
/// state when any identifier cannot resolve, and publishes a complete list
/// only after every identifier has resolved.
final class SelectedProvider
    extends
        $NotifierProvider<
          Selected,
          AsyncValue<List<Selectable<SelectableIdentifier>>>
        > {
  /// Resolves the canonical identifier selection into current selectable objects.
  ///
  /// This provider is the boundary between selection state and resource state.
  /// It preserves the order of [selectionProvider], returns loading or error
  /// state when any identifier cannot resolve, and publishes a complete list
  /// only after every identifier has resolved.
  SelectedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedHash();

  @$internal
  @override
  Selected create() => Selected();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(
    AsyncValue<List<Selectable<SelectableIdentifier>>> value,
  ) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<
            AsyncValue<List<Selectable<SelectableIdentifier>>>
          >(value),
    );
  }
}

String _$selectedHash() => r'22bff495d8332e0320ef87ba235ee6eb400d9c38';

/// Resolves the canonical identifier selection into current selectable objects.
///
/// This provider is the boundary between selection state and resource state.
/// It preserves the order of [selectionProvider], returns loading or error
/// state when any identifier cannot resolve, and publishes a complete list
/// only after every identifier has resolved.

abstract class _$Selected
    extends $Notifier<AsyncValue<List<Selectable<SelectableIdentifier>>>> {
  AsyncValue<List<Selectable<SelectableIdentifier>>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<Selectable<SelectableIdentifier>>>,
              AsyncValue<List<Selectable<SelectableIdentifier>>>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<Selectable<SelectableIdentifier>>>,
                AsyncValue<List<Selectable<SelectableIdentifier>>>
              >,
              AsyncValue<List<Selectable<SelectableIdentifier>>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
