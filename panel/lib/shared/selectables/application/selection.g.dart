// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'selection.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Selection)
final selectionProvider = SelectionProvider._();

final class SelectionProvider
    extends $NotifierProvider<Selection, List<SelectableIdentifier>> {
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

abstract class _$Selection extends $Notifier<List<SelectableIdentifier>> {
  List<SelectableIdentifier> build();
  @$mustCallSuper
  @override
  void runBuild() {
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
    element.handleCreate(ref, build);
  }
}

@ProviderFor(hasSelection)
final hasSelectionProvider = HasSelectionProvider._();

final class HasSelectionProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
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

@ProviderFor(isSelected)
final isSelectedProvider = IsSelectedFamily._();

final class IsSelectedProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
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

  IsSelectedProvider call(SelectableIdentifier selectable) =>
      IsSelectedProvider._(argument: selectable, from: this);

  @override
  String toString() => r'isSelectedProvider';
}

@ProviderFor(Selected)
final selectedProvider = SelectedProvider._();

final class SelectedProvider
    extends
        $NotifierProvider<
          Selected,
          AsyncValue<List<Selectable<SelectableIdentifier>>>
        > {
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

String _$selectedHash() => r'd3ec270254d95bc662ca45115f3bde037972decd';

abstract class _$Selected
    extends $Notifier<AsyncValue<List<Selectable<SelectableIdentifier>>>> {
  AsyncValue<List<Selectable<SelectableIdentifier>>> build();
  @$mustCallSuper
  @override
  void runBuild() {
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
    element.handleCreate(ref, build);
  }
}
