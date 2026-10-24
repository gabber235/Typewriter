// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resource_session.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the resource session for the active local work scope.
///
/// A new scope or user replaces the session, which in turn replaces every
/// capability repository built on it.

@ProviderFor(resourceSession)
final resourceSessionProvider = ResourceSessionProvider._();

/// Provides the resource session for the active local work scope.
///
/// A new scope or user replaces the session, which in turn replaces every
/// capability repository built on it.

final class ResourceSessionProvider
    extends
        $FunctionalProvider<ResourceSession, ResourceSession, ResourceSession>
    with $Provider<ResourceSession> {
  /// Provides the resource session for the active local work scope.
  ///
  /// A new scope or user replaces the session, which in turn replaces every
  /// capability repository built on it.
  ResourceSessionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'resourceSessionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$resourceSessionHash();

  @$internal
  @override
  $ProviderElement<ResourceSession> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ResourceSession create(Ref ref) {
    return resourceSession(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ResourceSession value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ResourceSession>(value),
    );
  }
}

String _$resourceSessionHash() => r'cb8b639470bfcf5f64004602eda5057d1dd75158';
