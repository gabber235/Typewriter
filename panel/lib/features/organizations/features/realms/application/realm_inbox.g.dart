// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'realm_inbox.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Projects saved issues from publication and local activity from its owners.

@ProviderFor(realmInbox)
final realmInboxProvider = RealmInboxFamily._();

/// Projects saved issues from publication and local activity from its owners.

final class RealmInboxProvider
    extends
        $FunctionalProvider<RealmInboxState, RealmInboxState, RealmInboxState>
    with $Provider<RealmInboxState> {
  /// Projects saved issues from publication and local activity from its owners.
  RealmInboxProvider._({
    required RealmInboxFamily super.from,
    required AuthoringScope super.argument,
  }) : super(
         retry: null,
         name: r'realmInboxProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$realmInboxHash();

  @override
  String toString() {
    return r'realmInboxProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<RealmInboxState> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RealmInboxState create(Ref ref) {
    final argument = this.argument as AuthoringScope;
    return realmInbox(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RealmInboxState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RealmInboxState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is RealmInboxProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$realmInboxHash() => r'3943aa5eefe413f2530aec4bc99d03926b19fb43';

/// Projects saved issues from publication and local activity from its owners.

final class RealmInboxFamily extends $Family
    with $FunctionalFamilyOverride<RealmInboxState, AuthoringScope> {
  RealmInboxFamily._()
    : super(
        retry: null,
        name: r'realmInboxProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Projects saved issues from publication and local activity from its owners.

  RealmInboxProvider call(AuthoringScope scope) =>
      RealmInboxProvider._(argument: scope, from: this);

  @override
  String toString() => r'realmInboxProvider';
}

/// Reveals the editor for the issue location.

@ProviderFor(openRealmInboxLocation)
final openRealmInboxLocationProvider = OpenRealmInboxLocationFamily._();

/// Reveals the editor for the issue location.

final class OpenRealmInboxLocationProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Reveals the editor for the issue location.
  OpenRealmInboxLocationProvider._({
    required OpenRealmInboxLocationFamily super.from,
    required (AuthoringScope, skir.ValueLocation) super.argument,
  }) : super(
         retry: null,
         name: r'openRealmInboxLocationProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$openRealmInboxLocationHash();

  @override
  String toString() {
    return r'openRealmInboxLocationProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    final argument = this.argument as (AuthoringScope, skir.ValueLocation);
    return openRealmInboxLocation(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is OpenRealmInboxLocationProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$openRealmInboxLocationHash() =>
    r'548c7c10505604cc1afc5d730d3181c78951a4c3';

/// Reveals the editor for the issue location.

final class OpenRealmInboxLocationFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<bool>,
          (AuthoringScope, skir.ValueLocation)
        > {
  OpenRealmInboxLocationFamily._()
    : super(
        retry: null,
        name: r'openRealmInboxLocationProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Reveals the editor for the issue location.

  OpenRealmInboxLocationProvider call(
    AuthoringScope scope,
    skir.ValueLocation location,
  ) =>
      OpenRealmInboxLocationProvider._(argument: (scope, location), from: this);

  @override
  String toString() => r'openRealmInboxLocationProvider';
}
