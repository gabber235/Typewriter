// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'selection.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

@ProviderFor(Selection)
const selectionProvider = SelectionProvider._();

final class SelectionProvider
    extends $NotifierProvider<Selection, List<SelectableIdentifier>> {
  const SelectionProvider._()
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

String _$selectionHash() => r'0b3cb01f49d579076ec617a4141c23ac52d8ff45';

abstract class _$Selection extends $Notifier<List<SelectableIdentifier>> {
  List<SelectableIdentifier> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref
        as $Ref<List<SelectableIdentifier>, List<SelectableIdentifier>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<List<SelectableIdentifier>, List<SelectableIdentifier>>,
        List<SelectableIdentifier>,
        Object?,
        Object?>;
    element.handleValue(ref, created);
  }
}

@ProviderFor(hasSelection)
const hasSelectionProvider = HasSelectionProvider._();

final class HasSelectionProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  const HasSelectionProvider._()
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
const isSelectedProvider = IsSelectedFamily._();

final class IsSelectedProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  const IsSelectedProvider._(
      {required IsSelectedFamily super.from,
      required SelectableIdentifier super.argument})
      : super(
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
    return isSelected(
      ref,
      argument,
    );
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
  const IsSelectedFamily._()
      : super(
          retry: null,
          name: r'isSelectedProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  IsSelectedProvider call(
    SelectableIdentifier selectable,
  ) =>
      IsSelectedProvider._(argument: selectable, from: this);

  @override
  String toString() => r'isSelectedProvider';
}

@ProviderFor(Selected)
const selectedProvider = SelectedProvider._();

final class SelectedProvider
    extends $AsyncNotifierProvider<Selected, List<Selectable>> {
  const SelectedProvider._()
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
}

String _$selectedHash() => r'b9a198d55a39afef6d9b4f26cf0f360cb8b18e66';

abstract class _$Selected extends $AsyncNotifier<List<Selectable>> {
  FutureOr<List<Selectable>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<AsyncValue<List<Selectable>>, List<Selectable>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<List<Selectable>>, List<Selectable>>,
        AsyncValue<List<Selectable>>,
        Object?,
        Object?>;
    element.handleValue(ref, created);
  }
}

@ProviderFor(fieldValue)
const fieldValueProvider = FieldValueFamily._();

final class FieldValueProvider
    extends $FunctionalProvider<SelectedValue, SelectedValue, SelectedValue>
    with $Provider<SelectedValue> {
  const FieldValueProvider._(
      {required FieldValueFamily super.from, required String super.argument})
      : super(
          retry: null,
          name: r'fieldValueProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$fieldValueHash();

  @override
  String toString() {
    return r'fieldValueProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<SelectedValue> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SelectedValue create(Ref ref) {
    final argument = this.argument as String;
    return fieldValue(
      ref,
      argument,
    );
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SelectedValue value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SelectedValue>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FieldValueProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$fieldValueHash() => r'88e46cdafdbe694db5524d12915cdf9a9265ee29';

final class FieldValueFamily extends $Family
    with $FunctionalFamilyOverride<SelectedValue, String> {
  const FieldValueFamily._()
      : super(
          retry: null,
          name: r'fieldValueProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  FieldValueProvider call(
    String path,
  ) =>
      FieldValueProvider._(argument: path, from: this);

  @override
  String toString() => r'fieldValueProvider';
}

@ProviderFor(selectedDataBlueprint)
const selectedDataBlueprintProvider = SelectedDataBlueprintProvider._();

final class SelectedDataBlueprintProvider extends $FunctionalProvider<
    ObjectBlueprint?,
    ObjectBlueprint?,
    ObjectBlueprint?> with $Provider<ObjectBlueprint?> {
  const SelectedDataBlueprintProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'selectedDataBlueprintProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$selectedDataBlueprintHash();

  @$internal
  @override
  $ProviderElement<ObjectBlueprint?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ObjectBlueprint? create(Ref ref) {
    return selectedDataBlueprint(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ObjectBlueprint? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ObjectBlueprint?>(value),
    );
  }
}

String _$selectedDataBlueprintHash() =>
    r'2f96a34451bc57ff90a879d78150ddd175cd55e1';

@ProviderFor(selectedHeader)
const selectedHeaderProvider = SelectedHeaderProvider._();

final class SelectedHeaderProvider
    extends $FunctionalProvider<Widget?, Widget?, Widget?>
    with $Provider<Widget?> {
  const SelectedHeaderProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'selectedHeaderProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$selectedHeaderHash();

  @$internal
  @override
  $ProviderElement<Widget?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Widget? create(Ref ref) {
    return selectedHeader(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Widget? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Widget?>(value),
    );
  }
}

String _$selectedHeaderHash() => r'b6c7dab8571eee08f6a293fa86978574533c145f';

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
