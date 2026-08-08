// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'header.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

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
