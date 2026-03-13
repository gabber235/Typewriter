// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'header.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(currentHeaderActions)
final currentHeaderActionsProvider = CurrentHeaderActionsFamily._();

final class CurrentHeaderActionsProvider
    extends
        $FunctionalProvider<
          Map<String, HeaderActions>,
          Map<String, HeaderActions>,
          Map<String, HeaderActions>
        >
    with $Provider<Map<String, HeaderActions>> {
  CurrentHeaderActionsProvider._({
    required CurrentHeaderActionsFamily super.from,
    required EditorMode super.argument,
  }) : super(
         retry: null,
         name: r'currentHeaderActionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$currentHeaderActionsHash();

  @override
  String toString() {
    return r'currentHeaderActionsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<Map<String, HeaderActions>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Map<String, HeaderActions> create(Ref ref) {
    final argument = this.argument as EditorMode;
    return currentHeaderActions(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, HeaderActions> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, HeaderActions>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CurrentHeaderActionsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$currentHeaderActionsHash() =>
    r'1958ceb9ac3bd7a75d238f19bb3047cd43d00d66';

final class CurrentHeaderActionsFamily extends $Family
    with $FunctionalFamilyOverride<Map<String, HeaderActions>, EditorMode> {
  CurrentHeaderActionsFamily._()
    : super(
        retry: null,
        name: r'currentHeaderActionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CurrentHeaderActionsProvider call(EditorMode editorMode) =>
      CurrentHeaderActionsProvider._(argument: editorMode, from: this);

  @override
  String toString() => r'currentHeaderActionsProvider';
}

@ProviderFor(_actions)
final _actionsProvider = _ActionsFamily._();

final class _ActionsProvider
    extends $FunctionalProvider<HeaderActions, HeaderActions, HeaderActions>
    with $Provider<HeaderActions> {
  _ActionsProvider._({
    required _ActionsFamily super.from,
    required (String, EditorMode) super.argument,
  }) : super(
         retry: null,
         name: r'_actionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$_actionsHash();

  @override
  String toString() {
    return r'_actionsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<HeaderActions> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  HeaderActions create(Ref ref) {
    final argument = this.argument as (String, EditorMode);
    return _actions(ref, argument.$1, argument.$2);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HeaderActions value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HeaderActions>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is _ActionsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$_actionsHash() => r'67c26626e08138467847823c96e9cc5704a90188';

final class _ActionsFamily extends $Family
    with $FunctionalFamilyOverride<HeaderActions, (String, EditorMode)> {
  _ActionsFamily._()
    : super(
        retry: null,
        name: r'_actionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  _ActionsProvider call(String path, EditorMode editorMode) =>
      _ActionsProvider._(argument: (path, editorMode), from: this);

  @override
  String toString() => r'_actionsProvider';
}

@ProviderFor(headerActions)
final headerActionsProvider = HeaderActionsProvider._();

final class HeaderActionsProvider
    extends
        $FunctionalProvider<
          List<HeaderAction>,
          List<HeaderAction>,
          List<HeaderAction>
        >
    with $Provider<List<HeaderAction>> {
  HeaderActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'headerActionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$headerActionsHash();

  @$internal
  @override
  $ProviderElement<List<HeaderAction>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<HeaderAction> create(Ref ref) {
    return headerActions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<HeaderAction> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<HeaderAction>>(value),
    );
  }
}

String _$headerActionsHash() => r'bd44f37d9e3b17b666d45fb3c96d7df68f808980';
