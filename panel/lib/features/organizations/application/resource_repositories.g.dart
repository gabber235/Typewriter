// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resource_repositories.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides one resource repository owner for the active local work scope.
///
/// Rebuilding the scope creates fresh transport and catalog dependencies; disposal
/// cascades to all repositories cached by that owner.

@ProviderFor(resourceRepositories)
final resourceRepositoriesProvider = ResourceRepositoriesProvider._();

/// Provides one resource repository owner for the active local work scope.
///
/// Rebuilding the scope creates fresh transport and catalog dependencies; disposal
/// cascades to all repositories cached by that owner.

final class ResourceRepositoriesProvider
    extends
        $FunctionalProvider<
          ResourceRepositories,
          ResourceRepositories,
          ResourceRepositories
        >
    with $Provider<ResourceRepositories> {
  /// Provides one resource repository owner for the active local work scope.
  ///
  /// Rebuilding the scope creates fresh transport and catalog dependencies; disposal
  /// cascades to all repositories cached by that owner.
  ResourceRepositoriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'resourceRepositoriesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$resourceRepositoriesHash();

  @$internal
  @override
  $ProviderElement<ResourceRepositories> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ResourceRepositories create(Ref ref) {
    return resourceRepositories(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ResourceRepositories value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ResourceRepositories>(value),
    );
  }
}

String _$resourceRepositoriesHash() =>
    r'74f8e4613886352c3ae8a0a21db64ddd16ff3388';
