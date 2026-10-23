// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'realm_inbox.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(realmInboxPopup)
final realmInboxPopupProvider = RealmInboxPopupFamily._();

final class RealmInboxPopupProvider
    extends
        $FunctionalProvider<
          AnchoredPopupController,
          AnchoredPopupController,
          AnchoredPopupController
        >
    with $Provider<AnchoredPopupController> {
  RealmInboxPopupProvider._({
    required RealmInboxPopupFamily super.from,
    required AuthoringScope super.argument,
  }) : super(
         retry: null,
         name: r'realmInboxPopupProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$realmInboxPopupHash();

  @override
  String toString() {
    return r'realmInboxPopupProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<AnchoredPopupController> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AnchoredPopupController create(Ref ref) {
    final argument = this.argument as AuthoringScope;
    return realmInboxPopup(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AnchoredPopupController value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AnchoredPopupController>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is RealmInboxPopupProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$realmInboxPopupHash() => r'fec72a75d7fdb3b8d6d9a6cd186938b7c2df9d43';

final class RealmInboxPopupFamily extends $Family
    with $FunctionalFamilyOverride<AnchoredPopupController, AuthoringScope> {
  RealmInboxPopupFamily._()
    : super(
        retry: null,
        name: r'realmInboxPopupProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  RealmInboxPopupProvider call(AuthoringScope scope) =>
      RealmInboxPopupProvider._(argument: scope, from: this);

  @override
  String toString() => r'realmInboxPopupProvider';
}
